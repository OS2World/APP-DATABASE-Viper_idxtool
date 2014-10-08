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

/*:VRX         CancelBtn_Click
*/
CancelBtn_Click: 

    call Quit
return

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

/*:VRX         CreateIndexBtn_Click
*/
CreateIndexBtn_Click: 

    IndexName = VRGet( "EF_1", "Value" )
    ok = VRMethod( "IndexList", "GetStringList", "IndexFields." )
    
    status = OpenDatabase()
    if status = 0 then
        return

    status = RxViperCreateIndex(database,IndexName,IndexFields.)
    if status <> 1 then
    Do
        Buttons.1 = "OK"
        Buttons.0 = 1
        id = VRMessage( VRWindow(), "Could not create index", "VIPER Database Engine Error", "Error", "Buttons.", OK, OK )
        status = CloseDatabase()        
    End
    Else
    Do
        status = CloseDatabase()
        call Quit
    End
    

return

/*:VRX         DatabaseList_DragDrop
*/
DatabaseList_DragDrop: 

SourceIndex = VRInfo("SourceIndex")
if SourceIndex <> 0 then
Do
    selectedfield = VRMethod( "IndexList", "GetString", SourceIndex )
    ok = VRMethod( "IndexList", "DeleteString", selectedfield )
    ok = VRMethod( "DatabaseList", "Clear" )
    ok = VRMethod( "DatabaseList", "AddStringList", "Fields.",  )
    ok = VRMethod( "IndexList", "GetStringList", "CurrentIndexFields." )

    do index = 1 to CurrentIndexFields.0
        ok = VRMethod( "DatabaseList", "DeleteString", CurrentIndexFields.index )
    
    end
End

return

/*:VRX         EF_1_Change
*/
EF_1_Change: 
value = VRGet( "EF_1", "Value" )
if value <> "" then
    ok = VRSet( "CreateIndexBtn", "Enabled", 1 )
else
    ok = VRSet( "CreateIndexBtn", "Enabled", 0 )    
return

/*:VRX         Fini
*/
Fini:
    window = VRWindow()
    call VRSet window, "Visible", 0
    drop window
return 0

/*:VRX         Halt
*/
Halt:
    signal _VREHalt
return

/*:VRX         IndexList_DragDrop
*/
IndexList_DragDrop: 

SourceIndex = VRInfo("SourceIndex")
TargetIndex = VRInfo("TargetIndex")
ok = VRMethod( "IndexList", "GetStringList", "IndexFields." )

if IndexFields.0 <> 0 & TargetIndex = 0 then
    TargetIndex = IndexFields.0 + 1

if IndexFields.0 = 0 & TargetIndex = 0 then
    TargetIndex = 1


selectedfield = VRMethod( "DatabaseList", "GetString", SourceIndex )
ok = VRMethod( "DatabaseList", "DeleteString", selectedfield )

position = VRMethod( "IndexList", "AddString", selectedfield, TargetIndex )

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

/*:VRX         Newidx_Close
*/
Newidx_Close:
    call Quit
return

/*:VRX         Newidx_Create
*/
Newidx_Create: 

database = InitArgs.1

title = 'Create new index for ' || database

ok = VRSet(VRWindow(), "Caption", title)

status = OpenDatabase()
if status = 0 then
    call Quit

status = RxViperGetFieldNames(database, Fields.)
if status = 1 then
Do
    ok = VRMethod( "DatabaseList", "Clear" )
    
    ok = VRMethod( "DatabaseList", "AddStringList", "Fields.",  )
    
End
Else
Do
    Buttons.1 = "OK"
    Buttons.0 = 1
    id = VRMessage( VRWindow(), "Can not read database field structure", "VIPER Database Engine Error", "Error", "Buttons.", OK, OK )
    call Quit
End    

status = CloseDatabase()
if status = 0 then
    call Quit
 


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

