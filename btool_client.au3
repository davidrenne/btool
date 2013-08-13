#NoTrayIcon
#include <GUIConstantsEx.au3>
#include <Array.au3>

StartBossToolClient()

Func StartBossToolClient()
    ; Set Some reusable info
    ; Set your Public IP address (@IPAddress1) here.
    ;   Local $szServerPC = @ComputerName
    ;   Local $szIPADDRESS = TCPNameToIP($szServerPC)
    Local $szIPADDRESS = @IPAddress1
    Local $nPORT = 33891
    Local $MainSocket, $ConnectedSocket, $szIP_Accepted
    Local $msg, $recv

    ; Start The TCP Services
    ;==============================================
    TCPStartup()

    ; Create a Listening "SOCKET".
    ;   Using your IP Address and Port 33891.
    ;==============================================
    $MainSocket = TCPListen($szIPADDRESS, $nPORT)

    ; If the Socket creation fails, exit.
    If $MainSocket = -1 Then Exit

    ; Initialize a variable to represent a connection
    ;==============================================
    $ConnectedSocket = -1


    ;Wait for and Accept a connection
    ;==============================================
    Do
        $ConnectedSocket = TCPAccept($MainSocket)
    Until $ConnectedSocket <> -1


    ; Get IP of client connecting
    $szIP_Accepted = SocketToIP($ConnectedSocket)

    ; GUI Message Loop
    ;==============================================
    While 1
        $msg = GUIGetMsg()

        ; GUI Closed
        ;--------------------
        If $msg = $GUI_EVENT_CLOSE Then ExitLoop

        ; Try to receive (up to) 2048 bytes
        ;----------------------------------------------------------------
        $recv = TCPRecv($ConnectedSocket, 2048)

        ; If the receive failed with @error then the socket has disconnected
        ;----------------------------------------------------------------
        If @error Then
			ExitLoop
		EndIf

        ; convert from UTF-8 to AutoIt native UTF-16
        $recv = BinaryToString($recv, 4)

		If StringStripWS($recv,3) = 'BOSS_COMING' Then
			$hFilesFolders = _FileListToArrayEx(@WorkingDir & '\btool_sounds\', '*.wav; *.mp3')
			_ArrayRandom($hFilesFolders)
			SoundPlay($hFilesFolders[1])
		EndIf
    WEnd


    If $ConnectedSocket <> -1 Then TCPCloseSocket($ConnectedSocket)
    TCPShutdown()

	;start over to wait for a new connection again because the server executable was closed.
	ShellExecute("btool_client.exe")
	Exit
EndFunc   ;==>StartBossToolClient

; Function to return IP Address from a connected socket.
;----------------------------------------------------------------------
Func SocketToIP($SHOCKET)
    Local $sockaddr, $aRet

    $sockaddr = DllStructCreate("short;ushort;uint;char[8]")

    $aRet = DllCall("Ws2_32.dll", "int", "getpeername", "int", $SHOCKET, _
            "ptr", DllStructGetPtr($sockaddr), "int*", DllStructGetSize($sockaddr))
    If Not @error And $aRet[0] = 0 Then
        $aRet = DllCall("Ws2_32.dll", "str", "inet_ntoa", "int", DllStructGetData($sockaddr, 3))
        If Not @error Then $aRet = $aRet[0]
    Else
        $aRet = 0
    EndIf

    $sockaddr = 0

    Return $aRet
EndFunc   ;==>SocketToIP



Func _ArrayRandom(ByRef $avArray, $iStart=0, $iEnd=0)
	If Not IsArray($avArray) Then Return SetError(1,0,0)

	Local $iRow, $iCol, $rRow, $Temp, $numCols = UBound($avArray,2), $Ubound = UBound($avArray) -1

	; Bounds checking
	If $iEnd < 1 Or $iEnd > $UBound Then $iEnd = $UBound
	If $iStart < 0 Then $iStart = 0
	If $iStart > $iEnd Then Return SetError(2, 0, 0)

	;	for 2 dimentional arrays:
	If $numCols Then
		For $iRow = $iStart To $iEnd ;for each row...
			$rRow = Random($iStart, $iEnd, 1) ;...select a random row
			For $iCol = 0 To $numCols -1	;swich the values for each cell in the rows
				$Temp = $avArray[$iRow][$iCol]
				$avArray[$iRow][$iCol] = $avArray[$rRow][$iCol]
				$avArray[$rRow][$iCol] = $Temp
			Next
		Next

	;	for 1 dimentional arrays:
	Else
		For $iRow = $iStart To $iEnd ;for each cell...
			$rRow = Random($iStart, $iEnd, 1) ;...select a random cell
			$Temp = $avArray[$iRow]	;switch the values in the cells
			$avArray[$iRow] = $avArray[$rRow]
			$avArray[$rRow] = $Temp
		Next
	EndIf
	Return 1
EndFunc


Func _FileListToArrayEx($s_path, $s_mask = "*.*", $i_flag = 0, $s_exclude = -1, $f_recurse = True, $f_full_path = True)

    If FileExists($s_path) = 0 Then Return SetError(1, 1, 0)

    ; Strip trailing backslash, and add one after to make sure there's only one
    $s_path = StringRegExpReplace($s_path, "[\\/]+\z", "") & "\"

    ; Set all defaults
    If $s_mask = -1 Or $s_mask = Default Then $s_mask = "*.*"
    If $i_flag = -1 Or $i_flag = Default Then $i_flag = 0
    If $s_exclude = -1 Or $s_exclude = Default Then $s_exclude = ""

    ; Look for bad chars
    If StringRegExp($s_mask, "[/:><\|]") Or StringRegExp($s_exclude, "[/:><\|]") Then
        Return SetError(2, 2, 0)
    EndIf

    ; Strip leading spaces between semi colon delimiter
    $s_mask = StringRegExpReplace($s_mask, "\s*;\s*", ";")
    If $s_exclude Then $s_exclude = StringRegExpReplace($s_exclude, "\s*;\s*", ";")

    ; Confirm mask has something in it
    If StringStripWS($s_mask, 8) = "" Then Return SetError(2, 2, 0)
    If $i_flag < 0 Or $i_flag > 2 Then Return SetError(3, 3, 0)

    ; Validate and create path + mask params
    Local $a_split = StringSplit($s_mask, ";"), $s_hold_split = ""
    For $i = 1 To $a_split[0]
        If StringStripWS($a_split[$i], 8) = "" Then ContinueLoop
        If StringRegExp($a_split[$i], "^\..*?\..*?\z") Then
            $a_split[$i] &= "*" & $a_split[$i]
        EndIf
        $s_hold_split &= '"' & $s_path & $a_split[$i] & '" '
    Next
    $s_hold_split = StringTrimRight($s_hold_split, 1)
    If $s_hold_split = "" Then $s_hold_split = '"' & $s_path & '*.*"'

    Local $i_pid, $s_stdout, $s_hold_out, $s_dir_file_only = "", $s_recurse = "/s "
    If $i_flag = 1 Then $s_dir_file_only = ":-d"
    If $i_flag = 2 Then $s_dir_file_only = ":D"
    If Not $f_recurse Then $s_recurse = ""

    $i_pid = Run(@ComSpec & " /c dir /b " & $s_recurse & "/a" & $s_dir_file_only & " " & $s_hold_split, "", @SW_HIDE, 4 + 2)

    While 1
        $s_stdout = StdoutRead($i_pid)
        If @error Then ExitLoop
        $s_hold_out &= $s_stdout
    WEnd

    $s_hold_out = StringRegExpReplace($s_hold_out, "\v+\z", "")
    If Not $s_hold_out Then Return SetError(4, 4, 0)

    ; Parse data and find matches based on flags
    Local $a_fsplit = StringSplit(StringStripCR($s_hold_out), @LF), $s_hold_ret
    $s_hold_out = ""

    If $s_exclude Then $s_exclude = StringReplace(StringReplace($s_exclude, "*", ".*?"), ";", "|")

    For $i = 1 To $a_fsplit[0]
        If $s_exclude And StringRegExp(StringRegExpReplace( _
            $a_fsplit[$i], "(.*?[\\/]+)*(.*?\z)", "\2"), "(?i)\Q" & $s_exclude & "\E") Then ContinueLoop
        If StringRegExp($a_fsplit[$i], "^\w:[\\/]+") = 0 Then $a_fsplit[$i] = $s_path & $a_fsplit[$i]
        If $f_full_path Then
            $s_hold_ret &= $a_fsplit[$i] & Chr(1)
        Else
            $s_hold_ret &= StringRegExpReplace($a_fsplit[$i], "((?:.*?[\\/]+)*)(.*?\z)", "$2") & Chr(1)
        EndIf
    Next

    $s_hold_ret = StringTrimRight($s_hold_ret, 1)
    If $s_hold_ret = "" Then Return SetError(5, 5, 0)

    Return StringSplit($s_hold_ret, Chr(1))
EndFunc