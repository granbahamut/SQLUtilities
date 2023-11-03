-- =======================================================================================================================================
-- Author: Ivan Dario Pinilla Torres
-- Description: Creación de tablas, carga de configuración de festivos y evento para disparar automáticamente la creación de festivos.
--
-- Parameters:
--  N/A
-- Returns:     
-- 	N/A
--
-- Change History:
--   2-11-2023 Ivan Dario Pinilla Torres: Creación de script para parametrización del procedimiento almacenado CalcularFestivos.
-- =======================================================================================================================================

-- ----------- Creación de tabla de configuración de festivos --------------- --

-- Categoria: 
-- 	1: Fija (Ver campos fecha_base_dia para el día fijo y fecha_base_mes para el mes fijo)
-- 	2: Segun pascua (ver campo regla), 
-- 	3: Trasladable (Ver campos fecha_base_dia para el día fijo y fecha_base_mes para el mes fijo y mover al siguiente lunes si la fecha no cae un lunes).
-- regla: 0: Sin regla, Si es mayor a 0:
-- -3: Jueves Santo
-- -2: Viernes Santo
-- 43: Ascención de Jesus
-- 64: Corpus Christi
-- 71: Sagrado corazon de Jesus
DROP TABLE IF EXISTS festivos_configuracion;
CREATE TABLE IF NOT EXISTS festivos_configuracion (
	festivo_id int not null,
    categoria int not null,
    nombre varchar(60) not null,
    fecha_base_dia int not null,
    fecha_base_mes int not null,
    regla int,
    PRIMARY KEY (festivo_id)
);

-- ----------- Creación de tabla para guardar los festivos calculados --------------- --

DROP TABLE IF EXISTS festivos;
CREATE TABLE IF NOT EXISTS festivos(
	festivo_id INT NOT NULL AUTO_INCREMENT,
    fecha date NOT NULL,
    config_id INT NOT NULL,
    PRIMARY KEY (festivo_id)
);

-- ----------- Cargue de reglas para calcular festivos --------------- --

INSERT INTO festivos_configuracion
VALUES 
(1, 1, "Año nuevo", 1, 1, 0), 
(2, 1, "Día del trabajo", 1, 5, 0), 
(3, 1, "Día de la independencia", 20, 7, 0), 
(4, 1, "batalla de Boyacá", 7, 8, 0), 
(5, 1, "Inmaculada concepción", 8, 12, 0), 
(6, 1, "Navidad", 25, 12, 0), 
(7, 2, "Jueves Santo", 0, 0, -3), 
(8, 2, "Viernes Santo", 0, 0, -2), 
(9, 2, "Ascención de Jesus", 0, 0, 43), 
(10, 2, "Corpus Christi", 0, 0, 64), 
(11, 2, "Sagrado corazón de Jesus", 0, 0, 71), 
(12, 3, "Epifanía (Reyes Magos)", 6, 1, 0), 
(13, 3, "Día de san Jose", 19, 3, 0), 
(14, 3, "San Pedro, San Pablo", 29, 6, 0), 
(15, 3, "Asunción de la virgen", 15, 8, 0), 
(16, 3, "Día de la raza", 12, 10, 0), 
(17, 3, "Todos los santos", 1, 11, 0), 
(18, 3, "Independencia de cartagena", 11, 11, 0);

-- ----------- Evento para lanzar automáticamente la creación de festivos --------------- --

SET GLOBAL event_scheduler = ON;
DROP EVENT IF EXISTS ACTUALIZADOR_FESTIVOS_EVT;
CREATE EVENT IF NOT EXISTS ACTUALIZADOR_FESTIVOS_EVT
ON SCHEDULE EVERY 1 YEAR STARTS '2023-01-01 00:00:00' -- <- Cambiar configuración a la fecha de inicio deseada e intervalo de ejecución.
ON COMPLETION PRESERVE -- <-- Convierte al evento en permanente.
COMMENT 'Este evento dispara la creación de festivos del año en que se ejecuta el evento.'
DO CALL CalcularFestivos(YEAR(NOW()) + 1); -- <-- Esto ejecuta el evento con el cálculo para el año siguiente al adicionar +1 al año actual.

SHOW EVENTS;