#Include "CR.CH"
 
CLASS Usuario FROM Entidade

   DATA nId AS NUMERIC INIT 0
   DATA cNome AS CHARACTER INIT SPACE(50)
   DATA cSenha AS CHARACTER INIT SPACE(50)
   DATA nSaldo AS NUMERIC INIT Number(12,2)
   DATA dNascimento AS DATE INIT DATE()
   DATA lAdministrador AS LOGICAL INIT .F.
   
	METHOD New() CONSTRUCTOR


ENDCLASS

//----------------------------------------------------------------//

METHOD New() CLASS Usuario
		 ::Super():New()
   
return Self

//----------------------------------------------------------------//

