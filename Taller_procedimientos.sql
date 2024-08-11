---Crear una nueva cuenta bancaria

create or replace procedure crear_cuenta_bancaria (
	id_cliente integer, 
	tipo_cuenta varchar(20),
	saldo_inicial numeric(15, 2))
	
language plpgsql
as $$
 
	declare numero_cuenta_nuevo int;
	declare existe boolean;
	 
    begin
		   if id_cliente = 0  then 
	       raise exception 'Debe ingresar el cliente';
       end if;
		
	   select case when count(1) > 0 then '1' else '0' end into existe
       from clientes  where cliente_id = id_cliente ;
	   if not existe then 
	      raise exception 'El cliente no esta registrado';
	   end if;
		
       existe = 1;
	   while existe = '1' loop
	    --numero_cuenta_nuevo = substr(cast(random() as text), 1, 20);
		numero_cuenta_nuevo = (floor(random() * 1000000000) + 1);
        select case when count(1) > 0 then '1' else '0' end into existe
          from cuentas_bancarias  where numero_cuenta = numero_cuenta_nuevo; 
       end loop;
	
  
	   insert into cuentas_bancarias(cliente_id, numero_cuenta, tipo_cuenta, saldo, 
									 fecha_apertura, estado)
	   values(id_cliente, numero_cuenta_nuevo, tipo_cuenta, saldo_inicial,
				current_timestamp, 'activa');
    end;
$$; 

--select * from cuentas_bancarias;

call crear_cuenta_bancaria(6, 'corriente', 220000000);

select * from cuentas_bancarias;

--Actualizar la informacion del cliente

create or replace procedure actualiza_cliente (
	id_cliente integer, 
	direccion_act varchar(100),
	telefono_act varchar(20),
    email_act varchar(200))
language plpgsql
as $$
   
	declare existe boolean;
	
    begin
	   if id_cliente = 0  then 
	      raise exception 'Debe ingresar el cliente';
       end if;
				
	   select case when count(1) > 0 then '1' else '0' end into existe
       from clientes  where cliente_id = id_cliente ;
	   if not existe then 
	      RAISE EXCEPTION 'El cliente no existe';
	   end if;
	
	   if direccion_act <> ' '  then 
	      update  clientes set direccion = direccion_act 	                        
	     where cliente_id = id_cliente;
       end if;
	   
	   if telefono_act <> ' '  then 
	       update  clientes set telefono = telefono_act
	       where cliente_id = id_cliente;
	   end if;
	   if email_act <> ' ' then 
	       update  clientes set  correo_electronico = email_act							
	       where cliente_id = id_cliente;
        END IF; 

    end;
$$;

select * from clientes;
call actualiza_cliente(3, 'Loma Linda', '3123456789', 'mgrisales@gmail.com');
select * from clientes;

---Eliminar una cuenta bancaria
create or replace procedure eliminar_cuenta_bancaria (
	id_cuenta integer)
language plpgsql
as $$
    
	declare existe boolean;

    begin
	  if id_cuenta = 0  then 
	      raise exception 'debe ingresar el id de cuenta a eliminar';
       end if;
	   
	   select case when count(1) > 0 then '1' else '0' end into existe
	    from cuentas_bancarias 
	   where cuenta_id = id_cuenta;
	   
	   if not existe  then 
	       raise exception 'Cuenta bancaria no existe';
       end if;
	       
	   delete  from transacciones 
	   where cuenta_id = id_cuenta;
	   
	   delete  from préstamos 
	   where cuenta_id = id_cuenta;
	   
	   delete  from tarjetas_credito 
	   where cuenta_id = id_cuenta;
	   
	   delete  from cuentas_bancarias 
	   where cuenta_id = id_cuenta;
    end;
$$;

select * from cuentas_bancarias; 
select * from préstamos where cuenta_id = 4; 
select * from tarjetas_credito;
select * from transacciones;


call eliminar_cuenta_bancaria(4);

--- Transferir fondos entre cuentas

create or replace procedure transferir_fondos (
	id_cuenta_origen integer, 
	id_cuenta_destino integer,
	transferencia numeric(15, 2),
    desc_transf varchar(100))
