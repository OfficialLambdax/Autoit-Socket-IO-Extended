#cs
	_UT_Assert(Const $bool, Const $msg = "Assert Failure", Const $erl = @ScriptLineNumber)

	_UT_Is($x1, $is, $x2, $bStrict = True)
	_UT_ArrayElementCountIs($x1, $is, $x2)
	_UT_ArrayContentIsEqual($x1, $x2, $bStrict = True)

	_UT_CompileAndRun($sPath, $nInstances = 1, $p1...$p10 = Default); if instances is > 1 then an array will be returned with pids

	_UT_SetNamespace($sNamespace); Only works if @compiled = 1
	_UT_Has($sKey, $sNamespace = $___g_UT_RunningNamespace)
	_UT_Set($sKey, $sVal, $sNamespace = $___g_UT_RunningNamespace)
	_UT_Get($sKey, $sDefault = Null, $sNamespace = $___g_UT_RunningNamespace)

#ce


Func testVartypeTranslation()

	; Test array validoty
	Local $array1 = [1, 2, 'String', 22.51, ptr(25), Binary("0x00204060"), -5, 0x5, Null]
	Local $array2 = [12930219083, "string", $array1, 3.14213892178217895943490578340578349587348957934057889345, "", StringSplit("a|b|c|", "|")]
	Local $test_array = [ptr(213213), 125125.2525, 123213, 'string string||||)("#="#)#)=", "xDDDD!!=)"!?=)#?="!)?=)#?=)', $array2, -2590, 12893238923789238, binary(0.2)]

	Local $transported_array = __Io_stringary2data(__Io_data2stringary($test_array))


	_UT_Assert(_UT_ArrayContentIsEqual($test_array, $transported_array), "__Io_stringary2data did not transport as expected")

EndFunc

Func testPackageHandling()

	Local Const $Transported_Package = "0x546573744576656E740A496E7433327C313233340A537472696E677C30783733373437323639364536370A496E7433327C350A496E7436347C393939393939393939393939390A4B6579776F72647C0A5074727C307830303030303044350A426F6F6C3A66616C73657C46616C73650A426F6F6C3A747275657C5472756523"

	Local $sEventName = "TestEvent"
	Local $aParams = [1234, "string", 5,  9999999999999, Null, Ptr(213), False, 1==1]
	Local $nParams = UBound($aParams) + 2;+2 Because this function relies on @NumParams and not Ubound

	Local $created_package = StringToBinary(__Io_createPackage($sEventName, $aParams, $nParams))

	; Since our test is a string, we loose-match this one
	_UT_Assert(_UT_Is($Transported_Package, "equal", $created_package, False), '$created_package package is wrong')


	; Try to unpack our package
	Local $recvd_package = BinaryToString($created_package)
	Local $aProducts = __Io_getProductsFromPackage($recvd_package)

	_UT_Assert(IsArray($aProducts), '__Io_getProductsFromPackage did not return an array')

	if IsArray($aProducts) Then
		Local $aProduct = $aProducts[1]
		Local $sEventName2 = $aProduct[0]
		Local $aParams2 = $aProduct[1]

		_UT_Assert(_UT_Is($sEventName, "equal", $sEventName2))

		_UT_Assert(_UT_Is($aParams[0], "equal", $aParams2[1]))
		_UT_Assert(_UT_Is($aParams[1], "equal", $aParams2[2]))
		_UT_Assert(_UT_Is($aParams[2], "equal", $aParams2[3]))
		_UT_Assert(_UT_Is($aParams[3], "equal", $aParams2[4]))
		_UT_Assert(_UT_Is($aParams[4], "equal", $aParams2[5]))
		_UT_Assert(_UT_Is($aParams[5], "equal", $aParams2[6]))
		_UT_Assert(_UT_Is($aParams[6], "equal", $aParams2[7]))
		_UT_Assert(_UT_Is($aParams[7], "equal", $aParams2[8]))

	EndIf

EndFunc

Func testFireEvents()
	Global $__g_io_events[1000] = [0]
	; Register event
	Local $socketConnectOrListen = 0xB00B5

	__Io_Push3x($__g_io_events, "this:_sho uld-.be:OK", test_fakeCallback, $socketConnectOrListen)

	Local $socket = 0xB00B5
	Local $aParams = [1, 'test']
	Local $parentSocket = $socketConnectOrListen
	_UT_Assert(__Io_FireEvent($socket, $aParams, 'this:_sho uld-.be:OK', $parentSocket))
EndFunc

Func test_fakeCallback($socket, $string)
	_UT_Assert(_UT_IS($socket, "equal", 0xB00B5))
	_UT_Assert(_UT_IS($string, "equal", "test"))
EndFunc

