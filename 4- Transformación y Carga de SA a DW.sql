--------------------------------------------------------------------------------------------------------
-- Autor:
-- Steven González Morera
--------------------------------------------------------------------------------------------------------
USE TRANSACCIONES_DW
GO

--------------------------------------------------------------------------------------------------------
-- SI EL PROCEDIMIENTO ALMACENADO EXISTE, LO ELIMINA.
--------------------------------------------------------------------------------------------------------
IF EXISTS (SELECT 'X'
             FROM SYS.OBJECTS
		    WHERE TYPE = 'P' AND NAME = 'DW_EXTRACCION_DATOS')
   DROP PROCEDURE DW_EXTRACCION_DATOS
GO
--------------------------------------------------------------------------------------------------------
-- CREAR PROCEDIMIENTO ALMACENADO PARA CARGA DE DATOS.
--------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------
-- Los parámetros y variables de fecha que definimos a continuación los dejamos con la intención
-- de que a futuro se puedan utilizar para hacer transformación y carga al DW por fecha. Pero actualmente
-- no tienen ninguna función
--------------------------------------------------------------------------------------------------------

CREATE PROCEDURE DW_EXTRACCION_DATOS (@pFechaInicio VARCHAR(10), @pFechaFinal VARCHAR(10)) AS 
BEGIN
   -------------------------------------------------------------------------------------------------------
   DECLARE
      @vFechaIncio date = CONVERT(DATE, @pFechaInicio, 23),
      @vFechaFinal date = CONVERT(DATE, @pFechaFinal, 23)
   --------------------------------------------------------------------------------------------------------
   -- LA continuación transformamos y cargados a las dimensiones, los datos provenientes del Stagin Area.
   -- Aquí se hacen conversiones para pasar los datos varchar  que no se necesitan que sean numéricos, como
   -- los ID.
   --------------------------------------------------------------------------------------------------------
   ---- Transformación y carga de la dimensión de cuentas al DW -------------------------------------------
   -- El campo de cuenta en el E-R permitia nulos, por lo que se espera que puedan llegar
   -- a este punto. Es por esto que a este valor le hacemos una validación para ver si es NULL, y
   -- en caso de que lo sea, se cambian por el numero 0 para que al DW no ente un null.
   -- En las restricciones, validamos que el ID sea numérico y positivo. 
   --------------------------------------------------------------------------------------------------------
   IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='DIM_CUENTAS')
      BEGIN
			INSERT INTO DIM_CUENTAS(CTA_ID, CTA_NUMERO)
			SELECT CONVERT(INTEGER, SCTA.CTA_ID) CTA_ID,
				    ISNULL((CONVERT(INTEGER, SCTA.CTA_NUMERO)), 0) CTA_NUMERO_CUENTA
			  FROM TRANSACCIONES_SA.DBO.SA_CUENTAS SCTA
			 WHERE SCTA.CTA_ID NOT IN (SELECT DCTA.CTA_ID FROM DIM_CUENTAS DCTA WHERE DCTA.CTA_ID = SCTA.CTA_ID)
			   AND SCTA.CTA_ID NOT IN (SELECT SCTA.CTA_ID
										 FROM TRANSACCIONES_SA.DBO.SA_CUENTAS SCTA
										GROUP BY SCTA.CTA_ID
									   HAVING COUNT(*) >1)
			   AND SCTA.CTA_ID IS NOT NULL
			   AND ISNUMERIC(SCTA.CTA_ID) = 1
			   AND CONVERT(INTEGER, SCTA.CTA_ID) >= 0
      END
   --------------------------------------------------------------------------------------------------------
   ---- Transformación y carga de la dimensión de datos de persona al DW ----------------------------------
   -- Para la siguiente transformación y carga de dimensión usamos 2 INNER JOIN, ya que necesitamos llenar la
   -- dimensión de datos de persona, con valores que en el modelo E-R/Staging Area, se localizaban en las
   -- tablas de Dirección de persona e Identificación de persona
   -- Los campos de nombres y apellidos en el E-R permitian nulos, por lo que se espera que puedan llegar
   -- a este punto. Es por esto que a estos valores le hacemos una validación para ver si son NULLS, y
   -- en caso de que lo sean, se cambian por una descripción de que no está indicado.
   -- En las restricciones, validamos que el ID sea numérico y positivo. Y que los valores de texto
   -- que no permiten NULL, cumplan con el largo que le definimos en la creación de la tabla
   --------------------------------------------------------------------------------------------------------
    IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='DIM_DATOS_PERSONA')
      BEGIN
			INSERT INTO DIM_DATOS_PERSONA(PER_ID, PER_PRIMER_APELLIDO, PER_SEGUNDO_APELLIDO, PER_PRIMER_NOMBRE, PER_SEGUNDO_NOMBRE, PER_PID_DOCUMENTO, PER_PRO_NOMBRE, PER_CAN_NOMBRE, PER_DIS_NOMBRE)
			SELECT CONVERT(INTEGER, SPER.PER_ID) PER_ID,
				    ISNULL(SPER.PER_PRIMER_APELLIDO,'--- No indicado ---') PER_PRIMER_APELLIDO,
					ISNULL(SPER.PER_SEGUNDO_APELLIDO,'--- No indicado ---') PER_SEGUNDO_APELLIDO,
					ISNULL(SPER.PER_PRIMER_NOMBRE,'--- No indicado ---') PER_PRIMER_NOMBRE,
					ISNULL(SPER.PER_SEGUNDO_NOMBRE,'--- No indicado ---') PER_SEGUNDO_NOMBRE,
					SPID.PID_DOCUMENTO,
					SPDI.PDI_PRO_NOMBRE,
					SPDI.PDI_CAN_NOMBRE,
					SPDI.PDI_DIS_NOMBRE
			  FROM TRANSACCIONES_SA.DBO.SA_DATOS_PERSONA SPER INNER JOIN TRANSACCIONES_SA.DBO.SA_PERSONA_IDENTIFICACION SPID ON SPER.PER_ID = SPID.PID_PER_ID
															  INNER JOIN TRANSACCIONES_SA.DBO.SA_PERSONA_DIRECCION SPDI ON SPID.PID_PER_ID = SPDI.PDI_PER_ID
			   WHERE SPER.PER_ID NOT IN (SELECT DPER.PER_ID FROM DIM_DATOS_PERSONA DPER WHERE DPER.PER_ID = SPER.PER_ID)
			   AND SPER.PER_ID NOT IN (SELECT SPER.PER_ID
										 FROM TRANSACCIONES_SA.DBO.SA_DATOS_PERSONA SPER
										GROUP BY SPER.PER_ID
									   HAVING COUNT(*) >1)
			   AND SPER.PER_ID IS NOT NULL
			   AND ISNUMERIC(SPER.PER_ID) = 1
			   AND CONVERT(INTEGER, SPER.PER_ID) >= 0
			   AND LEN(SPID.PID_DOCUMENTO) > 5
			   AND LEN(SPID.PID_DOCUMENTO) <= 50
			   AND LEN(SPDI.PDI_PRO_NOMBRE) > 5
			   AND LEN(SPDI.PDI_PRO_NOMBRE) <= 50
			   AND LEN(SPDI.PDI_CAN_NOMBRE) > 5
			   AND LEN(SPDI.PDI_CAN_NOMBRE) <= 50
			   AND LEN(SPDI.PDI_DIS_NOMBRE) > 5
			   AND LEN(SPDI.PDI_DIS_NOMBRE) <= 50
      END
   --------------------------------------------------------------------------------------------------------
   ---- Transformación y carga de la dimensión de monedas al DW -------------------------------------------
   -- El campo de descripción en el E-R permitia nulos, por lo que se espera que puedan llegar
   -- a este punto. Es por esto que a este valor le hacemos una validación para ver si es NULL, y
   -- en caso de que lo sean, se cambian por una descripción de que no está indicado.
   -- En las restricciones, validamos que el ID sea numérico y positivo. 
   --------------------------------------------------------------------------------------------------------
        IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='DIM_MONEDAS')
      BEGIN
			INSERT INTO DIM_MONEDAS(MON_ID, MON_DESCRIPCION)
			SELECT CONVERT(INTEGER, SMON.MON_ID) MON_ID,
				   ISNULL(SMON.MON_DESCRIPCION, '--- No indicado ---')
			  FROM TRANSACCIONES_SA.DBO.SA_MONEDAS SMON
			 WHERE SMON.MON_ID NOT IN (SELECT DMON.MON_ID FROM DIM_MONEDAS DMON WHERE DMON.MON_ID = SMON.MON_ID)
			   AND SMON.MON_ID NOT IN (SELECT SMON.MON_ID
										 FROM TRANSACCIONES_SA.DBO.SA_MONEDAS SMON
										GROUP BY SMON.MON_ID
									   HAVING COUNT(*) >1)
			   AND SMON.MON_ID IS NOT NULL
			   AND ISNUMERIC(SMON.MON_ID) = 1
			   AND CONVERT(INTEGER, SMON.MON_ID) >= 0
      END
   --------------------------------------------------------------------------------------------------------
   ---- Transformación y carga de la dimensión de estado de persona al DW -----------------------------------------
   -- En las restricciones, validamos que el ID sea numérico y positivo. Y que los valores de texto
   -- que no permiten NULL, cumplan con el largo que le definimos en la creación de la tabla
   --------------------------------------------------------------------------------------------------------
      IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='DIM_PERSONA_ESTADO_SALUD')
      BEGIN
			INSERT INTO DIM_PERSONA_ESTADO_SALUD(TPE_ID, TPE_DESCRIPCION)
			SELECT CONVERT(INTEGER, STPE.TPE_ID) TPE_ID,
				   STPE.TPE_DESCRIPCION
			  FROM TRANSACCIONES_SA.DBO.SA_PERSONA_ESTADO_SALUD STPE
			 WHERE STPE.TPE_ID NOT IN (SELECT DTPE.TPE_ID FROM DIM_PERSONA_ESTADO_SALUD DTPE WHERE DTPE.TPE_ID = STPE.TPE_ID)
			   AND STPE.TPE_ID NOT IN (SELECT STPE.TPE_ID
										 FROM TRANSACCIONES_SA.DBO.SA_PERSONA_ESTADO_SALUD STPE
										GROUP BY STPE.TPE_ID
									   HAVING COUNT(*) >1)
			   AND STPE.TPE_ID IS NOT NULL
			   AND STPE.TPE_DESCRIPCION IS NOT NULL
			   AND ISNUMERIC(STPE.TPE_ID) = 1
			   AND CONVERT(INTEGER, STPE.TPE_ID) >= 0
			   AND LEN(STPE.TPE_DESCRIPCION) > 5
			   AND LEN(STPE.TPE_DESCRIPCION) <= 50
      END
   --------------------------------------------------------------------------------------------------------
   ---- Transformación y carga de la dimensión de genero de persona al DW ---------------------------------
   -- En las restricciones, validamos que el ID sea numérico y positivo. Y que los valores de texto
   -- que no permiten NULL, cumplan con el largo que le definimos en la creación de la tabla
   --------------------------------------------------------------------------------------------------------
         IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='DIM_PERSONA_GENERO')
      BEGIN
			INSERT INTO DIM_PERSONA_GENERO(TGE_ID, TGE_DESCRIPCION)
			SELECT CONVERT(INTEGER, STGE.TGE_ID) TGE_ID,
				   STGE.TGE_DESCRIPCION
			  FROM TRANSACCIONES_SA.DBO.SA_PERSONA_GENERO STGE
			 WHERE STGE.TGE_ID NOT IN (SELECT DTGE.TGE_ID FROM DIM_PERSONA_GENERO DTGE WHERE DTGE.TGE_ID = STGE.TGE_ID)
			   AND STGE.TGE_ID NOT IN (SELECT STGE.TGE_ID
										 FROM TRANSACCIONES_SA.DBO.SA_PERSONA_GENERO STGE
										GROUP BY STGE.TGE_ID
									   HAVING COUNT(*) >1)
			   AND STGE.TGE_ID IS NOT NULL
			   AND STGE.TGE_DESCRIPCION IS NOT NULL
			   AND ISNUMERIC(STGE.TGE_ID) = 1
			   AND CONVERT(INTEGER, STGE.TGE_ID) >= 0
			   AND LEN(STGE.TGE_DESCRIPCION) > 5
			   AND LEN(STGE.TGE_DESCRIPCION) <= 50
	 END
   --------------------------------------------------------------------------------------------------------
   ---- Transformación y carga de la tabla de hechos y la de errores --------------------------------------
   --------------------------------------------------------------------------------------------------------

   IF EXISTS (SELECT 'X'
                FROM INFORMATION_SCHEMA.TABLES 
               WHERE TABLE_TYPE='BASE TABLE' 
                 AND TABLE_NAME='FAC_TRANSACCION')
      BEGIN
   --------------------------------------------------------------------------------------------------------
   -- Se definen en varchar las variables que van a tomar los valores de la tabla de transacciones del SA
   -- gracias al cursor. Los otros valores que definimos son equivalentes a los ID y medidas que
   -- posteriormente ingresamos en la tabla de hechos/errores, y están en numérico porque se hacen las 
   -- conversiones para que en caso de que lleguen a la tabla de hechos, lleguen en el formato correcto
   --------------------------------------------------------------------------------------------------------
		   DECLARE
			  @TRN_ID     VARCHAR(255),
			  @TRN_CTA_ID VARCHAR(255),
			  @TRN_FECHA  VARCHAR(255),
			  @TRN_TIPO   VARCHAR(255),
			  @TRN_MONTO  VARCHAR(255),
			  @vTRN_CTA_ID INTEGER,
			  @vTRN_PER_ID   INTEGER,
			  @vTRN_TPE_ID INTEGER,
			  @vTRN_TGE_ID    INTEGER,
			  @vTRN_MON_ID INTEGER,
			  @vTRN_FEC_ID INTEGER,
			  @vTRN_TCA_ID INTEGER,
			  @vTRN_CLI_ID INTEGER,
			  @vTRN_TCA_VALOR_COMPRA DECIMAL(18,5),
			  @vTRN_TCA_VALOR_VENTA DECIMAL(18,5),
			  @vTRN_TCA_VALOR_CONTABLE DECIMAL(18,5),
			  @vTRN_MONTO DECIMAL(25,2),
			  @vTRN_TIPO SMALLINT,
			  @vERROR INTEGER
		   DECLARE
   --------------------------------------------------------------------------------------------------------
   -- Se declara el cursor
   --------------------------------------------------------------------------------------------------------
			  C_TRANSACCION CURSOR FOR
				 SELECT TRN_ID,
						TRN_CTA_ID,
						TRN_FECHA,
						TRN_TIPO,
						TRN_MONTO
				    FROM TRANSACCIONES_SA.DBO.SA_TRANSACCIONES
				 ORDER BY TRN_ID
			  BEGIN
				 OPEN C_TRANSACCION
				 FETCH NEXT FROM C_TRANSACCION INTO @TRN_ID,
													@TRN_CTA_ID,
													@TRN_FECHA,
													@TRN_TIPO,
													@TRN_MONTO
				 WHILE @@FETCH_STATUS = 0
					BEGIN
   --------------------------------------------------------------------------------------------------------
   -- A continuación define las variables de la tabla de hechos en sus respectivas variables,
   -- buscándo las relaciones de los ID por medio de INNER JOINS en las tablas de SA, para evitar perder
   -- datos.
   --------------------------------------------------------------------------------------------------------
					   -------------------------------------------------------------------------------
					   -- ID DE LA PERSONA.
					   -------------------------------------------------------------------------------
					   SELECT @vTRN_PER_ID = CONVERT(INTEGER, SPER.PER_ID)
						 FROM TRANSACCIONES_SA.DBO.SA_TRANSACCIONES STRN INNER JOIN TRANSACCIONES_SA.DBO.SA_CUENTAS SCTA ON STRN.TRN_CTA_ID = SCTA.CTA_ID
																	  INNER JOIN TRANSACCIONES_SA.DBO.SA_CLIENTES SCLI ON SCTA.CTA_CLI_ID = SCLI.CLI_ID
																	  INNER JOIN TRANSACCIONES_SA.DBO.SA_DATOS_PERSONA SPER ON SCLI.CLI_PER_ID = SPER.PER_ID
					   WHERE TRN_ID = @TRN_ID
					   -------------------------------------------------------------------------------
					   -- ID DEL ESTADO DE SALUD LA PERSONA.
					   -------------------------------------------------------------------------------
					   SELECT @vTRN_TPE_ID = CONVERT(INTEGER, STPE.TPE_ID)
					      FROM TRANSACCIONES_SA.DBO.SA_TRANSACCIONES STRN INNER JOIN TRANSACCIONES_SA.DBO.SA_CUENTAS SCTA ON STRN.TRN_CTA_ID = SCTA.CTA_ID
																	  INNER JOIN TRANSACCIONES_SA.DBO.SA_CLIENTES SCLI ON SCTA.CTA_CLI_ID = SCLI.CLI_ID
																	  INNER JOIN TRANSACCIONES_SA.DBO.SA_DATOS_PERSONA SPER ON SCLI.CLI_PER_ID = SPER.PER_ID
																	  INNER JOIN TRANSACCIONES_SA.DBO.SA_PERSONA_ESTADO_SALUD STPE ON SPER.PER_TPE_ID = STPE.TPE_ID
					   WHERE TRN_ID = @TRN_ID
					   -------------------------------------------------------------------------------
					   -- ID DEL GENERO DE LA PERSONA.
					   -------------------------------------------------------------------------------
					   SELECT @vTRN_TGE_ID = CONVERT(INTEGER, STGE.TGE_ID)
					      FROM TRANSACCIONES_SA.DBO.SA_TRANSACCIONES STRN INNER JOIN TRANSACCIONES_SA.DBO.SA_CUENTAS SCTA ON STRN.TRN_CTA_ID = SCTA.CTA_ID
																	  INNER JOIN TRANSACCIONES_SA.DBO.SA_CLIENTES SCLI ON SCTA.CTA_CLI_ID = SCLI.CLI_ID
																	  INNER JOIN TRANSACCIONES_SA.DBO.SA_DATOS_PERSONA SPER ON SCLI.CLI_PER_ID = SPER.PER_ID
																	  INNER JOIN TRANSACCIONES_SA.DBO.SA_PERSONA_GENERO STGE ON SPER.PER_TGE_ID = STGE.TGE_ID
					   WHERE TRN_ID = @TRN_ID
					   -------------------------------------------------------------------------------
					   -- ID DEL CLIENTE.
					   -------------------------------------------------------------------------------
					   SELECT @vTRN_CLI_ID = CONVERT(INTEGER, SCLI.CLI_ID)
					      FROM TRANSACCIONES_SA.DBO.SA_TRANSACCIONES STRN INNER JOIN TRANSACCIONES_SA.DBO.SA_CUENTAS SCTA ON STRN.TRN_CTA_ID = SCTA.CTA_ID
																	  INNER JOIN TRANSACCIONES_SA.DBO.SA_CLIENTES SCLI ON SCTA.CTA_CLI_ID = SCLI.CLI_ID

					   WHERE TRN_ID = @TRN_ID
					   -------------------------------------------------------------------------------
					   -- ID DE LA MONEDA.
					   -------------------------------------------------------------------------------
					   SELECT @vTRN_MON_ID = CONVERT(INTEGER, SMON.MON_ID)
					      FROM TRANSACCIONES_SA.DBO.SA_TRANSACCIONES STRN INNER JOIN TRANSACCIONES_SA.DBO.SA_CUENTAS SCTA ON STRN.TRN_CTA_ID = SCTA.CTA_ID
																	      INNER JOIN TRANSACCIONES_SA.DBO.SA_MONEDAS SMON ON SCTA.CTA_MON_ID = SMON.MON_ID
                       WHERE TRN_ID = @TRN_ID
					   -------------------------------------------------------------------------------
					   -- ID Y DATOS NUMERICOS DEL TIPO DE CAMBIO.
					   -- Los datos delos valores de compre, venta y contable originalmente permiten nulos en el E-R.
					   -- Por lo que aquí se evalua si el dato recibido es nulo, y en caso de que lo sea, lo transforma en un 0
					   -- que puede ser ingresado a la tabla de hechos como un indicador que ese dato está realmente nulo
					   -------------------------------------------------------------------------------
					   SELECT @vTRN_TCA_ID = CONVERT(INTEGER, STCA.TCA_ID), 
						       @vTRN_TCA_VALOR_COMPRA = ISNULL(CONVERT(DECIMAL(18,5), STCA.TCA_VALOR_COMPRA), 0.00),
						       @vTRN_TCA_VALOR_VENTA = ISNULL(CONVERT(DECIMAL(18,5), STCA.TCA_VALOR_VENTA), 0.00),
						       @vTRN_TCA_VALOR_CONTABLE = ISNULL(CONVERT(DECIMAL(18,5), STCA.TCA_VALOR_CONTABLE), 0.00)
					      FROM TRANSACCIONES_SA.DBO.SA_TRANSACCIONES STRN INNER JOIN TRANSACCIONES_SA.DBO.SA_CUENTAS SCTA ON STRN.TRN_CTA_ID = SCTA.CTA_ID
																	      INNER JOIN TRANSACCIONES_SA.DBO.SA_MONEDAS SMON ON SCTA.CTA_MON_ID = SMON.MON_ID
																	      INNER JOIN TRANSACCIONES_SA.DBO.SA_TIPO_CAMBIO STCA ON SMON.MON_ID = STCA.TCA_MON_ID
					   WHERE TRN_ID = @TRN_ID
					   -------------------------------------------------------------------------------
				       -- CONVERTIR EL ID DE CUENTA A INTEGER.
					   -- debido a que originalmente se obtiene del cursor como un varchar
					   -------------------------------------------------------------------------------
						SET @vTRN_CTA_ID = CONVERT(INTEGER, @TRN_CTA_ID)
					   -------------------------------------------------------------------------------
					   -- FECHA CONVERTIDA A INTEGER.
					   -- debido a que originalmente se obtiene del cursor como un varchar
					   -------------------------------------------------------------------------------
						SET @vTRN_FEC_ID = CONVERT(INTEGER, REPLACE(@TRN_FECHA,'-',''))
					   -------------------------------------------------------------------------------
					   -- CONVERTIR TIPO DE TRANSACCION A SMALLINT.
					   -- debido a que originalmente se obtiene del cursor como un varchar
					   -------------------------------------------------------------------------------
					   SET @vTRN_TIPO = ISNULL(CONVERT(SMALLINT, @TRN_TIPO), 0)
					   -------------------------------------------------------------------------------
					   -- CONVERTIR MONTO A DECIMAL.
					   -- debido a que originalmente se obtiene del cursor como un varchar
					   -------------------------------------------------------------------------------
					   SET @vTRN_MONTO = CONVERT(DECIMAL(25,2), @TRN_MONTO)
					   -------------------------------------------------------------------------------
					   -- INSERT EN LA TABLA DE TRANSACCIONES.
					   -------------------------------------------------------------------------------
					   -- SECCION DE VALIDACIÓN.
					   -------------------------------------------------------------------------------
					   SET @vERROR = 0
					   -------------------------------------------------------------------------------
					   -- El siguiente IF valida que no se ingresen IDs ni valores numéricos negativos
					   -- Y que se cumpla con el tamaño máximo del smallint de tipo de transacción
					   -- en los valores de compra, venta y contables se permite 0 porque a como se pudo
					   -- ver arriba, es posible que haya NULLS transformados en 0
					   -------------------------------------------------------------------------------
						IF @vTRN_TGE_ID <= 0 
						   OR @vTRN_TPE_ID <= 0
						   OR @vTRN_TPE_ID <= 0
					       OR @vTRN_PER_ID <= 0
					       OR @vTRN_MON_ID <= 0
					       OR @vTRN_FEC_ID <= 0
					       OR @TRN_CTA_ID <= 0
					       OR @vTRN_CLI_ID <= 0
					       OR @vTRN_TCA_ID <= 0
						   OR @vTRN_MONTO <= 0
						   OR @vTRN_TIPO <= 0 
						   OR @vTRN_TIPO > 32767 
						   OR @vTRN_TCA_VALOR_COMPRA < 0 
						   OR @vTRN_TCA_VALOR_VENTA < 0 
						   OR @vTRN_TCA_VALOR_CONTABLE < 0 
						SET @vERROR = 1
					   -------------------------------------------------------------------------------
					   -- El siguiente IF valida que el ID de persona se encuenttre en en la dimensión
					   -- antes de intentar ingresarlo en la tabla de hechos, ya que solo se pueden 
					   -- ingresar IDs que sean válidos en caso de que sean foraneos
					   -- Esta validación la agregamos porque notamos en el modelo E-R, que no había una
					   -- relación por medio de llave entre persona y cliente, lo cual puede significar
					   -- que en la tabla de clientes haya IDs de persona que no existen en la tabla de
					   -- personas
					   -------------------------------------------------------------------------------
						IF (NOT EXISTS(SELECT 1 FROM TRANSACCIONES_DW.DBO.DIM_DATOS_PERSONA DPER WHERE @vTRN_PER_ID = DPER.PER_ID))
						SET @vERROR = 1
					   -------------------------------------------------------------------------------
					   -- El siguiente IF valida que la llave primaria de la tabla de hechos, es decir
					   -- que el conjunto de IDs que forman esa llave primaria, no hayan formado ya
					   -- una llave primaria anteriormente. En otras palabras, define un error, si 
					   -- se repite la llave primarua en la tabla de hechos, para no ingresarlo nuevamente
					   -------------------------------------------------------------------------------
						IF (EXISTS(SELECT 1 FROM TRANSACCIONES_DW.DBO.FAC_TRANSACCION DTRN WHERE DTRN.TRN_TGE_ID = @vTRN_TGE_ID 
						                                                                    AND DTRN.TRN_TPE_ID = @vTRN_TPE_ID
							                                                                AND DTRN.TRN_PER_ID = @vTRN_PER_ID
																							AND DTRN.TRN_MON_ID = @vTRN_MON_ID
																							AND DTRN.TRN_FEC_ID = @vTRN_FEC_ID
																							AND DTRN.TRN_CTA_ID = @vTRN_CTA_ID
																							AND DTRN.TRN_CLI_ID = @vTRN_CLI_ID
																							AND DTRN.TRN_TCA_ID = @vTRN_TCA_ID))
						SET @vERROR = 1
					   -------------------------------------------------------------------------------
					   IF @vERROR = 0
					   -------------------------------------------------------------------------------
					   -- Inserta los datos a la tabla de hechos, si no hay errores
					   -------------------------------------------------------------------------------
						   INSERT INTO FAC_TRANSACCION(TRN_TGE_ID,
			   										   TRN_TPE_ID,
			   										   TRN_PER_ID,
			   										   TRN_MON_ID,
			   										   TRN_FEC_ID,
			   										   TRN_CTA_ID,
			   										   TRN_CLI_ID,
													   TRN_TCA_ID,
													   TRN_TIPO,
													   TRN_MONTO,
													   TRN_TCA_VALOR_COMPRA,
													   TRN_TCA_VALOR_VENTA,
													   TRN_TCA_VALOR_CONTABLE)
											   VALUES (@vTRN_TGE_ID,
			   										   @vTRN_TPE_ID,
			   										   @vTRN_PER_ID,
			   										   @vTRN_MON_ID,
			   										   @vTRN_FEC_ID,
			   										   @TRN_CTA_ID,
			   										   @vTRN_CLI_ID,
													   @vTRN_TCA_ID,
													   @vTRN_TIPO,
													   @vTRN_MONTO,
													   @vTRN_TCA_VALOR_COMPRA,
													   @vTRN_TCA_VALOR_VENTA,
													   @vTRN_TCA_VALOR_CONTABLE)
						ELSE
					   -------------------------------------------------------------------------------
					   -- Inserta los datos a la tabla de errores, si hay errores
					   -------------------------------------------------------------------------------
						   INSERT INTO FAC_TRANSACCION_ERRORES(TRN_TGE_ID,
			   										   TRN_TPE_ID,
			   										   TRN_PER_ID,
			   										   TRN_MON_ID,
			   										   TRN_FEC_ID,
			   										   TRN_CTA_ID,
			   										   TRN_CLI_ID,
													   TRN_TCA_ID,
													   TRN_TIPO,
													   TRN_MONTO,
													   TRN_TCA_VALOR_COMPRA,
													   TRN_TCA_VALOR_VENTA,
													   TRN_TCA_VALOR_CONTABLE)
											   VALUES (@vTRN_TGE_ID,
			   										   @vTRN_TPE_ID,
			   										   @vTRN_PER_ID,
			   										   @vTRN_MON_ID,
			   										   @vTRN_FEC_ID,
			   										   @TRN_CTA_ID,
			   										   @vTRN_CLI_ID,
													   @vTRN_TCA_ID,
													   @vTRN_TIPO,
													   @vTRN_MONTO,
													   @vTRN_TCA_VALOR_COMPRA,
													   @vTRN_TCA_VALOR_VENTA,
													   @vTRN_TCA_VALOR_CONTABLE)
					   -------------------------------------------------------------------------------
					   FETCH NEXT FROM C_TRANSACCION INTO @TRN_ID,
														  @TRN_CTA_ID,
														  @TRN_FECHA,
														  @TRN_TIPO,
														  @TRN_MONTO
					END
				CLOSE      C_TRANSACCION
				DEALLOCATE C_TRANSACCION
			  END
      END
   -------------------------------------------------------------------------------------------------------
END
GO

EXEC DW_EXTRACCION_DATOS '2010-01-02', '2010-01-06'
GO