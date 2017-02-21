#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=hit.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Fileversion=1.0.0.10
#AutoIt3Wrapper_Res_Fileversion_AutoIncrement=p
#AutoIt3Wrapper_Res_Language=1036
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
;~ Assistance au farming sur le jeu HIT
;~ Le bot est capable de lire le nombre de ticket rixe et de lancer une partir si il reste des tickets et de quitter la partie pour vérifier à nouveau
;~
;~ A venir
;~ Si plus de ticket rixe, on lance quelques parties de farming
#include <Date.au3>
#include <ColorConstants.au3>
#include <GUIConstantsEx.au3>
#include <GuiListView.au3>
#include <WindowsConstants.au3>
#include <AutoItConstants.au3>
#include <MsgBoxConstants.au3>
#include <ScreenCapture.au3>
#Include <Array.au3>
#Include <String.au3>

; On chope la fenetre
Global $hwnd = WinGetHandle("BlueStacks App Player")

; Declare the flags
Global $mode_test = true

Global $Interrupt = 0
$EventCheck = 0

; Todays actions
; Allows the script to carry on from where it stopped
$Tc = 0

;~ Cett option permet d'avoir les coordonées de l'app bluestack et non des dualscreen
Opt("MouseCoordMode", 2)
Opt("GUIOnEventMode", 1)

Global $hGUI = GUICreate("Manetli Gaming", 500, 250)
$hPic_background = GUICtrlCreatePic(@WorkingDir & "\background.jpg", 0, 0, 0, 0)
;; create more controls here
GUICtrlSetState($hPic_background, $GUI_DISABLE)

GUISetOnEvent($GUI_EVENT_CLOSE, "ThatExit")

$RunBtn = GUICtrlCreateButton("Lancer", 10, 10, 80, 30)
GUICtrlSetOnEvent($RunBtn, "RunnerFunc")
$StopBtn = GUICtrlCreateButton("Arrêter", 10, 10, 80, 30)
GUICtrlSetOnEvent($StopBtn, "StopFunc")

$gemmeGame = GUICtrlCreateInput("0", 175, 15, 20, 20) ;delay de 2sec par defaut
$labelGemmeGame = GUICtrlCreateLabel("GemmeGame :", 100, 18, 150, 15)
GUICtrlSetBkColor($labelGemmeGame, $GUI_BKCOLOR_TRANSPARENT )
GUICtrlSetColor($labelGemmeGame, $COLOR_WHITE)

$labelRixeCounter = GUICtrlCreateLabel("Ticket :", 420, 18, 40, 15)
GUICtrlSetBkColor($labelRixeCounter, $GUI_BKCOLOR_TRANSPARENT )
GUICtrlSetColor($labelRixeCounter, $COLOR_WHITE)
$inputRixeCounter = GUICtrlCreateLabel("??/10", 460, 18, 40, 15)
GUICtrlSetBkColor($inputRixeCounter, $GUI_BKCOLOR_TRANSPARENT )
GUICtrlSetColor($inputRixeCounter, $COLOR_WHITE)

;~ Moyenne score rixe
$labelRixeScoreMoy = GUICtrlCreateLabel("Moy :", 360, 18, 40, 15)
GUICtrlSetBkColor($labelRixeScoreMoy, $GUI_BKCOLOR_TRANSPARENT )
GUICtrlSetColor($labelRixeScoreMoy, $COLOR_WHITE)
$inputRixeScoreMoy = GUICtrlCreateLabel("0", 390, 18, 40, 15)
GUICtrlSetBkColor($inputRixeScoreMoy, $GUI_BKCOLOR_TRANSPARENT )
GUICtrlSetColor($inputRixeScoreMoy, $COLOR_WHITE)

;~ Score total des rixes
$labelRixeScore = GUICtrlCreateLabel("Score :", 285, 18, 40, 15)
GUICtrlSetBkColor($labelRixeScore, $GUI_BKCOLOR_TRANSPARENT )
GUICtrlSetColor($labelRixeScore, $COLOR_WHITE)
$inputRixeScore = GUICtrlCreateLabel("0", 320, 18, 40, 15)
GUICtrlSetBkColor($inputRixeScore, $GUI_BKCOLOR_TRANSPARENT )
GUICtrlSetColor($inputRixeScore, $COLOR_WHITE)

