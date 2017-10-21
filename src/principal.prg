#Include "CR.CH"
*
Function Main()
   Public oWnd,oIcone,oBrush,oMenu
   Public oMetro,oBtnLogo,oBtnExit
   PUBLIC SIS_DB := CURDRIVE()+":\"+CURDIR()+"\DATA\"
   PUBLIC IdUsuario:=0 , aBotoes:={} ,oTextFont
   *
   Store NIL To oWnd,oIcone,oBrush,oVSlider,oImgTouch,oImgEnd
   *
   HB_LANGSELECT( 'PT' )
   *
   REQUEST HB_Lang_PT
   REQUEST HB_CODEPAGE_DE850, HB_CODEPAGE_DEISO
   *
   SetGetColorFocus( CLR_SKY )
   *
   SET DELE ON
   SET CENT ON
   SET DATE BRIT
   SET EPOCH TO 1980
   SET MULTIPLE ON
   *
   SET 3DLOOK ON
   SET SOFTSEEK OFF
   SET CONFIRM ON
   sethandlecount(250)
   SetBalloon( .T. )
   *
   REQUEST DBFCDX
   RDDSETDEFAULT("DBFCDX")
   *
   DEFINE ICON  oIcone RESOURCE "CR"
   *
   CriarTabelas()
   CriarIndice()
	
   IF !Login()
      QUIT
   ENDIF
   *
   AbreTabelas()
   *
   SELECT PESSOA
   SET ORDER TO 1
   SEEK IDUSUARIO
   temSenha:=.f.
   nomeDoUsuario:=""
   IF !EOF()
      temSenha:= !Empty(pessoa->senha)
      nomeDoUsuario:= StrCapFirst(alltrim(pessoa->nome))
   ENDIF
	
   DEFINE FONT oTextFont NAME "Segoe UI Light" SIZE 8,20 BOLD
   DEFINE FONT oTextFont2 NAME "Segoe UI Light" SIZE 12,42 BOLD
   DEFINE WINDOW oWnd TITLE SIS_NAME STYLE nOr( WS_POPUP, WS_MAXIMIZE ) COLOR CLR_WHITE, CLR_GREEN
   *
   DEFINE METROPANEL oMetro OF oWnd TITLE SIS_NAME+" "+SIS_VERSAO+IIF( Empty(nomeDoUsuario), ""," Bem-vindo "+nomeDoUsuario) COLOR CLR_WHITE, CLR_BLACK

   DEFINE BRUSH oBrush FILE '.\res\background.png' RESIZE
   oMetro:SetBrush( oBrush )
   oBrush:End()
   *
   oMetro:lDesignMode := .F.
   *
	DEFINE METROBUTTON oBtnSair OF oMetro ;
       COLOR   CLR_WHITE,METRO_RED ;
       CAPTION   "Sair do Programa" ALIGN "TOPLEFT" ;
       BITMAP   "EXIT" BMPALIGN   "TOPRIGHT" ;
       SIZE   40, 40 LARGE;
       GROUP 1;
		 ACTION   {|o| oWnd:End() }

   if temSenha
      DEFINE METROBUTTON oBtnCadRes OF oMetro ;
       COLOR   CLR_WHITE,METRO_GREEN ;
       CAPTION   "Cadastro de Reserva" ALIGN "TOPLEFT" ;
       BITMAP   "RESERVA" BMPALIGN   "TOPRIGHT" ;
       SIZE   40, 40 LARGE;
       GROUP 1;
		 ACTION   {|o| ManterReserva() }

      DEFINE METROBUTTON oBtnCadGru OF oMetro ;
       COLOR   CLR_WHITE,METRO_GREEN ;
       CAPTION   "Cadastro de Grupo" ALIGN "TOPLEFT" ;
       BITMAP   "RESERVA" BMPALIGN   "TOPRIGHT" ;
       SIZE   40, 40 LARGE;
		 GROUP 1;
       ACTION   {|o| ManterGrupo() }
      
      DEFINE METROBUTTON oBtnCadPes OF oMetro ;
       COLOR   CLR_WHITE,METRO_GREEN ;
       CAPTION   "Cadastro de Pessoas" ALIGN "TOPLEFT" ;
       BITMAP   ".\res\people.png" BMPALIGN   "TOPRIGHT" ;
       SIZE   64, 64 LARGE;
       GROUP 1;
		 ACTION   {|o| ManterPessoa() }

      DEFINE METROBUTTON oBtnReorg OF oMetro ;
       COLOR   CLR_WHITE,METRO_GREEN ;
       CAPTION   "Reorganizar" ALIGN "TOPLEFT" ;
       BITMAP   "PESSOA" BMPALIGN   "TOPRIGHT" ;
       SIZE   40, 40 LARGE;
       GROUP 1;
		 ACTION   {|o| CriarIndice(.t.),AbreTabelas() }
      
      DEFINE METROBUTTON oBtnImportar OF oMetro ;
       COLOR   CLR_WHITE,METRO_GREEN ;
       CAPTION   "Importar Alunos" ALIGN "TOPLEFT" ;
       BITMAP   "PESSOA" BMPALIGN   "TOPRIGHT" ;
       SIZE   40, 40 LARGE;
       GROUP 1;
		 ACTION   {|o| ImportarAlunos() }
   endif
	*
   MsgRun("Carregando botoes...","Aguarde...",{||CarregaBotoesGrupos()})
   *
   ACTIVATE WINDOW oWnd MAXIMIZED ON INIT (oMetro:Show(),BringWindowToTop( oWnd:hWnd ))

Function CarregaBotoesGrupos()
	*
   select grupo
   go top
   while ! grupo->(eof())
      *
      cBtn:= "oBtnGrupo"+strzero(grupo->id,5,0)
		DEFINE METROBUTTON &cBtn OF oMetro ;
       COLOR   CLR_WHITE,CLR_HBLUE ;
       CAPTION   "Salas" ALIGN "TOPLEFT" ;
       BITMAP   "ITEM" BMPALIGN   "TOPRIGHT" ;
       SIZE   40, 40 ;
       BODYTEXT StrCapFirst(alltrim(grupo->nome)) TEXTALIGN "BOTTOMLEFT" TEXTFONT oTextFont ;
       GROUP IIF(TEMSENHA,2,1);
		 ACTION {|o| CarregaBotoesReserva(o:Cargo)}
      *           
      *
      oBtnMTGrupo:=&cBtn
      oBtnMTGrupo:Cargo := grupo->id
		select grupo
      skip
   end

Function CarregaBotoesReserva(nGrupo)
			MsgRun("Use a tecla [ALT]+[TAB] para alternar as janelas","",{|| CarregaBotoesReserva_1(nGrupo)})