language plpgsql
as $$
   
	declare existe boolean;
 
    begin
	
	   if id_cuenta_origen = 0  then 
	       raise exception 'Debe ingresar id de cuenta origen';
       end if;
	   
	   if id_cuenta_destino = 0  then 
	       raise exception 'Debe ingresar id de cuenta destino';
       end if;
	   
	   if transferencia <= 0 then
	      raise exception 'Valor a trasnferir en cero o negativo';
	   end if;
	
       select case when count(1) > 0 then '1' else '0' end into existe
         from cuentas_bancarias  where cuenta_id = id_cuenta_origen; 
		 
	   if not existe then
	      raise exception 'Cuenta origen no Existe';
	   end if;
	   
	   select case when count(1) > 0 then '1' else '0' end into existe
         from cuentas_bancarias  where cuenta_id = id_cuenta_destino; 
		 
	   if not existe  then
	      raise exception 'Cuenta destino no Existe';
	   end if;
	
    
	   insert into transacciones(cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion) 
	   values(id_cuenta_origen, 'retiro', transferencia, current_timestamp, desc_transf);
	   
	   insert into transacciones(cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion) 
	   values(id_cuenta_destino, 'depósito', transferencia, current_timestamp, desc_transf);
	   
	   update cuentas_bancarias set saldo = saldo - transferencia 
	   where cuenta_id = id_cuenta_origen; 
	   update cuentas_bancarias set saldo = saldo + transferencia 
	   where cuenta_id = id_cuenta_destino; 
    end;
$$;

call transferir_fondos(3, 2, 1000000, 'Tranferencia pago impuesto carro');

-- Agregar una nueva transacción
create or replace procedure nueva_transaccion(
	id_cuenta integer, 
	transferencia numeric(15, 2),
	tipo_trans_nueva varchar(20),
    desc_trans varchar(100))
language plpgsql
as $$
    
	declare existe boolean;
 
    begin
		   if id_cuenta = 0  then 
	       raise exception 'Debe ingresar id de cuenta';
       end if;
	   
	   if transferencia <= 0 then
	      raise exception 'Valor a trasnferir en Cero o Negativo';
	   end if;
	
       select case when count(1) > 0 then '1' else '0' end into existe
         from cuentas_bancarias  where cuenta_id = id_cuenta; 
		 
	   if not existe  then
	      raise exception 'Cuenta no existe';
	   end if;
	   
	   if tipo_trans_nueva not in('depósito', 'retiro') then
	   	      raise exception 'tipo transacción no existe';
	   end if;
	
 
	   insert into transacciones(cuenta_id, tipo_transaccion, monto, fecha_transaccion, descripcion) 
	   values(id_cuenta, tipo_trans_nueva, transferencia, current_timestamp, desc_trans);
	   
	   if tipo_trans_nueva  = 'retiro' then
	   update cuentas_bancarias set saldo = saldo - transferencia where cuenta_id = id_cuenta;  
       
	   else
	   update cuentas_bancarias set saldo = saldo + transferencia where cuenta_id = id_cuenta;  
	   end if;
	end;
$$;

call nueva_transaccion(7, 20000000, 'retiro', 'Pago seguro carro');

--Calcular el saldo total de todas las cuentas de un cliente

create or replace function Saldo_cliente (id_cliente integer)
	returns numeric (15,2)
language plpgsql
as $$
   
	declare saldo_por_cliente numeric(15, 2) default 0.00;
	
    begin
	   
	   select sum(saldo)  into saldo_por_cliente
       from cuentas_bancarias  where cliente_id = id_cliente and estado = 'activa';
				
	   return saldo_por_cliente;
	
	   
    end;
$$;

select Saldo_cliente(6);

---
select *
       from transacciones 
	   where fecha_transaccion between '2024-08-01' and '2024-08-31';
    end;

create or replace function Rep_trans (fecha_inicial date, fecha_final date)
returns table(transaccion_id_bus integer,
			 cuenta_id_rep integer,
			 tipo_transaccion_rep varchar,
			 monto_rep  numeric,
			 fecha_transaccion_rep date,
			 descripcion_rep  varchar) 
 language plpgsql
 as $$
   
 
    begin
    -- logica de la funcion
	   return query
       select *
       from transacciones 
	   where fecha_transaccion between fecha_inicial and fecha_final;
    end;
$$;


select * from Rep_trans('2024-08-01', '2024-08-31');






