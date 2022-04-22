--------------------------------------------------------------------------------------------------------
-- Autor:
-- Steven González Morera
--------------------------------------------------------------------------------------------------------
USE MASTER
GO

DROP DATABASE TRANSACCIONES_DW
GO

CREATE DATABASE TRANSACCIONES_DW
GO

USE TRANSACCIONES_DW
GO

--------------------------------------------------------------------------------------------------------
------------------------------- Creación de Tablas del Data Warehouse ----------------------------------
-- Aquí creamos las tablas del Data Warehouse tras desnormalizar las tablas del Entidad - Relación
-- A continuación damos más detalles sobre las columnas que quitamos o movimos.
--------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------
-- A continuación se crea la tabla de Dimensión de Fechas. Están todos los campos necesarios
-- para hacer poder buscar datos entre rangos de fechs, periodos, entra otra información.
--------------------------------------------------------------------------------------------------------
CREATE TABLE DIM_FECHA(
   FEC_ID                int NOT NULL primary key, /* Format: AAAAMMDD */
   FEC_FECHA             datetime NOT NULL,        /* Actual date */
   FEC_DIA_SEMANA        tinyint NULL,             /* 1 to 7 */
   FEC_DIA_MES           tinyint NULL,             /* 1 to 31 */
   FEC_DIA_PERIODO       smallint NULL,            /* 1 to 366 */
   FEC_SEMANA            tinyint NULL,             /* 1 to 53 */
   FEC_MES               tinyint NULL,             /* 1 to 12 */
   FEC_TRIMESTRE         tinyint NULL,             /* 1 to 4 */
   FEC_SEMESTRE          tinyint NULL,             /* 1 to 2 */
   FEC_PERIODO           char(4) NULL,             /* Just the number */
   FEC_SEMANA_PERIODO    nvarchar(25) NULL,        /* Week Unique Identifier: Week + Year */
   FEC_MES_PERIODO       nvarchar(25) NULL,        /* Month Unique Identifier: Month + Year */
   FEC_TRIMESTRE_PERIODO nvarchar(25) NULL,        /* Quarter Unique Identifier: Quarter + Year */
   FEC_SEMESTRE_PERIODO  nvarchar(25) NULL,        /* Semester Unique Identifier: Semester + Year */
   FEC_DIA_SEMANA_ENG    nvarchar(10) NULL,
   FEC_DIA_SEMANA_ESP    nvarchar(10) NULL,
   FEC_NOMBRE_MES_ING    nvarchar(10) NULL,        /* January to December */
   FEC_NOMBRE_MES_ESP    nvarchar(10) NULL,        /* Enero a Diciembre */
)
GO

--------------------------------------------------------------------------------------------------------
-- A continuación se llena la tabla de Dimensión de Fechas de acuerdo al siguiente script.
--------------------------------------------------------------------------------------------------------
declare
   @StartDate datetime,
   @EndDate datetime
   set @StartDate = convert(datetime, '01/01/1900', 103)
   set @EndDate   = convert(datetime, '31/12/2050', 103)
   SET LANGUAGE English
   while @StartDate <= @EndDate begin
      insert
            into DIM_Fecha(FEC_ID,
                       FEC_FECHA,
                       FEC_DIA_SEMANA,
                       FEC_DIA_SEMANA_ENG,
                       FEC_DIA_MES,
                       FEC_DIA_PERIODO,
                       FEC_SEMANA,
                       FEC_NOMBRE_MES_ING,
                       FEC_MES,
                       FEC_TRIMESTRE,
                       FEC_PERIODO,
                       FEC_SEMESTRE,
                       FEC_SEMANA_PERIODO,
                       FEC_MES_PERIODO,
                       FEC_TRIMESTRE_PERIODO,
                       FEC_SEMESTRE_PERIODO)
      values ((DATEPART(year , @StartDate) * 10000) + (DATEPART(month , @StartDate)*100) + DATEPART(day , @StartDate),
              @StartDate,
              DATEPART(dw , @StartDate),
              DATENAME(dw, @StartDate),
              DATEPART(day , @StartDate),
              DATEPART(dayofyear , @StartDate),
              DATEPART(wk , @StartDate),
              DATENAME(month, @StartDate),
              DATEPART(month , @StartDate),
              DATEPART(quarter , @StartDate),
              DATEPART(year , @StartDate),
              CASE WHEN DATEPART(quarter , @StartDate) < 3 THEN 1 ELSE 2 END,
              CAST(DATEPART(year , @StartDate) as char(4)) + '-' + RIGHT('0'+CAST(DATEPART(wk , @StartDate) AS varchar(2)),2),
              CAST(DATEPART(year , @StartDate) as char(4)) + '-' + RIGHT('0'+CAST(DATEPART(month , @StartDate) AS varchar(2)),2),
              CAST(DATEPART(year , @StartDate) as char(4)) + '-' + CAST(DATEPART(quarter , @StartDate) AS varchar(1)),
              CAST(DATEPART(year , @StartDate) as char(4)) + '-' +
                          CAST(CASE WHEN DATEPART(quarter , @StartDate) < 3 THEN 1 ELSE 2 END AS char(2)))
      set @StartDate = dateadd(day,1,@StartDate)
   end