Function CarregaBotoesReserva_1(nGrupo)
	Local cNomeGrupo:="",oWndReserva,oMetroReserva,oTextFontR,oTextFontR2 ,lFechar:=.f.
   *
	select grupo
	set order to 1
	seek nGrupo
	*
	cNomeGrupo:= "Sessão "+StrCapFirst(grupo->nome)
	*
   SELECT reserva_grupo
   SET ORDER TO 2
   OrdScope(0,nGrupo)
   OrdScope(1,nGrupo)
   GO TOP
	*
	if Eof()
		MsgAlert("Está sala está vazia!","Desculpe")
	   SELECT reserva_grupo
		OrdScope(0,NIL)
	   OrdScope(1,NIL)
		return
	endif	
	
	DEFINE FONT oTextFontR NAME "Segoe UI Light" SIZE 8,20 BOLD
   DEFINE FONT oTextFontR2 NAME "Segoe UI Light" SIZE 12,42 BOLD
   *
	DEFINE WINDOW oWndReserva TITLE SIS_NAME STYLE nOr( WS_POPUP, WS_MAXIMIZE ) COLOR CLR_WHITE, CLR_BLACK
   *
   DEFINE METROPANEL oMetroReserva OF oWndReserva TITLE cNomeGrupo COLOR CLR_WHITE, CLR_BLACK
   *
   DEFINE BRUSH oBrushReserva FILE '.\res\background.png' RESIZE
   oMetroReserva:SetBrush( oBrushReserva )
   oBrushReserva:End()
   *
	oMetroReserva:lDesignMode := .F.
   *
	DEFINE METROBUTTON oBtnSairReserva OF oMetroReserva ;
       COLOR   CLR_WHITE,METRO_OLIVE ;
       CAPTION   "Retornar" ALIGN "TOPLEFT" ;
       BITMAP   "EXIT" BMPALIGN   "TOPRIGHT" ;
       SIZE   40, 40 ;
       GROUP 1;
		 ACTION   {|o| oWndReserva:End() }

   select reserva_grupo
   go top
   while ! reserva_grupo->(eof())
      cBtn:= "oBtn"+strzero(reserva_grupo->id_reserva,5,0)
      *
      select reserva
      set order to 1
      seek reserva_grupo->id_reserva
		
		cBodyText:=Reserva_Status()
		
  		if len(StrToken(cBodyText,1,";"))>8
			DEFINE METROBUTTON &cBtn OF oMetroReserva ;
	       COLOR   CLR_WHITE,METRO_GREEN ;
	       CAPTION   "Reserva" ALIGN "TOPLEFT" ;
	       BITMAP   "ITEM" BMPALIGN   "TOPRIGHT" ;
	       SIZE   40, 40 LARGE;
	       BODYTEXT cBodyText TEXTALIGN   "BOTTOMLEFT" TEXTFONT oTextFont ;
	       ACTION {|o| Reservar( o:Cargo ) }
      else
			DEFINE METROBUTTON &cBtn OF oMetroReserva ;
	       COLOR   CLR_WHITE,METRO_GREEN ;
	       CAPTION   "Reserva" ALIGN "TOPLEFT" ;
	       BITMAP   "ITEM" BMPALIGN   "TOPRIGHT" ;
	       SIZE   40, 40 ;
	       BODYTEXT cBodyText TEXTALIGN   "BOTTOMLEFT" TEXTFONT oTextFont ;
	       ACTION {|o| Reservar( o:Cargo ) }
		endif
		*
      oBtnMT:=&cBtn
      oBtnMT:Cargo := reserva_grupo->id_reserva
		*
		aadd(aBotoes,oBtnMT)
      select reserva_grupo
      skip
   end

  ACTIVATE WINDOW oWndReserva MAXIMIZED ON INIT (oMetroReserva:Show(),BringWindowToTop( oWndReserva:hWnd )) VALID (lFechar:=.T.)
 	
   hWndMain    := WndMain():hWnd
   StopUntil( { || lFechar .or. !IsWindow( hWndMain ) } )
	SysRefresh()
Function ImportarAlunos()
   Local xcaminho
   xcaminho := cGetFile("*.*","Informe o arquivo")
   * VALID EXTENSAO XLS
   IF UPPER(cFileExt(xcaminho)) # "XLS"
      IF UPPER(cFileExt(xcaminho)) # "XLSX"
         MsgAlert("No Arquivo de Origem não é aceito a extensão "+UPPER(cFileExt(vcampo_origem)),"Atenção")
         RETURN .F.
      ENDIF
   ENDIF
   *
   MsgMeter({|oMeter,oText,oDlg,lEnd|ImportarAlunos_Meter(xcaminho,oMeter,oText,oDlg,lEnd)			},"Importando alunos...","Aguarde um momento")
Function ImportarAlunos_Meter(cCaminho,oMeter,oText,oDlg,lEnd)

   hColunaCabeca := {=>}
   lvolta:=.f.
   TRY
      oExcel := CreateObject( "Excel.Application" )
      oBook := oExcel:WorkBooks:Open( cCaminho,;
       OleDefaultArg(), ;
       OleDefaultArg(), ;
       OleDefaultArg(), ;
       OleDefaultArg(), ;
       '1111')
      oSheet := oExcel:Get("ActiveSheet")
   CATCH oerro
      MsgAlert("Atenção não é possível abrir a planilha - erro Tecnico! - "+oerro:description,"Alerta")
      lvolta:=.t.
   END
   *
   IF lvolta
      RETURN .T.
   ENDIF
   nTotalLinhas := 2000
   //			WHILE .T.
      //			   nTotalLinhas++
      //				cCampo       := oSheet:Cells(nTotalLinhas,4):Value
      //			   if Empty(cCampo)
         //				   nTotalLinhas--
         //					EXIT
      //				ENDIF
   //			END
   avalores:={}
   oMeter:SetTotal(nTotalLinhas)
   oMeter:refresh()
   For nLinha:=1 to nTotalLinhas
      cValor  := strtran( alltrim(cvaltochar( oSheet:Cells(nLinha,4):Value)) , "'","")
      cNome  := strtran( alltrim(cvaltochar(oSheet:Cells(nLinha,5):Value)) , "'","")
      aadd(avalores,cValor)
      IF LEN(cValor) = 6
         SELECT PESSOA
         SET ORDER TO 2
         SEEK cValor
         IF EOF()
            SELECT PESSOA
            SET ORDER TO 1
            GO BOTTOM
            nIdPessoa:= pessoa->id + 1
            SELECT PESSOA
            append blank
            if rlock()
               replace pessoa->id with nIdPessoa
               replace pessoa->nome with alltrim(upper(cNome))
               replace pessoa->MATRICULA with alltrim(upper(cValor))
               commit
               unlock
            endif
         ENDIF
      ENDIF
      oMeter:Set(nLinha)
   next
   *FWDBG avalores
         	 
Function AbreTabelas()
   *
   CLOSE DATA
   *
   USE &SIS_DB.PESSOA SHARED NEW
   IF NetErr()
      MsgAlert("Arquivo aberto em modo exclusivo! - Pessoa","Alerta")
      CLOSE DATA
      RETURN
   ENDIF
   SET INDEX TO &SIS_DB.PESSOA
   *
   USE &SIS_DB.RESERVA SHARED NEW
   IF NetErr()
      MsgAlert("Arquivo aberto em modo exclusivo! - Reserva","Alerta")
      CLOSE DATA
      RETURN
   ENDIF
   SET INDEX TO &SIS_DB.RESERVA
   *
   USE &SIS_DB.RESERVAS SHARED NEW
   IF NetErr()
      MsgAlert("Arquivo aberto em modo exclusivo! - Reservas","Alerta")
      CLOSE DATA
      RETURN
   ENDIF
   SET INDEX TO &SIS_DB.RESERVAS
   *
   USE &SIS_DB.DISPOR SHARED NEW
   IF NetErr()
      MsgAlert("Arquivo aberto em modo exclusivo! - Disponibilidade","Alerta")
      CLOSE DATA
      RETURN
   ENDIF
   SET INDEX TO &SIS_DB.DISPOR

   USE &SIS_DB.GRUPO SHARED NEW
   IF NetErr()
      MsgAlert("Arquivo aberto em modo exclusivo! - Grupo","Alerta")
      CLOSE DATA
      RETURN
   ENDIF
   SET INDEX TO &SIS_DB.GRUPO

   USE &SIS_DB.RESERVA_GRUPO SHARED NEW
   IF NetErr()
      MsgAlert("Arquivo aberto em modo exclusivo! - Grupo da Reserva","Alerta")
      CLOSE DATA
      RETURN
   ENDIF
   SET INDEX TO &SIS_DB.RESERVA_GRUPO
Function NomeDoAluno(nIdAluno)
   Select pessoa
   set order to 1
   seek nIDAluno
   return alltrim(pessoa->nome)
