-- Se ejecuta automáticamente la PRIMERA vez que arranca el contenedor.
-- Crea el usuario de replicación que usará el Nodo B (esclavo).
CREATE USER IF NOT EXISTS 'replicador'@'%' IDENTIFIED BY 'Replica.Pass.2026';
GRANT REPLICATION SLAVE ON *.* TO 'replicador'@'%';

-- Tabla de demostración para la presentación
CREATE DATABASE IF NOT EXISTS empresa_db;
USE empresa_db;
CREATE TABLE IF NOT EXISTS empleados (
  id    INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(50),
  puesto VARCHAR(50),
  creado TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO empleados (nombre, puesto) VALUES
  ('Charlie','Gerente de Red'),
  ('Emir','Admin de Sistemas');

FLUSH PRIVILEGES;