GO

SET LANGUAGE Spanish

UPDATE DIM_Fecha
   SET FEC_DIA_SEMANA_ESP = DATENAME(dw, FEC_FECHA),
       FEC_NOMBRE_MES_ESP = DATENAME(month, FEC_FECHA)
GO

--------------------------------------------------------------------------------------------------------
-- A continuación se crea la tabla de Dimensión de Genero de Persona. Esta tabla mantiene los 2 campos
-- equivalentes a los campos de Etidad - Relación (catálogo).
--------------------------------------------------------------------------------------------------------
CREATE TABLE DIM_PERSONA_GENERO (
   TGE_ID INTEGER NOT NULL CONSTRAINT PK_TGE_ID PRIMARY KEY,
   TGE_DESCRIPCION VARCHAR(50)NOT NULL
)
GO

--------------------------------------------------------------------------------------------------------
-- A continuación se crea la tabla de Dimensión de Estado de Salud de Persona. Esta tabla mantiene
-- los 2 campos equivalentes a los campos de Etidad - Relación (catálogo).
--------------------------------------------------------------------------------------------------------
CREATE TABLE DIM_PERSONA_ESTADO_SALUD (
   TPE_ID INTEGER NOT NULL CONSTRAINT PK_TPE_ID PRIMARY KEY,
   TPE_DESCRIPCION VARCHAR(50)NOT NULL
)
GO

--------------------------------------------------------------------------------------------------------
-- A continuación se crea la tabla de Dimensión de Datos de la Persona. Esta tabla mantiene su ID,
-- pero se removieron los ID que marcaban una relación al genero y estado de salud, ya que eran valores
-- que se duplicarían en la tabla de hechos. Los otros campos que no son ID los mantieneN (nombres y
-- apellidos), pero se le suman los atributos de las tablas de Identificación de Persona y Dirección
-- de persona, ya que quitamos estas tablas porque estaban relacionadas con la misma llave primaria
-- y no se puede repetir el ID en el modelo estrella.
--------------------------------------------------------------------------------------------------------
CREATE TABLE DIM_DATOS_PERSONA (
   PER_ID INTEGER NOT NULL CONSTRAINT PK_PER_ID PRIMARY KEY,
   PER_PRIMER_APELLIDO VARCHAR(50)NOT NULL,
   PER_SEGUNDO_APELLIDO VARCHAR(50)NOT NULL,
   PER_PRIMER_NOMBRE VARCHAR(50)NOT NULL,
   PER_SEGUNDO_NOMBRE VARCHAR(50)NOT NULL,
   PER_PID_DOCUMENTO VARCHAR(50)NOT NULL,
   PER_PRO_NOMBRE VARCHAR(50)NOT NULL,
   PER_CAN_NOMBRE VARCHAR(50)NOT NULL,
   PER_DIS_NOMBRE VARCHAR(50)NOT NULL,
)
GO