Function PreencherDisponibilidade(vDia,tDisponibilidade,aDisponibilidade,vHora,oHora)
   if len(aDisponibilidade)>0
      nPosicao := Ascan(aDisponibilidade,{|item|item[1]==PegaNrDia(vDia)})
      if nPosicao > 0
         tDisponibilidade:=aDisponibilidade[nPosicao][2]
         if len(tDisponibilidade) > 0
            oHora:SetItems(tDisponibilidade)
            oHora:Select(1)
            oHora:Refresh()
         endif
         return .t.
      endif
      return .f.
   endif
   return .t.
Function NomeDoDia(oDia,vDia,dData)
   vDia:= OemToAnsi(CDoW(dData))
   oDia:Refresh()
   SysRefresh()
   return .t.
			
Function Reservar(nIdReserva)
   Local oDataReserva,dDataReserva
   Local oHoraIni,vHoraIni,lSair:=.f.
   Local oHoraFim,vHoraFim,oDia,vDia,aDisponibilidade:={},tDisponibilidade:={}
   local oDlg, oFont1, oFont2, lOk := .F.,vHora:=""
   vDia:=""
   aDados:=Reservar_PegaDadosDeHoje(nIdReserva)
   *
   lStatus:=aDados[1]
   dDataInicio:=aDados[2]
   hHoraInicio:=aDados[3]
   *
   dDataReserva:=dDataInicio
   vHoraIni:=hHoraInicio
   vHoraFim:=hHoraInicio

   use &SIS_DB.RESERVAS alias reservasFiltro shared new
   if neterr()
      MsgAlert("Arquivo aberto em modo exclusivo!","Atenção")
      return .f.
   endif
   SET INDEX TO &SIS_DB.RESERVAS
   *
   use &SIS_DB.DISPOR alias disporFiltro shared new
   if neterr()
      MsgAlert("Arquivo aberto em modo exclusivo!","Atenção")
      return .f.
   endif
   SET INDEX TO &SIS_DB.DISPOR
   *
   SELECT reservasFiltro
   SET FILTER TO reservasFiltro->IDRESERVA == nIdReserva .AND. reservasFiltro->DTRESERV >= DATE()
   GO TOP
   *
   SELECT disporFiltro
   SET ORDER TO 2
   OrdScope(0,nIdReserva)
   OrdScope(1,nIdReserva)
   GO TOP
   
   SELECT disporFiltro
   GO TOP
   While !Eof()
      aadd(aDisponibilidade,{disporFiltro->DIA,{}})
      nRegistro:=len(aDisponibilidade)
      cHora:=disporFiltro->HRINI
      *
      While cHora <= disporFiltro->HRFIM
         tHora:=TString(Secs(cHora)+Secs(disporFiltro->LIMITE))
         if tHora > disporFiltro->HRFIM
            tHora := disporFiltro->HRFIM
         endif
         aadd(aDisponibilidade[nRegistro][2],cHora+"-"+tHora)
         cHora:=Secs(tHora)+1
         cHora:=TString(cHora)
      end
      skip
   End
   *
   
   SELECT disporFiltro
   GO TOP
   *
   if oFont1 == nil
      DEFINE FONT oFont1 NAME "Segoe UI Light" SIZE 0, -30 BOLD
   endif
   *
   DEFINE FONT oFont2 NAME "Segoe UI Light" SIZE 10,26 BOLD
   DEFINE FONT oFontbRW NAME "Segoe UI Light" SIZE 10,28 BOLD
   *
   DEFINE DIALOG oDlg STYLE nOr( WS_CHILD, WS_POPUP ) ;
    SIZE ScreenWidth(), (ScreenHeight() / 2) +100;
    COLOR CLR_WHITE, CLR_DIALOGS PIXEL
   *
   @ 20, 15  SAY "Por favor insira a data e hora que deseja reservar" FONT oFont1 TRANSPARENT PIXEL OF oDlg
   *
   @ 50, 45 SAY "Data para Reserva:" FONT oFont2 TRANSPARENT PIXEL OF oDlg
   @ 50, 130 Get oDataReserva VAR dDataReserva FONT oFont2 SIZE 60, 14 valid NomeDoDia(oDia,@vDia,dDataReserva) .and. IIF( LEN(aDisponibilidade) > 0 , PreencherDisponibilidade(vDia,@tDisponibilidade,aDisponibilidade,@vHora,@oHora),.T.) PICTURE "@D"  PIXEL CENTER UPDATE OF oDlg
   @ 50, 200 SAY oDia var vDia FONT oFont2 TRANSPARENT PIXEL SIZE 100, 14 OF oDlg
   *
   IF LEN(aDisponibilidade) > 0
      @ 65, 45 SAY "Hora:" FONT oFont2 TRANSPARENT PIXEL OF oDlg
      @ 65, 130 COMBOBOX oHora VAR vHora ITEMS tDisponibilidade FONT oFont2 SIZE 120, 14 COLOR "N*/W" PIXEL UPDATE OF oDlg
	
   ELSE
      @ 65, 45 SAY "Hora Inicial:" FONT oFont2 TRANSPARENT PIXEL OF oDlg
      @ 65, 130 GET oHoraIni var vHoraIni FONT oFont2 SIZE 60, 14 COLOR "N*/W" NOBORDER valid .t. PICTURE "99:99:99" PIXEL   CENTER UPDATE OF oDlg
      *
      @ 80, 45 SAY "Hora Final:" FONT oFont2 TRANSPARENT PIXEL OF oDlg
      @ 80, 130 GET oHoraFim var vHoraFim FONT oFont2 SIZE 60, 14 COLOR "N*/W" NOBORDER valid .t. PICTURE "99:99:99" PIXEL  CENTER UPDATE OF oDlg
   ENDIF
   *
   @ 200, ScreenWidth() / 5 + 100 FLATBTN PROMPT "Ok" ;
    SIZE 50, 20 ACTION ( lOk := .T., oDlg:End() ) FONT oFont2 PIXEL OF oDlg
   *
   @ 200, ScreenWidth() / 5 + 170 FLATBTN PROMPT "Cancel" ;
    SIZE 50, 20 ACTION (lOk:=.f.,oDlg:End()) FONT oFont2  cancel PIXEL  OF oDlg
   *
   IF LEN(aDisponibilidade)>0
      @ 095,45 SAY "Disponibilidade" FONT oFont2 TRANSPARENT PIXEL
      @ 110,45 XBROWSE oBrwDisponibilidade OF oDlg SIZE 235,100 PIXEL ;
       ALIAS 'disporFiltro' FIELDS DiaDaSemana(disporFiltro->DIA),disporFiltro->HRINI,disporFiltro->HRFIM,disporFiltro->LIMITE ;
       HEADERS "Dia","Hr.Inicial","Hr.Fim","Limite";
       COLORS CLR_WHITE, CLR_DIALOGS FONT oFontbRW
      *
      oBrwDisponibilidade:bClrHeader := {||{CLR_WHITE, CLR_DIALOGS}}
      oBrwDisponibilidade:nMarqueeStyle       := 4
      oBrwDisponibilidade:nColDividerStyle    := LINESTYLE_DARKGRAY
      oBrwDisponibilidade:nRowDividerStyle    := LINESTYLE_DARKGRAY
      oBrwDisponibilidade:lColDividerComplete := .T.
      oBrwDisponibilidade:lFastEdit           := .F.
      oBrwDisponibilidade:lHScroll            := .F.
      oBrwDisponibilidade:lVScroll            := .F.
      oBrwDisponibilidade:l2007               := .F.
      *
      oBrwDisponibilidade:CreateFromCode()
   ENDIF
   *
   @ 20, 400 SAY "Já reservado" FONT oFont1 TRANSPARENT PIXEL
   if temSenha
      @ 50,400 XBROWSE oBrw OF oDlg SIZE 340,100 PIXEL ;
       ALIAS 'reservasFiltro' FIELDS reservasFiltro->DTRESERV,reservasFiltro->HRINI,reservasFiltro->HRFIM,NomeDoAluno(reservasFiltro->idAluno) ;
       FIELDSIZES 100,100,100,330 ;
       HEADERS "Data","Hr.Inicial","Hr.Final","Nome";
       COLORS CLR_WHITE, CLR_DIALOGS FONT oFontbRW ;
       ON RIGHT CLICK Reservar_PopupMenu(oBrw,nRow,nCol)
      *
      oBrw:bClrHeader := {||{CLR_WHITE, CLR_DIALOGS}}
      oBrw:nMarqueeStyle       := 4
      oBrw:nColDividerStyle    := LINESTYLE_DARKGRAY
      oBrw:nRowDividerStyle    := LINESTYLE_DARKGRAY
      oBrw:lColDividerComplete := .T.
      oBrw:lFastEdit           := .F.
      oBrw:lHScroll            := .F.
      oBrw:lVScroll            := .F.
      oBrw:l2007               := .F.
      *
      oBrw:CreateFromCode()
   else
      @ 50,400 XBROWSE oBrw OF oDlg SIZE 170,100 PIXEL ;
       ALIAS 'reservasFiltro' FIELDS reservasFiltro->DTRESERV,reservasFiltro->HRINI,reservasFiltro->HRFIM ;
       HEADERS "Data","Hr.Inicial","Hr.Final";
       COLORS CLR_WHITE, CLR_DIALOGS FONT oFontbRW
      *
      oBrw:bClrHeader := {||{CLR_WHITE, CLR_DIALOGS}}
      oBrw:nMarqueeStyle       := 4
      oBrw:nColDividerStyle    := LINESTYLE_DARKGRAY
      oBrw:nRowDividerStyle    := LINESTYLE_DARKGRAY
      oBrw:lColDividerComplete := .T.
      oBrw:lFastEdit           := .F.
      oBrw:lHScroll            := .F.
      oBrw:lVScroll            := .F.
      oBrw:l2007               := .F.
      *
      oBrw:CreateFromCode()
   endif
   ACTIVATE DIALOG oDlg CENTERED valid Reservar_Valid(@lOk,nIdReserva,dDataReserva,@vHoraIni,@vHoraFim,@vHora,oDlg)
   
   if lOk
      select reservas
      set order to 1
      go bottom
      nIdReservaNovo:= reservas->id + 1
      select reservas
      append blank
      if RLOCK()
         replace id with nIdReservaNovo
         replace dtreserv with dDataReserva
         replace hrini with vhoraini
         replace hrfim with vhorafim
         replace idreserva with nIdReserva
         replace idaluno with IdUsuario
         commit
         unlock
      endif
      if !TemSenha
         MsgWait("A sessão será encerrada!")
         __quit()
		endif
   endif
   for nBotao:=1 to len(aBotoes)
      try
         select reserva
         set order to 1
         seek aBotoes[nBotao]:Cargo
         aBotoes[nBotao]:cText:= strtran(Reserva_Status(),";",CRLF)
         aBotoes[nBotao]:Refresh()
      catch
      end
   next
   close reservasFiltro
   close disporFiltro
   RETURN lOk