;~ Total de party en rixe
$labelRixeCount = GUICtrlCreateLabel("Rixe :", 230, 18, 40, 15)
GUICtrlSetBkColor($labelRixeCount, $GUI_BKCOLOR_TRANSPARENT )
GUICtrlSetColor($labelRixeCount, $COLOR_WHITE)
$inputRixeCount = GUICtrlCreateLabel("0", 260, 18, 40, 15)
GUICtrlSetBkColor($inputRixeCount, $GUI_BKCOLOR_TRANSPARENT )
GUICtrlSetColor($inputRixeCount, $COLOR_WHITE)

Global $disconnectMethod = 0
Global $isDisconnected = false
Global $rixeRetry = false
Global $counterRixeRead = 0
Global $counter = 0
Global $maximumRixeTicket = 0
Global $bluestackLeftBarWidth = 59;
Global $bluestackTopBarHeight = 32;
Global $sleepTimeAleatoire = 0
Global $rixeScoreTotal = 0
Global $rixeTotal = 0
Global $rixeScoreMoy = 0
Global $ticketChargement = false
Global $rixeGemmeLaunch = GUICtrlRead($gemmeGame)

;~ Global $idMylist = GUICtrlCreateList("", 10, 50, 480, 300)
;~ GUICtrlSetLimit(-1, 200) ; to limit horizontal scrolling
Global $idListview = GUICtrlCreateListView("Heure|Nbr|Message", 10, 50, 480, 190) ;,$LVS_SORTDESCENDING)
_GUICtrlListView_SetColumnWidth($idListview,0,55)
_GUICtrlListView_SetColumnWidth($idListview,1,40)
_GUICtrlListView_SetColumnWidth($idListview,2,381)



; We want the stop button to be hidden when not needed, so we hide it for now.
GUICtrlSetState($StopBtn, $GUI_HIDE)
GUISetState()
GUIRegisterMsg($WM_COMMAND, "_WM_COMMAND")


While 1
  Sleep(10)
  If $EventCheck = 1 Then
    ; This temporary return to the main loop, allows AutoIt to quickly handle system events
    ; such as GUI_EVENT_CLOSE. If we reached this far, then its safe to assume that
    ; there was no system events, and we can return to the RunnerFunc.
;~ 	$Interrupt = 0
;~     RunnerFunc()
  EndIf
WEnd

Func RunnerFunc()
  ; This check avoids GUI flicker
  If $EventCheck = 0 Then
    GUICtrlSetState($RunBtn, $GUI_HIDE)
    GUICtrlSetState($StopBtn, $GUI_SHOW)
  EndIf

  $rixeGemmeLaunch = GUICtrlRead($gemmeGame)

  $M = 3000000

  $Interrupt = 0
  ConsoleWrite("Not while RunnerFunc() $Interrupt " & $Interrupt & @CRLF)
  $EventCheck = 0
;~   For $i = $Tc To $M
	ConsoleWrite("RunnerFunc() $Interrupt " & $Interrupt & @CRLF)
	If $sleepTimeAleatoire = 0 Then
		$sleepTimeAleatoire = 500
	Else
		If $mode_test = false Then
;~ 			$delay = GUICtrlRead($delayAction)
;~ 			$delayRatio = $delay / 100000
;~ 			$sleepTimeAleatoire = $delayAction + Random(1500*$delayRatio, 16000*$delayRatio, 1)
			$sleepTimeAleatoire = Random(2000, 10000, 1)
		Else
			$sleepTimeAleatoire = 1000
		EndIf
	EndIf
	sleep($sleepTimeAleatoire)
    ; Check for Interruption
    If $Interrupt <> 0 Then
	  $EventCheck = 0
      Return
	Else
		_startPlaying()
;~ 		$Tc = $i+1
		; Return to allow checking for system events
		$EventCheck = 1
		RunnerFunc()
		Return
    EndIf
;~   Next
  ConsoleWrite(">Waiting for next run" & @CRLF)
  ; Waiting loop here!
EndFunc

Func StopFunc()
  $Interrupt = 1
  ConsoleWrite("StopFunc() $Interrupt " & $Interrupt & @CRLF)
  GUICtrlSetState($StopBtn, $GUI_HIDE)
  GUICtrlSetState($RunBtn, $GUI_SHOW)
  ConsoleWrite(">Stopped" & @CRLF)
EndFunc

