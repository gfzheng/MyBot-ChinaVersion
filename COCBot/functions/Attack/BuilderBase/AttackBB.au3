; #FUNCTION# ====================================================================================================================
; Name ..........: PrepareAttackBB
; Description ...: This file controls attacking preperation of the builders base
; Syntax ........:
; Parameters ....: None
; Return values .: None
; Author ........: Chilly-Chill (04-2019)
; Modified ......: GrumpyHog (06-2022)
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2017
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
Local $ai_AttackDropPoints


; Only Clan Games requires a preset number of Attacks
Func AttackBB($iNumberOfAttacks = 0)

	If Not $g_bChkEnableBBAttack And $iNumberOfAttacks = 0 Then Return False

	; active CG skip regular attacks
	;If Not $g_bClanGamesCompleted And $g_IsClanGamesActive And $iNumberOfAttacks = 0 Then 
	;	SetLog("Clan Games Active pausing regular BB Attacks")
	;	Return False 
	;Else
	SetLog("Proceeding with regular BB Attacks")
	;EndIf

	SetLog("$g_bChkBBStorageFull: " & $g_bChkBBStorageFull)
	SetLog("$g_bChkBBTrophyRange: " & $g_bChkBBTrophyRange)
	SetLog("$g_bChkBBAttIfLootAvail: " & $g_bChkBBAttIfLootAvail)
	SetLog("$g_bChkBBWaitForMachine: " & $g_bChkBBWaitForMachine)

	local $iSide, $aBMPos
	local $bAttack = True
	Local $iAttack = 1
	Local $bClanGames = True

	If Not ClickAttack() Then
	  SetLog("Can't find attack button")
	  Return False
   EndIf

	If _Sleep(1500) Then Return

	; if 0 will attack until no loot
	If $iNumberOfAttacks = 0 Then $bClanGames = False

	SetLog("Number of Attacks: " & $iNumberOfAttacks)

	While 1
		$iSide = Random(0, 3, 1) ; randomly choose top left or top right
		$aBMPos = 0

		; check for troops, loot and Batlle Machine
		If Not PrepareAttackBB($bClanGames) Then
			SetLog("PrepareAttackBB failed")
			ClickAway()
			ZoomOut()
			Return False
		EndIf

		SetLog("Attack : " & $iAttack, $COLOR_BLUE)
		SetDebugLog("PrepareAttackBB(): Success.")

		; search for a match
		If _Sleep(2000) Then Return

		local $aBBFindNow = [521, 308, 0xffc246, 30] ; search button

		If _CheckPixel($aBBFindNow, True) Then
			PureClick($aBBFindNow[0], $aBBFindNow[1])
		Else
			SetLog("Could not locate search button to go find an attack.", $COLOR_ERROR)
			Return
		EndIf

		If _Sleep(1500) Then Return ; give time for find now button to go away

		If _CheckPixel($aBBFindNow, True) Then ; click failed so something went wrong
			SetLog("Click BB Find Now failed. We will come back and try again.", $COLOR_ERROR)
			ClickAway()
			ZoomOut()
			Return
		EndIf

		local $iAndroidSuspendModeFlagsLast = $g_iAndroidSuspendModeFlags
		$g_iAndroidSuspendModeFlags = 0 ; disable suspend and resume
		If $g_bDebugSetlog = True Then SetDebugLog("Android Suspend Mode Disabled")

		; wait for the clouds to clear
		SetLog("Searching for Opponent.", $COLOR_BLUE)
		local $timer = __TimerInit()
		local $iPrevTime = 0

		While Not CheckBattleStarted()
			local $iTime = Int(__TimerDiff($timer)/ 60000)

			If ConnectionLost(False) Then Return False

			If $iTime > $iPrevTime Then ; if we have increased by a minute
				SetLog("Clouds: " & $iTime & "-Minute(s)")
				$iPrevTime = $iTime
			EndIf

			If _Sleep($DELAYRESPOND) Then
				$g_iAndroidSuspendModeFlags = $iAndroidSuspendModeFlagsLast
				If $g_bDebugSetlog = True Then SetDebugLog("Android Suspend Mode Enabled")
				Return
			EndIf
		WEnd

		ZoomOut()
	
		If _Sleep(250) Then Return

		SaveVillageDebugImage()
		
		If _Sleep(250) Then Return

		;_GetRedArea()
		
		;If _Sleep(250) Then Return
		
		;AttackCSVDebugImage()

		;generate attack drop points
		Switch $iSide
			Case 0
				$ai_AttackDropPoints = _GetVectorOutZone($eVectorLeftTop)
			Case 1
				$ai_AttackDropPoints = _GetVectorOutZone($eVectorRightTop)
			Case 2
				$ai_AttackDropPoints = _GetVectorOutZone($eVectorRightBottom)
			Case Else
				$ai_AttackDropPoints = _GetVectorOutZone($eVectorLeftBottom)
		EndSwitch

		; Get troops on attack bar and their quantities
		local $aBBAttackBar = GetAttackBarBB()
		If _Sleep($DELAYRESPOND) Then
			$g_iAndroidSuspendModeFlags = $iAndroidSuspendModeFlagsLast
			If $g_bDebugSetlog = True Then SetDebugLog("Android Suspend Mode Enabled")
			Return
		EndIf

	  ; Deploy all troops
	  local $bTroopsDropped = False, $bBMDeployed = False
	  SetLog( $g_bBBDropOrderSet = True ? "Deploying Troops in Custom Order." : "Deploying Troops in Order of Attack Bar.", $COLOR_BLUE)
	  While Not $bTroopsDropped
		local $iNumSlots = UBound($aBBAttackBar, 1)
		If $g_bBBDropOrderSet = True Then
			local $asBBDropOrder = StringSplit($g_sBBDropOrder, "|")
			For $i=0 To $g_iBBTroopCount - 1 ; loop through each name in the drop order
				local $j=0, $bDone = 0
				While $j < $iNumSlots And Not $bDone
					If $aBBAttackBar[$j][0] = $asBBDropOrder[$i+1] Then
						DeployBBTroop($aBBAttackBar[$j][0], $aBBAttackBar[$j][1], $aBBAttackBar[$j][2], $aBBAttackBar[$j][4], $iSide)
						If $j = $iNumSlots-1 Or $aBBAttackBar[$j][0] <> $aBBAttackBar[$j+1][0] Then
							$bDone = True
							If _Sleep($g_iBBNextTroopDelay) Then ; wait before next troop
								$g_iAndroidSuspendModeFlags = $iAndroidSuspendModeFlagsLast
								If $g_bDebugSetlog = True Then SetDebugLog("Android Suspend Mode Enabled")
								Return
							EndIf
						EndIf
					EndIf
					$j+=1
				WEnd
			Next
		Else
			For $i=0 To $iNumSlots - 1
				DeployBBTroop($aBBAttackBar[$i][0], $aBBAttackBar[$i][1], $aBBAttackBar[$i][2], $aBBAttackBar[$i][4], $iSide)
				If $i = $iNumSlots-1 Or $aBBAttackBar[$i][0] <> $aBBAttackBar[$i+1][0] Then
					If _Sleep($g_iBBNextTroopDelay) Then ; wait before next troop
						$g_iAndroidSuspendModeFlags = $iAndroidSuspendModeFlagsLast
						If $g_bDebugSetlog = True Then SetDebugLog("Android Suspend Mode Enabled")
						Return
					EndIf
				Else
					If _Sleep($DELAYRESPOND) Then ; we are still on same troop so lets drop them all down a bit faster
						$g_iAndroidSuspendModeFlags = $iAndroidSuspendModeFlagsLast
						If $g_bDebugSetlog = True Then SetDebugLog("Android Suspend Mode Enabled")
						Return
					EndIf
				EndIf
			Next
		EndIf
		$aBBAttackBar = GetAttackBarBB(True)
		If $aBBAttackBar = "" Then $bTroopsDropped = True
	  WEnd

	  SetLog("All Troops Deployed", $COLOR_SUCCESS)

	  ; place hero and activate ability
	  If $g_bBBMachineReady And Not $bBMDeployed Then SetLog("Deploying Battle Machine.", $COLOR_BLUE)
	  While Not $bBMDeployed And $g_bBBMachineReady
		$aBMPos = GetMachinePos()
		If IsArray($aBMPos) Then
			PureClickP($aBMPos)

			; get random drop point
			Local $iPoint = Random(0, UBOUND($ai_AttackDropPoints) - 1, 1)
			Local $iPixel = $ai_AttackDropPoints[$iPoint]
			PureClickP($iPixel)

			If _Sleep(500) Then ; wait before clicking ability
				$g_iAndroidSuspendModeFlags = $iAndroidSuspendModeFlagsLast
				If $g_bDebugSetlog = True Then SetDebugLog("Android Suspend Mode Enabled")
				Return
			EndIf
			PureClickP($aBMPos) ; potentially add sleep here later, but not needed at the moment
		Else
			$bBMDeployed = True ; true if we dont find the image... this logic is because sometimes clicks can be funky so id rather keep looping till image is gone rather than until we think we have deployed
		EndIf
	  WEnd

	  If $bBMDeployed Then SetLog("Battle Machine Deployed", $COLOR_SUCCESS)

	  ; Continue with abilities until death
	  local $bMachineAlive = True
	  while $bMachineAlive And $bBMDeployed
		If _Sleep($g_iBBMachAbilityTime) Then ; wait for machine to be available
			$g_iAndroidSuspendModeFlags = $iAndroidSuspendModeFlagsLast
			If $g_bDebugSetlog = True Then SetDebugLog("Android Suspend Mode Enabled")
			Return
		EndIf
		local $timer = __TimerInit() ; give a bit of time to check if hero is dead because of the random lightning strikes through graphic
		$aBMPos = GetMachinePos()
		While __TimerDiff($timer) < 3000 And Not IsArray($aBMPos) ; give time to find
			$aBMPos = GetMachinePos()
		 WEnd

		If Not IsArray($aBMPos) Then ; if machine wasnt found then it is dead, if not we hit ability
			$bMachineAlive = False
		Else
			PureClickP($aBMPos)
		EndIf
	  WEnd

	  If $bBMDeployed And Not $bMachineAlive Then SetLog("Battle Machine Dead")

	  ; wait for end of battle
	  SetLog("Waiting for end of battle.", $COLOR_BLUE)
	  If Not Okay() Then
		 $g_iAndroidSuspendModeFlags = $iAndroidSuspendModeFlagsLast
		 If $g_bDebugSetlog Then SetDebugLog("Android Suspend Mode Enabled")
		 Return
	  EndIf

	  SetLog("Battle ended")
	  If _Sleep(3000) Then
		$g_iAndroidSuspendModeFlags = $iAndroidSuspendModeFlagsLast
		If $g_bDebugSetlog Then SetDebugLog("Android Suspend Mode Enabled")
		Return
	  EndIf

	  ; wait for ok after both attacks are finished
	  SetLog("Waiting for opponent", $COLOR_BLUE)
	  Okay()

	  SetLog("Done", $COLOR_SUCCESS)

	If _Sleep(1500) Then Return

	$iAttack += 1

	If $bClanGames Then
		If $iAttack > $iNumberOfAttacks Then ExitLoop
	EndIf

	WEnd

	$g_iAndroidSuspendModeFlags = $iAndroidSuspendModeFlagsLast ; reset android suspend and resume stuff
	If $g_bDebugSetlog Then SetDebugLog("Android Suspend Mode Enabled")

	If _Sleep(2000) Then Return

	ClickAway()
	ZoomOut()

	Return True