Function Reservar_PopupMenu(oBrw,nRow,nCol)
   Local oMenu
   MENU oMenu POPUP 2013
   MENUITEM "Remover reserva" ACTION iif( MsgYesNo("Deseja realmente remover?","Pergunta"),oBrw:Delete(),.t. ) When !oBrw:Eof()
   ENDMENU
   ACTIVATE MENU oMenu OF oBrw  AT nRow,nCol
Function Reservar_Valid(lOk,nIdReserva,dDataReserva,hHoraIni,hHoraFim,hHora,oDlg)
   Local lReturn:=.t.
   Default hHora:=""
   if !lOk
      return .t.
   endif
   if !Empty(hHora)
      hHoraIni := StrToken(hHora,1,"-")
      hHoraFim := StrToken(hHora,2,"-")
   endif
	
   if hHoraIni > hHoraFim
      MsgAlert("Hora inicial maior que hora final!","Atenção")
      oDlg:Update()
      oDlg:Refresh()
      return .f.
   endif

   if hHoraIni == hHoraFim
      MsgAlert("Hora inicial igual a hora final, não forma período!","Atenção")
      oDlg:Update()
      oDlg:Refresh()
      return .f.
   endif
   *
   if dDataReserva == date()
      if Secs(hHoraIni) < Secs(time())
         MsgAlert("Hora inicial menor que hora atual!","Atenção")
         lOk:=.f.
         oDlg:Update()
         oDlg:Refresh()
         return .f.
      endif
      *
      if Secs(hHoraFim) < Secs(time())
         MsgAlert("Hora Final menor que hora atual!","Atenção")
         lOk:=.f.
         oDlg:Update()
         oDlg:Refresh()
         return .f.
      endif
   endif
   *
   if dDataReserva < date()
      MsgAlert("Data da reserva não pode ser menor que a data atual!","Atenção")
      lOk:=.f.
      oDlg:Update()
      oDlg:Refresh()
      return .f.
   endif
   *
   select reservas
   set order to 4
   GO TOP
   seek dtos(dDataReserva)
   While !reservas->(Eof())
      if reservas->IDRESERVA == nIdReserva
         if reservas->dtreserv == dDataReserva
            *
            if reservas->hrfim >= hhorafim .and. reservas->hrini <= hhoraini
               MsgAlert("Horário da reserva não está disponível!","Atenção-1")
               lOk:=.f.
               lReturn:=.f.
               exit
            endif
            *
            if reservas->hrini <= hhoraini
               if reservas->hrfim >= hhoraini
                  MsgAlert("Horário da reserva não está disponível!","Atenção-2")
                  lOk:=.f.
                  lReturn:=.f.
                  exit
               endif
            endif
            *
            if reservas->hrfim <= hhorafim .and. reservas->hrini >= hhoraini
               MsgAlert("Horário da reserva não está disponível!","Atenção-3")
               lOk:=.f.
               lReturn:=.f.
               exit
            endif
            *
         endif
      endif
      select reservas
      skip
   End
   *
   if lReturn
      aDia := CarregarDias()
      nDia := Ascan(aDia,CDoW(dDataReserva))
      lExiste:=.F.
      lHorario:=.f.
      if nDia > 0 .AND. !disporFiltro->(EOF())
         select disporFiltro
         set order to 2
         seek nIdReserva
         While !Eof() .and. dispor->idreserva == nIdReserva
            if disporFiltro->dia == nDia
               lExiste:=.t.
               if !Empty(disporFiltro->limite)
                  if ALLTRIM(ElapTime(hhoraini,hhorafim)) > ALLTRIM(disporFiltro->limite)
                     MsgAlert("Limite excedido!","Atenção")
                     lOk:=.f.
                     lReturn:=.f.
                     exit
                  endif
               endif
               if V->hrini <= hhoraini .and. hhorafim <= disporFiltro->hrfim
                  lHorario:=.t.
                  exit
               endif
            endif
            select dispor
            skip
         End
         if lReturn
            if !lExiste
               MsgAlert("Não existe dia disponivel!","Atenção")
               lOk:=.f.
               lReturn:=.f.
            endif
         endif
         if lReturn
            if !lHorario
               MsgAlert("Horário não está disponível!","Atenção")
               lOk:=.f.
               lReturn:=.f.
            endif
         endif
      EndIf
   End
   oDlg:Update()
   oDlg:Refresh()
   return lReturn