Func _WM_COMMAND($hWnd, $Msg, $wParam, $lParam)
	If BitAND($wParam, 0x0000FFFF) =  $StopBtn Then
	  $Interrupt = 1
	EndIf
  Return $GUI_RUNDEFMSG
EndFunc
Func ThatExit()
   Exit
EndFunc

 Func _startPlaying()
	$counter = $counter+1
;~ 	 On check si on est déconnecté
	_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\disconnect.jpg", $hwnd, 330+$bluestackLeftBarWidth, 305+$bluestackTopBarHeight, 687+$bluestackLeftBarWidth, 325+$bluestackTopBarHeight)
	_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\disconnect2.jpg", $hwnd, 483+$bluestackLeftBarWidth, 295+$bluestackTopBarHeight, 682+$bluestackLeftBarWidth, 311+$bluestackTopBarHeight)
	_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\disconnect3.jpg", $hwnd, 452+$bluestackLeftBarWidth, 295+$bluestackTopBarHeight, 714+$bluestackLeftBarWidth, 312+$bluestackTopBarHeight)
	$disconnectedTxt = _TessOcr(@WorkingDir & "\cache\disconnect.jpg", @WorkingDir & "\cache\disconnect")
	$disconnectedTxt2 = _TessOcr(@WorkingDir & "\cache\disconnect2.jpg", @WorkingDir & "\cache\disconnect2")
	$disconnectedTxt3 = _TessOcr(@WorkingDir & "\cache\disconnect3.jpg", @WorkingDir & "\cache\disconnect3")
;~ 	ConsoleWrite("$disconnectedTxt " & $disconnectedTxt[1] & @CRLF)
;~ 	ConsoleWrite("$disconnectedTxt2 " & $disconnectedTxt2[1] & @CRLF)
;~ 	ConsoleWrite("$disconnectedTxt3 " & $disconnectedTxt3[1] & @CRLF)
	If $disconnectedTxt[1] = "Vou have been disconnected from the server." Then
		$isDisconnected = true
		$disconnectMethod = 1
	ElseIf $disconnectedTxt2[1] = "Network connection lost." Then
		$isDisconnected = true
		$disconnectMethod = 2
	ElseIf $disconnectedTxt3[1] = "Network connection is unstable‘" OR $disconnectedTxt3[1] = "Network connection is unstable" Then
		$isDisconnected = true
		$disconnectMethod = 3
	Else
		$isDisconnected = false
	EndIf

	If $isDisconnected = true Then
		If $mode_test = false Then
			$currentWindow = WinGetHandle("")
			WinActivate($hwnd)
			$positionHorizontaleAleatoire = _positionAleatoire(584, Random(1, 100, 1)) + $bluestackLeftBarWidth
			$positionVerticaleAleatoire = _positionAleatoire(417, Random(1, 10, 1)) + $bluestackTopBarHeight
			$mousePos = MouseGetPos()
			MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
			ConsoleWrite("$MOUSE_CLICK_LEFT x:" & $positionHorizontaleAleatoire & " y:" & $positionVerticaleAleatoire & @CRLF)
			MouseMove($mousePos[0],$mousePos[1],0)
			WinActivate($currentWindow)
		EndIf
	EndIf

	;~ 	 On check si nous sommes sur la home
	_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\challenge.jpg", $hwnd, 887+$bluestackLeftBarWidth, 624+$bluestackTopBarHeight, 993+$bluestackLeftBarWidth, 647+$bluestackTopBarHeight)
	$buttonChallenge = _TessOcr(@WorkingDir & "\cache\challenge.jpg", @WorkingDir & "\cache\challenge")
;~ 	ConsoleWrite("$buttonChallenge " & $buttonChallenge[1] & @CRLF)
	If $buttonChallenge[1] = "Challenge" Then
		If $mode_test = false Then
			$currentWindow = WinGetHandle("")
			WinActivate($hwnd)
			$positionHorizontaleAleatoire = _positionAleatoire(939, Random(1, 25, 1)) + $bluestackLeftBarWidth
			$positionVerticaleAleatoire = _positionAleatoire(558, Random(1, 10, 1)) + $bluestackTopBarHeight
			$mousePos = MouseGetPos()
			MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
			ConsoleWrite("$MOUSE_CLICK_LEFT x:" & $positionHorizontaleAleatoire & " y:" & $positionVerticaleAleatoire & @CRLF)
			MouseMove($mousePos[0],$mousePos[1],0)
			WinActivate($currentWindow)
		EndIf
	EndIf

	;~ 	 On check si nous sommes sur la vue Challenge pour cliquer sur Arena
	_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\arena.jpg", $hwnd, 134+$bluestackLeftBarWidth, 578+$bluestackTopBarHeight, 188+$bluestackLeftBarWidth, 593+$bluestackTopBarHeight)
	$buttonArena = _TessOcr(@WorkingDir & "\cache\arena.jpg", @WorkingDir & "\cache\arena")