Func test_banning()
	; Create some space
	Global $__g_io_aBanlist[6] = [0]; This is essentially what the _Io_listen invokes
	Local Const $ip = @IPAddress1

	_Io_Ban($ip)

	_UT_Assert(_UT_IS(_Io_IsBanned($ip), "lesser", 1), "Failed to add " & $ip & " to banlist")
	_Io_Sanction($ip)

	_UT_Assert(_UT_IS(_Io_IsBanned($ip), "equal", False), $ip & " was never removed from banlist.")


EndFunc

Func test_misc()


	Global $__g_io_sockets[10000] = [0]
	Local $nSocketsToAdd = 16

	For $i = 1 To $nSocketsToAdd
		__Io_createFakeSocket()
	Next

	Local $nSockets = _Io_getSocketsCount()

	_UT_Assert(_UT_IS($nSockets, 'equal', $nSocketsToAdd), 'The fake socket count is not equal to what _Io_getSocketsCount says...')


EndFunc

Func test_postAndPrescript($mock = Null, $mock2 = Null)
	#forceref $mock, $mock2
	_Io_setEventPreScript(test_postAndPrescript)
	_Io_setEventPostScript(test_postAndPrescript)

	_UT_Assert(IsFunc($__g_Io_fPreScript))
	_UT_Assert(IsFunc($__g_Io_fPostScript))

EndFunc

Func test_public_basic_ClientServer()
	Local Const $MessageToSendFromServerToClient = "Hi again!"
	Local $timer = TimerInit(), $timeout = False
	; Build and compile a server and a client
	Local $iServer = _UT_CompileAndRun("Tests_Server.au3", 1, $MessageToSendFromServerToClient)
	Local $iClient = _UT_CompileAndRun("Tests_Client.au3")


	While ProcessExists($iServer) and ProcessExists($iClient)
		if TimerDiff($timer) > 10000 Then
			$timeout = True
			ExitLoop
		EndIf
	WEnd
	ProcessClose($iClient)
	ProcessClose($iServer)

	; Only to make this easier to read.
	Local Const $bStrict = False

	_UT_Assert(Not $timeout, 'A occurred occured when waiting for server and client to shutdown')

	_UT_Assert(_UT_Is(_UT_GET("@server client connected to server", False), "equal", True, $bStrict))
	_UT_Assert(_UT_Is(_UT_GET("@server client disconnected from server", False), "equal", False, $bStrict))
	_UT_Assert(_UT_Is(_UT_GET("@server server recvd message from client", False), "equal", True, $bStrict))
	_UT_Assert(_UT_Is(_UT_GET("@server server started", False), "equal", True, $bStrict))
	_UT_Assert(_UT_Is(_UT_GET("@client client connected to server", True), "equal", True, $bStrict))
	_UT_Assert(_UT_Is(_UT_GET("@client client disconnected from server", False), "equal", True, $bStrict))
	_UT_Assert(_UT_Is(_UT_GET("@client client recvd message from server", True), "equal", True, $bStrict))
	_UT_Assert(_UT_Is($MessageToSendFromServerToClient, "equal", _UT_Get("@welcome message")), "The message sent from server could not be read properly")

EndFunc


Func test_public_basic_ClientServer_With_Encryption()
	Local Const $MessageToSendFromServerToClient = "Hi again!"
	Local $timer = TimerInit(), $timeout = False
	_UT_Cleanup()

	; Create some key
	FileDelete("key.txt")
	FileWrite("key.txt", _Crypt_DeriveKey("My super Secret password", $CALG_AES_256))

	Local $iServer = _UT_CompileAndRun("Tests_Encrypt_Server.au3", 1, $MessageToSendFromServerToClient)
	Local $iClient = _UT_CompileAndRun("Tests_Encrypt_Client.au3")

	While ProcessExists($iServer) and ProcessExists($iClient)
		if TimerDiff($timer) > 10000 Then
			$timeout = True
			ExitLoop
		EndIf
	WEnd

	ProcessClose($iClient)
	ProcessClose($iServer)

	_UT_Assert(Not $timeout, 'A timeout occurred when waiting for server and client to shutdown')
	_UT_Assert(_UT_Is($MessageToSendFromServerToClient, "equal", _UT_Get("@welcome message")), "The message sent from server could not be read properly")

EndFunc

#include <Array.au3>