EndFunc

Func CheckBattleStarted()
	local $sSearchDiamond = GetDiamondFromRect("376,10,460,28")

	local $aCoords = decodeSingleCoord(findImage("BBBattleStarted", $g_sImgBBBattleStarted, $sSearchDiamond, 1, True))
	If IsArray($aCoords) And UBound($aCoords) = 2 Then
		SetLog("Battle Started", $COLOR_SUCCESS)
		Return True
	EndIf

	Return False ; If battle not started
EndFunc

Func GetMachinePos()
	If Not $g_bBBMachineReady Then Return

	local $sSearchDiamond = GetDiamondFromRect("0,630,860,732")
	local $aCoords = decodeSingleCoord(findImage("BBBattleMachinePos", $g_sImgBBBattleMachine, $sSearchDiamond, 1, True))

	If IsArray($aCoords) And UBound($aCoords) = 2 Then
		Return $aCoords
	Else
		If $g_bDebugImageSave Then SaveDebugImage("BBBattleMachinePos")
	EndIf

	Return
EndFunc

Func Okay()
	local $timer = __TimerInit()

	While 1
		local $aCoords = decodeSingleCoord(findImage("OkayButton", $g_sImgOkButton, "FV", 1, True))
		If IsArray($aCoords) And UBound($aCoords) = 2 Then
			PureClickP($aCoords)
			Return True
		EndIf

		; check for advert
		If $g_sAndroidGameDistributor = "Magic" Then ClashOfMagicAdvert()

		If ConnectionLost(False) Then Return False

		If __TimerDiff($timer) >= 180000 Then
			SetLog("Could not find button 'Okay'", $COLOR_ERROR)
			If $g_bDebugImageSave Then SaveDebugImage("BBFindOkay")
			Return False
		EndIf

		If Mod(__TimerDiff($timer), 3000) Then
			If _Sleep($DELAYRESPOND) Then Return
		EndIf
	WEnd

	Return True