;~ 	ConsoleWrite("$buttonArena " & $buttonArena[1] & @CRLF)
	If $buttonArena[1] = "Arena" Then
		If $mode_test = false Then
			$currentWindow = WinGetHandle("")
			WinActivate($hwnd)
			$positionHorizontaleAleatoire = _positionAleatoire(155, Random(1, 25, 1)) + $bluestackLeftBarWidth
			$positionVerticaleAleatoire = _positionAleatoire(531, Random(1, 10, 1)) + $bluestackTopBarHeight
			$mousePos = MouseGetPos()
			MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
			ConsoleWrite("$MOUSE_CLICK_LEFT x:" & $positionHorizontaleAleatoire & " y:" & $positionVerticaleAleatoire & @CRLF)
			MouseMove($mousePos[0],$mousePos[1],0)
			WinActivate($currentWindow)
		EndIf
	EndIf

;~ 	 On check si nous sommes sur la vue Arena pour cliquer sur Brawl
	_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\brawl.jpg", $hwnd, 709+$bluestackLeftBarWidth, 549+$bluestackTopBarHeight, 780+$bluestackLeftBarWidth, 572+$bluestackTopBarHeight)
	$buttonBrawl = _TessOcr(@WorkingDir & "\cache\brawl.jpg", @WorkingDir & "\cache\brawl")
;~ 	ConsoleWrite("$buttonBrawl " & $buttonBrawl[1] & @CRLF)
	If $buttonBrawl[1] = "Enter" Then
		If $mode_test = false Then
			$currentWindow = WinGetHandle("")
			WinActivate($hwnd)
			$positionHorizontaleAleatoire = _positionAleatoire(742, Random(1, 25, 1)) + $bluestackLeftBarWidth
			$positionVerticaleAleatoire = _positionAleatoire(562, Random(1, 10, 1)) + $bluestackTopBarHeight
			$mousePos = MouseGetPos()
			MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
			ConsoleWrite("$MOUSE_CLICK_LEFT x:" & $positionHorizontaleAleatoire & " y:" & $positionVerticaleAleatoire & @CRLF)
			MouseMove($mousePos[0],$mousePos[1],0)
			WinActivate($currentWindow)
		EndIf
	EndIf

;~ 	 On check si nous pouvons gemmer
	_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\brawlGemme.jpg", $hwnd, 443+$bluestackLeftBarWidth, 210+$bluestackTopBarHeight, 718+$bluestackLeftBarWidth, 232+$bluestackTopBarHeight)
	$buttonBrawlGemme = _TessOcr(@WorkingDir & "\cache\brawlGemme.jpg", @WorkingDir & "\cache\brawlGemme")
;~ 	ConsoleWrite("$buttonBrawlGemme " & $buttonBrawlGemme[1] & @CRLF)
	If $buttonBrawlGemme[1] = "Recharge Brawl Points." Then
		If $mode_test = false Then
			$currentWindow = WinGetHandle("")
			WinActivate($hwnd)
			$positionHorizontaleAleatoire = _positionAleatoire(586, Random(1, 25, 1)) + $bluestackLeftBarWidth
			$positionVerticaleAleatoire = _positionAleatoire(416, Random(1, 10, 1)) + $bluestackTopBarHeight
			$mousePos = MouseGetPos()
			MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
			ConsoleWrite("$MOUSE_CLICK_LEFT x:" & $positionHorizontaleAleatoire & " y:" & $positionVerticaleAleatoire & @CRLF)
			MouseMove($mousePos[0],$mousePos[1],0)
			WinActivate($currentWindow)
			$rixeGemmeLaunch = $rixeGemmeLaunch +1
			GUICtrlSetData($gemmeGame,$rixeGemmeLaunch)
		EndIf
	EndIf

	; On déplace la fenetre pour garder toujours les même coordonées
