#include <GUIConstants.au3>
$connected = 0
$connected2 = 0
Global $socket,$socket2
Global $sendtxt
HotKeySet("^+b", "NotifyClientsOfBoss")
TCPStartup()

$client1Ip = @IPAddress1
$client2Ip = @IPAddress1

;replace with your friend's IP (up to two machines supported)
;$client1Ip = "192.168.1.12"
;$client2Ip = "192.168.1.12"

$socket  = TCPConnect("192.168.1.14", "33891")
$socket2 = TCPConnect("192.168.1.12", "33891")

If $socket = -1 Then
	MsgBox(64, "TCPClient", "Connection Failure Client 1.")
	$connected = 0
Else
	MsgBox(64, "TCPClient", "Connected successfully Client 1.")
	$connected = 1
	SendAtConnect()
EndIf

If $socket2 = -1 Then
	MsgBox(64, "TCPClient", "Connection Failure Client 2.")
	$connected2 = 0
Else
	MsgBox(64, "TCPClient", "Connected successfully Client 2.")
	$connected2 = 1
	SendAtConnect()
EndIf

While 1
    $msg = GUIGetMsg()

	$recv  = TCPRecv($socket, 1024)
    $recv2 = TCPRecv($socket2, 1024)

	Select
        Case $msg = $GUI_EVENT_CLOSE
            If $connected = 1 Then
                TCPSend($socket, "QUIT :TCPClient exited." & @CRLF)
                TCPCloseSocket($socket)
                TCPShutdown()
            EndIf
            If $connected2 = 1 Then
                TCPSend($socket2, "QUIT :TCPClient exited." & @CRLF)
                TCPCloseSocket($socket2)
                TCPShutdown()
            EndIf

            ExitLoop
    EndSelect
WEnd
Exit

Func NotifyClientsOfBoss()
	$sendtxt = "BOSS_COMING"
	If $connected = 1 Then
		TCPSend($socket, $sendtxt & @CRLF)
        If @error Then
			$connected = 0
			msgbox(0,'Client 1 Down','Client 1 Down')
		EndIf
	EndIf
	If $connected2 = 1 Then
		TCPSend($socket2, $sendtxt & @CRLF)
        If @error Then
			$connected2 = 0
			msgbox(0,'Client 2 Down','Client 2 Down')
		EndIf
	EndIf
EndFunc   ;==>NotifyClientsOfBoss


Func SendAtConnect()
    TCPSend($socket, "NICK TCPClient" & @CRLF)
    TCPSend($socket, 'USER TCPClient "TCPClient" "TCPClient" :TCPClient' & @CRLF)
    TCPSend($socket2, "NICK TCPClient" & @CRLF)
    TCPSend($socket2, 'USER TCPClient "TCPClient" "TCPClient" :TCPClient' & @CRLF)
EndFunc   ;==>SendAtConnect