--------------------------------------------------------------------------------------------------------
-- A continuación se crea la tabla de Dimensión de Cuentas. Esta tabla mantiene su ID,
-- pero se removieron los ID que marcaban una relación a monedas y cliente, ya que eran valores
-- que se duplicarían en la tabla de hechos. Borramos el campo CTA__EMP_ID ya que no se relacionaba con
-- más, y es un campo muerto para el negocio. También se mantuvo el campo numérico CTA_NUMERO en la
-- dimensión, debido a que este campo realmente representa un código.
--------------------------------------------------------------------------------------------------------
CREATE TABLE DIM_CUENTAS (
   CTA_ID INTEGER NOT NULL CONSTRAINT PK_CTA_ID PRIMARY KEY,
   CTA_NUMERO INTEGER NOT NULL,
)
GO

--------------------------------------------------------------------------------------------------------
-- A continuación se crea la tabla de Dimensión de Monedas. Esta tabla mantiene
-- los 2 campos equivalentes a los campos de Etidad - Relación (catálogo).
--------------------------------------------------------------------------------------------------------
CREATE TABLE DIM_MONEDAS (
   MON_ID INTEGER NOT NULL CONSTRAINT PK_MON_ID PRIMARY KEY,
   MON_DESCRIPCION VARCHAR(100)NOT NULL
)
GO

