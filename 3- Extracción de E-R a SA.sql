--------------------------------------------------------------------------------------------------------
-- Autor:
-- Steven González Morera
--------------------------------------------------------------------------------------------------------
USE TRANSACCIONES_SA
GO

--------------------------------------------------------------------------------------------------------
-- SI EL PROCEDIMIENTO ALMACENADO EXISTE, LO ELIMINA.
--------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT 'X'
             FROM SYS.OBJECTS
		    WHERE TYPE = 'P' AND NAME = 'STGA_EXTRACCION_DATOS')
   DROP PROCEDURE STGA_EXTRACCION_DATOS
GO
--------------------------------------------------------------------------------------------------------
-- CREAR PROCEDIMIENTO ALMACENADO PARA CARGA DE DATOS.
--------------------------------------------------------------------------------------------------------

CREATE PROCEDURE STGA_EXTRACCION_DATOS (@pFechaInicio VARCHAR(10), @pFechaFinal VARCHAR(10)) AS 
BEGIN
   -------------------------------------------------------------------------------------------------------
   -- Se reciben las fechas de los parametros para poder hacer un filtro más abajo
   --------------------------------------------------------------------------------------------------------
   DECLARE
      @vFechaIncio date = CONVERT(DATE, @pFechaInicio, 23),
      @vFechaFinal date = CONVERT(DATE, @pFechaFinal, 23)
   -------------------------------------------------------------------------------------------------------
   -- A partir de ahora se cargan los valores de las tablas del modelo E-R al Stagin Area
   --------------------------------------------------------------------------------------------------------
   IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='SA_CLIENTES')
      BEGIN
         INSERT INTO SA_CLIENTES(CLI_ID, CLI_PER_ID)
         SELECT T01.CLI_ID, T01.CLI_PER_ID
           FROM VENTAS.DBO.CLIENTES T01
          WHERE T01.CLI_ID NOT IN (SELECT T02.CLI_ID FROM SA_CLIENTES T02 WHERE T01.CLI_ID = T02.CLI_ID)
      END
   -------------------------------------------------------------------------------------------------------
   IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='SA_CUENTAS')
      BEGIN
         INSERT INTO SA_CUENTAS(CTA_ID, CTA_CLI_ID,CTA_EMP_ID,CTA_MON_ID,CTA_NUMERO)
         SELECT T01.CTA_ID,T01.CTA_CLI_ID,T01.CTA_EMP_ID,T01.CTA_MON_ID,T01.CTA_NUMERO
           FROM VENTAS.DBO.CUENTAS T01
          WHERE T01.CTA_ID NOT IN (SELECT T02.CTA_ID FROM SA_CUENTAS T02 WHERE T01.CTA_ID = T02.CTA_ID)
      END
   -------------------------------------------------------------------------------------------------------
      IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='SA_DATOS_PERSONA')
      BEGIN
         INSERT INTO SA_DATOS_PERSONA(PER_ID,PER_TGE_ID,PER_TPE_ID,PER_PRIMER_APELLIDO,PER_SEGUNDO_APELLIDO,PER_PRIMER_NOMBRE,PER_SEGUNDO_NOMBRE)
         SELECT T01.PER_ID, T01.PER_TGE_ID,T01.PER_TPE_ID,T01.PER_PRIMER_APELLIDO,T01.PER_SEGUNDO_APELLIDO,T01.PER_PRIMER_NOMBRE,T01.PER_SEGUNDO_NOMBRE
           FROM VENTAS.DBO.DATOSPERSONA T01
          WHERE T01.PER_ID NOT IN (SELECT T02.PER_ID FROM SA_DATOS_PERSONA T02 WHERE T01.PER_ID = T02.PER_ID)
      END
   -------------------------------------------------------------------------------------------------------
      IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='SA_MONEDAS')
      BEGIN
         INSERT INTO SA_MONEDAS(MON_ID, MON_DESCRIPCION)
         SELECT T01.MON_ID, T01.MON_DESCRIPCION
           FROM VENTAS.DBO.MONEDAS T01
          WHERE T01.MON_ID NOT IN (SELECT T02.MON_ID FROM SA_MONEDAS T02 WHERE T01.MON_ID = T02.MON_ID)
      END
   -------------------------------------------------------------------------------------------------------
   IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='SA_PERSONA_DIRECCION')
      BEGIN
         INSERT INTO SA_PERSONA_DIRECCION(PDI_PER_ID, PDI_PRO_NOMBRE, PDI_CAN_NOMBRE, PDI_DIS_NOMBRE)
         SELECT T01.PDI_PER_ID, T01.PRO_NOMBRE, T01.CAN_NOMBRE, T01.DIS_NOMBRE
           FROM VENTAS.DBO.PERSONADIRECCION T01
          WHERE T01.PDI_PER_ID NOT IN (SELECT T02.PDI_PER_ID FROM SA_PERSONA_DIRECCION T02 WHERE T01.PDI_PER_ID = T02.PDI_PER_ID)
      END
   -------------------------------------------------------------------------------------------------------
   IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='SA_PERSONA_ESTADO_SALUD')
      BEGIN
         INSERT INTO SA_PERSONA_ESTADO_SALUD(TPE_ID,TPE_DESCRIPCION)
         SELECT T01.TPE_ID, T01.TPE_DESCRIPCION
           FROM VENTAS.DBO.PERSONAESTADOSALUD T01
          WHERE T01.TPE_ID NOT IN (SELECT T02.TPE_ID FROM SA_PERSONA_ESTADO_SALUD T02 WHERE T01.TPE_ID = T02.TPE_ID)
      END
   -------------------------------------------------------------------------------------------------------
      IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='SA_PERSONA_GENERO')
      BEGIN
         INSERT INTO SA_PERSONA_GENERO(TGE_ID,TGE_DESCRIPCION)
         SELECT T01.TGE_ID, T01.TGE_DESCRIPCION
           FROM VENTAS.DBO.PERSONAGENERO T01
          WHERE T01.TGE_ID NOT IN (SELECT T02.TGE_ID FROM SA_PERSONA_GENERO T02 WHERE T01.TGE_ID = T02.TGE_ID)
      END
   -------------------------------------------------------------------------------------------------------
         IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='SA_PERSONA_IDENTIFICACION')
      BEGIN
         INSERT INTO SA_PERSONA_IDENTIFICACION(PID_PER_ID,PID_DOCUMENTO)
         SELECT T01.PID_PER_ID, T01.PID_DOCUMENTO
           FROM VENTAS.DBO.PERSONAIDENTIFICACION T01
          WHERE T01.PID_PER_ID NOT IN (SELECT T02.PID_PER_ID FROM SA_PERSONA_IDENTIFICACION T02 WHERE T01.PID_PER_ID = T02.PID_PER_ID)
      END
   -------------------------------------------------------------------------------------------------------
            IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='SA_TIPO_CAMBIO')
      BEGIN
         INSERT INTO SA_TIPO_CAMBIO(TCA_ID,TCA_MON_ID,TCA_FECHA,TCA_VALOR_COMPRA,TCA_VALOR_VENTA,TCA_VALOR_CONTABLE)
         SELECT T01.TCA_ID, T01.TCA_MON_ID,CONVERT(DATE, T01.TCA_FECHA, 23),T01.TCA_VALOR_COMPRA,T01.TCA_VALOR_VENTA,T01.TCA_VALOR_CONTABLE
           FROM VENTAS.DBO.TIPO_CAMBIO T01
          WHERE T01.TCA_ID NOT IN (SELECT T02.TCA_ID FROM SA_TIPO_CAMBIO T02 WHERE T01.TCA_ID = T02.TCA_ID)
		  AND CONVERT(DATE, T01.TCA_FECHA, 23) >= @vFechaIncio AND CONVERT(DATE, T01.TCA_FECHA, 23) <= @vFechaFinal
      END
   -------------------------------------------------------------------------------------------------------
      IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='SA_TRANSACCIONES')
      BEGIN
         INSERT INTO SA_TRANSACCIONES(TRN_ID, TRN_CTA_ID, TRN_FECHA, TRN_TIPO,TRN_MONTO)
         SELECT T01.TRN_ID, T01.TRN_CTA_ID, CONVERT(DATE, T01.TRN_FECHA, 23), T01.TRN_TIPO,T01.TRN_MONTO
           FROM VENTAS.DBO.TRANSACCIONES T01
          WHERE T01.TRN_ID NOT IN (SELECT T02.TRN_ID FROM SA_TRANSACCIONES T02 WHERE T01.TRN_ID = T02.TRN_ID)
		   AND CONVERT(DATE, T01.TRN_FECHA, 23) >= @vFechaIncio AND CONVERT(DATE, T01.TRN_FECHA, 23) <= @vFechaFinal
      END

   -------------------------------------------------------------------------------------------------------
END
GO

EXEC STGA_EXTRACCION_DATOS '2010-01-02', '2010-01-02'
GO
