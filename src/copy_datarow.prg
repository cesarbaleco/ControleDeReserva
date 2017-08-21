/*
* tdatarow.prg
* FWH 13.05
* Class TDataRow
*
*/

#include "fivewin.ch"
#include "dbinfo.ch"
#include "adodef.ch"
#include "xbrowse.ch"
#include "dbcombo.ch"
#include "Set.ch"

#define COLOR_BTNFACE       15

#ifdef __XHARBOUR__
   #xtranslate HB_STRTOHEX( <c> ) => STRTOHEX( <c> )
   #xtranslate HB_TTOS( <t> )     => TTOS( <t> )
   #xtranslate HB_CTOT( <c> )     => CTOT( <c> )
   #xtranslate HB_DateTime()      => DateTime()
#endif

#define FLD_NAME  1
#define FLD_VAL   2
#define FLD_RW    3
#define FLD_PIC   4
#define FLD_TYP   4
#define FLD_VLD   5
#define FLD_DFLT  6
#define FLD_HIDE  7
#define FLD_SIZE  FLD_HIDE

//----------------------------------------------------------------------------//

static lExit := .f.

//----------------------------------------------------------------------------//

CLASS TDataRow

   CLASSDATA cBmpList // Sample: "top=restop,up=<bmp>,down=<bmp>,bottom=<bmp>,new=<bmp>,redo=<bmp>,undo=<bmp>,save=,bmp>,close=<bmp>
                      // Case insensitive. Any order. Any number of bmps

   DATA aData
   DATA aOrg   //PROTECTED
   DATA aPrompts
   DATA aModiData
   DATA aDefault
   DATA cTitle
   //
   DATA uSource
   DATA cFieldList
   DATA cSrcType
   DATA cDbms
   DATA l1900  AS LOGICAL INIT .f.
   DATA lReadOnly AS LOGICAL INIT .f.
   DATA lTypeCheck AS LOGICAL INIT .t.
   DATA RecNo AS NUMERIC INIT 0
   DATA bSave, bSaveData, bEdit, bPreSave, bOnSave, bValid
   DATA bGoTop, bGoBottom, bGoUp, bGoDown
   DATA bCanGoUp, bCanGoDn
   //
   DATA cAlias    READONLY INIT ""
   DATA nArea     READONLY INIT 0
   DATA cFile     READONLY INIT ""
   DATA oBrw
   //
   ACCESS lValidData       INLINE ( ! Empty( ::cSrcType ) .and. ! Empty( ::aData ) )
   //
   // Transaction Support
   DATA lUseTrans AS LOGICAL INIT .f.
   DATA bBeginTrans, bCommitTrans, bRollBack
   //
   METHOD New( aData, oDbf ) CONSTRUCTOR
   //
   METHOD FCount           INLINE Len( ::aData )
   MESSAGE FieldPos        METHOD __FieldPos
   METHOD __FieldPos( u )
   METHOD FieldName( n )   INLINE If( n > 0 .and. n < Len( ::aData ), ::aData[ n, 1 ], "" )
   METHOD FieldType( cn )  INLINE ( cn := ::FieldPos( cn ), If( cn > 0, ValType( ::aData[ cn ][ 2 ] ), "U" ) )
   METHOD FieldPrompt( cn ) INLINE ( cn := ::FieldPos( cn ), If( cn > 0, ::aPrompts[ cn ], "" ) )
   METHOD FieldPic( cn, cPic )         // --> cPrev
   METHOD FieldCbxItems( cn, aItems )  // --> aPrev
   METHOD FieldValid( cn, bValid )     // --> bPrev
   METHOD FieldHide( cn, lHide )       // --> lPrev
   //
   METHOD FieldOrg( fld )  INLINE ::aOrg[ ::FieldPos( fld ), 2 ]
   METHOD FieldGet( fld )  INLINE XEval( ::aData[ ::FieldPos( fld ), 2 ] )
   MESSAGE FieldPut        METHOD dr_FieldPut( cnFld, uValue )
   //
   METHOD CopyFrom( oRec )
   METHOD Edit( lReadOnly, lNavigate )
   METHOD Undo( cnFld )
   METHOD Load()
   METHOD Save( lCheckValid )
   METHOD SetPrompt( cnField, cPrompt )
   METHOD SetDefault( ncField, uDefault, lCanModify )
   METHOD Modified( ncField )
   METHOD EditedFlds()
   METHOD CloseMsg()
   METHOD lValid()      INLINE If( ::bValid == nil, .t., Eval( ::bValid, Self ) )
   METHOD End()         INLINE ( ::uSource := nil, ::cSrcType := "", ::aData := nil )
   //
   // Navigataional methods
   //
   METHOD GoTop(l)      INLINE If( ::bGoTop    == nil, nil, If( ::CloseMsg(l), ( Eval( ::bGoTop,    Self ), ::Load() ), nil ) )
   METHOD GoUp(l)       INLINE If( ::bGoUp     == nil, nil, If( ::CloseMsg(l), ( Eval( ::bGoUp,     Self ), ::Load() ), nil ) )
   METHOD GoDown(l)     INLINE If( ::bGoDown   == nil, nil, If( ::CloseMsg(l), ( Eval( ::bGoDown,   Self ), ::Load() ), nil ) )
   METHOD GoBottom(l)   INLINE If( ::bGoBottom == nil, nil, If( ::CloseMsg(l), ( Eval( ::bGoBottom, Self ), ::Load() ), nil ) )
   METHOD GoNew(l)      INLINE If( ::RecNo > 0 .and. ::CloseMsg(l), ::Load( .t. ), nil )
   METHOD CanGoUp       INLINE ::bCanGoUp == nil .or. Eval( ::bCanGoUp )
   METHOD CanGoDn       INLINE ::bCanGoDn == nil .or. Eval( ::bCanGoDn )
   //
   DESTRUCTOR Destroy
   //

PROTECTED:

   METHOD ReadDBF( cFieldList, lBlank )
   METHOD ReadADO( cFieldList, lBlank )
   METHOD ReadDLP( cFieldList, lBlank )
   METHOD ReadObj( cFieldList, lBlank )
   METHOD ReadXBR( cFieldList, lBlank )
   METHOD SaveDbf()
   METHOD SaveADO()
   METHOD SaveDLP()
   METHOD SaveOBJ()
   METHOD SaveXBR()
   METHOD NaviBlocks()
   METHOD BeginTrans()  INLINE If( ::lUseTrans .and. ValType( ::bBeginTrans ) == 'B',  Eval( ::bBeginTans, Self ),  nil )
   METHOD CommitTrans() INLINE If( ::lUseTrans .and. ValType( ::bCommitTrans ) == 'B', Eval( ::bCommitTans, Self ), nil )
   METHOD RollBack()    INLINE If( ::lUseTrans .and. ValType( ::bRollBack ) == 'B',    Eval( ::bRollback, Self ),   nil )
   //
   // Support methods for edit dialog
   METHOD PlaceControls()
   METHOD MakeOneGet()
   METHOD DlgButtons()
   //
   METHOD EqualVal( x, y )
   //
   ERROR HANDLER nomessage

ENDCLASS

//----------------------------------------------------------------------------//

METHOD New( uSource, cFieldList, lBlank ) CLASS TDataRow

   local n

   // Parameter tolerance
   if ValType( uSource ) == 'L'
      lBlank := uSource; uSource := nil; cFieldList := nil
   elseif ValType( cFieldList ) == 'L'
      lBlank := cFieldList; cFieldList := nil
   endif
   // Parameter tolerance ends

//   ::aData     := { { "Blank", Space( 20 ) } }

   if uSource == nil
      uSource  := Alias()
   endif

   ::uSource   := uSource
   if ! Empty( cFieldList )
      cFieldList     := TrimList( cFieldList )
      ::cFieldList   := cFieldList
   endif

   ::Load( lBlank )

return Self

//----------------------------------------------------------------------------//

