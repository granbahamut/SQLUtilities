-- =======================================================================================================================================
-- Author: Ivan Dario Pinilla Torres
-- Description: Calcula los días festivos segun calendario gregoriano para Colombia, adiciona 18 días festivos para un año específico.
--
-- Parameters:
--   @anio - Año a calcular einsertar en la base de datos.
-- Returns:     N/A
--
-- Change History:
--   2-11-2023 Ivan Dario Pinilla Torres: Creación del procedimiento almacenado.
-- =======================================================================================================================================

-- Validación de día de pascua por algoritmo de Gauss y solamente para calendario gregoriano (a partir del 1583 y hasta el año 2499):
-- A = anio
-- B = anio DIV 100 
-- C = anio MOD 100 
-- D = B DIV 4
-- E = B MOD 4
-- F = (B + 8) DIV 25 
-- G = (B - F + 1) DIV 3     
-- H = (19 x A + B - D - G + 15) MOD 30     
-- I = C DIV 4     
-- K = C MOD 4     
-- L = (32 + 2 x E + 2 x I - H - K) MOD 7     
-- M = (A + 11 x H + 22 x L) DIV 451     
-- P = 114 + H + L - 7 x M
-- La Pascua será el día (p MOD 31)+1 del mes p DIV 31

DROP PROCEDURE IF EXISTS CalcularFestivos;
DELIMITER //
CREATE PROCEDURE CalcularFestivos(anio INT)
	-- RETURNS DATE
	BEGIN
		-- ----------- Declarations --------------- --

		DECLARE a, b, c, d, e, f, g, h, i, k, l, m, p INT;
        DECLARE pp varchar(100);
		DECLARE pascua DATE;
		
        DECLARE terminado INT DEFAULT 0;
        DECLARE festivo_id INT;
        DECLARE categoria INT;
        DECLARE nombre varchar(60);
        DECLARE fecha_base_dia INT; 
        DECLARE fecha_base_mes INT; 
        DECLARE regla INT;
        DECLARE cur CURSOR FOR SELECT * FROM festivos_configuracion ORDER BY festivo_id;
        DECLARE CONTINUE HANDLER FOR NOT FOUND SET terminado = 1;
        
        -- ----------- Calculo de día de pascua (domingo de resurrección) ----------- --
        SET a = anio % 19;
		SET b = anio DIV 100;
		SET c = anio % 100;
		SET d = b DIV 4;
		SET e = b % 4;
		SET f = (b + 8) DIV 25;
        SET g = (b - f + 1) DIV 3;
        SET h = (19 * a + b - d - g + 15) % 30;
        SET i = c DIV 4;
        SET k = c % 4;
        SET l = (32 + 2 * e + 2 * i - h - k) MOD 7;
		SET m = (a + 11 * h + 22 * l) DIV 451;
		SET p = (114 + h + l - 7 * m);
        SET pascua = STR_TO_DATE(CONCAT((p%31)+1, "-", p DIV 31, "-", anio), '%d-%m-%Y');
        
        -- -----------Validación del festivo indicado ----------- --
        
        -- categoria 1: Festivo fijo: No se modifica la fecha (Ver campos fecha_base_dia para el día fijo y fecha_base_mes para el mes fijo en la tabla festivos_configuracion).
        -- categoria 2: Se mueve la fecha dependiente del día de pascua + el día de la regla según el festivo que sigue o precede la pascua.
        -- categoria 3: Se traslada al siguiente lunes, si el día en que cae no es un lunes.
        
        -- Primero valido si ya hay festivos para el año indicado, si los hay entonces el proceso saca un error:
        IF EXISTS(SELECT * FROM festivos WHERE YEAR(fecha) = anio) = 1 THEN 
			SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Festivos ya configurados para el año indicado';
        END IF;
        -- Si no hay festivos ya configurados, entonces inicio la carga:
        OPEN cur;
			label: LOOP
				FETCH cur INTO festivo_id, categoria, nombre, fecha_base_dia, fecha_base_mes, regla;
                IF terminado = 1 THEN LEAVE label;
				END IF;
				IF categoria = 1 THEN 
					INSERT INTO festivos (fecha, config_id) VALUES (STR_TO_DATE(CONCAT(fecha_base_dia, '-', fecha_base_mes, '-', anio), '%d-%m-%Y'), festivo_id);
                ELSEIF categoria = 2 THEN 
					-- Inserto el valor basado en el día de de pascua + la regla.
					INSERT INTO festivos (fecha, config_id) VALUES (DATE_ADD(pascua, INTERVAL regla DAY), festivo_id);
                ELSEIF categoria = 3 AND DAYOFWEEK(STR_TO_DATE(CONCAT(fecha_base_dia, '-', fecha_base_mes, '-', anio), '%d-%m-%Y')) <> 2 THEN -- 2 = Día de la semana -> Lunes
					BEGIN
						-- Realizo operación por modulo 7 para obtener el siguiente lunes por medio de la funcion INTERVAL(7 + 0 - día de la semana a evaluar MOD 7)
						INSERT INTO festivos (fecha, config_id) VALUES (STR_TO_DATE(CONCAT(fecha_base_dia, '-', fecha_base_mes, '-', anio), '%d-%m-%Y') + INTERVAL(7 + 0 - WEEKDAY(STR_TO_DATE(CONCAT(fecha_base_dia, '-', fecha_base_mes, '-', anio), '%d-%m-%Y'))) % 7 DAY, festivo_id);
                    END;
				ELSEIF categoria = 3 AND DAYOFWEEK(STR_TO_DATE(CONCAT(fecha_base_dia, '-', fecha_base_mes, '-', anio), '%d-%m-%Y')) = 2 THEN 
					BEGIN
						-- Inserto el valor sin calculos, porque es un lunes.
						INSERT INTO festivos (fecha, config_id) VALUES (STR_TO_DATE(CONCAT(fecha_base_dia, '-', fecha_base_mes, '-', anio), '%d-%m-%Y'), festivo_id);
					END;
				END IF;
            END LOOP label;
        CLOSE cur;
	END //    
DELIMITER ;
