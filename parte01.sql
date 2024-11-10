CREATE OR REPLACE FUNCTION actividad_cliente(
    codigo CHAR(1),
    clientedoc INTEGER,
    anio INTEGER
)
RETURNS INTEGER
AS $$
DECLARE
    actividad INTEGER;
BEGIN
    actividad := 0;
    IF NOT EXISTS (SELECT 1 FROM clientes WHERE clientes.cliente_documento = clientedoc) THEN  
		RAISE NOTICE 'No existe el cliente';
    ELSE
        IF codigo IN ('R', 'r') THEN
            SELECT COUNT(*) INTO actividad
            FROM reservas_anteriores as ra
   			WHERE ra.cliente_documento = clientedoc AND EXTRACT(YEAR FROM ra.fecha_reserva) = anio;
        ELSIF codigo IN ('E', 'e') THEN
            SELECT COUNT(*) INTO actividad
            FROM estadias_anteriores as ea
            WHERE ea.cliente_documento = clientedoc AND EXTRACT(YEAR FROM ea.check_in) = anio;
        ELSE
            RAISE NOTICE 'Código de operación incorrecto';
        END IF;
    END IF;
    RETURN actividad;
END;
$$
LANGUAGE plpgsql;