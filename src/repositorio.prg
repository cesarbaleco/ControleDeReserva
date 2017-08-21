#Include "CR.CH"

Function CriarTabelas()

   if !lIsDir(SIS_DB)
      if !lMkDir(SIS_DB)
         MsgStop("Não é possível prosseguir sem o diretório de dados!","Erro")
         return .F.
      endif
   endif
	
   MsgMeter({|oMeter,oText,oDlg,lEnd|CriarTabelas_Meter(oMeter,oText,oDlg,lEnd)},"Criando tabelas...","Aguarde um momento")
	
Function CriarTabelas_Meter(oMeter,oText,oDlg,lEnd)
   oMeter:SetTotal(4)
   oText:SetText("Aguarde, criando tabelas...")
   oMeter:Set(1)
   *
   aEst:={}
   aadd(aEst,{"ID","N",20,0})
   aadd(aEst,{"MATRICULA","C",20,0})
   aadd(aEst,{"NOME","C",50,0})
   aadd(aEst,{"SENHA","C",20,0})
   IF ! File(SIS_DB+"PESSOA.DBF")
      DbCreate(SIS_DB+"PESSOA.DBF",aEst)
      USE &SIS_DB.PESSOA EXCLUSIVE
      IF EOF()
         APPEND BLANK
         REPLACE ID WITH 1
         REPLACE NOME WITH "ADMINISTRADOR"
         REPLACE SENHA WITH "1@QAZ"
         REPLACE MATRICULA WITH "MATHEUS"
         COMMIT
         UNLOCK
      ENDIF
      CLOSE DATA
   ENDIF
   oMeter:Set(2)
   aEst:={}
   aadd(aEst,{"ID","N",20,0})
   aadd(aEst,{"NOME","C",50,0})
   IF ! File(SIS_DB+"RESERVA.DBF")
      DbCreate(SIS_DB+"RESERVA.DBF",aEst)
   ENDIF
   oMeter:Set(3)
   aEst:={}
   aadd(aEst,{"ID","N",20,0})
   aadd(aEst,{"DTRESERV","D",8,0})
   aadd(aEst,{"HRINI","C",8,0})
   aadd(aEst,{"HRFIM","C",8,0})
   aadd(aEst,{"IDRESERVA","N",20,0})
   aadd(aEst,{"IDALUNO","N",20,0})
   IF ! File(SIS_DB+"RESERVAS.DBF")
      DbCreate(SIS_DB+"RESERVAS.DBF",aEst)
   ENDIF
   oMeter:Set(4)
   aEst:={}
   aadd(aEst,{"ID","N",20,0})
   aadd(aEst,{"IDRESERVA","N",20,0})
   aadd(aEst,{"DIA","N",1,0})
   aadd(aEst,{"HRINI","C",8,0})
   aadd(aEst,{"HRFIM","C",8,0})
   aadd(aEst,{"LIMITE","C",8,0})
   IF ! File(SIS_DB+"DISPOR.DBF")
      DbCreate(SIS_DB+"DISPOR.DBF",aEst)
   ENDIF

Function CriarIndice(lApagar)
   Default lApagar:=.f.
	*
	CLOSE DATA
	*
	if !lIsDir(SIS_DB)
      if !lMkDir(SIS_DB)
         MsgStop("Não é possível prosseguir sem o diretório de dados!","Erro")
         return .F.
      endif
   endif
   *
   IF !FILE("VERSAO.CONFIG")
   	lApagar:=.T.
	ELSE
		cVersao:= MemoRead("VERSAO.CONFIG")
		if cVersao # SIS_VERSAO
			lApagar:=.T.
		endif	
	ENDIF
	
   IF lApagar
		DELETE FILE (SIS_DB+"PESSOA.CDX")
		DELETE FILE (SIS_DB+"RESERVA.CDX")
		DELETE FILE (SIS_DB+"RESERVAS.CDX")
		DELETE FILE (SIS_DB+"DISPOR.CDX")
	ENDIF	
	*
   MsgMeter({|oMeter,oText,oDlg,lEnd|CriarIndice_Meter(oMeter,oText,oDlg,lEnd)},"Criando indices...","Aguarde um momento")
	*
	MemoWrit("VERSAO.CONFIG",SIS_VERSAO)
Function CriarIndice_Meter(oMeter,oText,oDlg,lEnd)
   *
   oMeter:SetTotal(4)
   oText:SetText("Aguarde, indexando...")
   oMeter:Set(1)
   if !File(SIS_DB+"PESSOA.CDX")
      USE &SIS_DB.PESSOA EXCLUSIVE
      IF !NetErr()
         PACK
         INDEX ON ID TAG PESSOA01 TO &SIS_DB.PESSOA 
         INDEX ON MATRICULA TAG PESSOA02 TO &SIS_DB.PESSOA 
         INDEX ON UPPER(NOME) TAG PESSOA03 TO &SIS_DB.PESSOA
      ENDIF
   ENDIF
   CLOSE DATA
   *
   oMeter:Set(2)
   if !File(SIS_DB+"RESERVA.CDX")
      USE &SIS_DB.RESERVA EXCLUSIVE
      IF !NetErr()
         PACK
         INDEX ON ID TAG RESERVA01 TO &SIS_DB.RESERVA 
         INDEX ON UPPER(NOME) TAG RESERVA02 TO &SIS_DB.RESERVA
      ENDIF
   ENDIF
   CLOSE DATA
   *
   oMeter:Set(3)
   if !File(SIS_DB+"RESERVAS.CDX")
      USE &SIS_DB.RESERVAS EXCLUSIVE
      IF !NetErr()
         PACK
         INDEX ON ID TAG RESERVAS01 TO &SIS_DB.RESERVAS 
         INDEX ON IDRESERVA TAG RESERVAS02 TO &SIS_DB.RESERVAS
         INDEX ON IDALUNO TAG RESERVAS03 TO &SIS_DB.RESERVAS
         INDEX ON DTOS(DTRESERV) TAG RESERVAS04 TO &SIS_DB.RESERVAS
      ENDIF
   ENDIF
   CLOSE DATA
   *
   oMeter:Set(4)
   if !File(SIS_DB+"DISPOR.CDX")
      USE &SIS_DB.DISPOR EXCLUSIVE
      IF !NetErr()
         PACK
         INDEX ON ID TAG DISPOR01 TO &SIS_DB.DISPOR 
         INDEX ON IDRESERVA TAG DISPOR02 TO &SIS_DB.DISPOR 
      ENDIF
   ENDIF
   CLOSE DATA
		   	
		   	
		   	
		   
		   
	
	
	              
	