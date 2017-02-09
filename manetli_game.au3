;~ Assistance au farming sur le jeu HIT
;~ Le bot est capable de lire le nombre de ticket rixe et de lancer une partir si il reste des tickets et de quitter la partie pour vérifier à nouveau
;~
;~ A venir
;~ Si plus de ticket rixe, on lance quelques parties de farming


#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=hit.ico
#AutoIt3Wrapper_UseX64=y
#AutoIt3Wrapper_Res_Fileversion=1.0
#AutoIt3Wrapper_Res_Language=1036
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
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
$hwnd = WinGetHandle("BlueStacks App Player")

; Declare the flags
Global $counter = 0
Global $sleepTimeAleatoire = 0
Global $ticketChargement = false
$Interrupt = 0
$EventCheck = 0

; Todays actions
; Allows the script to carry on from where it stopped
$Tc = 0

Opt("GUIOnEventMode", 1)

$hGUI = GUICreate("Manetli Gaming", 500, 350)
$hPic_background = GUICtrlCreatePic(@WorkingDir & "\background.jpg", 0, 0, 0, 0)
;; create more controls here
GUICtrlSetState($hPic_background, $GUI_DISABLE)

GUISetOnEvent($GUI_EVENT_CLOSE, "ThatExit")

$RunBtn = GUICtrlCreateButton("Lancer", 10, 10, 80, 30)
GUICtrlSetOnEvent($RunBtn, "RunnerFunc")
$StopBtn = GUICtrlCreateButton("Arrêter", 10, 10, 80, 30)
GUICtrlSetOnEvent($StopBtn, "StopFunc")

$MaxActions = GUICtrlCreateInput("30000", 270, 15, 70, 20)
$labelCheck = GUICtrlCreateLabel("Nombre maximum de check :", 120, 18, 150, 50)
GUICtrlSetBkColor($labelCheck, $GUI_BKCOLOR_TRANSPARENT )
GUICtrlSetColor($labelCheck, $COLOR_WHITE)

;~ Global $idMylist = GUICtrlCreateList("", 10, 50, 480, 300)
;~ GUICtrlSetLimit(-1, 200) ; to limit horizontal scrolling
Global $idListview = GUICtrlCreateListView("Heure|Nbr|Message", 10, 50, 480, 290) ;,$LVS_SORTDESCENDING)
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
    RunnerFunc()
  EndIf
WEnd

Func RunnerFunc()
  ; This check avoids GUI flicker
  If $EventCheck = 0 Then
    GUICtrlSetState($RunBtn, $GUI_HIDE)
    GUICtrlSetState($StopBtn, $GUI_SHOW)
  EndIf

  $M = GUICtrlRead($MaxActions)

  $Interrupt = 0
  $EventCheck = 0
  For $i = $Tc To $M
	If $sleepTimeAleatoire = 0 Then
		$sleepTimeAleatoire = 500
	Else
		$sleepTimeAleatoire = Random(4000, 23000, 1)
	EndIf
	sleep($sleepTimeAleatoire)
    ; Check for Interruption
    If $Interrupt <> 0 Then
	  $EventCheck = 0
      Return
    EndIf
	_startPlaying()
    $Tc = $i+1
    ; Return to allow checking for system events
    $EventCheck = 1
    Return
  Next
  ConsoleWrite(">Waiting for next run" & @CRLF)
  ; Waiting loop here!
EndFunc

Func StopFunc()
  GUICtrlSetState($StopBtn, $GUI_HIDE)
  GUICtrlSetState($RunBtn, $GUI_SHOW)
  ConsoleWrite(">Stopped" & @CRLF)
EndFunc

Func _WM_COMMAND($hWnd, $Msg, $wParam, $lParam)
  If BitAND($wParam, 0x0000FFFF) =  $StopBtn Then $Interrupt = 1
  Return $GUI_RUNDEFMSG
EndFunc
Func ThatExit()
   Exit
EndFunc

 Func _startPlaying()
	 $counter = $counter+1
	; On déplace la fenetre pour garder toujours les même coordonées
	WinMove($hwnd, "", -1280, 176, 1235, 694 )
	; Ca c'est super cool, on chope la couleur d'un pixel
	; On indique les coordonées X et Y et la fenetre si besoin
	; Coordonée du compteur de ticket Rixe, la couleur = #FFFDD1
	Local $compteurRixeHaut = PixelGetColor(-368, 267, $hwnd)