METHOD Load( lBlank ) CLASS TDataRow

   local n, cKey
   local lReload  := ( ValType( ::aData ) == 'A' )

   if ValType( ::uSource ) == 'C' .and. Select( ::uSource ) > 0
      ( ::uSource )->( ::ReadDBF( ::cFieldList, lBlank, lReload ) )
   elseif ValType( ::uSource ) == 'O'
      if ::uSource:ClassName == "TOLEAUTO"
         //
         ::bBeginTrans   := { || ::uSource:ActiveConnection:BeginTrans() }
         ::bCommitTrans  := { || ::uSource:ActiveConnection:CommitTrans() }
         ::bRollBack     := { || ::uSource:ActiveConnection:RollBackTrans() }
         //
         ::ReadADO( ::cFieldList, lBlank, lReload )
      elseif ::uSource:IsKindOf( 'TDOLPHINQRY' )
         ::ReadDLP( ::cFieldList, lBlank, lReload )
      elseif ::uSource:IsKindOf( "TXBROWSE" )
         ::ReadXBR( ::cFieldList, lBlank, lReload )
      else
         ::ReadOBJ( ::cFieldList, lBlank, lReload )
      endif
   elseif ValType( ::uSource ) $ 'AH'
      if ValType( ::uSource ) == 'H'
         ::cSrcType     := "HSH"
         ::aData        := {}
         for each cKey IN ::uSource:Keys
            AAdd( ::aData, { cKey, ::uSource:Values[HB_EnumIndex()] } )
         next
      else
         ::cSrcType     := "ARR"
         ::aData        := ::uSource
      endif
      if ! Empty( ::aData ) .and. ValType( ::aData[ 1 ] ) == 'A' .and. Len( ::aData[ 1 ] ) > 1
         ::aOrg      := AClone( ::aData )
         AEval( ::aOrg, { |a| If( ValType( a[ 2 ] ) == 'B', a[ 2 ] := Eval( a[ 2 ] ), nil ) } )
         for n := 1 to Len( ::aData )
            if Len( ::aData[ n ] ) < 4
               ASize( ::aData[ n ], 4 )
               if ::aData[ n, 3 ] == nil
                  ::aData[ n, 3 ] := .t.
               endif
               if ::aData[ n, 4 ] == nil .and. ValType( ::aData[ n, 2 ] ) == 'N'
                  ::aData[ n, 4 ] := GetNumPict( ::aData[ n, 2 ] )
               endif
            endif
         next
         ::RecNo     := 1
         ::lTypeCheck:= .f.
      endif
   endif

   if ::lValidData
      if ::aPrompts == nil
         ::aPrompts     := {}
         AEval( ::aData, { |a| AAdd( ::aPrompts, a[ 1 ] ) } )
      endif
      if ::aDefault == nil
         ::aDefault     := Array( Len( ::aData ) )
      else
         if ::RecNo == 0
            AEval( ::aDefault, { |u,i| If( u == nil .or. ValType( u ) == 'B', nil, ::aData[ i, 2 ] := u ) } )
         endif
      endif
   else
      // MsgAlert( "Invalid Data" )
   endif

return ::lValidData

//----------------------------------------------------------------------------//

METHOD SetPrompt( ncField, cPrompt ) CLASS TDataRow

   local nPos

   if ValType( ncField ) == 'A'
      // Should be 2-dim array
      AEval( ncField, { |a| ::SetPrompt( a[ 1 ], a[ 2 ] ) } )
      return nil
   elseif ValType( ncField ) == 'N'
      nPos     := ncField
   else
      ncField  := Upper( AllTrim( ncField ) )
      nPos     := AScan( ::aData, { |a| Upper( AllTrim( a[ 1 ] ) ) == ncField } )
   endif
   if nPos < 1 .or. nPos > Len( ::aData )
      return nil
   endif
   cPrompt     := AllTrim( cPrompt )
   if Upper( AllTrim( ::aData[ nPos, 1 ] ) ) == Upper( cPrompt )
      ::aPrompts[ nPos ]   := cPrompt
      return nil
   endif
   if AScan( ::aPrompts, { |c| Upper( c ) == Upper( cPrompt ) } ) == 0 .and. ;
      AScan( ::aData,    { |a| Upper( a[ 1 ] ) == Upper( cPrompt ) } ) == 0
      ::aPrompts[ nPos ]   := cPrompt
   endif

return nil

//----------------------------------------------------------------------------//

METHOD SetDefault( ncField, uDefault, lCanModify ) CLASS TDataRow

   local nPos

   if ValType( ncField ) == 'A'
      // Should be 2-dim array
      AEval( ncField, { |a| ::SetDefault( a[ 1 ], a[ 2 ], If( Len( a ) > 2, a[ 3 ], .t. ) ) } )
      return nil
   elseif ValType( ncField ) == 'N'
      nPos     := ncField
   else
      ncField  := Upper( AllTrim( ncField ) )
      nPos     := AScan( ::aData, { |a| Upper( AllTrim( a[ 1 ] ) ) == ncField } )
   endif
   if nPos < 1 .or. nPos > Len( ::aData )
      return nil
   endif

   DEFAULT lCanModify := ( ValType( uDefault ) != 'B' )

   if ::aData[ nPos, 3 ] == .f.
      lCanModify     := .f.
   endif

   ::aDefault[ nPos ]      := uDefault
   if ::RecNo == 0 .and. ValType( uDefault ) != 'B'
      ::aData[ nPos, 2 ]   := uDefault
   endif
   ::aData[ nPos, 3 ]      := lCanModify

return nil

//----------------------------------------------------------------------------//

METHOD FieldPic( fld, cNewPic ) CLASS TDataRow

   local cPic

   if ( fld := ::FieldPos( fld ) ) > 0
      if Len( ::aData[ fld ] ) >= 4 .and. ValType( ::aData[ fld, 4 ] ) == 'C' .and. Len( ::aData[ fld, 4 ] ) > 1
         cPic     := ::aData[ fld, 4 ]
      endif
      //
      if ValType( cNewPic ) == 'C' .and. Len( cNewPic ) > 1
         if Len( ::aData[ fld ] ) < 4
            ASize( ::aData[ fld ], 5 )
         endif
         ::aData[ fld, 4 ] := cNewPic
      endif
   endif

return cPic

//----------------------------------------------------------------------------//

METHOD FieldCbxItems( fld, aLookUp ) CLASS TDataRow

   local aRet

   if ( fld := ::FieldPos( fld ) ) > 0
      if Len( ::aData[ fld ] ) >= 4 .and. ValType( ::aData[ fld, 4 ] ) == 'A'
         aRet  := ::aData[ fld, 4 ]
      endif
      //
      if ValType( aLookUp ) == 'A' .and. ! Empty( aLookUp )
         if Len( ::aData[ fld ] ) < 4
            ASize( ::aData[ fld ], 5 )
         endif
         ::aData[ fld, 4 ] := aLookUp
      endif
   endif

return aRet

//----------------------------------------------------------------------------//

METHOD FieldValid( fld, bValid ) CLASS TDataRow

   local bRet

   if ( fld := ::FieldPos( fld ) ) > 0
      if Len( ::aData[ fld ] ) >= 5 .and. ValType( ::aData[ fld, 4 ] ) == 'B'
         bRet  := ::aData[ fld, 5 ]
      endif
      //
      if ValType( bValid ) == 'B'
         if Len( ::aData[ fld ] ) < 5
            ASize( ::aData[ fld ], 5 )
         endif
         ::aData[ fld, 5 ] := bValid
      endif
   endif

return bRet

//----------------------------------------------------------------------------//

METHOD FieldHide( fld, lHide ) CLASS TDataRow

   local lRet := .f.

   if ( fld := ::FieldPos( fld ) ) > 0
      if Len( ::aData[ fld ] ) >= FLD_HIDE
         lRet     := ( ::aData[ fld, FLD_HIDE ] == .t. )
      endif
      //
      if ValType( lHide ) == 'L'
         if Len( ::aData[ fld ] ) >= FLD_HIDE
            ::aData[ fld, FLD_HIDE ]   := lHide
         elseif lHide
            ASize( ::aData[ fld ], FLD_HIDE )
            ::aData[ fld, FLD_HIDE ]   := lHide
         endif
      endif
   endif

return lRet

//----------------------------------------------------------------------------//

METHOD dr_FieldPut( cnfld, uVal ) CLASS TDataRow

   local fld, cFldType, cType

   if ( fld := ::FieldPos( cnfld ) ) > 0
      if ::lReadOnly .or. ( Len( ::aData[ fld ] ) > 2 .and. ::aData[ fld, 3 ] == .f. )
         return ::error(  HB_LangErrMsg( 39 ), ::className(), ::FieldName( fld ), 39, { uVal } )
      else
         cFldType    := ValType( ::aOrg[ fld, 2 ] )
         cType       := ValType( uVal )
         if cFldType == 'D' .and. cType == 'T'
            uVal     := FW_TTOD( uVal )
         elseif cFldType == 'T' .and. cType == 'D'
            uVal     := FW_DTOT( uVal )
         endif
         if ! ::lTypeCheck .or. ::aOrg[ fld, 2 ] == nil .or. ;
            ValType( uVal ) == cFldType

            if ValType( ::aData[ fld, 2 ] ) == 'B'
               Eval( ::aData[ fld, 2 ], uVal )
            else
               ::aData[ fld, 2 ]    := uVal
            endif
            return ::FieldGet( fld )
         else
            return ::error(  HB_LangErrMsg( 33 ), ::className(), ::FieldName( fld ), 33, { uVal } )
         endif
      endif
   else
      return ::error(  HB_LangErrMsg( 14 ), ::className(), cValToChar( cnfld ), 14, { uVal } )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD Modified( fld ) CLASS TDataRow

   local lModified   := .f.

   if PCount() > 0
      if ( fld := ::FieldPos( fld ) ) > 0
         lModified := ! ::EqualVal( ::aData[ fld, FLD_VAL ], ::aOrg[ fld, FLD_VAL ] )
         if lModified .and. ::RecNo == 0 .and. ! Empty( ::aDefault[ fld ] )
            if ::EqualVal( ::aData[ fld, FLD_VAL ], XEval( ::aDefault[ fld ] ) )
               lModified    := .f.
            endif
         endif
      endif
   else
      for fld := 1 to Len( ::aData )
         if ::Modified( fld )
            lModified   := .t.
            exit
         endif
      next
   endif

