/*  
Who:	T.KOPP
When:	9-5-2020
Why:	provides mask formulas strings  
 
*/  
SET NOCOUNT ON   
IF EXISTS (SELECT * FROM sysobjects WHERE name = 'sp_MaskFormulas' AND type = 'P')
    DROP PROCEDURE [sp_MaskFormulas]
GO 
CREATE PROCEDURE [dbo].[sp_MaskFormulas] 
	@MODE NVARCHAR(255) 
AS
BEGIN 
	IF @MODE='MASK_FORMULAS'
	BEGIN
		DECLARE @MaskFormulas TABLE (IDX INT IDENTITY(1,1), ProviderCode NVARCHAR(255), FormulaType NVARCHAR(255), ReplaceRegex NVARCHAR(255), MaskChar NVARCHAR(2), MaskExpression NVARCHAR(4000))
		INSERT INTO @MaskFormulas(ProviderCode, FormulaType, ReplaceRegex, MaskChar, MaskExpression ) VALUES  
			('IPADDRESS', 'REGEX' , '\d', '*'
				, '^\d{1,3}\.\d{1,3}\.(\d{1,3}\.\d{1,3})$') 	 
		,	('SSNPOST', 'REGEX' , '\d', '*'
				, '^\d{3}\-\d{2}\-(\d{4})$')  						
		,	('SSN', 'REGEX' , '\d', '*'
				, '^(\d{3}\-\d{2}\-)\d{4}$') 
		,	('DIGITMASK', 'REGEX' , '\d', '*'
				, '^(.*)$') 	
		,	('ALPHANUMERICMASK', 'REGEX' , '\d|\w', '*'
				, '^(.*)$') 												
		SELECT ProviderCode, FormulaType, ReplaceRegex, MaskChar, MaskExpression  FROM @MaskFormulas 
	END

END
--