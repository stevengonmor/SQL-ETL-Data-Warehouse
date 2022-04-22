--------------------------------------------------------------------------------------------------------
-- Autor:
-- Steven González Morera
--------------------------------------------------------------------------------------------------------
USE MASTER
GO

DROP DATABASE TRANSACCIONES_SA
GO

CREATE DATABASE TRANSACCIONES_SA
GO

USE TRANSACCIONES_SA
GO

--------------------------------------------------------------------------------------------------------
-------------------------------- Creación de Tablas del Staging Area -----------------------------------
-- Estas tablas son copías de las tablas del modelo Entidad - Relación, pero sin restricciones. Por lo
-- tanto, les mantuvimos los mismos campos, pero en varchar(255) para que acepten cualquier dato, aunque
-- sean largos.
--------------------------------------------------------------------------------------------------------

CREATE TABLE SA_PERSONA_ESTADO_SALUD (
   TPE_ID          VARCHAR(255),
   TPE_DESCRIPCION VARCHAR(255)
)
GO

CREATE TABLE SA_PERSONA_DIRECCION (
   PDI_PER_ID     VARCHAR(255),
   PDI_PRO_NOMBRE VARCHAR(255),
   PDI_CAN_NOMBRE VARCHAR(255),
   PDI_DIS_NOMBRE VARCHAR(255)
)
GO

CREATE TABLE SA_PERSONA_IDENTIFICACION (
   PID_PER_ID          VARCHAR(255),
   PID_DOCUMENTO VARCHAR(255)
)
GO

CREATE TABLE SA_PERSONA_GENERO(
   TGE_ID     VARCHAR(255),
   TGE_DESCRIPCION VARCHAR(255),
   
)
GO

CREATE TABLE SA_DATOS_PERSONA(
   PER_ID     VARCHAR(255),
   PER_TGE_ID VARCHAR(255),
   PER_TPE_ID VARCHAR(255),
   PER_PRIMER_APELLIDO VARCHAR(255),
   PER_SEGUNDO_APELLIDO VARCHAR(255),
   PER_PRIMER_NOMBRE VARCHAR(255),
   PER_SEGUNDO_NOMBRE VARCHAR(255),

)
GO

CREATE TABLE SA_TIPO_CAMBIO (
   TCA_ID          VARCHAR(255),
   TCA_MON_ID VARCHAR(255),
   TCA_FECHA VARCHAR(255),
   TCA_VALOR_COMPRA VARCHAR(255),
   TCA_VALOR_VENTA VARCHAR(255),
   TCA_VALOR_CONTABLE VARCHAR(255)
)

GO

CREATE TABLE SA_MONEDAS (
   MON_ID          VARCHAR(255),
   MON_DESCRIPCION VARCHAR(255)
)

GO

CREATE TABLE SA_TRANSACCIONES (
   TRN_ID     VARCHAR(255),
   TRN_CTA_ID VARCHAR(255),
   TRN_FECHA VARCHAR(255),
   TRN_TIPO VARCHAR(255),
   TRN_MONTO VARCHAR(255)
)
GO

CREATE TABLE SA_CUENTAS (
   CTA_ID     VARCHAR(255),
   CTA_CLI_ID VARCHAR(255),
   CTA_EMP_ID VARCHAR(255),
   CTA_MON_ID VARCHAR(255),
   CTA_NUMERO VARCHAR(255)
)
GO

CREATE TABLE SA_CLIENTES (
   CLI_ID          VARCHAR(255),
   CLI_PER_ID VARCHAR(255)
)
GO
