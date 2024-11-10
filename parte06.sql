CREATE SEQUENCE logidseq
START 1
INCREMENT 1;



CREATE TABLE public.audit_estadia(
idop integer DEFAULT nextval('logidseq') PRIMARY KEY NOT NULL,
accion char(1) NOT NULL,
fecha date NOT NULL,
usuario text NOT NULL,
cliente_documento integer NOT NULL,
hotel_codigo integer NOT NULL,
nro_habitacion integer NOT NULL,
check_in date NOT NULL
);

CREATE OR REPLACE FUNCTION sumarOperacion()
RETURNS TRIGGER AS $$
DECLARE
    
BEGIN
    IF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_estadia (accion, fecha, usuario, cliente_documento, hotel_codigo, nro_habitacion, check_in)
        VALUES ('U', CURRENT_DATE, CURRENT_USER, OLD.cliente_documento, OLD.hotel_codigo, OLD.nro_habitacion, OLD.check_in);
        
        RETURN NEW;
    ELSEIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_estadia (accion, fecha, usuario, cliente_documento, hotel_codigo, nro_habitacion, check_in)
        VALUES ('D', CURRENT_DATE, CURRENT_USER, OLD.cliente_documento, OLD.hotel_codigo, OLD.nro_habitacion, OLD.check_in); 
        
        RETURN NEW;
    ELSEIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_estadia (accion, fecha, usuario, cliente_documento, hotel_codigo, nro_habitacion, check_in)
        VALUES ('I', CURRENT_DATE, CURRENT_USER, NEW.cliente_documento, NEW.hotel_codigo, NEW.nro_habitacion, NEW.check_in);
        
        RETURN NEW;
    END If;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER auditoria_estadias
AFTER UPDATE OR DELETE OR INSERT 
ON estadias_anteriores
FOR EACH ROW
EXECUTE FUNCTION sumarOperacion()