return lModified

//----------------------------------------------------------------------------//

METHOD Undo( fld ) CLASS TDataRow

   if PCount() > 0
      if ( fld := ::FieldPos( fld ) ) > 0
         if ValType( ::aData[ fld, 2 ] ) == 'B'
            Eval( ::aData[ fld, 2 ], ::aOrg[ fld, 2 ] )
         else
            ::aData[ fld, 2 ] := ::aOrg[ fld, 2 ]
         endif
      endif
   else
      AEval( ::aData, { |a,i| If( ValType( a[ 2 ] ) == 'B', ;
                  Eval( a[ 2 ], ::aOrg[ i, 2 ] ), ;
                  a[ 2 ] := ::aOrg[ i, 2 ] ) } )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD EditedFlds() CLASS TDataRow

   local n, aRet  := {}

   for n := 1 to Len( ::aData )
      if ! ::EqualVal( ::aData[ n, 2 ], IfNil( XEval( ::aDefault[ n ] ), ::aOrg[ n, 2 ] ) )
         AAdd( aRet, { n, ::aData[ n, 1 ], ::aData[ n, 2 ], ::aOrg[ n, 2 ], ;
                       XEval( ::aDefault[ n ] ) } )
      endif
   next n

return aRet

//----------------------------------------------------------------------------//

METHOD CloseMsg( lSave ) CLASS TDataRow

   local nChoice  := 0
   local a

   nChoice  := If( lSave == .t., 1, If( lSave == .f., 2, 0 ) )

   if ::cSrcType $ "ARR"
      AEval( ::aOrg, { |a,i| ASize( ::aData[ i ], Len( a ) ) } )
   elseif ::cSrcType $ "HSH"
      for each a in ::aData
         ::uSource[ a[ 1 ] ] := a[ 2 ]
      next
   elseif ! ::lReadOnly .and. ::Modified()
      if nChoice == 0
         nChoice  := Alert( "Data Modified. Save/Discard Changes?", { "Save", "Discard", "Cancel" } )
      endif
      if nChoice == 1
         ::Save()
      elseif nChoice == 2
         ::Undo()
      else
         return .f.
      endif
   endif

return .t.

//----------------------------------------------------------------------------//

METHOD __FieldPos( cName ) CLASS TDataRow

   local nPos     := 0

   if ValType( cName ) == 'N'
      return cName
   endif
   cName    := Upper( AllTrim( cName ) )
   if ( nPos := AScan( ::aPrompts, { |c| Upper( c ) == cName } ) ) == 0
   if ( nPos := AScan( ::aPrompts, { |c| Upper( CharRem( ' ', c ) ) == cName } ) ) == 0
   if ( nPos := AScan( ::aPrompts, { |c| Upper( StrTran( c, ' ', '_' ) ) == cName } ) ) == 0
      nPos  := AScan( ::aData, { |a| Upper( Trim( a[ 1 ] ) ) == cName } )
   endif
   endif
   endif

return nPos

//----------------------------------------------------------------------------//

METHOD ReadDBF( cFieldList, lBlank, lReload ) CLASS TDataRow

   local i, j, nFieldPos

   DEFAULT cFieldList   := FW_ArrayAsList( ArrTranspose( DbStruct() )[ 1 ] ), ;
           lBlank       := Eof()

   ::cAlias    := ::uSource
   ::nArea     := Select( ::cAlias )
   ::cFile     := ( ::nArea )->( DBINFO( DBI_FULLPATH ) )

   if ValType( cFieldList ) == 'A'
      cFieldList  := FW_ArrayAsList( cFieldList )
   endif
   cFieldList  := StrTran( cFieldList, ' ', '' )

   if lReload
      AEval( Eval( &( "{ || { " + cFieldList + " } }" ) ), { |u,i| ::aData[ i, 2 ] := u } )
   else
      ::aData  := ArrTranspose( { FW_ListAsArray( cFieldList ), Eval( &( "{ || { " + cFieldList + " } }" ) ) } )
   endif

   if lBlank .and. ! eof()
      AEval( ::aData, { |a| a[ 2 ] := uValBlank( a[ 2 ] ) } )
   endif

   if ! lReload
      for i := 1 to Len( ::aData )
         ASize( ::aData[ i ], 4 )
         nFieldPos   := FieldPos( ::aData[ i, 1 ] )
         ::aData[ i, 3 ]   := !( FieldType( nFieldPos ) $ "+=" )
         if FieldType( nFieldPos  ) $ 'N+'
            ::aData[ i, 4 ]   := NumPict( FieldLen( nFieldPos ), FieldDec( nFieldPos ) )
         else
            ::aData[ i, 4 ]   := FieldType( nFieldPos )
         endif
      next
   endif

   ::aOrg      := AClone( ::aData )
   ::RecNo     := If( lBlank .or. eof(), 0, RecNo() )
   ::cSrcType  := "DBF"
   ::lReadOnly := DbInfo( DBI_ISREADONLY )
   if Empty( ::cTitle )
      ::cTitle := cFileNoExt( DbInfo( DBI_FULLPATH ) )
   endif

return nil

//----------------------------------------------------------------------------//

METHOD ReadADO( cFieldList, lBlank, lReload ) CLASS TDataRow

   local oRs      := ::uSource
   local n, nFlds, aList, aFld, aData := {}
   local oField, cType, uVal, cPic

   DEFAULT lBlank := oRs:Eof()

   if ! lBlank
      TRY
         oRs:Resync( adAffectCurrent, adResyncAllValues )
      CATCH
      END
   endif

   DEFAULT ::cDBMS := FW_RDBMSName( oRs:ActiveConnection )
   ::l1900         := ! Empty( ::cDbms ) .and. ::cDbms $ "MSACCESS,MSSQL"

   if cFieldList == nil
      nFlds := oRs:Fields:Count
      aFld  := Array( nFlds )
      for n := 1 to nFlds
         aFld[ n ]   := oRs:Fields:Item( n - 1 )
      next
   else
      aList    := HB_ATokens( cFieldList, ',' )
      aFld     := Array( Len( aList ) )
      for n := 1 to Len( aList )
         TRY
            aFld[ n ]   := oRs:Fields( aList[ n ] )
         CATCH
            // invalid field name
         END
      next
   endif
   for each oField in aFld
      if oField != nil
         cType    := FieldTypeAdoToDbf( oField:Type )
         cPic     := nil
         if ! Empty( cType ) .and. cType $ "CDLNT"
            uVal     := If( oRs:Eof(), nil, oField:Value )
            if ValType( uVal ) == 'D' .and. uVal == {^ 1899/12/30 }
               uVal  := nil
            elseif ValType( uVal ) == 'T'
               if Left( HB_TTOS( uVal ), 8 ) == "18991230"
                  uVal  := nil
               elseif FW_TIMEPART( uVal ) < 1.0
                  uVal  := FW_TTOD( uVal )
               endif
            endif
            if uVal == nil .or. lBlank
               uVal  := FW_DeCode( cType, 'C', Space( Min( 100, oField:DefinedSize ) ), ;
                        'D', CToD( '' ), 'L', .f., 'N', 0.00, 'T', CToT( '' ), nil )
            else
               if cType == 'C' .and. ! IsBinaryData( uVal )
                  uVal     := Trim( uVal )
                  if Len( uVal ) < Min( 100, oField:DefinedSize )
                     uVal  := PadR( uVal, Min( 100, oField:DefinedSize ) )
                  endif
               endif
            endif
            if cType == 'N'
               if AScan( { 14, 131, 139 }, oField:Type ) > 0
                  cPic  := NumPict( Min( 19, oField:Precision ), ;
                           If( oField:NumericScale >= 255, 0, ;
                              Min( Min( 19, oField:Precision ) - 2, oField:NumericScale ) ) )
               elseif AScan( { 4, 5, 6 }, oField:Type ) > 0
                  cPic  := NumPict( Min( oField:Precision, 11 ), 2 )
               elseif AScan( { 2,3,16,17,18,19,20,21 }, oField:Type ) > 0
                  cPic  := NumPict( Min( oField:Precision, 10 ), 0 )
               endif
            endif
            if cType == 'C' .and. oField:DefinedSize > 100
               cType    := 'M'
            endif
            AAdd( aData, { oField:Name, uVal, FW_AdoFieldUpdateable( oRs, oField ), IfNil( cPic, cType ) } )
         endif
      endif
   next

   if lReload
      AEval( aData, { |a,i| ::aData[ i, 2 ] := a[ 2 ] } )
   else
      ::aData     := aData
   endif
   ::RecNo     := If( lBlank, 0, oRs:BookMark )
   ::aOrg      := AClone( ::aData )
   ::cSrcType  := "ADO"
   ::lReadOnly := ( oRs:LockType == adLockReadOnly )
   if ! Empty( oRs:ActiveConnection ) .and. FW_RDBMSName( oRs:ActiveConnection ) = "SQLITE"
      ::lTypeCheck   := .f.
   endif

   if Empty( ::cTitle )
      TRY
         ::cTitle := ::oRs:Fields( 0 ):Properties( "BASETABLENAME" ):Value
      CATCH
      END
   endif

