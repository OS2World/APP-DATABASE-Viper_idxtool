/*:VRX         Main
*/
/*  Main
*/
Main:
/*  Process the arguments.
    Get the parent window.
*/
    parse source . calledAs .
    parent = ""
    argCount = arg()
    argOff = 0
    if( calledAs \= "COMMAND" )then do
        if argCount >= 1 then do
            parent = arg(1)
            argCount = argCount - 1
            argOff = 1
        end
    end; else do
        call VROptions 'ImplicitNames'
        call VROptions 'NoEchoQuit'
    end
    InitArgs.0 = argCount
    if( argCount > 0 )then do i = 1 to argCount
        InitArgs.i = arg( i + argOff )
    end
    drop calledAs argCount argOff

/*  Load the windows
*/
    call VRInit
    parse source . . spec
    _VREPrimaryWindowPath = ,
        VRParseFileName( spec, "dpn" ) || ".VRW"
    _VREPrimaryWindow = ,
        VRLoad( parent, _VREPrimaryWindowPath )
    drop parent spec
    if( _VREPrimaryWindow == "" )then do
        call VRMessage "", "Cannot load window:" VRError(), ,
            "Error!"
        _VREReturnValue = 32000
        signal _VRELeaveMain
    end

/*  Process events
*/
    call Init
    signal on halt
    do while( \ VRGet( _VREPrimaryWindow, "Shutdown" ) )
        _VREEvent = VREvent()
        interpret _VREEvent
    end
_VREHalt:
    _VREReturnValue = Fini()
    call VRDestroy _VREPrimaryWindow
_VRELeaveMain:
    call VRFini
exit _VREReturnValue

VRLoadSecondary:
    __vrlsWait = abbrev( 'WAIT', translate(arg(2)), 1 )
    if __vrlsWait then do
        call VRFlush
    end
    __vrlsHWnd = VRLoad( VRWindow(), VRWindowPath(), arg(1) )
    if __vrlsHWnd = '' then signal __vrlsDone
    if __vrlsWait \= 1 then signal __vrlsDone
    call VRSet __vrlsHWnd, 'WindowMode', 'Modal' 
    __vrlsTmp = __vrlsWindows.0
    if( DataType(__vrlsTmp) \= 'NUM' ) then do
        __vrlsTmp = 1
    end
    else do
        __vrlsTmp = __vrlsTmp + 1
    end
    __vrlsWindows.__vrlsTmp = VRWindow( __vrlsHWnd )
    __vrlsWindows.0 = __vrlsTmp
    do while( VRIsValidObject( VRWindow() ) = 1 )
        __vrlsEvent = VREvent()
        interpret __vrlsEvent
    end
    __vrlsTmp = __vrlsWindows.0
    __vrlsWindows.0 = __vrlsTmp - 1
    call VRWindow __vrlsWindows.__vrlsTmp 
    __vrlsHWnd = ''
__vrlsDone:
return __vrlsHWnd

/*:VRX         CloseDatabase
*/
CloseDatabase: 

status = RxViperCloseDatabase(database)
if status <> 1 then
Do
    Buttons.1 = "OK"
    Buttons.0 = 1
    id = VRMessage( VRWindow(), "Can not close database", "VIPER Database Engine Error", "Error", "Buttons.", OK, OK )
    
End
return status
/*:VRX         DeleteIndexBtn_Click
*/
DeleteIndexBtn_Click: 

selectedstring = VRGet( "IndexList", "SelectedString" )
status = OpenDatabase() /* Open the database */
if status = 1 then
Do
    status = RxViperDestroyIndex(database, selectedstring)
    if status <> 1 then 
    Do          /* Could not destroy index! */
        Buttons.1 = "OK"
        Buttons.0 = 1
        id = VRMessage( VRWindow(), "Can not delete index", "VIPER Database Engine Error", "Error", "Buttons.", OK, OK )
        status = CloseDatabase()
    End
    Else
    Do      /* Successfully destroyed database index!  */
        ok = VRMethod( "IndexList", "DeleteString", selectedstring )

        ok = VRMethod( "IndexFields", "Clear" )
        status = CloseDatabase()
    End