;~ 	WinMove($hwnd, "", -1280, 176, 1235, 694 )
	_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\counterRixe.jpg", $hwnd, 800+$bluestackLeftBarWidth, 20+$bluestackTopBarHeight, 895+$bluestackLeftBarWidth, 42+$bluestackTopBarHeight)
;~ 	Puis on lit l'image avec Tesseract et on stock le string dans un fichier .txt
	$counterRixe = _TessOcr(@WorkingDir & "\cache\counterRixe.jpg", @WorkingDir & "\cache\counterRixe")
;~ 	ConsoleWrite("$buttonRixeStart:" & $buttonRixeStart[1] & @CRLF)
	Local $counterRixeArr = _StringExplode($counterRixe[1], "/", 0)
	$maximumRixeTicket = 0
	If IsArray($counterRixeArr) Then
		$counterRixeReadCache = Int($counterRixeArr[0])
;~ 		ConsoleWrite("StringLen($counterRixeArr[0]) " & StringLen($counterRixeArr[0]) & @CRLF)
;~ 		ConsoleWrite("$counterRixeArr[0] " & $counterRixeArr[0] & @CRLF)
;~ 		ConsoleWrite("=====$counterRixeRead " & $counterRixeRead & "=====" & @CRLF)
;~ 		ConsoleWrite("$counterRixeReadCache " & $counterRixeReadCache & @CRLF)
;~ 		ConsoleWrite("IsInt($counterRixeReadCache) " & IsInt($counterRixeReadCache) & @CRLF)
;~ 		ConsoleWrite("-----------------------" & @CRLF)
		If $rixeRetry = false AND IsInt($counterRixeReadCache) = true AND StringLen($counterRixeArr[0]) > 0 AND $counterRixeArr[0] <> " " AND StringInStr($counterRixe[1], "/") > 1 Then
			$counterRixeRead = Int($counterRixeArr[0])
;~ 			ConsoleWrite("UBound:" & UBound($counterRixeArr, $UBOUND_ROWS) & @CRLF)
			If UBound($counterRixeArr, $UBOUND_ROWS) > 1 Then
				$maximumRixeTicket = Int($counterRixeArr[1])
			EndIf
		EndIf
	EndIf
;~ 	ConsoleWrite("$maximumRixeTicket:" & $maximumRixeTicket & @CRLF)
;~ 	ConsoleWrite("$counterRixeRead:" & $counterRixeRead & @CRLF)
	If $maximumRixeTicket = 10 And $counterRixeRead < 1 Then
;~ 		ConsoleWrite("$ticketChargement:" & $ticketChargement & @CRLF)
		If $ticketChargement = false Then
;~ 			ConsoleWrite("Les tickets du Rixe se rechargent" & @CRLF)
			GUICtrlSetData($inputRixeCounter,$counterRixeRead & "/10")
			GUICtrlCreateListViewItem(_NowTime() & "|" & $counter & "|Les tickets du Rixe se rechargent " & $counterRixeRead & "/10", $idListview)
			$ticketChargement = true
		EndIf
		;~ 			Nous allons gemmer un peu :)
;~ 		ConsoleWrite("$rixeGemmeLaunch:" & $rixeGemmeLaunch & @CRLF)
		If $rixeGemmeLaunch < 20 Then
			; On vérifie que le bouton "Lancer une partie" est là
			_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\buttonRixeStart2.jpg", $hwnd, 790+$bluestackLeftBarWidth, 600+$bluestackTopBarHeight, 900+$bluestackLeftBarWidth, 626+$bluestackTopBarHeight)
			$buttonRixeStart2 = _TessOcr(@WorkingDir & "\cache\buttonRixeStart2.jpg", @WorkingDir & "\cache\buttonRixeStart2")
			If $buttonRixeStart2[1] = "Start Brawl" Or $buttonRixeStart2[1] = "Sta rt Brawl" Then
				GUICtrlCreateListViewItem(_NowTime() & "|" & $counter & "|Le bouton est là et nous gemmons, on lance un rixe! " & $counterRixeRead & "/10", $idListview)
				_GUICtrlListView_Scroll($idListview, 0, (_GUICtrlListView_GetItemCount($idListview) -1) * 14)
				$positionHorizontaleAleatoire = _positionAleatoire(865, Random(1, 100, 1)) + $bluestackLeftBarWidth
				$positionVerticaleAleatoire = _positionAleatoire(615, Random(1, 10, 1)) + $bluestackTopBarHeight
				; On vérifie que le rixe est ouvert
				If @HOUR <> "05" Then
					If $mode_test = false Then
						$currentWindow = WinGetHandle("")
						WinActivate($hwnd)
						$mousePos = MouseGetPos()
						MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
						GUICtrlSetData($inputRixeCounter, $counterRixeRead -1 & "/10")
						$counterRixeRead = $counterRixeRead - 1
						ConsoleWrite("$MOUSE_CLICK_LEFT x:" & $positionHorizontaleAleatoire & " y:" & $positionVerticaleAleatoire & @CRLF)
						MouseMove($mousePos[0],$mousePos[1],0)
						WinActivate($currentWindow)
					EndIf
				EndIf
			EndIf
		EndIf
