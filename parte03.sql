CREATE TABLE public.resumen (
    pais_codigo CHAR(2) NOT NULL,
    cant_estrellas SMALLINT NOT NULL,
    total_extra NUMERIC (10,2),
    FOREIGN KEY (pais_codigo) REFERENCES paises(pais_codigo)
);

CREATE OR REPLACE FUNCTION generar_reporte()
RETURNS VOID
AS $$
DECLARE
	x RECORD;
   
BEGIN
 	INSERT INTO resumen(pais_codigo,cant_estrellas,total_extra)
		SELECT pa.pais_codigo,n , 0
   		FROM paises pa CROSS JOIN generate_series(1, 5) AS n
    	GROUP BY pa.pais_codigo, n;

 	FOR x IN(
 		SELECT h.pais_codigo as npais, h.estrellas as nestrellas, SUM(COALESCE(ie.monto, 0)) as nmonto
    	FROM hoteles h JOIN habitaciones hab ON h.hotel_codigo =hab.hotel_codigo
    	JOIN ingreso_extra(h.hotel_codigo) AS ie ON ie.tipohab=hab.tipo_habitacion_codigo
    	GROUP BY h.pais_codigo, h.estrellas
 	)LOOP
 		UPDATE resumen
 		SET total_extra=x.nmonto
 		WHERE pais_codigo=x.npais AND cant_estrellas=x.nestrellas;
	END LOOP;
	
	FOR x IN(
		SELECT r.pais_codigo as npais,r.cant_estrellas as nestrellas, r.total_extra as nmonto
		FROM resumen r
		ORDER BY r.pais_codigo,r.cant_estrellas
	)LOOP
		UPDATE resumen
 		SET total_extra=x.nmonto
 		WHERE pais_codigo=x.npais AND cant_estrellas=x.nestrellas;
	END LOOP;


END;
$$ LANGUAGE plpgsql;