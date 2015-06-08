#NoTrayIcon
#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_UseUpx=y
#AutoIt3Wrapper_Compression=4
#AutoIt3Wrapper_Icon=.\Icon\Icon.ico
#AutoIt3Wrapper_Res_Description=Firewall-Rules Generator
#AutoIt3Wrapper_Res_Fileversion=1.2.0.0
#AutoIt3Wrapper_Res_LegalCopyright=© by rugk, licensed under a MIT license (Expat)
#AutoIt3Wrapper_Res_Field=CompanyName|rugk
#AutoIt3Wrapper_Res_Field=ProductName|Firewall-Rules Generator
#AutoIt3Wrapper_Res_Field=OriginalFilename|ESSFirewallRulesGenerator.exe
#AutoIt3Wrapper_Res_Field=InternalName|FirewallRulesGenerator
#AutoIt3Wrapper_Run_After=del "%scriptdir%\%scriptfile%_stripped.au3"
#AutoIt3Wrapper_Run_Au3Stripper=y
#AutoIt3Wrapper_UseX64=n
#Au3Stripper_Parameters=/so
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#cs ======================================================= Information ===========================================================
Title ..........: Firewall-Rules Generator
Version ........: 1.2
Language .......: English
Description ....: Creates a settings file for ESSs firewall based on an IP list.
Author .........: rugk - https://forum.eset.com/user/3952-rugk/
Creation date ..: 2014-02-18
AutoIt version .: 3.3.12.0
AutoIt3Wrapper .: 15.503.1200.2
License ........: MIT license. For more information have a look at the file "License".
Website ........: https://forum.eset.com/index.php?showtopic=4158
Notes ..........: The Icon is based on a picture from Nemo (http://pixabay.com/en/firewall-security-internet-web-29940/ ©C0 Public
				  Domain) and from crisg (https://openclipart.org/detail/182735/check-list-by-crisg-182735 ©C0 Public Domain).
#ce ===============================================================================================================================

#Region INCLUDES
#include <MsgBoxConstants.au3>
#include <FileConstants.au3>
#include <StringConstants.au3>
#include <FileConstants.au3>

#include <StaticConstants.au3>
#include <GUIConstantsEx.au3>
#include <ComboConstants.au3>
#include <ButtonConstants.au3>
#EndRegion INCLUDES

#Region CONSTANTS
Global Const $title = "Firewall-Rules Generator"
Global Const $author = "rugk"
Global Const $internalName = "FirewallRulesGenerator"
Global Const $version = "1.2"
Global Const $website = "https://forum.eset.com/index.php?showtopic=4158"
Global Const $license = 'Copyright (c) 2015 rugk' & @CRLF & @CRLF & _ ; This is the MIT/Expat license (available online at http://opensource.org/licenses/MIT)
		'Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), ' & _
		'to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, ' & _
		'and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:' & @CRLF & @CRLF & _
		'The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.' & @CRLF & @CRLF & _
		'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, ' & _
		'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER ' & _
		'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS ' & _
		'IN THE SOFTWARE.'
#EndRegion CONSTANTS

#Region VARIBLES
Global $sInputFile, $sOutputFile
Global $sRuleName
Global $sXMLcode = '', $sWrongIPsLog = ''

Global $sOptionsString = ""
Global $bShowSmallOptionsGUI = True

Global $bShareable = False
Global $bSilent = False
Global $bConsole = False ;debugging: True
Global $bWriteWrongIPLog = True

Local $bIsActivated = True, $sDirection = "both", $sAction = "deny", $bLog = False, $bNotifyUser = False
#EndRegion VARIBLES

#Region PARAMETER-MANAGMENT
Local $actPar
For $i = 1 To $cmdline[0]
	$actPar = $cmdline[$i]
	Select
		Case $actPar = "/input" And $i < $cmdline[0]
			$sInputFile = $cmdline[$i + 1]
		Case $actPar = "/output" And $i < $cmdline[0]
			$sOutputFile = $cmdline[$i + 1]
		Case $actPar = "/name" And $i < $cmdline[0]
			$sRuleName = $cmdline[$i + 1]
		Case $actPar = "/shareable"
			$bShareable = True
		Case $actPar = "/silent"
			$bSilent = True
;~ 		Case $actPar = "/console" ;(the exe must be compiled as a console application to use this)
;~ 			$bConsole = True
		Case $actPar = "/doNotWriteWrongIPLog"
			$bWriteWrongIPLog = False
		Case $actPar = "/OptActivated" And $i < $cmdline[0]
			$bIsActivated = $cmdline[$i + 1] = True
		Case $actPar = "/OptLog" And $i < $cmdline[0]
			$bLog = $cmdline[$i + 1] = True
		Case $actPar = "/OptNotifyUser" And $i < $cmdline[0]
			$bNotifyUser = $cmdline[$i + 1] = True
		Case $actPar = "/OptDirection" And $i < $cmdline[0]
			If $cmdline[$i + 1] = "both" Or _
					$cmdline[$i + 1] = "in" Or _
					$cmdline[$i + 1] = "out" Then _
					$sDirection = $cmdline[$i + 1]
		Case $actPar = "/OptAction" And $i < $cmdline[0]
			If $cmdline[$i + 1] = "deny" Or _
					$cmdline[$i + 1] = "allow" Or _
					$cmdline[$i + 1] = "ask" Then _
					$sAction = $cmdline[$i + 1]
		Case $actPar = "/doNotShowSOGUI"
			$bShowSmallOptionsGUI = False
		Case FileExists($actPar) And $cmdline[0] = 1 ; If the only parameter is an existing path
			$sInputFile = $actPar
		Case $actPar = "/license"
			If $bConsole Then ConsoleWrite($license & @CRLF)
			MsgBox(0, $title, $license)
			Exit
		Case $actPar = "/?" Or $actPar = "/help" Or $actPar = "/h"
			Local $sText = "Parameters:"
			$sText &= @CRLF & "   " & "/input <file> : Specifiy the input file (must exist)"
			$sText &= @CRLF & "   " & "/output <file> : Specifiy the output file (if it exists it will be overwritten)"
			$sText &= @CRLF & "   " & "/name <name> : Set the name for the rule"
			$sText &= @CRLF & "   " & "/shareable : Add this to make a shareable XML file which doesn't contains private details"
			$sText &= @CRLF & "   " & "/silent : Doesn't show any success or error message."
;~ 			$sText &= @CRLF & "   " & "/console : Write success or error message into the console output."
			$sText &= @CRLF & "   " & "/doNotWriteWrongIPLog : Does not write the invalid IPs to the temp directory."
			$sText &= @CRLF & "   " & "/OptActivated <1 or 0> : Specifies whether the created rule should be activated (1) or disabled (0)."
			$sText &= @CRLF & "   " & "/OptLog <1 or 0> : Specifies whether the created rule should be set to logging (1) or not (0)."
			$sText &= @CRLF & "   " & "/OptNotifyUser <1 or 0> : Specifies whether the created rule should be set to notify the user (1) or not (0)."
			$sText &= @CRLF & "   " & "/OptDirection <both, in or out> : Specifies for what direction(s) the rule should be applied."
			$sText &= @CRLF & "   " & "/OptAction <deny, allow or ask> : Specifies what the rule should do."
			$sText &= @CRLF & "   " & '/doNotShowSOGUI : Prevent the options GUI from showing. (can be useful in conjunction with /silent)'
			$sText &= @CRLF & "   " & '/? /help /h : Show this help'
			$sText &= @CRLF & "   " & '/license : Show license'
			$sText &= @CRLF & @CRLF & 'Exitcodes:'
			$sText &= @CRLF & "   " & '0: Everything went well. The XML file should be valid.'
			$sText &= @CRLF & "   " & '1: Some IPs were not correct.'
			$sText &= @CRLF & "   " & '2: There are no correct IPs in the rule.'
			$sText &= @CRLF & "   " & '4: The XML file could not be written.'
			$sText &= @CRLF & "   " & 'The values are added if multiple errors occur.'
			$sText &= @CRLF & "   " & '100: An unknown error happend.'
			$sText &= @CRLF & @CRLF & 'Default values:'
			$sText &= @CRLF & "   " & '/OptActivated : 1'
			$sText &= @CRLF & "   " & '/OptLog : 0'
			$sText &= @CRLF & "   " & '/OptNotifyUser : 0'
			$sText &= @CRLF & "   " & '/OptDirection : both'
			$sText &= @CRLF & "   " & '/OptAction : deny'
			$sText &= @CRLF & "   " & 'All other values are asked from the user if they are not given.'
			MsgBox(0, $title, $sText)
			Exit
	EndSelect
Next
#EndRegion PARAMETER-MANAGMENT

#Region GUI
; Select the files which should be used for generating and saving
; "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}" = My computer
If Not FileExists($sInputFile) Then $sInputFile = FileOpenDialog($title & " - Input text file", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "text or list files (*.txt; *.lst)|All files (*.*)", $FD_FILEMUSTEXIST + $FD_PATHMUSTEXIST)
If @error Then Exit
If $sRuleName = "" Then $sRuleName = InputBox($title & " - Rule name", "Enter a name for this rule.", _FileName($sInputFile), " M") ; " M" means that it is mandatory and an't must be filled with a value
If @error Then Exit
If $bShowSmallOptionsGUI Then ; Either confirm/let the user choose options...
	Global $sOptionsString = SmallOptionsGUI($bIsActivated, $sDirection, $sAction, $bLog, $bNotifyUser)
Else ; ...or use the default/pre-set ones
	Global $sOptionsString = GetRuleOptionString($bIsActivated, $sDirection, $sAction, $bLog, $bNotifyUser)
EndIf
If @error Then Exit
If $sOutputFile = "" Then $sOutputFile = FileSaveDialog($title & " - Output settings file", "::{20D04FE0-3AEA-1069-A2D8-08002B30309D}", "configuration files (*.xml)|All files (*.*)", $FD_PROMPTOVERWRITE, _FileName($sInputFile) & ".xml")
If @error Then Exit
#EndRegion GUI

#Region PROCESS
; Read file
$avInput = FileReadToArray($sInputFile)
If @error = 1 Then ErrorExit("Error opening input file", "The input file couldn't be opened.")
If @error = 2 Then ErrorExit("Empty input file", "The input file doesn't contain any data.")

; Add beginning of XML code
Local $sUser
If $bShareable Then
	$sUser = $internalName & "\By" & StringUpper(StringLeft($author, 1)) & StringTrimLeft($author, 1) ; Fake computer and user
	$sDate = @YEAR & '/' & @MON & '/' & @MDAY & ' ' & "00" & ':' & "00" & ':' & "00" ; I think it's okay to share the roughly creation date - if you don't think so, you can still edit the XML file afterwards
Else
	$sUser = @ComputerName & '\' & @UserName ; Real computer/user
	$sDate = @YEAR & '/' & @MON & '/' & @MDAY & ' ' & @HOUR & ':' & @MIN & ':' & @MDAY ; Real date/time
EndIf

$sXMLcode &= '<?xml version="1.0" encoding="utf-8"?>' & @LF
$sXMLcode &= '<ESET>' & @LF
$sXMLcode &= ' <SECTION ID="1000103">' & @LF
$sXMLcode &= '  <SETTINGS>' & @LF
$sXMLcode &= '   <PLUGINS>' & @LF
$sXMLcode &= '    <PLUGIN ID="1000200">' & @LF
$sXMLcode &= '     <PROFILES>' & @LF
$sXMLcode &= '      <NODE NAME="@My profile" TYPE="SUBNODE">' & @LF
$sXMLcode &= '       <NODE NAME="EPFWDATA" TYPE="XML" XML_VERSION="2">' & @LF
$sXMLcode &= '        <RULES>' & @LF
$sXMLcode &= '         <RULE ID="1" NAME="' & $sRuleName & '" ' & $sOptionsString & ' MODIFIED="' & $sDate & '" USER_NAME="' & $sUser & '">' & @LF
$sXMLcode &= '          <REMOTE>' & @LF

; Go through input file and add IP adresses
Local $iIPcount = 0, $iIPv4count = 0, $iIPv6count = 0
Local $sInputFile_NameExt = _FileNameExt($sInputFile) ;just for speed :)
For $i = 0 To UBound($avInput) - 1
	; Remove spaces
	$avInput[$i] = StringStripWS($avInput[$i], $STR_STRIPALL)

	; Ignore comments and empty lines
	If $avInput[$i] = "" Or _
			StringIsSpace($avInput[$i]) Or _
			StringLeft($avInput[$i], 1) = "#" Or _
			StringLeft($avInput[$i], 1) = ";" Or _
			StringLeft($avInput[$i], 2) = "/" _
			Then ContinueLoop

	; Check what IP is it and add it
	If IsIPv4($avInput[$i]) Then
		$iIPv4count += 1
		$sXMLcode &= '           <IP_ADDR ADDRESS="' & $avInput[$i] & '" />' & @LF
	ElseIf IsIPv6($avInput[$i]) Then
		$iIPv6count += 1
		$sXMLcode &= '           <IP6_ADDR ADDRESS="' & $avInput[$i] & '" />' & @LF
	Else
		$sWrongIPsLog &= "[" & $sInputFile_NameExt & "] line " & $i + 1 & @TAB & "IP is not valid: " & $avInput[$i] & @CRLF
		ContinueLoop ;Go on...
	EndIf
Next
$iIPcount = $iIPv4count + $iIPv6count

; Add end of XML file
$sXMLcode &= '          </REMOTE>' & @LF
$sXMLcode &= '         </RULE>' & @LF
$sXMLcode &= '        </RULES>' & @LF
$sXMLcode &= '       </NODE>' & @LF
$sXMLcode &= '      </NODE>' & @LF
$sXMLcode &= '     </PROFILES>' & @LF
$sXMLcode &= '    </PLUGIN>' & @LF
$sXMLcode &= '   </PLUGINS>' & @LF
$sXMLcode &= '  </SETTINGS>' & @LF
$sXMLcode &= ' </SECTION>' & @LF
$sXMLcode &= '</ESET>' & @LF

$sXMLcode &= @LF & '<!--' & @LF
$sXMLcode &= 'Title: ' & $sRuleName & @LF
$sXMLcode &= 'Product: ESET Smart Security' & @LF
$sXMLcode &= 'Module: Firewall' & @LF
$sXMLcode &= 'Description: This is a settings file for ESET Smart Security with a Firewall rule, which was created by the ' & $title & ' v' & $version & ' from ' & $author & '. More information about this tool you can get here: ' & $website & @LF
$sXMLcode &= 'Notes: This rule contains ' & $iIPcount & ' IP addresses. (' & $iIPv4count & 'x IPv4 and ' & $iIPv6count & 'x IPv6)' & @LF
$sXMLcode &= '-->'

; Write code to file
Local $sOutputFileHandle, $bileWriteSuccessful

$sOutputFileHandle = FileOpen($sOutputFile, $FO_OVERWRITE + $FO_UTF8_NOBOM)
If $sOutputFileHandle <> -1 Then ;file opend correctly
	$bileWriteSuccessful = FileWrite($sOutputFileHandle, $sXMLcode)
	If $bileWriteSuccessful Then
		$bileWriteSuccessful = FileClose($sOutputFileHandle)
	EndIf
Else ;file couldn't be opend
	$bileWriteSuccessful = 0
EndIf

; Evaluate result
Local $sText = "", $iMsgFlagAdd = $MB_ICONINFORMATION, $exitcode = 0
If $bileWriteSuccessful Then
	$sText &= _FileNameExt($sOutputFile) & " was successfully written. "
Else
	$sText &= _FileNameExt($sOutputFile) & " couldn't be written successfully. "
	$iMsgFlagAdd = $MB_ICONERROR
	$exitcode += 4
EndIf

If $sWrongIPsLog <> "" Then ; Error lines
	$sText &= "Some lines in your source file doesn't contain a valid IP. "
	$iMsgFlagAdd = $MB_ICONWARNING
	$exitcode += 1
Else ; All okay
	If $bileWriteSuccessful And $iIPcount <> 0 Then $sText &= "You can now import it into ESET Smart Security. "
EndIf
If $iIPcount = 0 Then
	$sText &= "Your rule doesn't contain any IP address. "
	$iMsgFlagAdd = $MB_ICONERROR
	$exitcode += 2
EndIf

If StringRight($sText, 1) = " " Then $sText = StringTrimRight($sText, 1) ;remove last space
If $sWrongIPsLog <> "" Then $sText &= @CRLF & @CRLF & $sWrongIPsLog

; Write Wrong IPs
If $bWriteWrongIPLog And $sWrongIPsLog <> "" Then
	$TMPFileHandle = FileOpen(@TempDir & "\" & $internalName & "_wrongIPs.log", $FO_OVERWRITE)
	If $TMPFileHandle <> -1 Then ;file opend correctly
		$successful = FileWrite($TMPFileHandle, $sWrongIPsLog)
		If $successful Then FileClose($TMPFileHandle)
	EndIf
EndIf

; Show result
If Not $bSilent Then MsgBox($MB_OK + $iMsgFlagAdd, $title, $sText)
If $bConsole Then ConsoleWrite($sText & @CRLF)

Exit $exitcode
#EndRegion PROCESS

#Region FUNCS: ERRORS
Func ErrorExit($errTitle, $errMsg)
	If Not $bSilent Then MsgBox($MB_ICONERROR + $MB_OK, $title & " - " & $errTitle, $errMsg)
	Exit 100
EndFunc   ;==>ErrorExit
#EndRegion FUNCS: ERRORS

#Region FUNCS: STRINGS
Func IsIPv4($sIP)
	Return StringRegExp($sIP, "^(25[0-5]|2[0-4][0-9]|1[0-9]{2}|0?[1-9][0-9]?|00[1-9])(\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)){3}$", $STR_REGEXPMATCH)
	; Thanks to http://www.autoitscript.com/forum/topic/111331-check-ip-format-and-value/#entry796682 for this regular expression.
EndFunc   ;==>IsIPv4

Func IsIPv6($sIP)
	Return StringRegExp($sIP, "^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))$", $STR_REGEXPMATCH)
	; Thanks to https://stackoverflow.com/questions/53497/regular-expression-that-matches-valid-ipv6-addresses for this regular expression.
EndFunc   ;==>IsIPv6

Func GetRuleOptionString($bIsActivated, $sDirection, $sAction, $bLog, $bNotifyUser)
	Local $sOutput = 'PROTO="101" '

	Switch $sDirection
		Case "In"
			$sOutput &= 'DIR="1" '
		Case "Out"
			$sOutput &= 'DIR="2" '
		Case "Both"
			$sOutput &= 'DIR="3" '
	EndSwitch

	Switch $sAction
		Case "Deny"
			$sOutput &= 'ACTION="0" '
		Case "Allow"
			$sOutput &= 'ACTION="40" '
		Case "Ask"
			$sOutput &= 'ACTION="50" '
	EndSwitch

	If $bIsActivated Then
		$sOutput &= 'DISABLED="0" '
	Else
		$sOutput &= 'DISABLED="1" '
	EndIf

	Select
		Case $bLog And Not $bNotifyUser
			$sOutput &= 'EXT_ACTION="1" '
		Case Not $bLog And $bNotifyUser
			$sOutput &= 'EXT_ACTION="2" '
		Case $bLog And $bNotifyUser
			$sOutput &= 'EXT_ACTION="3" '
	EndSelect

	Return StringTrimRight($sOutput, 1) ;(Delete the last space)
EndFunc   ;==>GetRuleOptionString
#EndRegion FUNCS: STRINGS

#Region FUNCS: GUI
Func SmallOptionsGUI($bIsActivated, $sDirection, $sAction, $bLog, $bNotifyUser)
	;Create GUI
	$hSOGUI = GUICreate($title & " - Other options", 160, 275)
	$idActivated = GUICtrlCreateCheckbox("Activated", 10, 10, -1, 15)

	GUICtrlCreateLabel("Direction:", 10, 33, 50, 13)
	$idDirection = GUICtrlCreateCombo("", 60, 30, 90, 20, $CBS_DROPDOWNLIST)

	GUICtrlCreateLabel("Action:", 10, 58, 50, 13)
	$idAction = GUICtrlCreateCombo("", 60, 55, 90, 20, $CBS_DROPDOWNLIST)

	$idLog = GUICtrlCreateCheckbox("Log", 10, 80, -1, 15)
	$idNotifyUser = GUICtrlCreateCheckbox("Notify user", 10, 100, -1, 15)
	$idShareable = GUICtrlCreateCheckbox("Create shareable XML file", 10, 120, -1, 15)
	GUICtrlSetTip(-1, "If activated this will create a XML file without any personal details.")

	$idOKButt = GUICtrlCreateButton("OK", 10, 150, 140, 25, $BS_DEFPUSHBUTTON)
	$idCancelButt = GUICtrlCreateButton("Cancel", 10, 180, 140, 25)

	GUICtrlCreateLabel("Note: The protocol TCP && UDP is used. If you want to change this you can do this after importing the rule.", 10, 215, 140, 55)
	GUICtrlSetFont(-1, 8)

	; Put in default values
	If $bIsActivated Then
		GUICtrlSetState($idActivated, $GUI_CHECKED)
	Else
		GUICtrlSetState($idActivated, $GUI_UNCHECKED)
	EndIf
	GUICtrlSetData($idDirection, "In|Out|Both", $sDirection)
	GUICtrlSetData($idAction, "Deny|Allow|Ask", $sAction)
	If $bLog Then
		GUICtrlSetState($idLog, $GUI_CHECKED)
	Else
		GUICtrlSetState($idLog, $GUI_UNCHECKED)
	EndIf
	If $bNotifyUser Then
		GUICtrlSetState($idNotifyUser, $GUI_CHECKED)
	Else
		GUICtrlSetState($idNotifyUser, $GUI_UNCHECKED)
	EndIf
	If $bShareable Then
		GUICtrlSetState($idShareable, $GUI_CHECKED)
	Else
		GUICtrlSetState($idShareable, $GUI_UNCHECKED)
	EndIf

	; Show GUI
	GUISetState(@SW_SHOW)

	While 1
		Switch GUIGetMsg()
			Case $idOKButt
				GUISetCursor(15, 1) ;15 = Waiting
				GUISetState(@SW_DISABLE)
				ExitLoop
			Case $GUI_EVENT_CLOSE, $idCancelButt
				GUIDelete()
				Return SetError(1)
		EndSwitch
	WEnd

	; Read values
	$Input_IsActivated = GUICBIsChecked($idActivated)
	$Input_Direction = GUICtrlRead($idDirection)
	$Input_Action = GUICtrlRead($idAction)
	$Input_IsLog = GUICBIsChecked($idLog)
	$Input_IsNotify = GUICBIsChecked($idNotifyUser)
	$Input_Shareable = GUICBIsChecked($idShareable)

;~ 	MsgBox(0, "", "$Input_IsActivated = " & $Input_IsActivated & @CRLF & _
;~ 	"$Input_Direction = " & $Input_Direction & @CRLF & _
;~ 	"$Input_Action = " & $Input_Action & @CRLF & _
;~ 	"$Input_IsLog = " & $Input_IsLog & @CRLF & _
;~ 	"$Input_IsNotify = " & $Input_IsNotify) ;(debug)

	; Form option string
	GUIDelete()
	$bShareable = $Input_Shareable
	Return GetRuleOptionString($Input_IsActivated, $Input_Direction, $Input_Action, $Input_IsLog, $Input_IsNotify)
EndFunc   ;==>SmallOptionsGUI

Func GUICBIsChecked($idControlID)
	Return BitAND(GUICtrlRead($idControlID), $GUI_CHECKED) = $GUI_CHECKED
EndFunc   ;==>GUICBIsChecked
#EndRegion FUNCS: GUI

#Region FUNCS: FILEPATH
Func _FileName($path)
	$path = _FileNameExt($path) ;Remove dir
	If @error Then Return SetError(2)

	;Delete file extension
	Local $posDot = StringInStr($path, ".", 0, -1)
	If Not $posDot Then Return SetError(1, 0, $path) ;Error --> the path doesn't contain a file extension
	$path = StringLeft($path, $posDot - 1)
	Return $path
EndFunc   ;==>_FileName

Func _FileNameExt($path)
	$path = StringReplace($path, '"', '')
	Local $pos = StringInStr($path, "\", 0, -1)
	If Not $pos Then Return SetError(0, 1, $path) ;Cancel --> the path doesn't contain a dir (However in most cases the output is still correct)
	$path = StringTrimLeft($path, $pos)
	Return $path
EndFunc   ;==>_FileNameExt
#EndRegion FUNCS: FILEPATH