Function Reservar_PegaDadosDeHoje(nId)
   lStatus:=.t.
   dDataReserv:=date()
   cHoraFim:=time()
   *
   SET SOFTSEEK ON
   SELECT RESERVAS
   SET ORDER TO 4
   SEEK DTOS(DATE())
   While !Eof()
      if RESERVAS->IDRESERVA == nId
         IF RESERVAS->DTRESERV == DATE()
            IF RESERVAS->HRFIM > TIME()
               lStatus:=.f.
               cStatusData:=date()
               cStatusHora:=RESERVAS->HRFIM
               EXIT
            ENDIF
         ENDIF
         *
      ENDIF
      SELECT RESERVAS
      SKIP
      *
   End
   SET SOFTSEEK OFF
   return {lStatus,dDataReserv,cHoraFim}


Function Reserva_Status()
   * Trazer status atual da reserva
   Local cNomeReserva:=""
   Local cStatus:="Livre"
   Local cStatusData:="Sem reservas"
   Local cStatusHora:=""
   cNomeReserva:=alltrim(reserva->nome)
   
   SET SOFTSEEK ON
   SELECT RESERVAS
   SET ORDER TO 4
   GO TOP
   SEEK DTOS(DATE())
   SET SOFTSEEK OFF
   While !Eof()
      if RESERVAS->IDRESERVA == reserva->id
         IF RESERVAS->DTRESERV == DATE()
            IF RESERVAS->HRFIM > TIME()
               cStatus:="Ocupado(a)"
               cStatusData:="Até hoje"
               cStatusHora:="as "+RESERVAS->HRFIM
               exit
            ENDIF
         ENDIF
         *
         IF RESERVAS->DTRESERV > DATE()
            cStatus:="Livre"
            cStatusData:="Até "+DtoC(RESERVAS->DTRESERV)
            cStatusHora:="as "+RESERVAS->HRINI
            exit
         ENDIF
      ENDIF
      SELECT RESERVAS
      SKIP
      *
   End
   
   
   return cNomeReserva+";"+cStatus+";"+cStatusData+";"+cStatusHora
function ManterDisponibilidade(nIDReserva)

   local oDlg, oBar, oFont, oSegoe, oBrw
   IF Valtype(nIDReserva) # "N"
      MsgStop("Ocorreu uma inconsistencia contate o desenvolvedor! nIDReserva não é númerico!","Problema")
      RETURN
   ENDIF
   IF nIDReserva <= 0
      MsgStop("Não há reserva selecionada!","Problema")
      RETURN
   ENDIF
   *
   SELECT DISPOR
   SET ORDER TO 2
   OrdScope(0,nIdReserva)
   OrdScope(1,nIdReserva)
   GO TOP
   *
   DEFINE FONT oFont  NAME "ARIAL"     SIZE 0,-12 BOLD
   DEFINE FONT oSegoe NAME "Segoe UI"  SIZE 0,-14

   DEFINE DIALOG oDlg SIZE 600,400 PIXEL TRUEPIXEL FONT oFont ;
    TITLE "Disponibilidade da Reserva nº "+str(nIDReserva,20,0,.t.)

   DEFINE BUTTONBAR oBar OF oDlg SIZE 64,80 2007 NOBORDER 2010 3DLOOK

   DEFINE BUTTON OF oBar PROMPT "Adicionar" RESOURCE "NEW" ACTION ManterDisponibilidade_Incluir(oBrw,nIDReserva)
   DEFINE BUTTON OF oBar PROMPT "Editar"    RESOURCE "EDIT" ACTION ManterDisponibilidade_Alterar(oBrw,nIDReserva)
   DEFINE BUTTON OF oBar PROMPT "Remover"  RESOURCE "DELETE" ACTION ManterDisponibilidade_Excluir(oBrw,nIDReserva)
   DEFINE BUTTON OF oBar PROMPT "Retornar"    RESOURCE "RETURN"  GROUP ACTION oDlg:End()
   SELECT DISPOR
   @ 0,0 XBROWSE oBrw OF oDlg ALIAS "DISPOR" ;
    FIELDS DISPOR->ID,DiaDaSemana(DISPOR->DIA),DISPOR->HRINI,DISPOR->HRFIM,DISPOR->LIMITE;
    HEADERS "Id","Dia","Hr.Ini","Hr.Fim","Limite";
    FIELDSIZES 100,120,100,100,100;
    FONT oSegoe
    
   oBrw:nMarqueeStyle       := MARQSTYLE_HIGHLROW
   oBrw:nColDividerStyle    := LINESTYLE_BLACK
   oBrw:nRowDividerStyle    := LINESTYLE_BLACK
   oBrw:lColDividerComplete := .T.
   oBrw:lFastEdit           := .F.
   oBrw:lAllowColSwapping   := .F.
   oBrw:bClrSelFocus = { || { 0, 16777215 } }

   oBrw:CreateFromCode()
   oDlg:oClient := oBrw

   ACTIVATE DIALOG oDlg CENTERED ON INIT oDlg:Resize()
   RELEASE FONT oFont, oSegoe
Function DiaDaSemana(uDia)
   Local nDia := val(cvaltochar(uDia))
   if nDia > 0 .and. nDia < 8
      Return CarregarDias()[nDia]
   else
      return ""
   endif
Function CarregarDias()
   Local aDia:={}
   aadd(aDia,"Segunda-feira")
   aadd(aDia,"Terça-feira")
   aadd(aDia,"Quarta-feira")
   aadd(aDia,"Quinta-feira")
   aadd(aDia,"Sexta-feira")
   aadd(aDia,"Sábado")
   aadd(aDia,"Domingo")
   return aDia

Function PegaNrDia(cDia)
   Local aDia:=CarregarDias()
   return Ascan(aDia,{|Item| item == cDia })

Function ManterDisponibilidade_Excluir(oBrw,nIDReserva)
   if MsgYesNo("Ao excluir a disponibilidade as reservas podem sofrer alterações!"+CRLF+"Deseja realmente excluir?","Pergunta")
      oBrw:Delete()
   endif
		
Function ManterDisponibilidade_Incluir(oBrw,nIDReserva)
   Local nId:=0,cDia,cHrIni,cHrFim,cLimite,aDia,lMudou := .f.,nDia
   *
   aDia:=CarregarDias()
   *
   cDia   := aDia[1]
   cHrIni := space(len(dispor->hrini))
   cHrFim := space(len(dispor->hrfim))
   cLimite:= space(len(dispor->limite))
   *
   While .t.
      lMudou := .f.
      *
      lMudou := EDITVARS cDia,cHrIni,cHrFim,cLimite;
       PROMPTS "Dia","Hora Inicial","Horar Final","Limite";
       PICTURES aDia,"99:99:99","99:99:99","99:99:99";
       VALIDS {|| !Empty(cDia) },;
       {|oGet| ManterDisponibilidade_ValidarHora_Inicial(oGet,@cHrIni) },;
       {|oGet| ManterDisponibilidade_ValidarHora_Final(oGet,@cHrIni,@cHrFim) },;
       {|oGet| ManterDisponibilidade_ValidarHora_Limite(oGet,@cLimite) } ;
       TITLE "Incluir"
      *
      if lMudou
         *
         nDia := Ascan(aDia,cDia)
         if ManterDisponibilidade_ValidarDisponibilidade(nID,nIDReserva,nDia,cHrIni,cHrFim)
            select DISPOR
            go bottom
            nId := DISPOR->id + 1
            select DISPOR
            append blank
            if rlock()
               replace id with nId
               replace idreserva with nIDReserva
               replace dia with nDia
               replace hrini with cHrIni
               replace hrfim with cHrFim
               replace limite with cLimite
               commit
               unlock
            endif
         else
            loop
         endif
      endif
      exit
   end
   *
   select dispor
   go bottom

   oBrw:Refresh()
   