EndFunc

Func DeployBBTroop($sName, $x, $y, $iAmount, $iSide)
	SetLog("Deploying " & $sName & "x" & String($iAmount), $COLOR_ACTION)
	PureClick($x, $y) ; select troop
	If _Sleep($g_iBBSameTroopDelay) Then Return ; slow down selecting then dropping troops

   For $j=0 To $iAmount - 1
		; get random drop point
		Local $iPoint = Random(0, UBOUND($ai_AttackDropPoints) - 1, 1)
		Local $iPixel = $ai_AttackDropPoints[$iPoint]
		
		PureClickP($iPixel)
		
		If _Sleep($g_iBBSameTroopDelay) Then Return ; slow down dropping of troops
	Next
 EndFunc

 Func _ClickAttack()
	local $aColors = [[0xfdd79b, 96, 0], [0xffffff, 20, 50], [0xffffff, 69, 50]] ; coordinates of pixels relative to the 1st pixel
	Local $ButtonPixel = _MultiPixelSearch(8, 640, 120, 755, 1, 1, Hex(0xeac68c, 6), $aColors, 20)
	local $bRet = False

	If IsArray($ButtonPixel) Then
		SetDebugLog(String($ButtonPixel[0]) & " " & String($ButtonPixel[1]))
		PureClick($ButtonPixel[0] + 25, $ButtonPixel[1] + 25) ; Click fight Button
		$bRet = True
	Else
		SetLog("Can not find button for Builders Base Attack button", $COLOR_ERROR)
		If $g_bDebugImageSave Then SaveDebugImage("BBAttack_ButtonCheck_")
	EndIf
	Return $bRet
EndFunc

Func ClickAttack()
	local $aCoords = decodeSingleCoord(findImage("ClickAttack", $g_sImgBBAttackButton, GetDiamondFromRect("10,620,115,720"), 1, True))
	local $bRet = False

	If IsArray($aCoords) And UBound($aCoords) = 2 Then
		SetDebugLog(String($aCoords[0]) & " " & String($aCoords[1]))
		PureClick($aCoords[0], $aCoords[1]) ; Click Attack Button
		$bRet = True
	Else
		SetLog("Can not find button for Builders Base Attack button", $COLOR_ERROR)
		If $g_bDebugImageSave Then SaveDebugImage("ClickAttack")
	EndIf

	Return $bRet
EndFunc
