CREATE TABLE public.finguitos_usuarios(
    cliente_documento INT ,
    hotel_codigo integer,
    check_in date,
    check_out date,
    fecha_inicio date,
    fecha_fin date,
    finguitos integer,
    fecha_operacion timestamp,
    estado smallint,
    PRIMARY KEY (cliente_documento, hotel_codigo, check_in)
);

CREATE OR REPLACE FUNCTION registrarFinguitos()
    RETURNS TRIGGER AS $$
    DECLARE 
        fing integer;
        ultimo_precio integer;
        fecha_ini integer;
        fecha_f integer;
        est integer;
        x RECORD;
        agregado integer;
        
        BEGIN
        

        ultimo_precio := (SELECT precio_noche
                          FROM costos_habitacion
                          WHERE fecha_desde <= CURRENT_DATE
                          ORDER BY fecha_desde DESC
                          LIMIT 1);
                          
        agregado:=0;
        IF EXISTS (SELECT 1
                   FROM estadias_anteriores ea
                   WHERE ea.cliente_documento=NEW.cliente_documento AND 
                         ea.hotel_codigo=NEW.cliente_documento AND ea.check_in<NEW.check_in)
         THEN
            agregado:=5;
        END If;
                          
        IF TG_OP = 'INSERT' THEN
            fing := trunc((NEW.check_out - NEW.check_in) * ultimo_precio / 10) + agregado;
            fecha_ini := (SELECT DATE_ADD(NEW.check_in, INTERVAL '1 month'));
            fecha_f := (SELECT DATE_ADD(NEW.check_out, INTERVAL '2 years'));
            IF fecha_f>= CURRENT_DATE THEN
                est:=1;
            ELSE
                est:=2;
            END IF;
            INSERT INTO finguitos_usuarios
            VALUES (NEW.cliente_documento, NEW.hotel_codigo, NEW.check_in, NEW.check_out, fecha_ini,
            fecha_f, fing, CURRENT_TIMESTAMP,est);
            
            FOR x IN(
                SELECT *
                FROM finguitos_usuarios fu
                WHERE fu.cliente_documento=NEW.cliente_documento
            )LOOP
                IF x.estado=1 AND x.fecha_fin<CURRENT_DATE THEN
                    UPDATE finguitos_usuarios
                    SET estado=2
                    WHERE finguitos_usuarios.cliente_documento=x.cliente_documento AND
                          finguitos_usuarios.hotel_codigo=x.hotel_codigo AND
                          finguitos_usuarios.check_in=x.check_in;
			    END IF;
            END LOOP;
            
            RETURN NEW;
        ELSEIF TG_OP = 'UPDATE' THEN
            IF EXISTS (
                SELECT 1
                FROM finguitos_usuarios fu
                WHERE fu.cliente_documento=OLD.cliente_documento AND 
                      fu.hotel_codigo=OLD.hotel_codigo AND
                      fu.check_in=OLD.check_in
                ) THEN
                fing := trunc((NEW.check_out - NEW.check_in) * ultimo_precio / 10)+agregado ;
                fecha_ini := (SELECT DATE_ADD(NEW.check_in, INTERVAL '1 month'));
                fecha_f := (SELECT DATE_ADD(NEW.check_out, INTERVAL '2 years'));
                IF fecha_f>= CURRENT_DATE THEN
                    est:=1;
                ELSE
                    est:=2;
                END IF;
                UPDATE finguitos_usuarios
                SET check_in=NEW.check_in,
                    check_out=NEW.check_out,
                    fecha_inicio=fecha_ini,
                    fecha_fin=fecha_f,
                    finguitos=fing,
                    fecha_operacion=CURRENT_TIMESTAMP,
                    estado=est
                WHERE finguitos_usuarios.cliente_documento=OLD.cliente_documento AND
                      finguitos_usuarios.hotel_codigo=OLD.hotel_codigo AND
                      finguitos_usuarios.check_in=OLD.check_in;
                FOR x IN(
                SELECT *
                FROM finguitos_usuarios fu
                WHERE fu.cliente_documento=NEW.cliente_documento
                )LOOP
                IF x.estado=1 AND x.fecha_fin<CURRENT_DATE THEN
                    UPDATE finguitos_usuarios
                    SET estado=2
                    WHERE finguitos_usuarios.cliente_documento=x.cliente_documento AND
                          finguitos_usuarios.hotel_codigo=x.hotel_codigo AND
                          finguitos_usuarios.check_in=x.check_in;
			    END IF;
                END LOOP;
			END IF;	
        ELSEIF TG_OP = 'DELETE' THEN
            UPDATE finguitos_usuarios
            SET estado=3,fecha_operacion=CURRENT_TIMESTAMP
            WHERE finguitos_usuarios.cliente_documento=OLD.cliente_documento AND
                  finguitos_usuarios.hotel_codigo=OLD.hotel_codigo AND
                  finguitos_usuarios.check_in=OLD.check_in; 
        END IF;
            
                    
                    
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER finguitos
AFTER INSERT OR UPDATE OR DELETE ON estadias_anteriores
FOR EACH ROW
EXECUTE FUNCTION registrarFinguitos();