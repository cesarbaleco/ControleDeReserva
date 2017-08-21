#Include "Fivewin.CH"

#DEFINE DE_ERRO_NOME "VALOR DO NOME DO CAMPO NÃO É CARACTERE"
#DEFINE DE_ERRO_TIPO "VALOR DO TIPO DO CAMPO NÃO É CARACTERE"
#DEFINE DE_ERRO_TAMANHO "VALOR DO TAMANHO DO CAMPO NÃO É NUMÉRICO"
#DEFINE DE_ERRO_DECIMAL "VALOR DO DECIMAL DO CAMPO NÃO É NUMÉRICO"
#DEFINE DE_ERRO_NOME_TAMANHO8 "NÚMERO DE CARACTERES É MAIOR QUE 8"
#DEFINE DE_ERRO_NOME_TAMANHO0 "NÚMERO DE CARACTERES É MENOR OU IGUAL A 0"
#DEFINE DE_ERRO_TAMANHO0 "TAMANHO NÃO PODE SER MENOR OU IGUAL A 0"
#DEFINE DE_ERRO_TAMANHO255 "TAMANHO NÃO PODE SER MAIOR QUE 255"
#DEFINE DE_ERRO_TAMANHO1 "TAMANHO NÃO PODE SER MAIOR QUE 1"
#DEFINE DE_ERRO_TAMANHO8 "TAMANHO NÃO PODE SER MAIOR QUE 8"
#DEFINE DE_ERRO_TAMANHO10 "TAMANHO NÃO PODE SER MAIOR QUE 10"
#DEFINE DE_ERRO_TIPOINVALIDO "TIPO DO CAMPO INVÁLIDO"
#DEFINE DE_ERRO_TAMANHODECIMAL0 "DECIMAL NÃO PODE SER MENOR QUE 0"

//----------------------------------------------------------------//
 
CLASS Tabela

   DATA oModelo
   DATA aCampo AS ARRAY INIT {}
   DATA aIndice AS ARRAY INIT {}
    
   METHOD New(oModelo) CONSTRUCTOR
   Method InitCampos(oModelo)
   Method InitIndice()
   Method AddIndice(oIndice)
   Method ManterTabela() // Criar ou Alterar Tabela
   Method ManterIndice() // Criar Ou Alterar Indice
   Method Usar() // Verificar o que é necessário para abrir a tabela
ENDCLASS

//----------------------------------------------------------------//

METHOD New(oModelo) CLASS Tabela
::oModelo := oModelo
*
::InitCampos(::oModelo)
::InitIndice()
*
FWDBG ::aCampo,::aIndice

Return Self
*
Method InitCampos(oModelo) Class Tabela
Local aDados := aOData(oModelo)
Local aEstrutura:={}
Local oCampo:=NIL,cName:="",uData:=NIL,cType:="",nLen:=0,nDec:=0
*
For nItem := 1 to len(aDados)
   cName:=""
   uData:=NIL
   cType:=""
   nLen:=0
   nDec:=0
   *
   cName:=aDados[nItem]
   uData:= oModelo:&(aDados[nItem])
   cType := Valtype(uData)
   *
   Do Case
   case cType == "C"
      nLen := len(cValToChar(uData))
   case cType == "D"
      nLen := 8
   case cType == "N"
      nLen := len(cValToChar(uData))
      nAt := AT(".",cValToChar(uData))
      if nAt > 0
         nDec:= nLen - nAt
      endif
      nLen := len(strtran(cValToChar(uData),"."))
   case cType == "L"
      nLen := 1
   case cType == "M"
      nLen := 10
   case cType == "O"
      ? 'TODO: Relacionamento Com Objetos'
   ENDCASE
   *
   oCampo := Campo():New(cName,cType,nLen,nDec)
   *
   AADD(::aCampo,oCampo)
Next

Return

Method InitIndice() Class Tabela
Local oCampo:=NIL
// Colocar Baseado Na Classe Entidade
IF LEN(::aCampo) > 0
   For Each oCampo IN ::aCampo
      if upper(oCampo:cNome) == "NID"
         aadd(::aIndice, Indice():New(::oModelo:ClassName,::oModelo:ClassName+"PK",oCampo:cNome,.T.))
      endif
   Next
ENDIF

Method AddIndice(oIndice) Class Tabela
	    aadd(::aIndice,oIndice)

//----------------------------------------------------------------//

CLASS Campo

   DATA cNome AS CHARACTER INIT SPACE(8)
   DATA cTipo AS CHARACTER INIT SPACE(1)
   DATA nTamanho AS NUMERIC INIT 0
   DATA nDecimal AS NUMERIC INIT 0
   
   
   METHOD New() CONSTRUCTOR
   Method toString()

ENDCLASS


METHOD New(cNome,cTipo,nTamanho,nDecimal) CLASS Campo
	
::cNome   := cNome
::cTipo   := cTipo
::nTamanho:= nTamanho
::nDecimal:= nDecimal
*
IF Valtype(cNome) == "C"
   IF LEN(cNome) > 8
      *Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_NOME_TAMANHO8 ) )
   ENDIF
   IF LEN(cNome) <= 0
      Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_NOME_TAMANHO0 ) )
   ENDIF
ELSE
   Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_NOME ) )
ENDIF
*
IF Valtype(cTipo) == "C"
   IF Valtype(nTamanho) == "N"
      IF nTamanho <= 0
         Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_TAMANHO0 ) )
      ELSE
         DO CASE
         CASE cTipo == "C"
            IF nTamanho > 255
               Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_TAMANHO255 ) )
            ENDIF
         CASE cTipo == "N"
            IF nTamanho > 255
               Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_TAMANHO255 ) )
            ENDIF
         CASE cTipo == "L"
            IF nTamanho > 1
               Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_TAMANHO1 ) )
            ENDIF
         CASE cTipo == "D"
            IF nTamanho > 8
               Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_TAMANHO8 ) )
            ENDIF
         CASE cTipo == "M"
            IF nTamanho > 10
               Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_TAMANHO10 ) )
            ENDIF
         OTHERWISE
            Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_TIPOINVALIDO ) )
         ENDCASE
      ENDIF
   ELSE
      Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_TAMANHO ) )
   ENDIF
ELSE
   Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_TIPO ) )
ENDIF
*
IF Valtype(nDecimal) == "N"
   IF nDecimal < 0
      Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_TAMANHODECIMAL0 ) )
   ENDIF
ELSE
   Eval( ErrorBlock(), _FWGenError( 6, ::toString()+":"+DE_ERRO_DECIMAL ) )
ENDIF
	
return Self

Method toString() Class Campo
return "(cNome:"+cValToChar(::cNome)+","+"cTipo:"+cValToChar(::cTipo)+","+"nTamanho:"+cValToChar(::nTamanho)+","+"nDecimal:"+cValToChar(::nDecimal)+")"

//----------------------------------------------------------------//

CLASS Indice
   DATA cFile, cTag, cKey, lUnique
   
   METHOD New(cFile, cTag, cKey, lUnique) CONSTRUCTOR
   //	Method toString()

ENDCLASS

METHOD New(cFile, cTag, cKey, lUnique) CLASS Indice
		::cFile  := cFile
		::cTag   := cTag
		::cKey   := cKey
		::lUnique:= lUnique
		? 'TODO: Validar parametros'
Return Self

//----------------------------------------------------------------//

Function Number(nLen,nDec)
   return val(replicate("9",nLen-nDec)+"."+replicate("9",nDec))

//----------------------------------------------------------------//

