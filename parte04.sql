CREATE OR REPLACE FUNCTION verificar_costos() RETURNS TRIGGER AS $$
DECLARE
    estadias_sin_costo INTEGER;
BEGIN

    IF TG_OP = 'DELETE' THEN
		 IF NEW.hotel_codigo=NULL OR NEW.nro_habitacion=NULL OR NEW.fecha_desde=NULL OR 
            NEW.costo_noche=NULL OR NEW.precio_noche=NULL THEN
			RAISE NOTICE 'La operación de borrado no es correcta';
			RETURN NULL;   
         ELSEIF NOT EXISTS(SELECT 1
                      	   FROM costos_habitacion ch 
						   WHERE ch.hotel_codigo=OLD.hotel_codigo AND
                                 ch.nro_habitacion=OLD.nro_habitacion AND
                                 ch.fecha_desde=OLD.fecha_desde) THEN
			RAISE NOTICE 'La operación de borrado no es correcta';
            RETURN NULL;        
        ELSEIF EXISTS (
            SELECT 1
            FROM estadias_anteriores ea
            WHERE OLD.hotel_codigo=ea.hotel_codigo AND 
                  OLD.nro_habitacion=ea.nro_habitacion AND 
                  OLD.fecha_desde<=ea.check_in AND NOT EXISTS(
													SELECT 1
													FROM costos_habitacion ch
													WHERE OLD.hotel_codigo=ch.hotel_codigo AND 
														  OLD.nro_habitacion=ch.nro_habitacion AND 
														  ch.fecha_desde<=ea.check_in AND
														  OLD.fecha_desde<>ch.fecha_desde)) THEN
            RAISE NOTICE 'La operación de borrado no es correcta';
            RETURN NULL;
        ELSE
            RETURN OLD;
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
    	 IF NEW.hotel_codigo=NULL OR NEW.nro_habitacion=NULL OR NEW.fecha_desde=NULL OR 
            NEW.costo_noche=NULL OR NEW.precio_noche=NULL THEN
			RAISE NOTICE 'La actualización no es correcta';
            RETURN OLD;  
		  ELSEIF EXISTS(
					   SELECT 1
					   FROM costos_habitacion ch
					   WHERE ch.hotel_codigo = NEW.hotel_codigo AND
							 ch.nro_habitacion = NEW.nro_habitacion AND
							 ch.fecha_desde = NEW.fecha_desde) THEN
			RAISE NOTICE 'La actualización no es correcta';
			RETURN OLD;	
        ELSEIF NOT EXISTS(SELECT 1
                          FROM costos_habitacion ch
                          WHERE ch.hotel_codigo=OLD.hotel_codigo AND
                                ch.nro_habitacion=OLD.nro_habitacion AND
                                ch.fecha_desde=OLD.fecha_desde) THEN
			RAISE NOTICE 'La actualización no es correcta';
            RETURN OLD;
  		ELSEIF OLD.hotel_codigo=NEW.hotel_codigo AND
               OLD.nro_habitacion=NEW.nro_habitacion AND
               OLD.fecha_desde>=NEW.fecha_desde THEN
               RETURN NEW;        
        ELSEIF OLD.hotel_codigo=NEW.hotel_codigo AND
               OLD.nro_habitacion=NEW.nro_habitacion AND
               OLD.fecha_desde<NEW.fecha_desde AND EXISTS 
								 (SELECT 1
								  FROM estadias_anteriores ea
								  WHERE OLD.hotel_codigo=ea.hotel_codigo AND
										OLD.nro_habitacion=ea.nro_habitacion AND 
										OLD.fecha_desde<=ea.check_in AND NOT EXISTS(
												SELECT 1
												FROM costos_habitacion ch
												WHERE OLD.hotel_codigo=ch.hotel_codigo AND
													  OLD.nro_habitacion=ch.nro_habitacion AND 
													  ch.fecha_desde<=ea.check_in AND
													  OLD.fecha_desde<>ch.fecha_desde ))THEN
                    IF EXISTS (SELECT 1
							   FROM estadias_anteriores ea
							   WHERE OLD.hotel_codigo=ea.hotel_codigo AND
									 OLD.nro_habitacion=ea.nro_habitacion AND 
									 OLD.fecha_desde<=ea.check_in AND
									 NEW.fecha_desde>ea.check_in) THEN
						RAISE NOTICE 'La actualización no es correcta';
                   		RETURN OLD;
                    ELSE
                    	RETURN NEW;
                    END IF;     
        ELSEIF EXISTS (
            SELECT 1
            FROM estadias_anteriores ea
            WHERE OLD.hotel_codigo=ea.hotel_codigo AND
                  OLD.nro_habitacion=ea.nro_habitacion AND 
                  OLD.fecha_desde<=ea.check_in AND NOT EXISTS(
                                                    SELECT 1
                                                    FROM costos_habitacion ch
                                                    WHERE OLD.hotel_codigo=ch.hotel_codigo AND
                                                          OLD.nro_habitacion=ch.nro_habitacion AND 
                                                          ch.fecha_desde<=ea.check_in AND
                                                          OLD.fecha_desde<>ch.fecha_desde))THEN
            RAISE NOTICE 'La operacon de ACTUALIZACION no es correcta';
            RETURN OLD;
        ELSE
        RETURN NEW;
        END If;
    ELSE 
    RETURN NEW;
    END IF;

END;
$$ LANGUAGE plpgsql;

-- Crear el trigger para antes de la actualización
CREATE OR REPLACE TRIGGER control_costos
BEFORE DELETE OR UPDATE ON costos_habitacion
FOR EACH ROW
EXECUTE FUNCTION verificar_costos();