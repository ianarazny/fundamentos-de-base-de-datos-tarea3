CREATE TABLE registro_uso(
usuario text NOT NULL,
tabla name NOT NULL,
fecha date NOT NULL,
cantidad integer,
PRIMARY KEY(usuario,tabla,fecha)
);

CREATE OR REPLACE FUNCTION sumarRegistro()
RETURNS TRIGGER AS $$
DECLARE
    usr text;
    tab name;
    fec date;
BEGIN
    usr := CURRENT_USER;
    tab := TG_TABLE_NAME; 
    fec := CURRENT_DATE;

    IF TG_OP = 'DELETE' THEN
    IF EXISTS (SELECT 1
               FROM registro_uso ru
               WHERE ru.usuario=usuario AND ru.tabla=tabla AND ru.fecha=fecha)
            THEN
                
                UPDATE registro_uso
                SET cantidad=cantidad+1
                WHERE usuario=usr AND tabla=tab AND fecha=fec;
    ELSE
            INSERT INTO registro_uso(usuario,tabla,fecha,cantidad)
            VALUES (usr,tab,fec,1);
  	END IF;
            RETURN OLD;
    ELSEIF TG_OP='UPDATE' OR TG_OP='INSERT' THEN
        IF EXISTS (SELECT 1
               FROM registro_uso ru
               WHERE ru.usuario=usuario AND ru.tabla=tabla AND ru.fecha=fecha)
            THEN
                
                UPDATE registro_uso
                SET cantidad=cantidad+1
                WHERE usuario=usr AND tabla=tab AND fecha=fec;
  		ELSE
            INSERT INTO registro_uso(usuario,tabla,fecha,cantidad)
            VALUES (usr,tab,fec,1);
  		END IF;
            RETURN NEW; 
    END IF;
END;
$$ LANGUAGE plpgsql;



CREATE OR REPLACE TRIGGER registro_operaciones
BEFORE DELETE OR UPDATE OR INSERT ON estadias_anteriores 
FOR EACH STATEMENT
EXECUTE FUNCTION sumarRegistro();

CREATE OR REPLACE TRIGGER registro_operaciones2
BEFORE DELETE OR UPDATE OR INSERT ON clientes 
FOR EACH STATEMENT
EXECUTE FUNCTION sumarRegistro();


CREATE OR REPLACE TRIGGER registro_operaciones3
BEFORE DELETE OR UPDATE OR INSERT ON reservas_anteriores 
FOR EACH STATEMENT
EXECUTE FUNCTION sumarRegistro();