return nil

//----------------------------------------------------------------------------//

METHOD ReadDLP( cFieldList, lBlank, lReload ) CLASS TDataRow

   local oQry      := ::uSource
   local n, nFld, nFlds, aList, aFld, aData := {}
   local oField, cType, uVal, cPic

   DEFAULT lBlank := oQry:Eof()

   if cFieldList == nil
      nFlds := oQry:FCount()
      aFld  := Array( nFlds )
      AEval( aFld, { |u,i| aFld[ i ] := i } )
   else
      aList    := HB_ATokens( cFieldList, ',' )
      aFld     := Array( Len( aList ) )
      for n := 1 to Len( aList )
         aFld[ n ] := oQry:FieldPos( aList[ n ] )
      next
   endif
   for n := 1 to Len( aFld  )
      nFld     := aFld[ n ]
      cType    := oQry:FieldType( nFld )
      uVal     := oQry:FieldGet( nFld )

      AAdd( aData, { oQry:FieldName( nFld ), ;
         If( lBlank, uValBlank( uVal ), uVal ), ;
         .t., ;
         If( cType == 'N', NumPict( oQry:FieldLen( nFld ), oQry:FieldDec( nFld ) ), cType ), ;
         nil } )
   next

   if lReload
      AEval( aData, { |a,i| ::aData[ i, 2 ] := a[ 2 ] } )
   else
      ::aData     := aData
   endif
   ::RecNo     := If( lBlank, 0, oQry:RecNo() )
   ::aOrg      := AClone( ::aData )
   ::cSrcType  := "DLP"
   ::lReadOnly := .f.
   ::lTypeCheck   := .t.

return nil

//----------------------------------------------------------------------------//

METHOD ReadOBJ( cFieldList, lBlank, lReload )

   local aData

   if __ObjHasMethod( ::uSource, "ROWGET" )
      aData       := ::uSource:RowGet( cFieldList, @lBlank )
      if Empty( ::aData )
         ::aData  := aData
         ::aOrg   := AClone( ::aData )
      else
         AEval( aData, { |a,i| ::aData[ i, 2 ] := a[ 2 ], ::aOrg[ i, 2 ] := a[ 2 ] } )
      endif
      ::RecNo     := If( lBlank, 0, ::uSource:RecNo() )
      ::cSrcType  := "OBJ"
      ::lReadOnly := ::uSource:lReadOnly
      return nil
   endif

return nil

//----------------------------------------------------------------------------//

METHOD ReadXBR( cFieldList, lBlank ) CLASS TDataRow

   local oBrw     := ::uSource
   local aHeaders, cHeader, oCol

   DEFAULT lBlank := ( oBrw:nLen < 1 )

   if cFieldList == nil
      aHeaders    := oBrw:cHeaders
   else
      aHeaders    := HB_ATokens( cFieldList, "," )
      AEval( aHeaders , { |c,i| aHeaders[ i ] := AllTrim( c ) } )
   endif

   ::aData     := {}
   for each cHeader in aHeaders
      oCol     := oBrw:oCol( cHeader )
      if oCol != nil
         AAdd( ::aData, { cHeader, If( lBlank, oCol:BlankValue(), oCol:Value ), oCol:lEditable, nil } )
         if ValType( ATail( ::aData )[ 2 ] ) == 'N'
            ATail( ::aData )[ 4 ] := If( Empty( oCol:cEditPicture ), NumPict( 12, 2 ), oCol:cEditPicture )
         else
            ATail( ::aData )[ 4 ] := oCol:cDataType
            if oCol:bEditBlock != nil
               ATail( ::aData )[ 4 ] := oCol:bEditBlock
            elseif oCol:nEditType == EDIT_LISTBOX
               ATail( ::aData )[ 4 ] := ArrTranspose( { oCol:aEditListBound, oCol:aEditListTxt } )
            endif
         endif
      endif
   next
   ::RecNo     := If( lBlank, 0, oBrw:BookMark )
   ::aOrg      := AClone( ::aData )
   ::cSrcType  := "XBR"
   ::lReadOnly := oBrw:lReadOnly
   if oBrw:nDataType == DATATYPE_ARRAY
      ::lTypeCheck   := .f.
   elseif oBrw:nDataType == DATATYPE_ADO
      if ! Empty( oBrw:oRs:ActiveConnection ) .and. FW_RDBMSName( oBrw:oRs:ActiveConnection ) = "SQLITE"
         ::lTypeCheck   := .f.
      endif
      ::bBeginTrans   := { || ::uSource:oRs:ActiveConnection:BeginTrans() }
      ::bCommitTrans  := { || ::uSource:oRs:ActiveConnection:CommitTrans() }
      ::bRollBack     := { || ::uSource:oRs:ActiveConnection:RollBackTrans() }

   endif

return nil

//----------------------------------------------------------------------------//

METHOD Save( lCheckValid ) CLASS TDataRow

   local lSaved   := .f.
   local n, lAdded := .f.

   if lCheckValid == .t.
      if .not. ::lValid()
         MsgInfo( "Can not save Invalid Data" )
         return .f.
      endif
   endif

   ::BeginTrans()

   ::aModiData    := {}
   for n := 1 to ::FCount()
      if ( ::aData[ n, 3 ] == nil .or. ::aData[ n, 3 ] ) .and. ::Modified( n )
         AAdd( ::aModiData, { ::aData[ n, 1 ], ::aData[ n, 2 ], n } )
      endif
   next

   if ::bSave != nil
      lSaved   := Eval( ::bSave, Self )
      lSaved   := If( ValType( lSaved ) == 'L', lSaved, .t. )
   elseif ! Empty( ::aModiData )
      if ::RecNo == 0
         for n := 1 to Len( ::aDefault )
            if ValType( ::aDefault[ n ] ) == 'B'
               if AScan( ::aModiData, { |a| a[ 3 ] == n } ) == 0
                  AAdd( ::aModiData, { ::aData[ n, 1 ], XEval( ::aDefault[ n ] ), n } )
                  lAdded := .t.
               endif
            endif
         next n
      endif
      if lAdded
         ASort( ::aModiData, nil, nil, { |x,y| x[ 3 ] < y[ 3 ] } )
      endif

      if ::bPreSave != nil
         if ::cSrcType == "DBF"
            ( ::uSource )->( Eval( ::bPreSave, Self ) )
         else
            Eval( ::bPreSave, Self )
         endif
        ::aModiData    := {}
        for n := 1 to ::FCount()
           if ( ::aData[ n, 3 ] == nil .or. ::aData[ n, 3 ] ) .and. ::Modified( n )
              AAdd( ::aModiData, { ::aData[ n, 1 ], ::aData[ n, 2 ], n } )
           endif
        next
      endif
      if ::cSrcType == "DBF"
         lSaved   := ( ::uSource )->( ::SaveDBF() )
      elseif ::cSrcType == "ADO"
         lSaved   := ::SaveADO()
      elseif ::cSrcType == "DLP"
         lSaved   := ::SaveDLP()
      elseif ::cSrcType == "OBJ"
         lSaved   := ::SaveOBJ()
      elseif ::cSrcType == "XBR"
         lSaved   := ::SaveXBR()
      endif
   endif

   if lSaved .and. ::bOnSave != nil
      lSaved   := Eval( ::bOnSave, Self )
      lSaved   := If( ValType( lSaved ) == 'L', lSaved, .t. )
   endif

   if lSaved
      ::CommitTrans()
   else
      ::RollBack()
   endif

return lSaved

//----------------------------------------------------------------------------//

METHOD CopyFrom( oRec ) CLASS TDataRow

   local aField

   for each aField in oRec:aData
      TRY
         ::FieldPut( aField[ 1 ], aField[ 2 ] )
      CATCH
      END
   next

