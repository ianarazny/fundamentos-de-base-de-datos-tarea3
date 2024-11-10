CREATE OR REPLACE FUNCTION ingreso_extra(
    codhotel INTEGER,
    OUT tipohab SMALLINT,
    OUT monto NUMERIC(8, 2)
)
RETURNS SETOF RECORD
AS
$$
DECLARE
    registro RECORD;
BEGIN
    FOR registro IN (
        SELECT h.tipo_habitacion_codigo as tipohab, 
               SUM((e.check_out - e.check_in) * c.precio_noche) AS monto
        FROM estadias_anteriores e
        JOIN habitaciones h ON e.hotel_codigo = h.hotel_codigo AND e.nro_habitacion = h.nro_habitacion
        JOIN costos_habitacion c ON e.hotel_codigo = c.hotel_codigo AND e.nro_habitacion = c.nro_habitacion
        WHERE e.hotel_codigo = codhotel
        	  AND NOT EXISTS (
					SELECT 1
            	FROM reservas_anteriores r
            	WHERE r.hotel_codigo = e.hotel_codigo
            	AND r.nro_habitacion = e.nro_habitacion
            	AND r.check_in = e.check_in
			  )
		GROUP BY tipohab
    ) LOOP
        tipohab := registro.tipohab;
        monto := registro.monto;
        RETURN NEXT; 
    END LOOP;
    RETURN;
END;
$$
LANGUAGE plpgsql;