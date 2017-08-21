#Include "Fivewin.CH"

CLASS Entidade

   DATA nId AS NUMERIC INIT 0
   DATA dDataReg AS DATE 
   DATA dDataAlt AS DATE 
   
	METHOD New() CONSTRUCTOR

ENDCLASS
METHOD New() CLASS Entidade
return Self