return nil

//----------------------------------------------------------------------------//

METHOD SaveDBF() CLASS TDataRow

   local n, nCols    := ::FCount()
   local lAppend     := ( ::RecNo == 0 .or. ( bof() .and. eof() ) )
   local nSaveRec

   if ::lReadOnly .or. ! ::Modified()
      return .f.
   endif

   if lAppend
      ::RecNo  := 0
      REPEAT
         DbAppend()
      UNTIL ! NetErr()
   else
      if ::RecNo != RecNo()
         nSaveRec    := RecNo()
      endif
      DbGoTo( ::RecNo )
      do while ! DbRLock(); enddo
   endif

   if ::bSaveData == nil
      for n := 1 to Len( ::aModiData )
         TRY
            FieldPut( FieldPos( ::aModiData[ n, 1 ] ), ::aModiData[ n, 2 ] )
         CATCH
         END
      next n
   else
      Eval( ::bSaveData, Self )
   endif
   DbUnlock()

   ::ReadDBF( FW_ArrayAsList( ArrTranspose( ::aData )[ 1 ] ), .f., .t. )

   if ! Empty( nSaveRec )
      DbGoTo( nSaveRec )
   endif

return .t.

//----------------------------------------------------------------------------//

METHOD SaveADO() CLASS TDataRow

   local oRs   := ::uSource
   local lAppend  := ( ::RecNo == 0 .or. ( oRs:Bof .and. oRs:Eof ) )
   local uSaveBm, a, uVal, oField, n, aCols, aVals
   local lSaved   := .f.
   local lBinary  := .f.

   if ::lReadOnly .or. ! ::Modified()
      return .f.
   endif

   if lAppend
      ::RecNo     := 0
   elseif ::RecNo != oRs:BookMark
      uSaveBm        := oRs:BookMark
      oRs:BookMark   := ::RecNo
   endif

   if ::bSaveData == nil
      for n := 1 to Len( ::aModiData )
         oField   := oRs:Fields( ::aModiData[ n, 1 ] )
         lBinary  := AScan( { 128, 204, 205 }, oField:Type ) > 0
         uVal     := ::aModiData[ n, 2 ]
         if ValType( uVal ) == 'C'
            if lBinary
               uVal  := HB_STRTOHEX( uVal )
            else
               uVal  := Left( Trim( uVal ), oField:DefinedSize )
            endif
         endif
         if ValType( uVal ) $ "DT"
            if Empty( uVal )
               uVal     := AdoNull()
            elseif Year( uVal ) < 1900 .and. ::l1900
               uVal     := AdoNull()
            endif
         endif
         ::aModiData[ n, 2 ]  := uVal
      next n

      a     := ArrTranspose( ::aModiData )
      aCols := a[ 1 ]
      aVals := a[ 2 ]

      TRY
         if lAppend
            oRs:AddNew( aCols, aVals )
         else
            oRs:Update( aCols, aVals )
         endif
         lSaved   := .t.
      CATCH
         FW_ShowAdoError( oRs:ActiveConnection )
         oRs:CancelUpdate()
      END
   else
      lSaved   := Eval( ::bSaveData, Self )
      lSaved   := If( ValType( lSaved ) == 'L', lSaved, .t. )
   endif
   if lSaved
      ::ReadADO( FW_ArrayAsList( ArrTranspose( ::aData )[ 1 ] ), .f., .t. )
      if ! lAppend .and. uSaveBm != nil
         oRs:BookMark   := uSaveBm
      endif                                                                                                       a[ 2
   else
      ::Undo()
   endif

return lSaved

//----------------------------------------------------------------------------//

METHOD SaveDLP() CLASS TDataRow

   local n, nCols    := ::FCount()
   local oQry        := ::uSource
   local nSaveRec
   local lAppend     := ( ::RecNo == 0 )

   if ::lReadOnly .or. ! ::Modified()
      return .f.
   endif

   if lAppend
      if ! oQry:lAppend
         oQry:GetBlankRow( .f. )
      endif
   else
      nSaveRec    := ::RecNo
   endif

   if ::bSaveData == nil
      for n := 1 to Len( ::aModiData )
         oQry:FieldPut( oQry:FieldPos( ::aModiData[ n, 1 ] ), ::aModiData[ n, 2 ] )
      next n
      oQry:Save()
      if lAppend
         oQry:Refresh()
      endif
   else
      Eval( ::bSaveData, Self )
   endif

   if lAppend
      n     := ArrTranspose( ::aModiData )
      oQry:Find( n[ 2 ], n[ 1 ] )
   endif

   ::ReadDLP( FW_ArrayAsList( ArrTranspose( ::aData )[ 1 ] ), .f., .t. )

   if ! Empty( nSaveRec )
      oQry:GoTo( nSaveRec )
   endif

return .t.

//----------------------------------------------------------------------------//

METHOD SaveXBR() CLASS TDataRow

   local oBrw     := ::uSource
   local lAppend  := ( ::RecNo == 0 .or. oBrw:nLen < 1 )
   local uSaveBm  := oBrw:BookMark
   local nRow, aRow
   local lSaved   := .f.

   if ::lReadOnly .or. ! ::Modified()
      return .f.
   endif

   if lAppend
      if ! XBrAddNewRow( oBrw )
         MsgAlert( "Can not append new row for the datasource" )
         return .f.
      endif
   elseif ::RecNo != oBrw:BookMark
      uSaveBm        := oBrw:BookMark
      oBrw:BookMark  := ::RecNo
   endif
   if ::bSaveData == nil
      for nRow := 1 to Len( ::aData )
         aRow  := ::aData[ nRow ]
         // if aRow[ 3 ] .and. ::Modified( nRow )
         if aRow[ 3 ] .and. ( lAppend .or. ::Modified( nRow ) ) // 2014-04-11. Write all fields while appending
            oBrw:oCol( aRow[ 1 ] ):VarPut( aRow[ 2 ] )
            lSaved   := .t.
         endif
      next
   else
      lSaved   := Eval( ::bSaveData, Self )
      lSaved   := If( ValType( lSaved ) == 'L', lSaved, .t. )
   endif

   if lAppend .and. lSaved
      lSaved   := XbrSaveNewRow( oBrw )
   endif

   if lSaved
      ::ReadXBR( FW_ArrayAsList( ArrTranspose( ::aData )[ 1 ] ), .f., .t. )
      if ! lAppend .and. uSaveBm != nil
         oBrw:BookMark   := uSaveBm
      endif
   else
      ::Undo()
   endif
   oBrw:Refresh()

return lSaved

//----------------------------------------------------------------------------//

METHOD SaveOBJ() CLASS TDataRow

   if ::lReadOnly .or. ! ::Modified()
      return .f.
   endif

   if __ObjHasMethod( ::uSource, "ROWPUT" )
      ::RecNo  := ::uSource:RowPut( ::aData, ::RecNo, .f., Self )
      ::aOrg   := AClone( ::aData )
   endif

return .t.

//----------------------------------------------------------------------------//

METHOD NaviBlocks() CLASS TDataRow

   if ::bGoTop != nil
      return nil
   endif

   if ::oBrw != nil
      ::bGoTop       := { |oRec| oRec:oBrw:GoTop() }
      ::bGoUp        := { |oRec| oRec:oBrw:GoUp() }
      ::bGoDown      := { |oRec| oRec:oBrw:GoDown() }
      ::bGoBottom    := { |oRec| oRec:oBrw:GoBottom() }
      ::bCanGoUp     := { || ::oBrw:KeyNo > 1 }
      ::bCanGoDn     := { || ::oBrw:KeyNo < ::oBrw:nLen }
   elseif ::cSrcType == "DBF"
      ::bGoTop       := { |oRec| ( oRec:uSource )->( DbGoTop() ) }
      ::bGoUp        := { |oRec| ( oRec:uSource )->( DbSkip( -1 ), If( Bof(), DbGoTop(), nil ) ) }
      ::bGoDown      := { |oRec| ( oRec:uSource )->( DbSkip( +1 ), If( Eof(), DbGoBottom(), nil ) ) }
      ::bGoBottom    := { |oRec| ( oRec:uSource )->( DbGoBottom() ) }
      ::bCanGoUp     := { || ( ::uSource )->( OrdKeyNo() ) > 1 }
      ::bCanGoDn     := { || ( ::uSource )->( OrdKeyNo() ) < ( ::uSource )->( OrdKeyCount() ) }
   elseif ::cSrcType == "ADO"
      ::bGoTop       := { |oRec| If( oRec:uSource:RecordCount() > 0, oRec:uSource:MoveFirst(), nil ) }
      ::bGoUp        := { |oRec| If( oRec:uSource:RecordCount() > 0 .and. oRec:uSource:AbsolutePosition > 1, ;
                                     oRec:uSource:MovePrevious(), nil ) }
      ::bGoDown      := { |oRec| If( oRec:uSource:RecordCount() > 0 .and. oRec:uSource:AbsolutePosition < oRec:uSource:RecordCount(), ;
                                     oRec:uSource:MoveNext(), nil ) }
      ::bGoBottom    := { |oRec| If( oRec:uSource:RecordCount() > 0, oRec:uSource:MoveLast(), nil ) }
      ::bCanGoUp     := { || ::uSource:RecordCount() > 0 .and. ::uSource:AbsolutePosition > 1 }
      ::bCanGoDn     := { || ! ::uSource:Eof() .and. ::uSource:AbsolutePosition < ::uSource:RecordCount() }
   elseif ::cSrcType $ "OBJ,DLP"
      ::bGoTop       := { |oRec| oRec:uSource:GoTop() }
      ::bGoUp        := { |oRec| oRec:uSource:Skip( -1 ) }
      ::bGoDown      := { |oRec| oRec:uSource:Skip( +1 ) }
      ::bGoBottom    := { |oRec| oRec:uSource:GoBottom() }
      if ::cSrcType == "OBJ"
         ::bCanGoUp     := { || ::uSource:KeyNo() > 1 }
         ::bCanGoDn     := { || ::uSource:KeyNo() < ::uSource:KeyCount() }
      else
         ::bCanGoUp     := { || ::uSource:RecNo() > 1 }
         ::bCanGoDn     := { || ::uSource:RecNo() < ::uSource:RecCount() }
      endif
   endif

return nil

//----------------------------------------------------------------------------//

METHOD Edit( lReadOnly, lNavigate, cTitle, cMsg ) CLASS TDataRow

   local oRec  := Self
   local oDlg, oPanel
   local oFont, oSayFont, oFixed
   local uRet

   if ! ::lValidData
      return .f.
   endif

   ::NaviBlocks()

   if ::bEdit != nil
      uRet  := Eval( ::bEdit, Self )
      return uRet
   endif

   DEFAULT lReadOnly := ::lReadOnly //.and. Empty( ::bSave )
   DEFAULT lNavigate := .t.
   DEFAULT cTitle := ""


   DEFINE FONT oFont NAME "TAHOMA" SIZE 0,-14
   oSayFont := oFont:Bold()
   DEFINE FONT oFixed  NAME "COURIER NEW" SIZE 0,-16

   DEFINE DIALOG oDlg SIZE 800,500 PIXEL FONT oFont TITLE cTitle
   oPanel   := TScrollPanel():New( 20, 20, 200, 360, oDlg, .t. )
   oPanel:SetColor( CLR_BLACK, oDlg:nClrPane )
   oPanel:SetFont( oDlg:oFont )

   lExit    := .f.
   ACTIVATE DIALOG oDlg CENTERED ;
      ON INIT oRec:PlaceControls( oPanel, oSayFont, oFixed, lReadOnly, lNavigate, cMsg ) ;
      VALID ( /* lExit .and. */  oRec:CloseMsg() )
   RELEASE FONT oFont, oFixed, oSayFont

   if ::cSrcType == 'XBR'
      ::uSource:SetFocus()
   elseif ::oBrw != nil
      ::oBrw:SetFocus()
   endif

return ::Modified()  // return value valid only for arrays

//----------------------------------------------------------------------------//

METHOD PlaceControls( oPanel, oSayFont, oFixed, lReadOnly, lNavigate, cMsg ) CLASS TDataRow

   local nItem, oSay, oGet, nGets := 0
   local nRow  := 20
   local nSayWidth, nGetWidth, nWidth
   local nMaxSayWidth   := 0
   local nMaxGetWidth   := 0
   local oDlg     := oPanel:oWnd
   local hDC      := oDlg:GetDC()
   local nPanelWidth, nPanelHeight

   for nItem := 1 to Len( ::aData )
      if ! ::FieldHide( nItem )
         nMaxSayWidth   := Max( nMaxSayWidth, GetTextWidth( hDC, ::aPrompts[ nItem ] + " :", oSayFont:hFont ) )
      endif
   next

   for nItem := 1 to Len( ::aData )
      if ! ::FieldHide( nItem )
         ::MakeOneGet( hDC, oPanel, @nRow, nItem, lReadOnly, oSayFont, oFixed, nMaxSayWidth, @nGetWidth )
         nMaxGetWidth   := Max( nMaxGetWidth, nGetWidth )
      endif
   next

   nGets    := 0
   for nItem := 2 to Len( oPanel:aControls ) STEP 2
      oGet     := oPanel:aControls[ nItem ]
      if oGet:ClassName() == "TMULTIGET"
         oGet:nWidth := nMaxSayWidth + 10 + nMaxGetWidth
      endif
      nGets++
   next
   oDlg:ReleaseDC()
   oPanel:SetRange()

   nPanelWidth    := Max( If( lNavigate, 400, 200 ), 20 + nMaxSayWidth + 10 + nMaxGetWidth + 20 + 24 )
   nPanelHeight   := Min(  Int( ScreenHeight() * 0.8 - 100 ), ;
                           ATail( oPanel:aControls ):nBottom + 20 )

   oDlg:SetCoors(   TRect():new(  0,  0, 40 + nPanelHeight + 100, 40 + nPanelWidth + 40  ) )
   oPanel:SetCoors( TRect():New( 40, 40, 40 + nPanelHeight,      40 + nPanelWidth       ) )
   oDlg:bPainted  := { || oDlg:Box( oPanel:nTop - 2, oPanel:nLeft - 1, oPanel:nBottom + 2, oPanel:nRight + 2 ) }

   if nPanelHeight >= ATail( oPanel:aControls ):nBottom
      oPanel:nScrollRange     := 0
      oPanel:oVScroll:SetRange( 0, 0 )
      oPanel:WinStyle( WS_VSCROLL, .f. )
   endif

   ::DlgButtons( oDlg, oPanel, lNavigate, lReadOnly, nGets )

   if ! Empty( cMsg )
      @ 06,00 SAY cValToChar( cMsg ) SIZE oDlg:nWidth, 20 PIXEL OF oDlg CENTER TRANSPARENT
   endif

   oDlg:Center()
   oPanel:aControls[ 2 ]:SetFocus()

return .f.

//----------------------------------------------------------------------------//

METHOD MakeOneGet( hDC, oPanel, nRow, nAt, lReadOnly, oSayFont, oFixed, nSayWidth, nGetWidth ) CLASS TDataRow

#define ROWHT  22
#define ROWGAP  4

   local oRec     := Self
   local aLine, oGet, bGet, bValid, bAction
   local lCheck, lCombo, lMemo, cType, cPic, cVal
   local lPassWord   := .f.
   local nCol     := 20 + nSayWidth + 10

   aLine       := AClone( ::aData[ nAt ] )
   ASize( aLine, 5 )
   DEFAULT aLine[ 3 ] := .t.

   if ValType( aLine[ 2 ] ) == 'B'
      bGet     := aLine[ 2 ]
      cType    := ValType( Eval( bGet ) )
   else
      cType       := ValType( IfNil( aLine[ 2 ], Space( 60 ) ) )
   endif

   lCheck      := ( cType == 'L' )
   lCombo      := ValType( aLine[ 4 ] ) == 'A'
   lMemo       := ( ValType( aLine[ 4 ] ) == 'C' .and. Upper( aLine[ 4 ] ) == 'M' )
   if ::lReadOnly .or. ( aLine[ 3 ] == .f. )
      lReadOnly   := .t.
   endif

   if lReadOnly
      DEFAULT bGet := { || IfNil( oRec:aData[ nAt, 2 ], Space( 60 ) ) }
   else
      if oRec:aData[ nAt, 2 ] == nil
         DEFAULT bGet := { |x| If( x == nil, IfNil( oRec:aData[ nAt, 2 ], Space( 60 ) ), ;
                           oRec:aData[ nAt, 2 ] := If( Empty( x ), nil, x ) ) }
      else
         DEFAULT bGet := bSETGET( oRec:aData[ nAt, 2 ] )
      endif
      bValid   := aLine[ 5 ]
   endif

   if ValType( aLine[ 4 ] ) == 'C' .and. Len( aLine[ 4 ] ) > 1
      cPic     := aLine[ 4 ]
   elseif ValType( Eval( bGet ) ) == 'N'
      cPic     := GetNumPict( Eval( bGet ) )
   endif
   if lMemo
      nGetWidth   := 360
   else
      if cType == 'C'
         cVal     := Replicate( 'W', Len( Eval( bGet ) ) )
         lPassword:= ( ValType( aLine[ 4 ] ) == 'L' .and. aLine[ 4 ] == .t. ) .or. ;
                     "PASSWORD" $ Upper( ::aPrompts[ nAt ] ) .or. ;
                     "PASSWORD" $ Upper( aLine[ 1 ] )
      else
         cVal     := Replicate( '9', Len( Transform( Eval( bGet ), cPic ) ) )
      endif
      if lCombo
         if ValType( aLine[ 4 ][ 1 ] ) == 'A'
            AEval( aLine[ 4 ], { |a| If( Len( a[ 2 ] ) > Len( cVal ), cVal := a[ 2 ], nil ) } )
         else
            AEval( aLine[ 4 ], { |c| If( Len( c ) > Len( cVal ), cVal := c, nil ) } )
         endif
         cVal     := Replicate( 'W', Len( cVal ) )
      endif
      nGetWidth   := GetTextWidth( hDc, cVal, oPanel:oFont:hFont ) + 20 + If( lCombo, 30, 0 )
      nGetWidth   := Min( 500, nGetWidth )
   endif

   if lMemo
      @ nRow, 20 SAY ::aPrompts[ nAt ] + " :" SIZE  nSayWidth,ROWHT PIXEL OF oPanel FONT oSayFont TRANSPARENT
   else
      @ nRow, 20 SAY ::aPrompts[ nAt ] + " :" SIZE  nSayWidth,ROWHT PIXEL OF oPanel FONT oSayFont RIGHT TRANSPARENT
   endif

   if lMemo
      oGet := ;
      TMultiGet():New( nRow + 22 + 4, 20, bGet, oPanel, 500, 4 * 22 + 3 * 4, oFixed, ;
         .F.,nil,nil,nil, .T.,nil, .t.,nil, .F., .F., lReadOnly, bValid, nil, .F., nil, nil )

   elseif lCheck
      oGet   := ;
      TCheckBox():new( nRow, nCol, "", bGet, oPanel, ROWHT,ROWHT, nil, ;
         bValid, oPanel:oFont, nil, nil, nil, ;
         .f., .t., nil, .t., nil )

   elseif lCombo
      if ValType( aLine[ 4 ][ 1 ] ) == 'A'
         oGet := ;
         TDBCombo():New( nRow, nCol, bGet, nil, nGetWidth, If( IsAppThemed(), ROWHT, 300 ), oPanel, nil, ;
             bValid, nil, nil, nil,;
             .t., oPanel:oFont, nil, .t., nil,;
             .f., nil, nil, ;
             aLine[ 4 ], '1', '2', NIL ) //<aList> )
      else
         oGet   := ;
         TComboBox():New( nRow, nCol, bGet, aLine[ 4 ], nGetWidth, If( IsAppThemed(), ROWHT, 300 ), ;
            oPanel, nil, ;
            bValid, nil, nil, nil, ;
            .T., oPanel:oFont, nil, .T., nil, ;
            .F., nil, nil, nil, ;
            nil, nil )
      endif
   else
      if Left( ::aPrompts[ nAT ], 4 ) == "nClr" .or. ;
         Left( ::aData[ nAt, 1 ], 4 ) == "nClr"
         bAction   := { |o| BtnChooseColor( o ) }
      endif
      oGet   := ;
      TGet():New( nRow, nCol, bGet, oPanel, nGetWidth,ROWHT, cPic, ;
               bValid, nil, nil, oPanel:oFont, .F., ;
               nil, .T., nil, .T., nil, ;
               .F., VALTYPE(EVAL(bGet)) $ "DNT", ;
               nil, lReadOnly, lPassword, .f., nil, nil, ;
               nil, nil, nil, nil, bAction )
      oGet:nClrTextDis  := CLR_BLACK
      oGet:nClrPaneDis  := GetSysColor( COLOR_BTNFACE )
      oGet:lDiscolors   := .f.
      if lPassWord
         oGet:WinStyle( ES_PASSWORD, .t. )
      endif
      oGet:WinStyle( ES_AUTOHSCROLL, .t. )
   endif

   nRow     += If( lMemo, 5, 1 ) * ( ROWHT + ROWGAP )

return nil

//----------------------------------------------------------------------------//

METHOD DlgButtons( oDlg, oPanel, lNavigate, lReadOnly, nGets ) CLASS TDataRow

   local oRec           := Self
   local oFont
   local nRow, nCol, oBtn
   local lCanNavigate   := !( ::cSrcType $ "ARR,HSH" )  .and. ! Empty( ::bGoTop )
   local lDataSource    := !( ::cSrcType $ "ARR,HSH" )
   local aBmp           := MakeBmpArray( ::cBmpList )

   nRow        := oPanel:nBottom + ROWHT
   nCol        := oPanel:nRight - 32

   if !lDataSource
      aBmp[ 1, 3 ]   :=  Chr(0xFC)
   endif

   oFont := TFont():New( "Wingdings", 0, -22, .f., .f., 0, 0, 400, .f., .f., .f., 2,3, 2, 1,, 18 )
   @ nRow, nCol BTNBMP oBtn FILE aBmp[ 1, 1 ] RESOURCE aBmp[ 1, 2 ] PROMPT aBmp[ 1, 3 ] SIZE 32,32 PIXEL OF oDlg FONT oFont ;
      TOOLTIP "Fechar" ACTION ( lExit := .t., oDlg:End() )
   if ! lDataSource
      oBtn:SetColor( CLR_GREEN, oBtn:nClrPane )
   endif
   if ! lReadOnly
      if lDataSource
         nCol  -= 36
         @ nRow, nCol BTNBMP FILE aBmp[ 2, 1 ] RESOURCE aBmp[ 2, 2 ] PROMPT aBmp[ 2, 3 ] SIZE 32,32 PIXEL OF oDlg FONT oFont ;
            TOOLTIP "Salvar" ACTION ( oRec:Save( .t. ), oPanel:Update(), oPanel:SetFocus() , lExit := .t., oDlg:End() ) ;
            WHEN oRec:Modified() .or. nGets < 2
      else
         nCol  -= 36
         @ nRow, nCol BTNBMP oBtn PROMPT Chr( 0xFB ) SIZE 32,32 PIXEL OF oDlg FONT oFont ;
            TOOLTIP "Cancelar" ACTION ( oRec:Undo(), lExit := .t., oDlg:End() )
         oBtn:SetColor( CLR_HRED, oBtn:nClrPane )
         oBtn:lCancel   := .t.
      endif
   endif

//   RELEASE FONT oFont
//   oFont := TFont():New( "Wingdings 3", 0, -22, .f., .f., 0, 0, 400, .f., .f., .f., 2,3, 2, 1,, 18 )
//   if ! lReadOnly
//      nCol  -= 36
//      @ nRow, nCol BTNBMP oBtn FILE aBmp[ 3, 1 ] RESOURCE aBmp[ 3, 2 ] PROMPT aBmp[ 3, 3 ] SIZE 32,32 PIXEL OF oDlg FONT oFont ;
//         TOOLTIP "UnDo" ACTION ( oRec:Undo(), oPanel:Update(), oPanel:SetFocus() ) WHEN oRec:Modified() .or. nGets < 2
//         oBtn:lCancel   := .t.
//      if lDataSource
//         nCol  -= 36
//         @ nRow, nCol BTNBMP oBtn FILE aBmp[ 4, 1 ] RESOURCE aBmp[ 4, 2 ] PROMPT aBmp[ 4, 3 ] SIZE 32,32 PIXEL OF oDlg FONT oFont ;
//            TOOLTIP "Refresh" ACTION ( oRec:Load( oRec:RecNo == 0 ), oPanel:Update(), oPanel:SetFocus() )
//         oBtn:lCancel   := .t.
//      endif
//   endif
//   RELEASE FONT oFont

//   if lNavigate .and. lCanNavigate
//      oFont := TFont():New( "Wingdings 3", 0, -22, .f., .f., 0, 0, 400, .f., .f., .f., 2,3, 2, 1,, 18 )
//      nCol  := oPanel:nLeft
//      @ nRow, nCol BTNBMP FILE aBmp[ 5, 1 ] RESOURCE aBmp[ 5, 2 ] PROMPT aBmp[ 5, 3 ] SIZE 32,32 PIXEL OF oDlg FONT oFont ;
//         TOOLTIP "GoTop" ACTION ( oRec:GoTop(), oPanel:Update() ) ;
//         WHEN ( oRec:CanGoUp() )
//      nCol  += 36
//      @ nRow, nCol BTNBMP FILE aBmp[ 6, 1 ] RESOURCE aBmp[ 6, 2 ] PROMPT aBmp[ 6, 3 ] SIZE 32,32 PIXEL OF oDlg FONT oFont ;
//         TOOLTIP "GoUp"   ACTION ( oRec:GoUp(), oPanel:Update() ) ;
//         WHEN ( oRec:CanGoUp() )
//      nCol  += 36
//      @ nRow, nCol BTNBMP FILE aBmp[ 7, 1 ] RESOURCE aBmp[ 7, 2 ] PROMPT aBmp[ 7, 3 ] SIZE 32,32 PIXEL OF oDlg FONT oFont ;
//         TOOLTIP "GoDown"   ACTION ( oRec:GoDown(), oPanel:Update() ) ;
//         WHEN ( oRec:CanGoDn() )
//      nCol  += 36
//      @ nRow, nCol BTNBMP FILE aBmp[ 8, 1 ] RESOURCE aBmp[ 8, 2 ] PROMPT aBmp[ 8, 3 ] SIZE 32,32 PIXEL OF oDlg FONT oFont ;
//         TOOLTIP "GoBottom"   ACTION ( oRec:GoBottom(), oPanel:Update() ) ;
//         WHEN ( oRec:CanGoDn() )
//      RELEASE FONT oFont

//      oFont := TFont():New( "Wingdings 2", 0, -22, .f., .f., 0, 0, 400, .f., .f., .f., 2,3, 2, 1,, 18 )
//      nCol  += 38
//      @ nRow, nCol BTNBMP FILE aBmp[ 9, 1 ] RESOURCE aBmp[ 9, 2 ] PROMPT aBmp[ 9, 3 ] SIZE 32,32 PIXEL OF oDlg FONT oFont ;
//         TOOLTIP "AddNew" ACTION ( oRec:Load( .t. ), oPanel:Update() ) ;
//         WHEN oRec:RecNo > 0
///*
//      nCol  += 36
//      @ nRow, nCol BTNBMP FILE aBmp[ 10, 1 ] RESOURCE aBmp[ 10, 2 ] PROMPT aBmp[ 10, 3 ] SIZE 32,32 PIXEL OF oDlg FONT oFont ;
//         TOOLTIP "Delete"
//*/
//      RELEASE FONT oFont
//   endif

return nil

//----------------------------------------------------------------------------//

METHOD EqualVal( x, y ) CLASS TDataRow

   local c, lEq := .f.

   x  := XEval( x )

   if Empty( x ) .and. y == nil
      return .t.
   endif

   if ( c := ValType( x ) ) == ValType( y )
      if c == 'C'
         lEq   := ( Trim( x ) == Trim( y ) )
      else
         lEq   := ( x == y )
      endif
   endif

return lEq

//----------------------------------------------------------------------------//

METHOD nomessage(...) CLASS TDataRow

   local cMsg     := __GetMessage()
   local lAssign  := Left( cMsg, 1 ) == '_'
   local nPos, uVal, e

   if lAssign
      cMsg := SubStr( cMsg, 2 )
   endif
   nPos  := ::FieldPos( cMsg )
   if nPos > 0
      if lAssign
         uVal                 := HB_AParams()[ 1 ]
/*
         if ! ::lTypeCheck .or. ( ValType( uVal ) == ValType( ::aData[ nPos, 2 ] ) )
            ::aData[ nPos, 2 ]   := uVal
         else
            return ::error(  HB_LangErrMsg( 33 ), ::className(), cMsg, 33, { uVal } )
         endif
*/
         return ::FieldPut( nPos, uVal )
      endif
      return ::FieldGet( nPos )  //::aData[ nPos, 2 ]
   endif
   _ClsSetError( _GenError( If( lAssign, 1005, 1004 ), ::ClassName(), cMsg ) )

return nil

//----------------------------------------------------------------------------//

PROCEDURE Destroy CLASS TDataRow

   ::End()

return

//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//

static function XbrAddNewRow( oBrw )

   local lAdded   := .f.
   local aNew

   SWITCH oBrw:nDataType
   case DATATYPE_RDD
      REPEAT
         ( oBrw:cAlias )->( DBAPPEND() )
      UNTIL ! NetErr()
      lAdded   := .t.
      exit
   case DATATYPE_ADO
      oBrw:oRs:AddNew()
      lAdded   := .t.
      exit
   case DATATYPE_ODBF
      oBrw:oDbf:Append()
      lAdded   := .t.
      exit
   case DATATYPE_ARRAY
      if oBrw:nLen > 0
         aNew     := AClone( oBrw:aArrayData[ oBrw:nLen ] )
         AEval( aNew, { |u,i| aNew[ i ] := BLANK( u ) } )
         AAdd( oBrw:aArrayData, aNew )
         oBrw:nLen++
         oBrw:nArrayAt  := Len( oBrw:aArrayData )
         oBrw:GoBottom()
         lAdded   := .t.
      endif
      exit
   END

return lAdded

//----------------------------------------------------------------------------//

static function XbrSaveNewRow( oBrw )

   local lSaved   := .f.

   SWITCH oBrw:nDataType
   case DATATYPE_RDD
      ( oBrw:cAlias )->( DBCOMMIT() )
      lSaved   := .t.
      exit
   case DATATYPE_ADO
      TRY
         oBrw:oRs:Update()
         lSaved   := .t.
      CATCH
         oBrw:oRs:CancelUpdate()
         FW_ShowAdoError( oBrw:oRs:ActiveConnection )
      END
      exit
   case DATATYPE_ODBF
      oBrw:oDbf:Save()
      lSaved   := .t.
      exit
   case DATATYPE_ARRAY
      lSaved   := .t.
      exit
   END

return lSaved

//----------------------------------------------------------------------------//

static function TrimList( cList )

   cList    := AllTrim( cList )

   do while ", " $ cList
      cList    := StrTran( cList, ", ", "," )
   enddo
   do while " ," $ cList
      cList    := StrTran( cList, " ,", "," )
   enddo

return cList

//----------------------------------------------------------------------------//

static function GetNumPict( n ); return NumPict( 11, GetDec( n ) )

//----------------------------------------------------------------------------//

static function GetDec( n )

   local nDec  := 0
   local c     := cValToChar( n )

   if '.' $ c
      nDec  := Len( AfterAtNum( '.', c ) )
   endif

return nDec

//----------------------------------------------------------------------------//

function MakeBmpArray( cList )

   local aBmp  := {}
   local aPrompts := { "close", "save", "undo", "redo", "top", "up", "down", "bottom", "new", "delete" }
   local cChar := Chr(0x30)+Chr(0x3C)+Chr(0x51)+Chr(0x50)+Chr(0x76)+Chr(0xD1)+Chr(0xD2)+Chr(0x77)+Chr(0x2F)+Chr(0x25)
//   local cChar := Chr(0xFC)+Chr(0x3C)+Chr(0x51)+Chr(0x50)+Chr(0x76)+Chr(0xD1)+Chr(0xD2)+Chr(0x77)+Chr(0x2F)+Chr(0x25)
   local n, cBmp

   DEFAULT cList  := ""
   for n := 1 to Len( aPrompts )
      cBmp  := ExtractBmp( aPrompts[ n ], cList )
      if Empty( cBmp )
         AAdd( aBmp, { nil, nil, SubStr( cChar, n, 1 ) } )
      else
         AAdd( aBmp, { If( '.' $ cBmp, cBmp, nil ), If( '.' $ cBmp, nil, cBmp ), nil } )
      endif
   next

return aBmp

//----------------------------------------------------------------------------//

function ExtractBmp( cPrompt, cList )

   local cBmp
   local nAt

   if ( nAt := At( Upper( cPrompt ) + '=', Upper( cList ) ) ) > 0
      cList    := StrTran( SubStr( cList, nAt + Len( cPrompt ) + 1 ), ';', ',' )
      if ( nAt := At( ',', cList ) ) > 0
         cList := Left( cList, nAt - 1 )
      endif
      cBmp     := AllTrim( cList )
   endif

return cBmp

//----------------------------------------------------------------------------//

function BtnChooseColor(...)

   local aParams  := HB_AParams()
   local uREt, nClr
   local oGet, oCol

   if Len( aParams ) > 0
      if ValType( aParams[ 1 ] ) == 'O' .and. aParams[ 1 ]:IsKindOf( "TGET" )
         oGet     := aParams[ 1 ]
      elseif Len( aParams ) >= 4 .and. ValType( aParams[ 3 ] ) == 'O' .and. ;
         aParams[ 3 ]:IsKindOf( "TXBRWCOLUMN" )
         oCol     := aParams[ 3 ]
      elseif ValType( aParams[ 1 ] ) == 'N'
         nClr     := aParams[ 1 ]
      endif
   endif

   uRet     := ChooseColor( nClr )
   if uRet == 0
      uRet  := nil
   else
      if oGet != nil
         if ValType( oGet:oGet:VarGet() ) == 'C'
            oGet:cText     := cClrToCode( uRet )
         else
            oGet:cText     := uRet
         endif
      elseif oCol != nil
         if ValType( oCol:Value ) == 'C'
            uRet     := cClrToCode( uRet )
         endif
      elseif nClr == nil
         uRet     := cClrToCode( uRet )
      endif
   endif

return uRet

//----------------------------------------------------------------------------//