Function ManterDisponibilidade_ValidarDisponibilidade(nID,nIDReserva,nDia,cHrIni,cHrFim)
   Local lReturn:=.t.
   if select('disponibilidade') = 0
      USE &SIS_DB.DISPOR ALIAS DISPONIBILIDADE SHARED NEW
      IF NetErr()
         MsgAlert("Arquivo aberto em modo exclusivo! - Disponibilidade","Alerta")
         *CLOSE DATA
         RETURN .F.
      ENDIF
      SET INDEX TO &SIS_DB.DISPOR
   endif
			
   select disponibilidade
   set order to 2
   seek nIDReserva
   While !eof() .and. nIDReserva == disponibilidade->idreserva
      if nID == 0 .or. nID # disponibilidade->id // não existe ainda
         if nDia == disponibilidade->dia
            // FWDBG disponibilidade->hrfim,cHrFim,disponibilidade->hrini,cHrIni
            if disponibilidade->hrfim >= cHrFim .and. disponibilidade->hrini <= cHrIni
               MsgAlert("Horário não está disponível!","Atenção-1")
               lReturn:=.f.
               exit
            endif
            *
            if disponibilidade->hrfim >= cHrFim .and. disponibilidade->hrini >= cHrIni
               MsgAlert("Horário não está disponível!","Atenção-2")
               lReturn:=.f.
               exit
            endif
            *
            if disponibilidade->hrini <= cHrIni
               if disponibilidade->hrfim >= cHrIni
                  MsgAlert("Horário não está disponível!","Atenção-3")
                  lReturn:=.f.
                  exit
               endif
            endif
            if disponibilidade->hrfim <= cHrFim .and. disponibilidade->hrini >= cHrIni
               MsgAlert("Horário não está disponível!","Atenção-4")
               lReturn:=.f.
               exit
            endif
			            
         endif
      endif
      select disponibilidade
      skip
   end
   *
   CLOSE DISPONIBILIDADE
   return lReturn

Function ManterDisponibilidade_ValidarHora_Inicial(oGet,cHrIni)
   if !Empty(StrTran(cHrIni,":"))
      if left(cHrIni,2) < "00" .and. left(cHrIni,2) > "24"
         MsgAlert("Hora inicial não corresponde a uma hora válida (entre 00hrs e 24hrs)","Atenção")
         cHrIni:=space(len(dispor->hrini))
         oGet:Refresh()
         return .f.
      endif
   else
      return .f.
   endif
   RETURN .t.
Function ManterDisponibilidade_ValidarHora_Final(oGet,cHrIni,cHrFim)
		   
   if !Empty(StrTran(cHrFim,":"))
      if cHrFim < cHrIni
         MsgAlert("Hora final não pode ser menor que hora inicial","Atenção")
         cHrFim:=space(len(dispor->hrfim))
         oGet:Refresh()
         return .f.
      endif
      if cHrFim == cHrIni
         MsgAlert("Hora final não pode ser igual hora inicial","Atenção")
         cHrFim:=space(len(dispor->hrfim))
         oGet:Refresh()
         return .f.
      endif
      if left(cHrFim,2) < "00" .or. left(cHrFim,2) > "24"
         MsgAlert("Hora final não corresponde a uma hora válida (entre 00hrs e 24hrs)","Atenção")
         cHrFim:=space(len(dispor->hrfim))
         oGet:Refresh()
         return .f.
      endif
   else
      return .f.
   endif
   RETURN .t.
		
   RETURN .T.
Function ManterDisponibilidade_ValidarHora_Limite(oGet,cLimite)
		
   if !Empty(StrTran(cLimite,":"))
      if left(cLimite,2) > "24" .or. cLimite > "23:59:59"
         MsgAlert("Hora limite não pode exceder um dia (24 horas)","Atenção")
         cLimite:=space(len(dispor->limite))
         oGet:Refresh()
         return .f.
      endif
   endif
   RETURN .T.
Function ManterDisponibilidade_Alterar(oBrw,nIDReserva)
   Local nId:=0,cDia,cHrIni,cHrFim,cLimite,aDia,lMudou := .f.,nDia
   *
   aDia:=CarregarDias()
   *
   nId    := dispor->id
   nDia := Ascan(aDia,dispor->dia)
   if nDia > 0
      cDia   := aDia[nDia]
   else
      cDia   := aDia[1]
   endif
   cHrIni := dispor->hrini
   cHrFim := dispor->hrfim
   cLimite:= dispor->limite
   *
   lMudou := EDITVARS cDia,cHrIni,cHrFim,cLimite;
    PROMPTS "Dia","Hr Inicial","Hr Final","Limite";
    PICTURES aDia,"99:99:99","99:99:99","99:99:99";
    VALIDS {|| !Empty(cDia) }, {|| !Empty(cHrIni) }, {|| !Empty(cHrFim) },nil TITLE "Alterar"
   if lMudou
      nDia := Ascan(aDia,cDia)
      select DISPOR
      set order to 1
      seek nId
      if rlock()
         *replace id with nId
         *replace idreserva with nIDReserva
         replace dia with nDia
         replace hrini with cHrIni
         replace hrfim with cHrFim
         replace limite with cLimite
         commit
         unlock
      endif
   endif
   *
   oBrw:Refresh()
function ManterPessoa

   local oDlg, oBar, oFont, oSegoe, oBrw

   DEFINE FONT oFont  NAME "ARIAL"     SIZE 0,-12 BOLD
   DEFINE FONT oSegoe NAME "Segoe UI"  SIZE 0,-14

   DEFINE DIALOG oDlg SIZE 600,400 PIXEL TRUEPIXEL FONT oFont ;
    TITLE "Manter Pessoa"

   DEFINE BUTTONBAR oBar OF oDlg SIZE 64,80 2007 NOBORDER 2010 3DLOOK

   DEFINE BUTTON OF oBar PROMPT "Adicionar" RESOURCE "NEW" ACTION ManterPessoa_Incluir(oBrw)
   DEFINE BUTTON OF oBar PROMPT "Editar"    RESOURCE "EDIT" ACTION ManterPessoa_Alterar(oBrw)
   DEFINE BUTTON OF oBar PROMPT "Remover"  RESOURCE "DELETE" ACTION ManterPessoa_Excluir(oBrw)
   DEFINE BUTTON OF oBar PROMPT "Retornar"    RESOURCE "RETURN"  GROUP ACTION oDlg:End()
   SELECT PESSOA
   @ 0,0 XBROWSE oBrw OF oDlg DATASOURCE Alias() ;
    COLUMNS "Id", "Nome","Matricula";
    FONT oSegoe ;
    FOOTERS NOBORDER CELL LINES

   oBrw:CreateFromCode()
   oDlg:oClient := oBrw

   ACTIVATE DIALOG oDlg CENTERED ON INIT oDlg:Resize()
   RELEASE FONT oFont, oSegoe

function ManterGrupo

   local oDlg, oBar, oFont, oSegoe, oBrw

   DEFINE FONT oFont  NAME "ARIAL"     SIZE 0,-12 BOLD
   DEFINE FONT oSegoe NAME "Segoe UI"  SIZE 0,-14

   DEFINE DIALOG oDlg SIZE 600,400 PIXEL TRUEPIXEL FONT oFont ;
    TITLE "Manter Grupo"

   DEFINE BUTTONBAR oBar OF oDlg SIZE 64,80 2007 NOBORDER 2010 3DLOOK

   DEFINE BUTTON OF oBar PROMPT "Adicionar" RESOURCE "NEW" ACTION ManterGrupo_Incluir(oBrw)
   DEFINE BUTTON OF oBar PROMPT "Editar"    RESOURCE "EDIT" ACTION ManterGrupo_Alterar(oBrw)
   DEFINE BUTTON OF oBar PROMPT "Remover"  RESOURCE "DELETE" ACTION ManterGrupo_Excluir(oBrw)
   DEFINE BUTTON OF oBar PROMPT "Retornar"    RESOURCE "RETURN"  GROUP ACTION oDlg:End()
   SELECT GRUPO
   @ 0,0 XBROWSE oBrw OF oDlg DATASOURCE Alias() ;
    COLUMNS "Id", "Nome";
    FONT oSegoe ;
    FOOTERS NOBORDER CELL LINES

   oBrw:CreateFromCode()
   oDlg:oClient := oBrw

   ACTIVATE DIALOG oDlg CENTERED ON INIT oDlg:Resize()
   RELEASE FONT oFont, oSegoe