;~ 	Ca aussi c'est super cool, on prend un screenshot du cadran ticket rixe
	_ScreenCapture_Capture(@MyDocumentsDir & "\manetli\counterRixe.jpg", -397, 225, -320, 248)
;~ 	Puis on lit l'image avec Tesseract et on stock le string dans un fichier .txt
	$result = _TessOcr(@MyDocumentsDir & "\manetli\counterRixe.jpg", @MyDocumentsDir & "\manetli\counterRixe")
	$array = StringSplit($result, @CRLF)
	Local $counterRixeArr = _StringExplode($array[1], "/", 0)
	$mousePos = MouseGetPos()
	$counterRixe = Int($counterRixeArr[0])
;~ 	If Hex($compteurRixeHaut, 6) = "FFFDD1" And  Hex($compteurRixeBas, 6) = "FFFDD1" And $counterRixe < 1 Then
	If Hex($compteurRixeHaut, 6) = "FFFDD1" And $counterRixe < 1 Then
		If $ticketChargement = false Then
			GUICtrlCreateListViewItem(_NowTime() & "|" & $counter & "|Les tickets du Rixe se rechargent " & $counterRixe & "/10", $idListview)
			$ticketChargement = true
		EndIf
;~ 		ConsoleWrite("[" & $counter & "] Les tickets du Rixe se rechargent" & @CRLF)
	Else
		$ticketChargement = false
		; On vérifie que le bouton "Lancer une partie" est là
		; Coordonée du bouton "Commencer Rixe"
		Local $boutonRixe1 = PixelGetColor(-156, 800, $hwnd) ; Cette zone est juste à droite du bouton, il n'y a pas d'animation
		; Par sécurité, nous allons vérifier qu'une autre zone correspondant à l'interface du salon de rixe soit bien affichée
		Local $boutonRixe2 = PixelGetColor(-395, 435, $hwnd) ; position de l'encart noir du rang
		Local $boutonRixe3 = PixelGetColor(-183, 710, $hwnd) ; position du coffre de la semaine
		If Hex($boutonRixe1, 6) = "0F0B08" And Hex($boutonRixe2, 6) = "0B090B" And Hex($boutonRixe3, 6) = "8C8C8C" Then
			ConsoleWrite("$result:" & $result & @CRLF)
			ConsoleWrite("$counterRixeArr[0]:" & $counterRixeArr[0] & @CRLF)
			ConsoleWrite("$array[1]:" & $array[1] & @CRLF)
			GUICtrlCreateListViewItem(_NowTime() & "|" & $counter & "|Le bouton est là, on lance un rixe! " & $counterRixe & "/10", $idListview)
			$positionHorizontaleAleatoire = _positionAleatoire(-340, Random(1, 150, 1))
			$positionVerticaleAleatoire = _positionAleatoire(820, Random(1, 15, 1))
			; On vérifie que le rixe est ouvert
			If @HOUR <> "05" Then
				MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
				MouseMove($mousePos[0],$mousePos[1],0)
			EndIf
		Else
			; Une partie est peut être terminée, nous allons cliquer sur le bouton "Quitter"
			Local $boutonQuitterRixe1 = PixelGetColor(-239, 835, $hwnd)
			Local $boutonQuitterRixe2 = PixelGetColor(-198, 830, $hwnd)
			If Hex($boutonQuitterRixe1, 6) = "C8B478" Or hex($boutonQuitterRixe1, 6) = "422A00" And Hex($boutonQuitterRixe2, 6) = "221500" Then
				GUICtrlCreateListViewItem(_NowTime() & "|" & $counter & "|Le bouton pour quitter le rixe est là.", $idListview)
				$positionHorizontaleAleatoire = _positionAleatoire(-243, Random(1, 40, 1))
				$positionVerticaleAleatoire = _positionAleatoire(831, Random(1, 15, 1))
;~ 				ConsoleWrite($positionAleatoire & @CRLF)
				MouseClick($MOUSE_CLICK_LEFT, $positionHorizontaleAleatoire, $positionVerticaleAleatoire, 1, 0)
				MouseMove($mousePos[0],$mousePos[1],0)
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
	ShellExecuteWait(@ProgramFilesDir & " (x86)\Tesseract-OCR\tesseract.exe", '"' & $in_image & '" "' & $out_file & '" ' & '"-l eng"'  & '" ' &'" -psm 6"', Null, Null, @SW_HIDE)
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
	Return $Read
EndFunc   ;==>_TessOcr