;~ 		ConsoleWrite("[" & $counter & "] Les tickets du Rixe se rechargent" & @CRLF)
	Else
		$ticketChargement = false
		; On vérifie que le bouton "Lancer une partie" est là
		_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\buttonRixeStart.jpg", $hwnd, 790+$bluestackLeftBarWidth, 600+$bluestackTopBarHeight, 900+$bluestackLeftBarWidth, 626+$bluestackTopBarHeight)
		$buttonRixeStart = _TessOcr(@WorkingDir & "\cache\buttonRixeStart.jpg", @WorkingDir & "\cache\buttonRixeStart")
		If $buttonRixeStart[1] = "Start Brawl" Or $buttonRixeStart[1] = "Sta rt Brawl" Then
			GUICtrlCreateListViewItem(_NowTime() & "|" & $counter & "|Le bouton est là, on lance un rixe! " & $counterRixeRead & "/10", $idListview)
			_GUICtrlListView_Scroll($idListview, 0, (_GUICtrlListView_GetItemCount($idListview) -1) * 14)
			$positionHorizontaleAleatoire = _positionAleatoire(865, Random(1, 100, 1)) + $bluestackLeftBarWidth
			$positionVerticaleAleatoire = _positionAleatoire(615, Random(1, 10, 1)) + $bluestackTopBarHeight
			; On vérifie que le rixe est ouvert
			If @HOUR <> "05" Then
				If $mode_test = false Then
					$currentWindow = WinGetHandle("")
					WinActivate($hwnd)
					$mousePos = MouseGetPos()
					MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
					GUICtrlSetData($inputRixeCounter, $counterRixeRead -1 & "/10")
					$counterRixeRead = $counterRixeRead - 1
					ConsoleWrite("$MOUSE_CLICK_LEFT x:" & $positionHorizontaleAleatoire & " y:" & $positionVerticaleAleatoire & @CRLF)
					MouseMove($mousePos[0],$mousePos[1],0)
					WinActivate($currentWindow)
				EndIf
			EndIf
		Else
			; Une partie est peut être terminée, nous allons cliquer sur le bouton "Quitter"
			_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\buttonRixeExit.jpg", $hwnd, 953+$bluestackLeftBarWidth, 613+$bluestackTopBarHeight, 997+$bluestackLeftBarWidth, 634+$bluestackTopBarHeight)
			$buttonRixeExit = _TessOcr(@WorkingDir & "\cache\buttonRixeExit.jpg", @WorkingDir & "\cache\buttonRixeExit")
			If $buttonRixeExit[1] <> " " Then
;~ 				ConsoleWrite("$buttonRixeExit:" & $buttonRixeExit[1] & @CRLF)
			EndIf
			If $buttonRixeExit[1] = "Exit" Then
				GUICtrlCreateListViewItem(_NowTime() & "|" & $counter & "|Le bouton pour quitter le rixe est là.", $idListview)
