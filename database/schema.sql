-- ============================================
-- BASE DE DATOS: TRANSPORTE INTELIGENTE
-- SISTEMA DE RASTREO GPS - LÍNEA 18 JULIACA
-- ============================================

-- ============================================
-- 1. LIMPIAR BASE DE DATOS (si existe)
-- ============================================
DROP TABLE IF EXISTS ubicaciones_tiempo_real CASCADE;
DROP TABLE IF EXISTS ruta_paradas CASCADE;
DROP TABLE IF EXISTS asignaciones_bus_conductor CASCADE;
DROP TABLE IF EXISTS buses CASCADE;
DROP TABLE IF EXISTS paradas CASCADE;
DROP TABLE IF EXISTS rutas CASCADE;
DROP TABLE IF EXISTS conductores CASCADE;
DROP VIEW IF EXISTS vista_buses_activos CASCADE;
DROP FUNCTION IF EXISTS calcular_distancia CASCADE;
DROP FUNCTION IF EXISTS obtener_ultima_ubicacion CASCADE;

-- ============================================
-- 2. CREAR TABLAS
-- ============================================

-- Tabla: RUTAS
CREATE TABLE rutas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    color VARCHAR(7) DEFAULT '#FF5733',
    distancia_total DECIMAL(6,2),
    tiempo_promedio INT, -- minutos
    precio_pasaje DECIMAL(4,2) DEFAULT 1.50,
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla: PARADAS
CREATE TABLE paradas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(255),
    latitud DECIMAL(10,8) NOT NULL,
    longitud DECIMAL(11,8) NOT NULL,
    codigo VARCHAR(20) UNIQUE,
    tipo VARCHAR(50), -- 'terminal', 'mercado', 'universidad', 'plaza', 'normal'
    referencia TEXT, -- punto de referencia cercano
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice para búsquedas geoespaciales rápidas
CREATE INDEX idx_paradas_coords ON paradas(latitud, longitud);

-- Tabla: RUTA_PARADAS (relación muchos a muchos)
CREATE TABLE ruta_paradas (
    id SERIAL PRIMARY KEY,
    ruta_id INT REFERENCES rutas(id) ON DELETE CASCADE,
    parada_id INT REFERENCES paradas(id) ON DELETE CASCADE,
    orden INT NOT NULL,
    tiempo_estimado INT, -- minutos desde la parada anterior
    distancia_km DECIMAL(5,2), -- km desde la parada anterior
    es_parada_principal BOOLEAN DEFAULT false,
    UNIQUE(ruta_id, parada_id),
    UNIQUE(ruta_id, orden)
);