--------------------------------------------------------------------------------------------------------
-- A continuación se crea la tabla de hechos, que toma el rol de la tabla de transacciones del E-R.
-- En esta tabla se mantienen todos los valores numéricos del Data Warehouse que no son IDS, y las
-- relaciones con ID a las dimensiones. A cotinuación un desgloze de los campos y de dónde provienen:
-- TRN_TGE_ID: ID que relaciona a la dimensión de Genero de persona
-- TRN_TPE_ID: ID que relaciona a la dimensión de Estado de salud de persona
-- TRN_PER_ID: ID que relaciona a la dimensión de datos de persona
-- TRN_MON_ID: ID que relaciona a la dimensión de monedas
-- TRN_FEC_ID: ID que relaciona a la dimensión de fechas. Este valor en la tabla de transacciones y
--    tipo de cambio del E-C era un atributo tipo fecha, pero se separó en una dimensión y se vincula
--    con este ID.
-- TRN_CTA_ID: ID que relaciona a la dimensión de Cuentas
-- TRN_CLI_ID: Este ID es parte de la llave primaria, pero no relaciona a una dimensión, porque no hay
--    datos de clintes que colocar en dimensión, no que relacionar, más que el ID de persona, que está
--    en su propia dimensión. Por lo tanto, se mantiene para hacer la relación con personas para beneficio
--    del negocio, pero no tiene su propia dimensión
-- TRN_TCA_ID INTEGER NOT NULL: Este ID es parte de la llave primaria, pero no relaciona a una dimensión, 
--    porque todos los datos del tipo ce cambio se mantienen en la tabla de hechos por ser numéricos 
--    y necesarios para cálculos. Se mantiene el ID para poder identificar los tipos de cambio, pero
--    no tiene dimensión.
-- TRN_TIPO: Captura el tipo de transacción originario de la tabla de transacciones del E-R
-- TRN_MONTO: Captura el monto de transacción originario de la tabla de transacciones del E-R
-- TRN_TCA_VALOR_COMPRA: Captura el tipo de valor de compra originario de la tabla de tipo de cambio
-- TRN_TCA_VALOR_VENTA: Captura el tipo de valor de venta originario de la tabla de tipo de cambio
-- TRN_TCA_VALOR_CONTABLE: Captura el tipo de valor contable originario de la tabla de tipo de cambio
--
-- La fecha del tipo de cambio y transacción pasó a ser la dimensión de fecha, ya que es una misma fecha
--------------------------------------------------------------------------------------------------------
CREATE TABLE FAC_TRANSACCION (
   TRN_TGE_ID INTEGER NOT NULL,
   TRN_TPE_ID INTEGER NOT NULL,
   TRN_PER_ID INTEGER NOT NULL,
   TRN_MON_ID INTEGER NOT NULL,
   TRN_FEC_ID INTEGER NOT NULL,
   TRN_CTA_ID INTEGER NOT NULL,
   TRN_CLI_ID INTEGER NOT NULL,
   TRN_TCA_ID INTEGER NOT NULL,
   TRN_TIPO SMALLINT NOT NULL,
   TRN_MONTO  DECIMAL(25,2) NOT NULL CONSTRAINT TRN_MONTO_MAYOR_CERO CHECK (TRN_MONTO > 0),
   TRN_TCA_VALOR_COMPRA  DECIMAL(18,5) NOT NULL CONSTRAINT TRN_TCA_VALOR_COMPRA_MAYOR_CERO CHECK (TRN_TCA_VALOR_COMPRA >= 0),
   TRN_TCA_VALOR_VENTA  DECIMAL(18,5) NOT NULL CONSTRAINT TRN_TCA_VALOR_VENTA_MAYOR_CERO CHECK (TRN_TCA_VALOR_VENTA >= 0),
   TRN_TCA_VALOR_CONTABLE  DECIMAL(18,5) NOT NULL CONSTRAINT TRN_TCA_VALOR_CONTABLE_MAYOR_CERO CHECK (TRN_TCA_VALOR_CONTABLE >= 0),
   CONSTRAINT FK_TRN_TGE_ID FOREIGN KEY (TRN_TGE_ID) REFERENCES DIM_PERSONA_GENERO(TGE_ID),
   CONSTRAINT FK_TRN_TPE_ID FOREIGN KEY (TRN_TPE_ID) REFERENCES DIM_PERSONA_ESTADO_SALUD(TPE_ID),
   CONSTRAINT FK_TRN_PER_ID FOREIGN KEY (TRN_PER_ID) REFERENCES DIM_DATOS_PERSONA(PER_ID),
   CONSTRAINT FK_TRN_MON_ID FOREIGN KEY (TRN_MON_ID) REFERENCES DIM_MONEDAS(MON_ID),
   CONSTRAINT FK_TRN_FEC_ID FOREIGN KEY (TRN_FEC_ID) REFERENCES DIM_FECHA(FEC_ID),
   CONSTRAINT FK_TRN_CTA_ID FOREIGN KEY (TRN_CTA_ID) REFERENCES DIM_CUENTAS(CTA_ID),
   CONSTRAINT PK_FAC_TRANSACCCION PRIMARY KEY(TRN_TGE_ID, TRN_TPE_ID, TRN_PER_ID, TRN_MON_ID, TRN_FEC_ID, TRN_CTA_ID, TRN_CLI_ID, TRN_TCA_ID)
)
GO

--------------------------------------------------------------------------------------------------------
-- A continuación se crea la tabla vitacora de errores. Esta tabla no tiene restricciones en los datos
-- (se le define varchar(255)) porque está destinada a capturar los valores que son considerados errores
-- de acuerdo a la fase de transformación y carga. Es una replica de la tabla de hechos, pero sin 
-- restricciones.
--------------------------------------------------------------------------------------------------------
CREATE TABLE FAC_TRANSACCION_ERRORES (
   TRN_TGE_ID VARCHAR(255),
   TRN_TPE_ID VARCHAR(255),
   TRN_PER_ID VARCHAR(255),
   TRN_MON_ID VARCHAR(255),
   TRN_FEC_ID VARCHAR(255),
   TRN_CTA_ID VARCHAR(255),
   TRN_CLI_ID VARCHAR(255),
   TRN_TCA_ID VARCHAR(255),
   TRN_TIPO VARCHAR(255),
   TRN_MONTO  VARCHAR(255),
   TRN_TCA_VALOR_COMPRA  VARCHAR(255),
   TRN_TCA_VALOR_VENTA  VARCHAR(255),
   TRN_TCA_VALOR_CONTABLE  VARCHAR(255),
)