function ManterGrupo_Incluir(oBrw)
   Local nId:=0,cNome,lMudou := .f.
   *
   cNome:=space(len(grupo->nome))
   *
   lMudou := EDITVARS cNome;
    PROMPTS "Nome";
    PICTURES "@!";
    VALIDS {|| !Empty(cNome) } TITLE "Incluir"
   if lMudou
      select grupo
      go bottom
      nId := grupo->id + 1
      select grupo
      append blank
      if rlock()
         replace id with nId
         replace nome with cNome
         commit
         unlock
      endif
   endif
   *
   select grupo
   go bottom

   oBrw:Refresh()
function ManterGrupo_Alterar(oBrw)
   
   Local nId:=0,cNome,lMudou := .f.
   *
   nId:=grupo->id
   cNome:=grupo->nome
   
   lMudou := EDITVARS cNome;
    PROMPTS "Nome";
    PICTURES "@!";
    VALIDS {|| !Empty(cNome) } TITLE "Alterar"
   if lMudou
      select grupo
      set order to 1
      seek nId
      if rlock()
         replace nome with cNome
         commit
         unlock
      endif
   endif
   *
   oBrw:Refresh()

function ManterGrupo_Excluir(oBrw)
select reserva_grupo
set order to 2
seek grupo->id
if !eof()
	MsgAlert("Existe reservas para essa grupo, não é possivel excluir!","Atenção")
else
	oBrw:Delete()
endif
function ManterPessoa_Incluir(oBrw)
   Local nId:=0,lMudou:=.f.,cNome,cMatricula,cSenha
   *
   cNome     :=space(len(pessoa->nome))
   cMatricula:=space(len(pessoa->matricula))
   cSenha    :=space(len(pessoa->senha))
   *
   lMudou := EDITVARS cNome,cMatricula,cSenha;
    PROMPTS "Nome","Matrícula","Senha";
    PICTURES "@!", "@!", "@!";
    VALIDS {|| !Empty(cNome) }, {|| !Empty(cMatricula) }, nil TITLE "Incluir"
   *
   if lMudou
      select PESSOA
      go bottom
      nId := PESSOA->id + 1
      select PESSOA
      append blank
      if rlock()
         replace id with nId
         replace nome with cNome
         replace matricula with cMatricula
         replace senha with cSenha
         commit
         unlock
      endif
	
   endif
   select pessoa
   go bottom
   oBrw:Refresh()
function ManterPessoa_Excluir(oBrw)
   select reservas
   set order to 3
   seek pessoa->id
   if !eof()
      MsgAlert("Existe reservas para essa pessoa, não é possivel excluir!","Atenção")
   else
      if MsgYesNo("Deseja realmente excluir?","Pergunta")
         oBrw:Delete()
      endif
   endif
function ManterPessoa_Alterar(oBrw)
   Local nId:=0,lMudou:=.f.,cNome,cMatricula,cSenha
   *
   nId:=pessoa->id
   cNome     :=pessoa->nome
   cMatricula:=pessoa->matricula
   cSenha    :=pessoa->senha
   *
   lMudou := EDITVARS cNome,cMatricula,cSenha;
    PROMPTS "Nome","Matrícula","Senha";
    PICTURES "@!", "@!", "@!";
    VALIDS {|| !Empty(cNome) }, {|| !Empty(cMatricula) }, nil TITLE "Alterar"
   *
   if lMudou
      select PESSOA
      set order to 1
      seek nId
      select PESSOA
      if rlock()
         replace nome with cNome
         replace matricula with cMatricula
         replace senha with cSenha
         commit
         unlock
      endif
   endif
   oBrw:Refresh()

function ManterReserva

   local oDlg, oBar, oFont, oSegoe, oBrw

   DEFINE FONT oFont  NAME "ARIAL"     SIZE 0,-12 BOLD
   DEFINE FONT oSegoe NAME "Segoe UI"  SIZE 0,-14

   DEFINE DIALOG oDlg SIZE 700,400 PIXEL TRUEPIXEL FONT oFont ;
    TITLE "Manter Reserva"

   DEFINE BUTTONBAR oBar OF oDlg SIZE 100,80 2007 NOBORDER 2010 3DLOOK

   DEFINE BUTTON OF oBar PROMPT "Adicionar" RESOURCE "NEW" ACTION ManterReserva_Incluir(oBrw)
   DEFINE BUTTON OF oBar PROMPT "Criar Varios" RESOURCE "NEW" ACTION MsgRun("Aguarde um momento...","Criando reservas",{|| ManterReserva_CriarVarios(oBrw)})
   DEFINE BUTTON OF oBar PROMPT "Editar"    RESOURCE "EDIT" ACTION ManterReserva_Alterar(oBrw)
   DEFINE BUTTON OF oBar PROMPT "Disponibilidade" RESOURCE "EDIT" ACTION ManterDisponibilidade(reserva->id)
   DEFINE BUTTON OF oBar PROMPT "Grupo" RESOURCE "EDIT" ACTION ManterReserva_Grupo()
   DEFINE BUTTON OF oBar PROMPT "Remover"  RESOURCE "DELETE" ACTION ManterReserva_Excluir(oBrw)
   DEFINE BUTTON OF oBar PROMPT "Retornar"    RESOURCE "RETURN"  GROUP ACTION oDlg:End()
   *
   SELECT RESERVA
   go top
   @ 0,0 XBROWSE oBrw OF oDlg DATASOURCE Alias() ;
    COLUMNS "Id", "Nome";
    FONT oSegoe ;
    FOOTERS NOBORDER CELL LINES

   oBrw:CreateFromCode()
   oDlg:oClient := oBrw
																		 
   ACTIVATE DIALOG oDlg CENTERED ON INIT oDlg:Resize()
   RELEASE FONT oFont, oSegoe
Function ManterReserva_Grupo_Meter(nReservaInicial,nReservaFinal,nGrupo,oMeter,oText,oDlg,lEnd)
			nTotal:=nReservaFinal-nReservaInicial
			nTotal:=iif(nTotal==0,1,nTotal)
			oMeter:SetTotal( nReservaFinal-nReservaInicial )
			nContador:=1
			for nInicial := nReservaInicial to nReservaFinal
		       select reserva
		       set order to 1
		       seek nInicial
		       if !eof()
					 select reserva_grupo
			       set order to 1
			       seek nInicial
		       	 select reserva_grupo
					 if eof()
			       	 append blank
			       endif
					 if rlock()
		  		    	 replace id_reserva with nInicial
				     	 replace id_grupo   with nGrupo
				     	 commit
				     	 unlock
					 endif
				 endif
				 oMeter:Set(nContador++)
			next

Function ManterReserva_Grupo()
			Local nReservaInicial:=0,nReservaFinal:=0
			Local nGrupo:=0,aGrupos:={},lConfirmar:=.f.
			
			
			select grupo
			set order to 1
			go top
			*
			aGrupos := FW_DbfToArray()
			
			lConfirmar:=EDITVARS nReservaInicial,nReservaFinal,nGrupo;
	 			PROMPTS "De","Até","Grupo";
	 			PICTURES "99999999999","99999999999",aGrupos;
	 			TITLE "Os dados informados substituiram qualquer configuração existente"
	 	
		   if lConfirmar
		      MsgMeter({|oMeter,oText,oDlg,lEnd|ManterReserva_Grupo_Meter(nReservaInicial,nReservaFinal,nGrupo,oMeter,oText,oDlg,lEnd)},"Criando vinculos...","Aguarde um momento")
			endif


			