Func test_Public_Broadcast_ToMultiple_Clients()

	; Because this is a Broadcast and not a Broadcast TO ALL\Emit, this will cause our script only to ignore the7 first client only). So were testing
	Local Const $cnClientsToStart = 25
	Local $timer = TimerInit(), $timeout = False
	_UT_Cleanup()

	Local $iServer = _UT_CompileAndRun("Tests_Server2.au3", 1, $cnClientsToStart, "broadcast"); We pass the amount, so we can exit the server when we hit that amount
	Local $iClients = _UT_CompileAndRun("Tests_Client2.au3",  $cnClientsToStart);

	While ProcessExists($iServer)
		if TimerDiff($timer) > 10000 Then
			$timeout = True
			ExitLoop
		EndIf
	WEnd

	ProcessClose($iServer)

	; It has to be exactly 1 failure here
	Local $nMaxFailures = 0
	For $i = 1 To $iClients[0]
		Local $nPid = $iClients[$i]
		ProcessClose($nPid)
		Local $bHasPid = _UT_Has($nPid)

		If Not $bHasPid Then $nMaxFailures+=1
	Next

	_UT_Assert(_UT_Is($nMaxFailures, "equal or greater", 1), 'The broadcast should only cause exactly 1 failures, instead ' & $nMaxFailures & " were caused")

	_UT_Assert(Not $timeout, 'A timeout occurred when waiting for server or client to shutdown')
EndFunc


Func test_Public_Broadcast_To_All_Clients()

	; This is the exact same test as above but this one uses BroadcastToAll instead of just the regular Broadcast and the error-rate has to be exactly 0
	; Because this is a Broadcast and not a Broadcast TO ALL\Emit, this will cause our script only to ignore the7 first client only). So were testing
	Local Const $cnClientsToStart = 25
	Local $timer = TimerInit(), $timeout = False
	_UT_Cleanup()

	Local $iServer = _UT_CompileAndRun("Tests_Server2.au3", 1, $cnClientsToStart, "broadcast to all"); We pass the amount, so we can exit the server when we hit that amount
	Local $iClients = _UT_CompileAndRun("Tests_Client2.au3",  $cnClientsToStart);

	While ProcessExists($iServer)
		if TimerDiff($timer) > 10000 Then
			$timeout = True
			ExitLoop
		EndIf
	WEnd

	ProcessClose($iServer)

	; It has to be exactly 1 failure here
	Local $nMaxFailures = 0
	For $i = 1 To $iClients[0]
		Local $nPid = $iClients[$i]
		ProcessClose($nPid)
		Local $bHasPid = _UT_Has($nPid)

		If Not $bHasPid Then $nMaxFailures+=1
	Next

	_UT_Assert(_UT_Is($nMaxFailures, "equal", 0), 'The broadcast should only cause exactly 0 failures, instead ' & $nMaxFailures & " were caused")

	_UT_Assert(Not $timeout, 'A timeout occurred when waiting for server or client to shutdown')
EndFunc

Func test_public_BroadCast_to_subscriptions()

	; Because this is a Broadcast and not a Broadcast TO ALL\Emit, this will cause our script only to ignore the7 first client only). So were testing
	Local Const $cnClientsToStart = 4
	Local $timer = TimerInit(), $timeout = False
	_UT_Cleanup()

	Local $iServer = _UT_CompileAndRun("Tests_Subscriptions_Server.au3")
	Local $iClients = _UT_CompileAndRun("Tests_Subscriptions_Client.au3",  $cnClientsToStart);

	While ProcessExists($iServer)
		if TimerDiff($timer) > 10000 Then
			$timeout = True
			ExitLoop
		EndIf
	WEnd

	ProcessClose($iServer)


	Local $helloAs = 0
	Local $helloBs = 0
	For $i = 1 To $iClients[0]
		Local $nPid = $iClients[$i]
		ProcessClose($nPid)
		Local $sData = _UT_Get($nPid)

		If $sData == "Hello from Room A" Then $helloAs +=1
		If $sData == "Hello from Room B" Then $helloBs +=1

	Next

	_UT_Assert(_UT_Is($helloAs, "equal", 2), 'Did not get broadcasts from Room A')
	_UT_Assert(_UT_Is($helloBs, "equal", 2), 'Did not get broadcasts from Room B')

	_UT_Assert(Not $timeout, 'A timeout occurred when waiting for server or client to shutdown')
EndFunc


Func test_public_TidyUp()
	Local Const $nMax = 100
	Local $timer = TimerInit(), $timeout = False
	_UT_Cleanup()


	Local $iServer = _UT_CompileAndRun("Tests_Tidyup_Server.au3", 1, $nMax); The second parameter will se the Maximum sockets
	_UT_CompileAndRun("Tests_Subscriptions_Client.au3",  $nMax);


	While ProcessExists($iServer)
		if TimerDiff($timer) > 40000 Then
			$timeout = True
			ExitLoop
		EndIf
	WEnd

	If $timeout Then
		_UT_Assert(False, 'A timeout occurred when waiting for server or server to shutdown')
	EndIf


	_UT_Assert(_UT_Is(_UT_Get('_Io_getDeadSocketCount'), 'equal', 0, False), 'Automatic tidyup did not work correctly')

EndFunc