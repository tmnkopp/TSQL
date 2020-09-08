/*  
Who:	T.KOPP
When:	8-5-2020
Why:	calculates Expression strings, replacement for clr eval func
How:	
 
*/  
SET NOCOUNT ON   
IF EXISTS (SELECT * FROM sysobjects WHERE name = 'sp_ValidatorDefinitions' AND type = 'P')
    DROP PROCEDURE [sp_ValidatorDefinitions]
GO 
CREATE PROCEDURE [dbo].[sp_ValidatorDefinitions] 
	@MODE NVARCHAR(255) 
AS
BEGIN 
	IF @MODE='VALIDATION_EXPRESSIONS'
	BEGIN
		DECLARE @VALIDATIONS TABLE (IDX INT IDENTITY(1,1), ValidationCode NVARCHAR(255), ValidationType NVARCHAR(255), Expression NVARCHAR(4000), ErrorMessage NVARCHAR(4000))
		INSERT INTO @VALIDATIONS(ValidationCode, ValidationType, Expression, ErrorMessage ) VALUES  
			('IPADDRESS', 'REGEX'
				, '^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
				, 'Please provide a valid IP Address (ex. 255.255.255.255 ex. 255.0.0.1) for {0}.')  
 		,	('PHONE', 'REGEX'
				, '\(*\d{3}\)*( |-)*\d{3}( |-)*\d{4}'
				, 'Please provide a valid Phone Number ex. (555) 555-1234 for {0}')  
 		,	('CVE', 'REGEX'
				, '^CVE-\d{4}-\d{4,7}$'
				, 'Please provide a valid CVE ex. CVE-123-12345 for {0}')  
  		,	('NUMERIC', 'REGEX'
				, '^[0-9]*$'
				, 'Please provide a valid Number ex. 12345 for {0}')  
  		,	('DECIMAL', 'REGEX'
				, '^[-]?\d+(\.\d+)?$'
				, 'Please provide a valid Decimal Number ex. 3.14159 for {0}')  
  		,	('CIDR', 'REGEX'
				, '^s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8]))?$'
				, 'Please provide a valid CIDR ex. fe80:0000:0000:0000:0204:61ff:fe9d:f156/123 for {0}.{1}')  
  		,	('EMAIL', 'REGEX'
				, '^[a-zA-Z0-9.!#$%&''*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$'
				, 'Please provide a valid Email Address ex. example@example.com for {0}.{1}') 				

				
		SELECT ValidationCode, ValidationType, Expression, ErrorMessage FROM @VALIDATIONS 
	END

END
--