Function ManterReserva_CriarVarios(oBrw)
   Local nReservas:=1
   if MsgGet("Informe o nº de reservas em lote","Número",@nReservas)
      if nReservas > 0
         for nItem := 1 to nReservas
            select reserva
            go bottom
            nId := reserva->id + 1
            select reserva
            append blank
            if rlock()
               replace id with nId
               replace nome with "Reserva "+ str(nId,20,0,.t.)
               commit
               unlock
            endif
         next
         *
      endif
   endif
   select reserva
   go top

   oBrw:Refresh()
				
function ManterReserva_Incluir(oBrw)
   Local nId:=0,cNome,lMudou := .f.
   *
   cNome:=space(len(reserva->nome))
   
   lMudou := EDITVARS cNome;
    PROMPTS "Nome";
    PICTURES "@!";
    VALIDS {|| !Empty(cNome) } TITLE "Incluir"
   if lMudou
      select reserva
      go bottom
      nId := reserva->id + 1
      select reserva
      append blank
      if rlock()
         replace id with nId
         replace nome with cNome
         commit
         unlock
      endif
   endif
   *
   select reserva
   go bottom

   oBrw:Refresh()
   

			
function ManterReserva_Excluir(oBrw)
   Local lExcluir:=.f.
	select reservas
   set order to 2
   seek reserva->id
   if !eof()
      MsgAlert("Existe reservas realizadas para esse cadastro, não é possível excluir!","Atenção")
      return
   else
   	lExcluir:=.t.
	endif
   if lExcluir
	   if MsgYesNo("Deseja realmente excluir?","Pergunta")
         select reserva_grupo
         set order to 1
         seek reserva->id
         if !eof()
            if rlock()
            	DbDelete()
            endif	
			endif
	      *
   	   select dispor
         set order to 2
         seek reserva->id
         while !eof() .and. dispor->idreserva == reserva->id
            if rlock()
            	DbDelete()
            endif	
            select dispor
            skip
			end
			*
			select reservas
			oBrw:Delete()
         DbCommitAll()
         DbUnlockAll()
		endif
   endif
function ManterReserva_Alterar(oBrw)
   
   Local nId:=0,cNome,lMudou := .f.
   *
   nId:=reserva->id
   cNome:=reserva->nome
   
   lMudou := EDITVARS cNome;
    PROMPTS "Nome";
    PICTURES "@!";
    VALIDS {|| !Empty(cNome) } TITLE "Alterar"
   if lMudou
      select reserva
      set order to 1
      seek nId
      if rlock()
         replace nome with cNome
         commit
         unlock
      endif
   endif
   *
   oBrw:Refresh()


   
function Login()

   local oDlg, oFont1, oFont2, lOk := .F.
   local cUserName := Space( 100 ), cPassword := Space( 100 )

   if oFont1 == nil
      DEFINE FONT oFont1 NAME "Segoe UI Light" SIZE 0, -30 BOLD
   endif

   DEFINE FONT oFont2 NAME "Segoe UI Light" SIZE 10,30 BOLD

   DEFINE DIALOG oDlg STYLE nOr( WS_CHILD, WS_POPUP ) ;
    SIZE ScreenWidth(), ScreenHeight() / 2 ;
    COLOR CLR_WHITE, CLR_DIALOGS

   @ 1.2, 25 SAY "Por favor insira suas credenciais" FONT oFont1 TRANSPARENT

   @ 4, 29 SAY "Matrícula:" FONT oFont2 TRANSPARENT

   @ 4.7, 29 GET cUserName FONT oFont2 SIZE 200, 14 COLOR "N*/W" NOBORDER valid Login_Matricula(cUserName)   PICTURE "@!"

   @ 5.8, 29 SAY "Senha:" FONT oFont2 TRANSPARENT

   @ 6.7, 29 GET cPassword FONT oFont2 SIZE 200, 14 COLOR "N*/W" NOBORDER PASSWORD valid Login_Senha(cUserName,cPassword)    PICTURE "@!"

   @ 150, ScreenWidth() / 5 + 100 FLATBTN PROMPT "Ok" ;
    SIZE 50, 20 ACTION ( lOk := .T., oDlg:End() ) FONT oFont2

   @ 150, ScreenWidth() / 5 + 170 FLATBTN PROMPT "Cancel" ;
    SIZE 50, 20 ACTION oDlg:End() FONT oFont2  cancel

   ACTIVATE DIALOG oDlg CENTERED ON INIT BringWindowToTop( oDlg:hWnd ) VALID (IiF(lOk,Login_Senha(cUserName,cPassword),.T.))
   
   RETURN lOk
Function Login_Matricula(cUserName)
   IF Select('pessoa') = 0
      USE &SIS_DB.PESSOA SHARED NEW
      IF NetErr()
         MsgAlert("Arquivo aberto em modo exclusivo!")
         CLOSE DATA
         RETURN .F.
      ENDIF
      SET INDEX TO &SIS_DB.PESSOA
   ENDIF
   select pessoa
   set order to 2
   seek cUserName
   if eof()
      MsgInfo("Matrícula não encontrada!","Informação")
      return .f.
   endif
   IdUsuario:=pessoa->id
   return .t.
			
			
Function Login_Senha(cUserName,cPassword)
   IF Select('pessoa') = 0
      USE &SIS_DB.PESSOA SHARED NEW
      IF NetErr()
         MsgAlert("Arquivo aberto em modo exclusivo!")
         CLOSE DATA
         RETURN .F.
      ENDIF
      SET INDEX TO &SIS_DB.PESSOA
   ENDIF
   select pessoa
   set order to 2
   seek cUserName
   if eof()
      MsgInfo("Matrícula não encontrada!","Informação")
      return .f.
   else
      if !Empty(pessoa->senha)
         if Empty(cPassword)
            MsgInfo("Senha incorreta!","Informação")
            return .F.
         else
            if ALLTRIM(pessoa->senha) # ALLTRIM(cPassword)
               MsgInfo("Senha incorreta!","Informação")
               return .F.
            endif
         endif
      endif
   endif
   IdUsuario:=pessoa->id
   return .t.
			
			



function RandomColor(nExceto)
	Local aColor:={}
	Local numRandom:=0
	Default nExceto:=NIL
	aadd(aColor,CLR_GRAY      )      
	aadd(aColor,CLR_HBLUE     )
	aadd(aColor,CLR_HGREEN    )    
	aadd(aColor,CLR_HCYAN     )
	aadd(aColor,CLR_HRED      )
	aadd(aColor,CLR_HMAGENTA  )
	aadd(aColor,CLR_YELLOW    )
	aadd(aColor,CLR_WHITE     )
	aadd(aColor,METRO_LIME    )
	aadd(aColor,METRO_GREEN   )
	aadd(aColor,METRO_EMERALD )
	aadd(aColor,METRO_TEAL    )
	aadd(aColor,METRO_CYAN    )
	aadd(aColor,METRO_COBALT  )
	aadd(aColor,METRO_INDIGO  )
	aadd(aColor,METRO_VIOLET  )
	aadd(aColor,METRO_PINK    )
	aadd(aColor,METRO_MAGENTA )
	aadd(aColor,METRO_CRIMSON )
	aadd(aColor,METRO_RED     )
	aadd(aColor,METRO_ORANGE  )
	aadd(aColor,METRO_AMBER   )
	aadd(aColor,METRO_YELLOW  )
	aadd(aColor,METRO_BROWN   )
	aadd(aColor,METRO_OLIVE   )
	aadd(aColor,METRO_STEEL   )
	aadd(aColor,METRO_MAUVE   )
	aadd(aColor,METRO_TAUPE   )
	
	numRandom:=nRandom(len(aColor))
	
	if nExceto <> NIL
	   while aColor[numRandom] == nExceto
	   	numRandom:=nRandom(len(aColor))
	   end	
	endif
	return aColor[numRandom]