End
else
    return

return

/*:VRX         Fini
*/
Fini:
    window = VRWindow()
    call VRSet window, "Visible", 0
    drop window
return 0

/*:VRX         GetIndexStructure
*/
GetIndexStructure: 

status =  OpenDatabase()
if status = 0 then
    return

status = RxViperGetIndexNames(database, IndexNames.)

ok = VRMethod( "IndexList", "Clear" )
ok = VRMethod( "IndexFields", "Clear" )


if status = 1 then
Do
    ok = VRMethod( "IndexList", "AddStringList", "IndexNames.",  )
    ok = VRSet( "NewIndexBtn", "Enabled", 1 )
    ok = VRSet( "DeleteIndexBtn", "Enabled", 1 )
End    
Else
Do    
    Buttons.1 = "OK"
    Buttons.0 = 1
    id = VRMessage( VRWindow(), "Can not read database index structure", "VIPER Database Engine Error", "Error", "Buttons.", OK, OK )
    
End    

status = CloseDatabase()

return

/*:VRX         Halt
*/
Halt:
    signal _VREHalt
return

/*:VRX         IndexFields_Click
*/
IndexFields_Click: 

return

/*:VRX         IndexList_Click
*/
IndexList_Click: 
ok = VRMethod( "IndexFields", "Clear" )

selectedstring = VRGet( "IndexList", "SelectedString" )



status = RxViperOpenDatabase(database)
status = RxViperGetIndexDescription(database, selectedstring, IndexFields.)
ok = VRMethod( "IndexFields", "AddStringList", "IndexFields.",  )
status = RxViperCloseDatabase(database)

return
/*:VRX         Init
*/
Init:
    window = VRWindow()
    call VRMethod window, "CenterWindow"
    call VRSet window, "Visible", 1
    call VRMethod window, "Activate"
    drop window
return

/*:VRX         MNU_Database_Click
*/
MNU_Database_Click:
 
FileName = VRFileDialog( VRWindow(), "Select database", "Open", "*.db", , ,  )
if FileName <> "" then
Do
ok = VRMethod( "IndexList", "Clear" )

ok = VRSet( "IndexList", "Enabled", 1 )

/* look to see if FileName string contains an extension */
position  = Pos( ".", FileName, "1" )
if position <> 0 then
Do
    length  = Length( FileName )
    length = length - 3
    database  = Left( FileName, length, ' ')
End
Else
    database = FileName


/* ok = VRSet( "IndexFields", "Enabled", 1 )  */


call GetIndexStructure


End
return

/*:VRX         MNU_Help_Click
*/
MNU_Help_Click: 

return

/*:VRX         MNU_HelpProductInfo_Click
*/
MNU_HelpProductInfo_Click: 

    call PrdInfo VRWindow()
return

/*:VRX         NewIndexBtn_Click
*/
NewIndexBtn_Click: 

    call Newidx VRWindow(), database

    call GetIndexStructure
return

/*:VRX         OpenDatabase
*/
OpenDatabase: 

status = RxViperOpenDatabase(database)
if status <> 1 then
Do
    Buttons.1 = "OK"
    Buttons.0 = 1
    id = VRMessage( VRWindow(), "Can not open database", "VIPER Database Engine Error", "Error", "Buttons.", OK, OK )
  
End

return status

/*:VRX         Quit
*/
Quit:
    window = VRWindow()
    call VRSet window, "Shutdown", 1
    drop window
return

/*:VRX         Window1_Close
*/
Window1_Close:

    call SysDropFuncs
    call Quit
return

/*:VRX         Window1_Create
*/
Window1_Create: 

/* Register the VIPER Database Engine functions... */
rc = RxFuncAdd("SysLoadFuncs","Viper", "SysLoadFuncs")
call SysLoadFuncs



return

