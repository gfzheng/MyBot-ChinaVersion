; #FUNCTION# ====================================================================================================================
; Name ..........: TestLanguage
; Description ...: This function tests if the game is in english language
; Syntax ........:
; Parameters ....: None
; Return values .: None
; Author ........: Sardo (2015-06) , MHK2012 (2018-02)
; Modified ......: Hervidero(2015)
;
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================

Func TestLanguage()
	If Not $g_bRunState Then Return
	SetLog("Checking for UI Language", $COLOR_INFO)
	
	;Local $sTest = "大本營"
	
	;If $sTest = "大本營" Then 
	;	SetLog("大本營")
	;Else
	;	SetLog("Hmmm.....")
	;EndIf

	Local $sImgSimplifiedChinese =  @ScriptDir & "\imgxml\Language\SimplifiedChinese*"
	Local $sSearchArea = "15,685,110,715"
	Local $aSimplifiedChinese = decodeSingleCoord(findImage("TestLanguage", $sImgSimplifiedChinese, GetDiamondFromRect($sSearchArea), 1, True, Default))

	If IsArray($aSimplifiedChinese) And UBound($aSimplifiedChinese, 1) = 2 Then
		SetLog("Clash Language UI = Simplified Chinese", $COLOR_INFO)
		$g_SimplifiedChinese = True

		$aArmyCampSize[0] = 76
		$aArmyCampSize[1] = 136 + $g_iMidOffsetY ; Training Window, Overview screen, Current Size/Total Size

		$aSiegeMachineSize[0] = 682
		$aSiegeMachineSize[1] = 136 + $g_iMidOffsetY ; Training Window, Overview screen, Current Number/Total Number

		$aArmySpellSize[0] = 77
		$aArmySpellSize[1] = 284 + $g_iMidOffsetY ; Training Window Overviewscreen, current number/total capacity

		;$g_aArmyCCSpellSize[0] = 473
		;$g_aArmyCCSpellSize[1] = 438 + $g_iMidOffsetY ; Training Window, Overview Screen, Current CC Spell number/total cc spell capacity
		
		;$aIsAttackPage[0] = 56
		;$aIsAttackPage[1] = 548	+ $g_iBottomOffsetY
		;$aIsAttackPage[2] = 0xD11010
		;$aIsAttackPage[3] = 20 ; red button "end battle" 860x780 ; CHINA VERSION
		Return True
	EndIf

	; test the word "Attack!" on the Attack Button in the lower left corner
	If getOcrLanguage($aDetectLang[0], $aDetectLang[1]) = "english" Then
		SetLog("Language setting is English: Correct.", $COLOR_INFO)
		Return True
	ElseIf Not ChangeLanguage() Then
		SetLog("Language setting is Wrong: Change CoC language to English!", $COLOR_ERROR)
		btnStop()
	EndIf
EndFunc

Func ChangeLanguage()
	SetLog("Change Language To English", $COLOR_INFO)

	If IsMainPage() Then Click($aButtonSetting[0], $aButtonSetting[1], 1, 0, "Click Setting")
	If _Sleep(500) Then Return False

	For $i = 0 To 20 ; Checking Green Language Button continuously in 20sec
		If _ColorCheck(_GetPixelColor($aButtonLanguage[0], $aButtonLanguage[1], True), Hex($aButtonLanguage[2], 6), $aButtonLanguage[3]) Then ;	Green
			Click($aButtonLanguage[0], $aButtonLanguage[1], 1, 1000) ; Click Language Button
			SetLog("   1. Click Language Button")
			If _Sleep(200) Then Return False
			ExitLoop
		EndIf
		If $i = 20 Then Return False
		If _Sleep(900) Then Return False
	Next

	For $i = 0 To 20 ; Checking Language List continuously in 20sec
		If _ColorCheck(_GetPixelColor($aListLanguage[0], $aListLanguage[1], True), Hex($aListLanguage[2], 6), $aListLanguage[3]) Then ;	Green
			ClickDrag(Random(370, 375, 1), Random(170, 175, 1), Random(370, 375, 1), Random(590, 595, 1), 200)
			If _Sleep(200) Then Return False
			ClickDrag(Random(370, 375, 1), Random(170, 175, 1), Random(370, 375, 1), Random(380, 385, 1), 200)
			If _Sleep(900) Then Return False
			If _ColorCheck(_GetPixelColor($aEnglishLanguage[0], $aEnglishLanguage[1], True), Hex($aEnglishLanguage[2], 6), $aEnglishLanguage[3]) Then ;	Grey
				Click($aEnglishLanguage[0], $aEnglishLanguage[1], 1, 1000) ; Click Language Button
				SetLog("   2. Click English Language")
				If _Sleep(300) Then Return False
				ExitLoop
			EndIf
		EndIf
		If $i = 20 Then Return False
		If _Sleep(900) Then Return False
	Next

	For $i = 0 To 10 ; Checking OKAY Button continuously in 10sec
		If _ColorCheck(_GetPixelColor($aLanguageOkay[0], $aLanguageOkay[1], True), Hex($aLanguageOkay[2], 6), $aLanguageOkay[3]) Then
			If _Sleep(250) Then Return False
			Click($aLanguageOkay[0], $aLanguageOkay[1], 1, 0, "Click OKAY")
			SetLog("   3. Click OKAY")
			SetLog("Please wait for loading CoC...!")
			waitMainScreen()
			Return True
		EndIf
		If $i = 10 Then Return False
		If _Sleep(900) Then Return False
	Next

	Return False
EndFunc   ;==>TestLanguage