-- Tabla: CONDUCTORES
CREATE TABLE conductores (
    id SERIAL PRIMARY KEY,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    dni VARCHAR(8) UNIQUE NOT NULL,
    licencia VARCHAR(20),
    telefono VARCHAR(15),
    email VARCHAR(100),
    fecha_nacimiento DATE,
    direccion TEXT,
    estado VARCHAR(20) DEFAULT 'activo', -- activo, inactivo, suspendido
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla: BUSES
CREATE TABLE buses (
    id SERIAL PRIMARY KEY,
    placa VARCHAR(10) UNIQUE NOT NULL,
    ruta_id INT REFERENCES rutas(id),
    modelo VARCHAR(50),
    capacidad INT DEFAULT 40,
    tipo VARCHAR(20) DEFAULT 'diesel', -- diesel, GNV, electrico
    anio_fabricacion INT,
    numero_interno VARCHAR(10), -- número visible en el bus
    color VARCHAR(50) DEFAULT 'amarillo',
    estado VARCHAR(20) DEFAULT 'activo', -- activo, mantenimiento, inactivo
    dispositivo_gps VARCHAR(50),
    ultima_revision DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla: ASIGNACIONES (bus + conductor)
CREATE TABLE asignaciones_bus_conductor (
    id SERIAL PRIMARY KEY,
    bus_id INT REFERENCES buses(id) ON DELETE CASCADE,
    conductor_id INT REFERENCES conductores(id) ON DELETE CASCADE,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE,
    turno VARCHAR(20), -- mañana, tarde, noche
    activo BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla: UBICACIONES_TIEMPO_REAL
CREATE TABLE ubicaciones_tiempo_real (
    id SERIAL PRIMARY KEY,
    bus_id INT REFERENCES buses(id) ON DELETE CASCADE,
    latitud DECIMAL(10,8) NOT NULL,
    longitud DECIMAL(11,8) NOT NULL,
    velocidad DECIMAL(5,2) DEFAULT 0, -- km/h
    direccion INT, -- grados (0-360, norte = 0)
    altitud DECIMAL(6,2), -- metros sobre el nivel del mar
    precision_gps DECIMAL(5,2), -- precisión en metros
    fecha_registro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índice para consultas de última ubicación (muy usado)
CREATE INDEX idx_ubicaciones_bus_time ON ubicaciones_tiempo_real(bus_id, fecha_registro DESC);
CREATE INDEX idx_ubicaciones_fecha ON ubicaciones_tiempo_real(fecha_registro DESC);

-- ============================================
-- 3. FUNCIONES ÚTILES
-- ============================================

-- Función: Calcular distancia entre dos puntos (Haversine)
CREATE OR REPLACE FUNCTION calcular_distancia(
    lat1 DECIMAL, lon1 DECIMAL, 
    lat2 DECIMAL, lon2 DECIMAL
) RETURNS DECIMAL AS $$
DECLARE
    R DECIMAL := 6371; -- Radio de la Tierra en km
    dLat DECIMAL;
    dLon DECIMAL;
    a DECIMAL;
    c DECIMAL;
BEGIN
    dLat := RADIANS(lat2 - lat1);
    dLon := RADIANS(lon2 - lon1);
    
    a := SIN(dLat/2) * SIN(dLat/2) + 
         COS(RADIANS(lat1)) * COS(RADIANS(lat2)) * 
         SIN(dLon/2) * SIN(dLon/2);
    
    c := 2 * ATAN2(SQRT(a), SQRT(1-a));
    
    RETURN ROUND((R * c)::numeric, 2);
END;
$$ LANGUAGE plpgsql;

-- Función: Obtener última ubicación de un bus
CREATE OR REPLACE FUNCTION obtener_ultima_ubicacion(p_bus_id INT)
RETURNS TABLE(
    bus_id INT,
    placa VARCHAR,
    latitud DECIMAL,
    longitud DECIMAL,
    velocidad DECIMAL,
    fecha_registro TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        b.id,
        b.placa,
        u.latitud,
        u.longitud,
        u.velocidad,
        u.fecha_registro
    FROM buses b
    JOIN ubicaciones_tiempo_real u ON b.id = u.bus_id
    WHERE b.id = p_bus_id
    ORDER BY u.fecha_registro DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- Vista: Buses activos con su última ubicación y conductor
CREATE OR REPLACE VIEW vista_buses_activos AS
SELECT 
    b.id AS bus_id,
    b.placa,
    b.numero_interno,
    b.modelo,
    b.capacidad,
    b.ruta_id,
    r.nombre AS ruta_nombre,
    r.color AS ruta_color,
    r.precio_pasaje,
    u.latitud,
    u.longitud,
    u.velocidad,
    u.direccion,
    u.fecha_registro,
    c.nombres || ' ' || c.apellidos AS conductor_nombre,
    c.telefono AS conductor_telefono
FROM buses b
JOIN rutas r ON b.ruta_id = r.id
LEFT JOIN asignaciones_bus_conductor abc ON b.id = abc.bus_id AND abc.activo = true
LEFT JOIN conductores c ON abc.conductor_id = c.id
JOIN LATERAL (
    SELECT latitud, longitud, velocidad, direccion, fecha_registro
    FROM ubicaciones_tiempo_real
    WHERE bus_id = b.id
    ORDER BY fecha_registro DESC
    LIMIT 1
) u ON true
WHERE b.estado = 'activo' AND r.activa = true;

-- ============================================
-- 4. DATOS REALES - LÍNEA 18 JULIACA
-- ============================================

-- Insertar Ruta: Línea 18
INSERT INTO rutas (nombre, descripcion, color, distancia_total, tiempo_promedio, precio_pasaje) VALUES
('Línea 18', 'Terminal Terrestre - UPEU (Chullunquiani)', '#FF9800', 18.5, 55, 1.50);

-- Insertar Paradas de la Línea 18 (COORDENADAS REALES)
INSERT INTO paradas (nombre, direccion, latitud, longitud, codigo, tipo, referencia) VALUES
-- Inicio
('Terminal Terrestre Juliaca', 'Av. Independencia s/n', -15.489722, -70.132778, 'L18-P01', 'terminal', 'Salida hacia Puno'),
('Jr. Moquegua', 'Jr. Moquegua con Jr. 2 de Mayo', -15.491111, -70.131667, 'L18-P02', 'normal', 'Cerca al Mercado Central'),

-- Zona de Mercados
('Mercado Central', 'Jr. Melgar esquina Moquegua', -15.492500, -70.130278, 'L18-P03', 'mercado', 'Mercado principal de abarrotes'),
('Mercado Santa Bárbara', 'Jr. Lambayeque', -15.497500, -70.132000, 'L18-P04', 'mercado', 'Mercado mayorista'),
('Mercado Túpac Amaru', 'Av. Túpac Amaru', -15.495833, -70.128611, 'L18-P05', 'mercado', 'Mercado de La Capilla'),

-- Centro
('Plaza Bolognesi', 'Jr. San Román con Jr. Núñez', -15.492000, -70.128500, 'L18-P06', 'plaza', 'Plaza principal de Juliaca'),
('Jr. San Martín - Centro', 'Jr. San Martín 450', -15.500000, -70.136500, 'L18-P07', 'normal', 'Zona comercial'),

-- Zona Institucional
('SENATI Juliaca', 'Av. Circunvalación', -15.485000, -70.142000, 'L18-P08', 'instituto', 'Instituto Técnico'),
('IST Juliaca', 'Av. Huancané', -15.480000, -70.145000, 'L18-P09', 'instituto', 'Instituto Superior Tecnológico'),

-- Zona Norte
('Av. Circunvalación Norte', 'Cruce Salida a Huancané', -15.475000, -70.150000, 'L18-P10', 'normal', 'Zona residencial norte'),
('Urbanización Taparachi', 'Sector Taparachi', -15.470000, -70.155000, 'L18-P11', 'normal', 'Zona residencial'),

-- Final - Universidad
('UPEU - Entrada Principal', 'Carretera Juliaca-Arequipa Km 6', -15.467222, -70.158333, 'L18-P12', 'universidad', 'Universidad Peruana Unión'),
('UPEU - Campus', 'Chullunquiani', -15.465000, -70.160000, 'L18-P13', 'universidad', 'Paradero final dentro del campus');

-- Relacionar paradas con la Ruta 18
INSERT INTO ruta_paradas (ruta_id, parada_id, orden, tiempo_estimado, distancia_km, es_parada_principal) VALUES
(1, 1, 1, 0, 0, true),      -- Terminal Terrestre (inicio)
(1, 2, 2, 3, 0.5, false),   -- Jr. Moquegua
(1, 3, 3, 4, 0.8, true),    -- Mercado Central
(1, 4, 4, 5, 1.2, true),    -- Santa Bárbara
(1, 5, 5, 4, 0.9, true),    -- Túpac Amaru
(1, 6, 6, 3, 0.7, true),    -- Plaza Bolognesi
(1, 7, 7, 6, 1.8, false),   -- San Martín
(1, 8, 8, 7, 2.5, true),    -- SENATI
(1, 9, 9, 4, 1.3, true),    -- IST
(1, 10, 10, 5, 2.0, false), -- Circunvalación Norte
(1, 11, 11, 6, 2.5, false), -- Taparachi
(1, 12, 12, 8, 3.2, true),  -- UPEU Entrada
(1, 13, 13, 3, 1.1, true);  -- UPEU Campus (final)

-- Insertar Conductores reales de Juliaca
INSERT INTO conductores (nombres, apellidos, dni, licencia, telefono, fecha_nacimiento) VALUES
('Juan Carlos', 'Mamani Quispe', '12345678', 'A-IIb', '951234567', '1985-03-15'),
('Pedro Luis', 'Condori Apaza', '23456789', 'A-IIb', '962345678', '1988-07-22'),
('Miguel Ángel', 'Flores Ticona', '34567890', 'A-IIb', '973456789', '1990-11-10'),
('José Antonio', 'Huanca Puma', '45678901', 'A-IIb', '984567890', '1987-05-30'),
('Carlos Alberto', 'Quispe Machaca', '56789012', 'A-IIb', '995678901', '1992-09-18');

-- Insertar Microbuses de la Línea 18
INSERT INTO buses (placa, ruta_id, modelo, capacidad, tipo, anio_fabricacion, numero_interno, estado) VALUES
('T1A-987', 1, 'Hyundai County', 40, 'diesel', 2020, '18-01', 'activo'),
('T2B-456', 1, 'Mitsubishi Rosa', 35, 'diesel', 2019, '18-02', 'activo'),
('T3C-123', 1, 'Toyota Coaster', 38, 'diesel', 2021, '18-03', 'activo'),
('T4D-789', 1, 'JAC Sunray', 42, 'diesel', 2022, '18-04', 'activo'),
('T5E-321', 1, 'Hyundai County', 40, 'GNV', 2023, '18-05', 'activo');

-- Asignar conductores a buses (turno diurno)
INSERT INTO asignaciones_bus_conductor (bus_id, conductor_id, fecha_inicio, turno, activo) VALUES
(1, 1, CURRENT_DATE, 'mañana', true),
(2, 2, CURRENT_DATE, 'tarde', true),
(3, 3, CURRENT_DATE, 'mañana', true),
(4, 4, CURRENT_DATE, 'tarde', true),
(5, 5, CURRENT_DATE, 'mañana', true);

-- Ubicaciones iniciales (buses distribuidos en la ruta)
INSERT INTO ubicaciones_tiempo_real (bus_id, latitud, longitud, velocidad, direccion, altitud) VALUES
(1, -15.489722, -70.132778, 25, 45, 3825),   -- Terminal (inicio)
(2, -15.492000, -70.128500, 30, 90, 3825),   -- Plaza Bolognesi
(3, -15.485000, -70.142000, 20, 180, 3828),  -- SENATI
(4, -15.467222, -70.158333, 35, 270, 3850),  -- UPEU Entrada
(5, -15.497500, -70.132000, 15, 120, 3823);  -- Santa Bárbara

-- ============================================
-- 5. CONSULTAS DE VERIFICACIÓN
-- ============================================

-- Ver todas las rutas
SELECT * FROM rutas;

-- Ver todas las paradas de la Línea 18
SELECT 
    rp.orden,
    p.nombre,
    p.tipo,
    p.codigo,
    p.referencia,
    rp.distancia_km,
    rp.tiempo_estimado
FROM ruta_paradas rp
JOIN paradas p ON rp.parada_id = p.id
WHERE rp.ruta_id = 1
ORDER BY rp.orden;

-- Ver buses activos con ubicación actual
SELECT * FROM vista_buses_activos ORDER BY bus_id;

-- Calcular distancia total de la ruta
SELECT 
    r.nombre,
    SUM(rp.distancia_km) as distancia_total_km,
    SUM(rp.tiempo_estimado) as tiempo_total_min
FROM rutas r
JOIN ruta_paradas rp ON r.id = rp.ruta_id
WHERE r.id = 1
GROUP BY r.nombre;

-- ============================================
-- FIN DEL SCRIPT
-- ============================================