;~ 				ConsoleWrite($positionAleatoire & @CRLF)
				_ScreenCapture_CaptureWnd(@WorkingDir & "\cache\rixeScore.jpg", $hwnd, 1091+$bluestackLeftBarWidth, 530+$bluestackTopBarHeight, 1155+$bluestackLeftBarWidth, 565+$bluestackTopBarHeight)
				$rixeScore = _TessOcr(@WorkingDir & "\cache\rixeScore.jpg", @WorkingDir & "\cache\rixeScore")
				$rixeScore = $rixeScore[1]
				$rixeScore = StringReplace($rixeScore, "x ", "")
				$rixeScore = StringReplace($rixeScore, "x", "")
				$rixeScore = StringReplace($rixeScore, "A ", "")
				$rixeScore = StringReplace($rixeScore, "(*", "")
				$rixeScore = StringReplace($rixeScore, ")", "")
				$rixeScore = Int($rixeScore)
				$rixeScoreTotal = $rixeScoreTotal + $rixeScore
				$rixeTotal = $rixeTotal + 1
				$rixeScoreMoy = Round($rixeScoreTotal / $rixeTotal)
				GUICtrlSetData($inputRixeScore,$rixeScoreTotal)
				GUICtrlSetData($inputRixeCount,$rixeTotal)
				GUICtrlSetData($inputRixeScoreMoy,$rixeScoreMoy)
				ConsoleWrite("$rixeScore: " & $rixeScore & @CRLF)
				ConsoleWrite("$rixeScoreTotal: " & $rixeScoreTotal & @CRLF)
				If $mode_test = false Then
					$currentWindow = WinGetHandle("")
					WinActivate($hwnd)
;~ 					Si il nous reste des tickets alors on retry
					If $counterRixeRead >= Random(2, 4, 1) Then
						$positionHorizontaleAleatoire = _positionAleatoire(1105, Random(1, 20, 1)) + $bluestackLeftBarWidth
						$positionVerticaleAleatoire = _positionAleatoire(625, Random(1, 10, 1)) + $bluestackTopBarHeight
						$mousePos = MouseGetPos()
						MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
						$counterRixeRead = $counterRixeRead - 1
						$rixeRetry = true
						GUICtrlSetData($inputRixeCounter, $counterRixeRead & "/10")
					Else
;~ 						Sinon on click sur exit
						$positionHorizontaleAleatoire = _positionAleatoire(975, Random(1, 20, 1)) + $bluestackLeftBarWidth
						$positionVerticaleAleatoire = _positionAleatoire(625, Random(1, 10, 1)) + $bluestackTopBarHeight
						$mousePos = MouseGetPos()
						MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
						$rixeRetry = false
					EndIf
					ConsoleWrite("$MOUSE_CLICK_LEFT x:" & $positionHorizontaleAleatoire & " y:" & $positionVerticaleAleatoire & @CRLF)
					MouseMove($mousePos[0],$mousePos[1],0)
					WinActivate($currentWindow)
				EndIf
			EndIf
		EndIf
	EndIf
 EndFunc

 Func _positionAleatoire($pos, $marge)
	$grainDeSel = Random(1, 2, 1)
	If $grainDeSel = 2 Then
		$pos = $pos + $marge
	Else
		$pos = $pos - $marge
	EndIf
	Return $pos
 EndFunc

;~ Fonction OCR qui utilise la librairie Tesseract de HP & Google
Func _TessOcr($in_image, $out_file)
	Local $Read
;~ 	Local $iReturn = ShellExecuteWait(@ProgramFilesDir & " (x86)\Tesseract-OCR\tesseract.exe", '"' & $in_image & '" "' & $out_file & '" ' & '"-l eng"'  & '" ' &'" -psm 6"', Null, Null, @SW_HIDE)
	Local $iReturn = ShellExecuteWait("D:\GitHub\ManetliGame\lib\tesseract-ocr\tesseract.exe", $in_image & " " & $out_file, Null, Null, @SW_HIDE)
;~ Run(@COMSPEC & "/k " & @ProgramFilesDir & " (x86)\Tesseract-OCR\tesseract.exe " & $in_image & " " & $out_file, @TempDir, @SW_SHOW)
;~ 	ConsoleWrite("@ProgramFilesDir:" & @ProgramFilesDir & " (x86)\Tesseract-OCR\tesseract.exe" & @CRLF)
;~ 	ConsoleWrite("param:" & '"' & $in_image & '" "' & $out_file & '" ' & '"-l eng"'  & '" ' &'" -psm 6"' & @CRLF)
	If @error Then
		MsgBox(0,"Error","ShellExecuteWait Error")
		Exit
	EndIf
	If FileExists($out_file & ".txt") Then
		$Read = FileRead($out_file & ".txt")
		;FileDelete($out_file & ".txt")
	Else
		$Read = "No file created"
	EndIf
	$result = StringSplit($Read, @CRLF)
	Return $result
EndFunc   ;==>_TessOcr