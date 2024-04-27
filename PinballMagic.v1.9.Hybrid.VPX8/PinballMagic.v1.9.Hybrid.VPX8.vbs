'************************************************************
'************************************************************
'Ok, so this is a rebuild of my original plus all of the original contributions
'I've removed the raised playfield to allow for reflections
'Added playfield mesh so the playfield holes work as actual holes.
'removed the manual trough and a lot of the manual pinmame code that was done 
'and converted back to pinmame classes.
'converted all images to webp to lessen the file size.
'Added vr room thanks to sixtoe for his room and parts from it.
'spiral ramp still works with just physics but due to some change in vpx8 physics i had to add a helper for the end of the ramp,
'Lights converted to pinmame automatic lights using vpx fading and lightmaps
'Physics are now a mesh of roth's/nfozzy and jp's physics 3
'
'  Pinball Magic (CAPCOM 1995) - IPD No. 3596
'
'   Credits:
'
'     VPX by unclewilly, rothbauerw
'     Contributions from:
'        DJRobX (switch debugging and stage functionality, this never worked before, IT DOES NOW!!!)
'        randr (hand and misc primitivies)
'
'
'************************************************************
'************************************************************

Option Explicit
Randomize

'******************************************************
' 						OPTIONS
'******************************************************

Const EnableBallControl = False		'set to false to disable the C key from taking manual control
Const BypassMagnet = 1				'0 for default behavior, 1 to bypass magnet activation for trunk to prevent rom from enabling coil protection (DOF 112 for shaker) 
Const flasherintensity = .5  '1 for default  decimal to lower intensity 0-1

Dim FIobj
	for each FIobj in FLASHERS
		FIobj.IntensityScale = (FIobj.IntensityScale * flasherintensity)
	Next

'******************************************************
' 					STANDARD DEFINITIONS
'******************************************************


Const cGameName = "pmv112"
Const BallSize = 50
Const BallMass = 1

Const UseSolenoids = 1
Const UseLamps = 1
Const UseSync = 1
Const HandleMech = 0 

'Standard Sounds
Const SSolenoidOn = "Solenoid"
Const SSolenoidOff = ""
Const SCoin = "coin"

'******************************************************
' 					TABLE INIT
'******************************************************
Dim VarHidden, UseVPMColoredDMD, xx,  ClearBall
 UseVPMColoredDMD = True
Dim PlungerOption:PlungerOption = 1		

if Version < 10400 then msgbox "This table requires Visual Pinball 10.4 beta or newer!" & vbnewline & "Your version: " & Version/1000

On Error Resume Next
ExecuteGlobal GetTextFile("controller.vbs")
If Err Then MsgBox "You need the controller.vbs in order to run this table, available in the vp10 package"
On Error Goto 0

LoadVPM "01560000", "capcom.VBS", 3.26 

Dim DesktopMode, bsTrough, bsGenie

Sub Table1_Init
	vpmInit Me
	With Controller
		.GameName =  cGameName
		If Err Then MsgBox "Can't start Game " & cGameName & vbNewLine & Err.Description:Exit Sub
		.SplashInfoLine = "Pinball Magic" & vbNewLine & "by unclewilly/rothbauerw VPX"
		.HandleKeyboard = 0
		.ShowTitle = 0
		.ShowDMDOnly = 1
		.ShowFrame = 0
		.HandleMechanics = 0
		On Error Resume Next
		.Run GetPlayerHWnd
		If Err Then MsgBox Err.Description
		On Error Goto 0
	End With

	'Nudging
    vpmNudge.TiltSwitch=10
    vpmNudge.Sensitivity=1
    vpmNudge.TiltObj=Array(Bumper1b,LeftSlingshot,RightSlingshot)
 
    vpmMapLights aLights

	WandDiv.IsDropped=1:WandDiv1.IsDropped=0
	StageDiverter3.isDropped=1
	Kickback.PullBack

    '************  Trough	**************************
    Set bsTrough = New cvpmBallStack
    With bsTrough
        .InitSw 73, 74, 75, 76, 0, 0, 0, 0
        .InitKick ballrelease, 90, 10
        .InitExitSnd SoundFX("fx_ballrel", DOFContactors), SoundFX("fx_Solenoid", DOFContactors)
        .Balls = 3
    End With

    Set bsGenie = New cvpmBallStack
    With bsGenie
        .InitSw 0, 28, 29, 30, 0, 0, 0, 0
		.InitKick sw28, 325, 40
        .InitExitSnd SoundFX("fx_popper", DOFContactors), SoundFX("fx_Solenoid", DOFContactors)
    End With
    '************  Captive Ball	**************************
	Kicker3.CreateSizedballWithMass Ballsize/2,Ballmass
	kicker3.kick 0, 0
	set ClearBall = Kicker4.CreateSizedballWithMass(30,Ballmass*3/4)
	ClearBall.visible = False
	kicker4.kick 180, 10
	kicker4.enabled = false

    
	'**Main Timer init
	PinMAMETimer.Interval = PinMAMEInterval
	PinMAMETimer.Enabled = 1

	'** Stage
	Controller.Switch(59)= 1
	Controller.Switch(58)= 0
	CreateLBall

	'** Wand
	Controller.Switch(67)=1
	Controller.Switch(68)=0
	CriticDiv.IsDropped = 1
	TrunkDiv.IsDropped = 0
	ramp19.collidable = false

	If DesktopMode = False Then
		
	End If

	If PlungerOption = 1 Then

	Else

	End If
Dim uw
	If  RenderingMode = 2 Then
		for each uw in VRRoom
			uw.visible = true
		Next
	End If
	If  ShowFSS Then
		for each uw in VRRoom
			uw.visible = true
		Next
	End If
	LoadLUT

End Sub

Sub Table1_Paused:Controller.Pause = 1:End Sub
Sub Table1_unPaused:Controller.Pause = 0:End Sub
Sub Table1_Exit
	DOF 101, DOFOff
	DOF 102, DOFOff
	DOF 103, DOFOff
	DOF 104, DOFOff
	DOF 105, DOFOff
	DOF 110, DOFOff
	DOF 111, DOFOff
	DOF 112, DOFOff
	Controller.Stop
End Sub

'******************************************************
' 						KEYS
'******************************************************

Sub Table1_KeyDown(ByVal keycode)
	If keycode = LeftFlipperKey Then SolLFlipper(True)
	If keycode = RightFlipperKey Then SolRFlipper(True)
	If keycode = plungerkey then 
		If PlungerOption = 1 then
			plunger1.PullBack
		Else
			plunger.PullBack
		End If
		PlaySoundAt "fx_PlungerPull" , Plunger1 'PlaySound "plungerpull",0,1,AudioPan(Plunger),0.25,0,0,1,AudioFade(Plunger)
		TimerPlunger.Enabled = True
		TimerPlunger2.Enabled = False
	End If
	If keycode = LeftTiltKey Then Nudge 90, 4
	If keycode = RightTiltKey Then Nudge 270, 4
	If keycode = CenterTiltKey Then Nudge 0, 5
	If KeyCode = KeyFront then Controller.Switch(11)=1

    If keycode = RightMagnaSave AND bLutActive Then NextLUT:End If
    If keycode = LeftMagnaSave Then bLutActive = True:SetLUTLine "Color LUT image " & table1.ColorGradeImage

    ' Manual Ball Control
	If keycode = 46 Then	 				' C Key
		If contball = 1 Then
			contball = 0
		Else
			contball = 1
		End If
	End If
	If keycode = 48 Then 				' B Key
		If BCboost = 1 Then
			BCboost = BCboostmulti
		Else
			BCboost = 1
		End If
	End If
	If keycode = 203 Then BCleft = 1	' Left Arrow
	If keycode = 200 Then BCup = 1		' Up Arrow
	If keycode = 208 Then BCdown = 1	' Down Arrow
	If keycode = 205 Then BCright = 1	' Right Arrow

	If vpmKeyDown(keycode) Then Exit Sub 
End Sub

Sub Table1_KeyUp(ByVal keycode)
	If keycode = LeftFlipperKey Then SolLFlipper(False)
	If keycode = RightFlipperKey Then SolRFlipper(False)
    If keycode = LeftMagnaSave Then bLutActive = False:HideLUT
	If keycode = plungerkey then
		If PlungerOption = 1 then
			plunger1.fire
		Else
			plunger.fire
		End If
		PlaySoundAt "fx_plunger" , Plunger1 'PlaySound "plunger",0,1,AudioPan(Plunger),0.25,0,0,1,AudioFade(Plunger)
		TimerPlunger.Enabled = False
		TimerPlunger2.Enabled = True
		VR_Primary_plunger.Y = -173
	End If
	If KeyCode = KeyFront then Controller.Switch(11)=0

    'Manual Ball Control
	If keycode = 203 Then BCleft = 0	' Left Arrow
	If keycode = 200 Then BCup = 0		' Up Arrow
	If keycode = 208 Then BCdown = 0	' Down Arrow
	If keycode = 205 Then BCright = 0	' Right Arrow

	If vpmKeyUp(keycode) Then Exit Sub
End Sub

Sub TimerPlunger_Timer
  If VR_Primary_plunger.Y < -38 then
  		VR_Primary_plunger.Y = VR_Primary_plunger.Y + 5
  End If
End Sub

Sub TimerPlunger2_Timer
 'debug.print plunger.position
  VR_Primary_plunger.Y = -173 + (5* Plunger1.Position) -20
End Sub
'******************************************************
' 						SOLENOIDS
'******************************************************

SolCallback(1)="SolTrunk"
SolCallback(2)="SolGenie"
SolCallback(5)="SolKB"
SolCallback(6)="bsTrough.SolOut"
SolCallback(7)="bsTrough.SolIn"
SolCallBack(8)="vpmSolSound SoundFX(""Knocker"",DOFKnocker),"

SolCallback(11)="SolStageDoors"
SolCallback(12)="SolStageKicker"
SolCallback(13)="SolStageDiverter"
SolCallback(14)="SolWandDiverter"
SolCallback(17)="SolWand"
SolCallback(18)="SolElevator"
SolCallback(19)="DropReset"
SolCallback(20)="SolMag"

SolCallback(26)="vpmFlasher l176,"
SolCallback(27)="vpmFlasher l177,"
SolCallback(28)="vpmFlasher Array(l179LF,l178LF,lbg28l),"
SolCallback(29)="vpmFlasher Array(l179s2,l179s1),"
SolCallback(30)="vpmFlasher l180a,"
SolCallback(31)="vpmFlasher Array(l181b2,l181b,l181b3),"
SolCallback(32)="vpmFlasher Array(l182,l182b,l182c,l182d),"   'bg
'BACKGLASS
SolCallback(23)="vpmFlasher lbg23l,"
SolCallback(24)="vpmFlasher lbg24l,"
SolCallback(21)="vpmFlasher lbg21l,"
SolCallback(22)="vpmFlasher lbg22l,"
SolCallback(25)="vpmFlasher lbg25l,"
'**************
' Solenoid Subs
'**************

'***** Flippers *************************
 
'SolCallback(sLRFlipper) = "SolRFlipper"
'SolCallback(sLLFlipper) = "SolLFlipper"

Dim LeftKeyDown, RightKeyDown, FlippersEnabled

Function AllInTrough(drainhit)
dim x
		AllinTrough = False
		x = bsTrough.Balls()
		If  x = 3 then
			AllInTrough = True
	end If
End Function

Sub SolLFlipper(Enabled)
    If Enabled Then
		If NOT AllInTrough(0) Then
        PlaySoundAt SoundFX("fx_flipperup", DOFFlippers), LeftFlipper
			LF.Fire  'leftflipper.rotatetoend
			DOF 110, DOFOn
		Else
			DisableFlippers
		End If
		LeftKeyDown = True
    Else
		If NOT AllInTrough(0) Then
        PlaySoundAt SoundFX("fx_flipperdown", DOFFlippers), LeftFlipper
			LeftFlipper.RotateToStart
			DOF 110, DOFOff
		End if
		LeftKeyDown = False
    End If
End Sub
'
Sub SolRFlipper(Enabled)
    If Enabled Then
		If NOT AllInTrough(0) Then
        PlaySoundAt SoundFX("fx_flipperup", DOFFlippers), RightFlipper
		RF.Fire 'rightflipper.rotatetoend
			DOF 111, DOFOn
		Else 
			DisableFlippers
		End If
		RightKeyDown = True
    Else
		If NOT AllInTrough(0) Then
        PlaySoundAt SoundFX("fx_flipperdown", DOFFlippers), RightFlipper
			RightFlipper.RotateToStart
			DOF 111, DOFOff
		End If
		RightKeyDown = False
    End If
End Sub

Sub DisableFlippers()
	FlippersEnabled = False

	Bumper1b.threshold = 100
	LeftSlingShot.slingshotthreshold = 100
	RightSlingShot.slingshotthreshold = 100
	RightSlingShot1.slingshotthreshold = 100

	If LeftFlipper.currentAngle < LeftFlipper.StartAngle Then
		        PlaySoundAt SoundFX("fx_flipperdown", DOFFlippers), LeftFlipper
		LeftFlipper.RotateToStart
		DOF 110, DOFOff
	End If
	If RightFlipper.currentAngle > RightFlipper.StartAngle Then
        PlaySoundAt SoundFX("fx_flipperdown", DOFFlippers), RightFlipper
		RightFlipper.RotateToStart
		DOF 111, DOFOff
	End If
End Sub

Sub ActivateFlippers()
	FlippersEnabled = True

	Bumper1b.threshold = 3
	LeftSlingShot.slingshotthreshold = 3
	RightSlingShot.slingshotthreshold = 3
	RightSlingShot1.slingshotthreshold = 3

	If RightKeyDown and RightFlipper.currentAngle < RightFlipper.StartAngle + 1 Then
		SolRFlipper(True)
	End If
	If LeftKeyDown and LeftFlipper.currentAngle > LeftFlipper.StartAngle - 1 Then
		SolLFlipper(True)
	End If
End Sub

Sub LeftFlipper_Collide(parm)
	CheckLiveCatch ActiveBall, LeftFlipper, LFCount, parm
    PlaySound "rubber_hit_1", 0, parm / 60, pan(ActiveBall), 0.2, 0, 0, 0, AudioFade(ActiveBall)
End Sub

Sub RightFlipper_Collide(parm)
	CheckLiveCatch ActiveBall, RightFlipper, RFCount, parm
    PlaySound "rubber_hit_1", 0, parm / 60, pan(ActiveBall), 0.2, 0, 0, 0, AudioFade(ActiveBall)
End Sub
'''***********Flipper crap

Const ReflipAngle = 20

'******************************************************
' Flippers Polarity (Select appropriate sub based on era)
'******************************************************

Dim LF
Set LF = New FlipperPolarity
Dim RF
Set RF = New FlipperPolarity

InitPolarity

Sub InitPolarity()
	Dim x, a
	a = Array(LF, RF)
	For Each x In a
		x.AddPt "Ycoef", 0, RightFlipper.Y-65, 1 'disabled
		x.AddPt "Ycoef", 1, RightFlipper.Y-11, 1
		x.enabled = True
		x.TimeDelay = 60
		x.DebugOn=False ' prints some info in debugger
		
		x.AddPt "Polarity", 0, 0, 0
		x.AddPt "Polarity", 1, 0.05, -5.5
		x.AddPt "Polarity", 2, 0.4, -5.5
		x.AddPt "Polarity", 3, 0.6, -5.0
		x.AddPt "Polarity", 4, 0.65, -4.5
		x.AddPt "Polarity", 5, 0.7, -4.0
		x.AddPt "Polarity", 6, 0.75, -3.5
		x.AddPt "Polarity", 7, 0.8, -3.0
		x.AddPt "Polarity", 8, 0.85, -2.5
		x.AddPt "Polarity", 9, 0.9,-2.0
		x.AddPt "Polarity", 10, 0.95, -1.5
		x.AddPt "Polarity", 11, 1, -1.0
		x.AddPt "Polarity", 12, 1.05, -0.5
		x.AddPt "Polarity", 13, 1.1, 0
		x.AddPt "Polarity", 14, 1.3, 0
		
		x.AddPt "Velocity", 0, 0,	   1
		x.AddPt "Velocity", 1, 0.160, 1.06
		x.AddPt "Velocity", 2, 0.410, 1.05
		x.AddPt "Velocity", 3, 0.530, 1'0.982
		x.AddPt "Velocity", 4, 0.702, 0.968
		x.AddPt "Velocity", 5, 0.95,  0.968
		x.AddPt "Velocity", 6, 1.03,  0.945
	Next
	
	' SetObjects arguments: 1: name of object 2: flipper object: 3: Trigger object around flipper
	LF.SetObjects "LF", LeftFlipper, TriggerLF
	RF.SetObjects "RF", RightFlipper, TriggerRF
End Sub

'' Flipper trigger hit subs
'Sub TriggerLF_Hit()
'	LF.Addball activeball
'End Sub
'Sub TriggerLF_UnHit()
'	LF.PolarityCorrect activeball
'End Sub
'Sub TriggerRF_Hit()
'	RF.Addball activeball
'End Sub
'Sub TriggerRF_UnHit()
'	RF.PolarityCorrect activeball
'End Sub

'******************************************************
'  FLIPPER CORRECTION FUNCTIONS
'******************************************************

' modified 2023 by nFozzy
' Removed need for 'endpoint' objects
' Added 'createvents' type thing for TriggerLF / TriggerRF triggers.
' Removed AddPt function which complicated setup imo
' made DebugOn do something (prints some stuff in debugger)
'   Otherwise it should function exactly the same as before

Class FlipperPolarity
	Public DebugOn, Enabled
	Private FlipAt		'Timer variable (IE 'flip at 723,530ms...)
	Public TimeDelay		'delay before trigger turns off and polarity is disabled
	Private Flipper, FlipperStart, FlipperEnd, FlipperEndY, LR, PartialFlipCoef
	Private Balls(20), balldata(20)
	Private Name
	
	Dim PolarityIn, PolarityOut
	Dim VelocityIn, VelocityOut
	Dim YcoefIn, YcoefOut
	Public Sub Class_Initialize
		ReDim PolarityIn(0)
		ReDim PolarityOut(0)
		ReDim VelocityIn(0)
		ReDim VelocityOut(0)
		ReDim YcoefIn(0)
		ReDim YcoefOut(0)
		Enabled = True
		TimeDelay = 50
		LR = 1
		Dim x
		For x = 0 To UBound(balls)
			balls(x) = Empty
			Set Balldata(x) = new SpoofBall
		Next
	End Sub
	
	Public Sub SetObjects(aName, aFlipper, aTrigger)
		
		If TypeName(aName) <> "String" Then MsgBox "FlipperPolarity: .SetObjects error: first argument must be a String (And name of Object). Found:" & TypeName(aName) End If
		If TypeName(aFlipper) <> "Flipper" Then MsgBox "FlipperPolarity: .SetObjects error: Second argument must be a flipper. Found:" & TypeName(aFlipper) End If
		If TypeName(aTrigger) <> "Trigger" Then MsgBox "FlipperPolarity: .SetObjects error: third argument must be a trigger. Found:" & TypeName(aTrigger) End If
		If aFlipper.EndAngle > aFlipper.StartAngle Then LR = -1 Else LR = 1 End If
		Name = aName
		Set Flipper = aFlipper
		FlipperStart = aFlipper.x
		FlipperEnd = Flipper.Length * Sin((Flipper.StartAngle / 57.295779513082320876798154814105)) + Flipper.X ' big floats for degree to rad conversion
		FlipperEndY = Flipper.Length * Cos(Flipper.StartAngle / 57.295779513082320876798154814105)*-1 + Flipper.Y
		
		Dim str
		str = "Sub " & aTrigger.name & "_Hit() : " & aName & ".AddBall ActiveBall : End Sub'"
		ExecuteGlobal(str)
		str = "Sub " & aTrigger.name & "_UnHit() : " & aName & ".PolarityCorrect ActiveBall : End Sub'"
		ExecuteGlobal(str)
		
	End Sub
	
	' Legacy: just no op
	Public Property Let EndPoint(aInput)
		
	End Property
	
	Public Sub AddPt(aChooseArray, aIDX, aX, aY) 'Index #, X position, (in) y Position (out)
		Select Case aChooseArray
			Case "Polarity"
				ShuffleArrays PolarityIn, PolarityOut, 1
				PolarityIn(aIDX) = aX
				PolarityOut(aIDX) = aY
				ShuffleArrays PolarityIn, PolarityOut, 0
			Case "Velocity"
				ShuffleArrays VelocityIn, VelocityOut, 1
				VelocityIn(aIDX) = aX
				VelocityOut(aIDX) = aY
				ShuffleArrays VelocityIn, VelocityOut, 0
			Case "Ycoef"
				ShuffleArrays YcoefIn, YcoefOut, 1
				YcoefIn(aIDX) = aX
				YcoefOut(aIDX) = aY
				ShuffleArrays YcoefIn, YcoefOut, 0
		End Select
	End Sub
	
	Public Sub AddBall(aBall)
		Dim x
		For x = 0 To UBound(balls)
			If IsEmpty(balls(x)) Then
				Set balls(x) = aBall
				Exit Sub
			End If
		Next
	End Sub
	
	Private Sub RemoveBall(aBall)
		Dim x
		For x = 0 To UBound(balls)
			If TypeName(balls(x) ) = "IBall" Then
				If aBall.ID = Balls(x).ID Then
					balls(x) = Empty
					Balldata(x).Reset
				End If
			End If
		Next
	End Sub
	
	Public Sub Fire()
		Flipper.RotateToEnd
		processballs
	End Sub
	
	Public Property Get Pos 'returns % position a ball. For debug stuff.
		Dim x
		For x = 0 To UBound(balls)
			If Not IsEmpty(balls(x) ) Then
				pos = pSlope(Balls(x).x, FlipperStart, 0, FlipperEnd, 1)
			End If
		Next
	End Property
	
	Public Sub ProcessBalls() 'save data of balls in flipper range
		FlipAt = GameTime
		Dim x
		For x = 0 To UBound(balls)
			If Not IsEmpty(balls(x) ) Then
				balldata(x).Data = balls(x)
			End If
		Next
		PartialFlipCoef = ((Flipper.StartAngle - Flipper.CurrentAngle) / (Flipper.StartAngle - Flipper.EndAngle))
		PartialFlipCoef = abs(PartialFlipCoef-1)
	End Sub
	'Timer shutoff for polaritycorrect
	Private Function FlipperOn()
		If GameTime < FlipAt+TimeDelay Then
			FlipperOn = True
		End If
	End Function
	
	Public Sub PolarityCorrect(aBall)
		If FlipperOn() Then
			Dim tmp, BallPos, x, IDX, Ycoef
			Ycoef = 1
			
			'y safety Exit
			If aBall.VelY > -8 Then 'ball going down
				RemoveBall aBall
				Exit Sub
			End If
			
			'Find balldata. BallPos = % on Flipper
			For x = 0 To UBound(Balls)
				If aBall.id = BallData(x).id And Not IsEmpty(BallData(x).id) Then
					idx = x
					BallPos = PSlope(BallData(x).x, FlipperStart, 0, FlipperEnd, 1)
					If ballpos > 0.65 Then  Ycoef = LinearEnvelope(BallData(x).Y, YcoefIn, YcoefOut)								'find safety coefficient 'ycoef' data
				End If
			Next
			
			If BallPos = 0 Then 'no ball data meaning the ball is entering and exiting pretty close to the same position, use current values.
				BallPos = PSlope(aBall.x, FlipperStart, 0, FlipperEnd, 1)
				If ballpos > 0.65 Then  Ycoef = LinearEnvelope(aBall.Y, YcoefIn, YcoefOut)												'find safety coefficient 'ycoef' data
			End If
			
			'Velocity correction
			If Not IsEmpty(VelocityIn(0) ) Then
				Dim VelCoef
				VelCoef = LinearEnvelope(BallPos, VelocityIn, VelocityOut)
				
				If partialflipcoef < 1 Then VelCoef = PSlope(partialflipcoef, 0, 1, 1, VelCoef)
				
				If Enabled Then aBall.Velx = aBall.Velx*VelCoef
				If Enabled Then aBall.Vely = aBall.Vely*VelCoef
			End If
			
			'Polarity Correction (optional now)
			If Not IsEmpty(PolarityIn(0) ) Then
				Dim AddX
				AddX = LinearEnvelope(BallPos, PolarityIn, PolarityOut) * LR
				
				If Enabled Then aBall.VelX = aBall.VelX + 1 * (AddX*ycoef*PartialFlipcoef)
			End If
			If DebugOn Then debug.print "PolarityCorrect" & " " & Name & " @ " & GameTime & " " & Round(BallPos*100) & "%" & " AddX:" & Round(AddX,2) & " Vel%:" & Round(VelCoef*100)
		End If
		RemoveBall aBall
	End Sub
End Class

'******************************************************
'  FLIPPER POLARITY AND RUBBER DAMPENER SUPPORTING FUNCTIONS
'******************************************************

' Used for flipper correction and rubber dampeners
Sub ShuffleArray(ByRef aArray, byVal offset) 'shuffle 1d array
	Dim x, aCount
	aCount = 0
	ReDim a(UBound(aArray) )
	For x = 0 To UBound(aArray)		'Shuffle objects in a temp array
		If Not IsEmpty(aArray(x) ) Then
			If IsObject(aArray(x)) Then
				Set a(aCount) = aArray(x)
			Else
				a(aCount) = aArray(x)
			End If
			aCount = aCount + 1
		End If
	Next
	If offset < 0 Then offset = 0
	ReDim aArray(aCount-1+offset)		'Resize original array
	For x = 0 To aCount-1				'set objects back into original array
		If IsObject(a(x)) Then
			Set aArray(x) = a(x)
		Else
			aArray(x) = a(x)
		End If
	Next
End Sub

' Used for flipper correction and rubber dampeners
Sub ShuffleArrays(aArray1, aArray2, offset)
	ShuffleArray aArray1, offset
	ShuffleArray aArray2, offset
End Sub

' Used for flipper correction, rubber dampeners, and drop targets
Function BallSpeed(ball) 'Calculates the ball speed
	BallSpeed = Sqr(ball.VelX^2 + ball.VelY^2 + ball.VelZ^2)
End Function

' Used for flipper correction and rubber dampeners
Function PSlope(Input, X1, Y1, X2, Y2)		'Set up line via two points, no clamping. Input X, output Y
	Dim x, y, b, m
	x = input
	m = (Y2 - Y1) / (X2 - X1)
	b = Y2 - m*X2
	Y = M*x+b
	PSlope = Y
End Function

' Used for flipper correction
Class spoofball
	Public X, Y, Z, VelX, VelY, VelZ, ID, Mass, Radius
	Public Property Let Data(aBall)
		With aBall
			x = .x
			y = .y
			z = .z
			velx = .velx
			vely = .vely
			velz = .velz
			id = .ID
			mass = .mass
			radius = .radius
		End With
	End Property
	Public Sub Reset()
		x = Empty
		y = Empty
		z = Empty
		velx = Empty
		vely = Empty
		velz = Empty
		id = Empty
		mass = Empty
		radius = Empty
	End Sub
End Class

' Used for flipper correction and rubber dampeners
Function LinearEnvelope(xInput, xKeyFrame, yLvl)
	Dim y 'Y output
	Dim L 'Line
	'find active line
	Dim ii
	For ii = 1 To UBound(xKeyFrame)
		If xInput <= xKeyFrame(ii) Then
			L = ii
			Exit For
		End If
	Next
	If xInput > xKeyFrame(UBound(xKeyFrame) ) Then L = UBound(xKeyFrame)		'catch line overrun
	Y = pSlope(xInput, xKeyFrame(L-1), yLvl(L-1), xKeyFrame(L), yLvl(L) )
	
	If xInput <= xKeyFrame(LBound(xKeyFrame) ) Then Y = yLvl(LBound(xKeyFrame) )		 'Clamp lower
	If xInput >= xKeyFrame(UBound(xKeyFrame) ) Then Y = yLvl(UBound(xKeyFrame) )		'Clamp upper
	
	LinearEnvelope = Y
End Function

'******************************************************
'  FLIPPER TRICKS
'******************************************************

RightFlipper.timerinterval = 1
Rightflipper.timerenabled = True

Sub RightFlipper_timer()
	FlipperTricks LeftFlipper, LFPress, LFCount, LFEndAngle, LFState
	FlipperTricks RightFlipper, RFPress, RFCount, RFEndAngle, RFState
	FlipperNudge RightFlipper, RFEndAngle, RFEOSNudge, LeftFlipper, LFEndAngle
	FlipperNudge LeftFlipper, LFEndAngle, LFEOSNudge,  RightFlipper, RFEndAngle
End Sub

Dim LFEOSNudge, RFEOSNudge

Sub FlipperNudge(Flipper1, Endangle1, EOSNudge1, Flipper2, EndAngle2)
	Dim b
	 Dim BOT
	 BOT = GetBalls
	
	If Flipper1.currentangle = Endangle1 And EOSNudge1 <> 1 Then
		EOSNudge1 = 1
		'   debug.print Flipper1.currentangle &" = "& Endangle1 &"--"& Flipper2.currentangle &" = "& EndAngle2
		If Flipper2.currentangle = EndAngle2 Then
			For b = 0 To UBound(BOT)
				If FlipperTrigger(BOT(b).x, BOT(b).y, Flipper1) Then
					'Debug.Print "ball in flip1. exit"
					Exit Sub
				End If
			Next
			For b = 0 To UBound(BOT)
				If FlipperTrigger(BOT(b).x, BOT(b).y, Flipper2) Then
					BOT(b).velx = BOT(b).velx / 1.3
					BOT(b).vely = BOT(b).vely - 0.5
				End If
			Next
		End If
	Else
		If Abs(Flipper1.currentangle) > Abs(EndAngle1) + 30 Then EOSNudge1 = 0
	End If
End Sub


Dim FCCDamping: FCCDamping = 0.4

Sub FlipperCradleCollision(ball1, ball2, velocity)
	if velocity < 0.7 then exit sub		'filter out gentle collisions
    Dim DoDamping, coef
    DoDamping = false
    'Check left flipper
    If LeftFlipper.currentangle = LFEndAngle Then
		If FlipperTrigger(ball1.x, ball1.y, LeftFlipper) OR FlipperTrigger(ball2.x, ball2.y, LeftFlipper) Then DoDamping = true
    End If
    'Check right flipper
    If RightFlipper.currentangle = RFEndAngle Then
		If FlipperTrigger(ball1.x, ball1.y, RightFlipper) OR FlipperTrigger(ball2.x, ball2.y, RightFlipper) Then DoDamping = true
    End If
    If DoDamping Then
		coef = FCCDamping
        ball1.velx = ball1.velx * coef: ball1.vely = ball1.vely * coef: ball1.velz = ball1.velz * coef
        ball2.velx = ball2.velx * coef: ball2.vely = ball2.vely * coef: ball2.velz = ball2.velz * coef
    End If
End Sub
	


'Math
Function dSin(degrees)
	dsin = Sin(degrees * Pi / 180)
End Function

Function dCos(degrees)
	dcos = Cos(degrees * Pi / 180)
End Function

Function Atn2(dy, dx)
	If dx > 0 Then
		Atn2 = Atn(dy / dx)
	ElseIf dx < 0 Then
		If dy = 0 Then
			Atn2 = pi
		Else
			Atn2 = Sgn(dy) * (pi - Atn(Abs(dy / dx)))
		End If
	ElseIf dx = 0 Then
		If dy = 0 Then
			Atn2 = 0
		Else
			Atn2 = Sgn(dy) * pi / 2
		End If
	End If
End Function

'*************************************************
'  Check ball distance from Flipper for Rem
'*************************************************

Function Distance(ax,ay,bx,by)
	Distance = Sqr((ax - bx) ^ 2 + (ay - by) ^ 2)
End Function

Function DistancePL(px,py,ax,ay,bx,by) 'Distance between a point and a line where point Is px,py
	DistancePL = Abs((by - ay) * px - (bx - ax) * py + bx * ay - by * ax) / Distance(ax,ay,bx,by)
End Function

Function Radians(Degrees)
	Radians = Degrees * PI / 180
End Function

Function AnglePP(ax,ay,bx,by)
	AnglePP = Atn2((by - ay),(bx - ax)) * 180 / PI
End Function

Function DistanceFromFlipper(ballx, bally, Flipper)
	DistanceFromFlipper = DistancePL(ballx, bally, Flipper.x, Flipper.y, Cos(Radians(Flipper.currentangle + 90)) + Flipper.x, Sin(Radians(Flipper.currentangle + 90)) + Flipper.y)
End Function

Function FlipperTrigger(ballx, bally, Flipper)
	Dim DiffAngle
	DiffAngle = Abs(Flipper.currentangle - AnglePP(Flipper.x, Flipper.y, ballx, bally) - 90)
	If DiffAngle > 180 Then DiffAngle = DiffAngle - 360
	
	If DistanceFromFlipper(ballx,bally,Flipper) < 48 And DiffAngle <= 90 And Distance(ballx,bally,Flipper.x,Flipper.y) < Flipper.Length Then
		FlipperTrigger = True
	Else
		FlipperTrigger = False
	End If
End Function

'*************************************************
'  End - Check ball distance from Flipper for Rem
'*************************************************

Dim LFPress, RFPress, LFCount, RFCount
Dim LFState, RFState
Dim EOST, EOSA,Frampup, FElasticity,FReturn
Dim RFEndAngle, LFEndAngle

Const FlipperCoilRampupMode = 0 '0 = fast, 1 = medium, 2 = slow (tap passes should work)

LFState = 1
RFState = 1
EOST = leftflipper.eostorque
EOSA = leftflipper.eostorqueangle
Frampup = LeftFlipper.rampup
FElasticity = LeftFlipper.elasticity
FReturn = LeftFlipper.return
'Const EOSTnew = 1 'EM's to late 80's
Const EOSTnew = 0.8 '90's and later
Const EOSAnew = 1
Const EOSRampup = 0
Dim SOSRampup
Select Case FlipperCoilRampupMode
	Case 0
		SOSRampup = 2.5
	Case 1
		SOSRampup = 6
	Case 2
		SOSRampup = 8.5
End Select

Const LiveCatch = 16
Const LiveElasticity = 0.45
Const SOSEM = 0.815
'   Const EOSReturn = 0.055  'EM's
'   Const EOSReturn = 0.045  'late 70's to mid 80's
Const EOSReturn = 0.035  'mid 80's to early 90's
'   Const EOSReturn = 0.025  'mid 90's and later

LFEndAngle = Leftflipper.endangle
RFEndAngle = RightFlipper.endangle

Sub FlipperActivate(Flipper, FlipperPress)
	FlipperPress = 1
	Flipper.Elasticity = FElasticity
	
	Flipper.eostorque = EOST
	Flipper.eostorqueangle = EOSA
End Sub

Sub FlipperDeactivate(Flipper, FlipperPress)
	FlipperPress = 0
	Flipper.eostorqueangle = EOSA
	Flipper.eostorque = EOST * EOSReturn / FReturn
	
	If Abs(Flipper.currentangle) <= Abs(Flipper.endangle) + 0.1 Then
		Dim b, BOT
				BOT = GetBalls
		
		For b = 0 To UBound(BOT)
			If Distance(BOT(b).x, BOT(b).y, Flipper.x, Flipper.y) < 55 Then 'check for cradle
				If BOT(b).vely >= - 0.4 Then BOT(b).vely =  - 0.4
			End If
		Next
	End If
End Sub

Sub FlipperTricks (Flipper, FlipperPress, FCount, FEndAngle, FState)
	Dim Dir
	Dir = Flipper.startangle / Abs(Flipper.startangle) '-1 for Right Flipper
	
	If Abs(Flipper.currentangle) > Abs(Flipper.startangle) - 0.05 Then
		If FState <> 1 Then
			Flipper.rampup = SOSRampup
			Flipper.endangle = FEndAngle - 3 * Dir
			Flipper.Elasticity = FElasticity * SOSEM
			FCount = 0
			FState = 1
		End If
	ElseIf Abs(Flipper.currentangle) <= Abs(Flipper.endangle) And FlipperPress = 1 Then
		If FCount = 0 Then FCount = GameTime
		
		If FState <> 2 Then
			Flipper.eostorqueangle = EOSAnew
			Flipper.eostorque = EOSTnew
			Flipper.rampup = EOSRampup
			Flipper.endangle = FEndAngle
			FState = 2
		End If
	ElseIf Abs(Flipper.currentangle) > Abs(Flipper.endangle) + 0.01 And FlipperPress = 1 Then
		If FState <> 3 Then
			Flipper.eostorque = EOST
			Flipper.eostorqueangle = EOSA
			Flipper.rampup = Frampup
			Flipper.Elasticity = FElasticity
			FState = 3
		End If
	End If
End Sub

Const LiveDistanceMin = 30  'minimum distance In vp units from flipper base live catch dampening will occur
Const LiveDistanceMax = 114 'maximum distance in vp units from flipper base live catch dampening will occur (tip protection)

Sub CheckLiveCatch(ball, Flipper, FCount, parm) 'Experimental new live catch
	Dim Dir
	Dir = Flipper.startangle / Abs(Flipper.startangle)	'-1 for Right Flipper
	Dim LiveCatchBounce																														'If live catch is not perfect, it won't freeze ball totally
	Dim CatchTime
	CatchTime = GameTime - FCount
	
	If CatchTime <= LiveCatch And parm > 6 And Abs(Flipper.x - ball.x) > LiveDistanceMin And Abs(Flipper.x - ball.x) < LiveDistanceMax Then
		If CatchTime <= LiveCatch * 0.5 Then												'Perfect catch only when catch time happens in the beginning of the window
			LiveCatchBounce = 0
		Else
			LiveCatchBounce = Abs((LiveCatch / 2) - CatchTime)		'Partial catch when catch happens a bit late
		End If
		
		If LiveCatchBounce = 0 And ball.velx * Dir > 0 Then ball.velx = 0
		ball.vely = LiveCatchBounce * (32 / LiveCatch) ' Multiplier for inaccuracy bounce
		ball.angmomx = 0
		ball.angmomy = 0
		ball.angmomz = 0
	Else
		If Abs(Flipper.currentangle) <= Abs(Flipper.endangle) + 1 Then FlippersD.Dampenf ActiveBall, parm
	End If
End Sub

'######################### Add new FlippersD Profile
'######################### Adjust these values to increase or lessen the elasticity

Dim FlippersD
Set FlippersD = New Dampener
FlippersD.name = "Flippers"
FlippersD.debugOn = False
FlippersD.Print = False
FlippersD.addpoint 0, 0, 1.1
FlippersD.addpoint 1, 3.77, 0.99
FlippersD.addpoint 2, 6, 0.99

Class Dampener
	Public Print, debugOn   'tbpOut.text
	Public name, Threshold  'Minimum threshold. Useful for Flippers, which don't have a hit threshold.
	Public ModIn, ModOut
	Private Sub Class_Initialize
		ReDim ModIn(0)
		ReDim Modout(0)
	End Sub
	
	Public Sub AddPoint(aIdx, aX, aY)
		ShuffleArrays ModIn, ModOut, 1
		ModIn(aIDX) = aX
		ModOut(aIDX) = aY
		ShuffleArrays ModIn, ModOut, 0
		If GameTime > 100 Then Report
	End Sub
	
	Public Sub Dampen(aBall)
		If threshold Then
			If BallSpeed(aBall) < threshold Then Exit Sub
		End If
		Dim RealCOR, DesiredCOR, str, coef
		DesiredCor = LinearEnvelope(cor.ballvel(aBall.id), ModIn, ModOut )
		RealCOR = BallSpeed(aBall) / (cor.ballvel(aBall.id) + 0.0001)
		coef = desiredcor / realcor
		If debugOn Then str = name & " In vel:" & Round(cor.ballvel(aBall.id),2 ) & vbNewLine & "desired cor: " & Round(desiredcor,4) & vbNewLine & _
		"actual cor: " & Round(realCOR,4) & vbNewLine & "ballspeed coef: " & Round(coef, 3) & vbNewLine
		If Print Then Debug.print Round(cor.ballvel(aBall.id),2) & ", " & Round(desiredcor,3)
		
		aBall.velx = aBall.velx * coef
		aBall.vely = aBall.vely * coef
		If debugOn Then TBPout.text = str
	End Sub
	
	Public Sub Dampenf(aBall, parm) 'Rubberizer is handle here
		Dim RealCOR, DesiredCOR, str, coef
		DesiredCor = LinearEnvelope(cor.ballvel(aBall.id), ModIn, ModOut )
		RealCOR = BallSpeed(aBall) / (cor.ballvel(aBall.id) + 0.0001)
		coef = desiredcor / realcor
		If Abs(aball.velx) < 2 And aball.vely < 0 And aball.vely >  - 3.75 Then
			aBall.velx = aBall.velx * coef
			aBall.vely = aBall.vely * coef
		End If
	End Sub
	
	Public Sub CopyCoef(aObj, aCoef) 'alternative addpoints, copy with coef
		Dim x
		For x = 0 To UBound(aObj.ModIn)
			addpoint x, aObj.ModIn(x), aObj.ModOut(x) * aCoef
		Next
	End Sub
	
	Public Sub Report() 'debug, reports all coords in tbPL.text
		If Not debugOn Then Exit Sub
		Dim a1, a2
		a1 = ModIn
		a2 = ModOut
		Dim str, x
		For x = 0 To UBound(a1)
			str = str & x & ": " & Round(a1(x),4) & ", " & Round(a2(x),4) & vbNewLine
		Next
		TBPout.text = str
	End Sub
End Class

'******************************************************
'  TRACK ALL BALL VELOCITIES
'  FOR RUBBER DAMPENER AND DROP TARGETS
'******************************************************

Dim cor
Set cor = New CoRTracker

Class CoRTracker
	Public ballvel, ballvelx, ballvely
	
	Private Sub Class_Initialize
		ReDim ballvel(0)
		ReDim ballvelx(0)
		ReDim ballvely(0)
	End Sub
	
	Public Sub Update()	'tracks in-ball-velocity
		Dim str, b, AllBalls, highestID
		allBalls = GetBalls
		
		For Each b In allballs
			If b.id >= HighestID Then highestID = b.id
		Next
		
		If UBound(ballvel) < highestID Then ReDim ballvel(highestID)	'set bounds
		If UBound(ballvelx) < highestID Then ReDim ballvelx(highestID)	'set bounds
		If UBound(ballvely) < highestID Then ReDim ballvely(highestID)	'set bounds
		
		For Each b In allballs
			ballvel(b.id) = BallSpeed(b)
			ballvelx(b.id) = b.velx
			ballvely(b.id) = b.vely
		Next
	End Sub
End Class
'******************************************************
'****  END FLIPPER CORRECTIONS
'******************************************************


'***** Kick Back *************************
Sub SolKB(enabled)
	If enabled Then
		Kickback.Fire
		PlaySoundAt SoundFX("AutoPlunger",DOFContactors), kickback
	Else
		Kickback.Pullback
	end If
End Sub

'***** Trunk Lock ************************
TrunkWall1.IsDropped = 1:TrunkWall2.IsDropped = 1
Sub SolTrunk(enabled)
	If enabled Then
		TrunkDoorP.TransY = -100
		TrunkDoor.IsDropped = 1
		TrunkDoor.TimerEnabled = 1
		PlaySoundAt SoundFX("solenoid",DOFContactors), TrunkDoorP
	Else

	End If
End Sub

Sub TrunkDoor_Timer
	TrunkDoorP.TransY = 0
	TrunkDoor.IsDropped = 0
	TrunkDoor.TimerEnabled = 0
End Sub

Sub Sw25_hit()
	DOF 112, DOFOff
	Controller.Switch(25) = 1
End Sub

Sub Sw25_Unhit()
	Controller.Switch(25) = 0
End Sub

Sub Sw26_hit()
	TrunkWall2.IsDropped = 0
	Controller.Switch(26) = 1
End Sub

Sub Sw26_Unhit()
	TrunkWall2.IsDropped = 1
	Controller.Switch(26) = 0
End Sub

Sub Sw27_hit()
	TrunkWall1.IsDropped = 0
	Controller.Switch(27) = 1
End Sub

Sub Sw27_Unhit()
	TrunkWall1.IsDropped = 1
	Controller.Switch(27) = 0
	If controller.Switch(28) = true then
		ActivateFlippers
	End If
End Sub

'*********** Wand ************************
Dim WandPos,WandDir, Wandcount, LtCount, RLAInit
LtCount = 0
WandPos = 42:WandDir = -1
HandP.ObjRotZ = WandPos
RingLMap.ObjRotZ = WandPos
WandP.ObjRotZ = WandPos
WandR.ObjRotZ = WandPos

Sub SolWand(enabled)
If Enabled Then
	DOF 101, DOFOn
	WandT.Enabled = 1
Else
	WandT.enabled = 0
end if
End Sub

Sub WandT_Timer
	if wandcount = 0 then
		PlaysoundAt SoundFX("Motor",DOFGear), HandP
	end If
	Ltcount = LtCount + WandDir
	wandcount = wandcount + 1
	If wandcount = 10 then wandcount = 0
	WandPos = WandPos + (WandDir * 0.1)
	If WandPos > 42 then WandPos = 42:WandDir = -1
	If WandPos < -22 then WandPos = -22:WandDir = 1
	If WandPos >38 then 
		Controller.Switch(67)=1
		CriticDiv.IsDropped = 1
		TrunkDiv.IsDropped = 0
	Else
		DOF 101, DOFOff
		Controller.Switch(67)=0
	end If
	If WandPos < -18 then 
		Controller.Switch(68)=1
		CriticDiv.IsDropped = 0
		TrunkDiv.IsDropped = 1
	Else
		DOF 101, DOFOff
		Controller.Switch(68)=0
	end If
	If WandPos > -18 and wandPos < 38 Then
		CriticDiv.IsDropped = 0
		TrunkDiv.IsDropped = 0
	end If
	HandP.ObjRotZ = WandPos
	RingLMap.ObjRotZ = WandPos
	WandP.ObjRotZ = WandPos
	WandR.ObjRotZ = WandPos	
'RingLight
End Sub

Sub SolMag(enabled)
	If enabled Then
		Ramp19.Collidable = True
	Else
		Ramp19.Collidable = False
	End If
End Sub

'*******End Wand

Sub SolStageDiverter(enabled)
	If enabled then 
		PlaySoundAt SoundFX("solenoid",DOFContactors), Stagein
		StageDiverter.IsDropped = 1
		StageDiverter3.IsDropped = 0
	Else
		PlaySoundAt SoundFX("solenoid",DOFContactors), Stagein
		StageDiverter.IsDropped = 0
		StageDiverter3.IsDropped = 1	
	end if
End Sub

Sub SolWandDiverter(enabled)
	If enabled then 
		PlaySoundAt SoundFX("solenoid",DOFContactors), sw51a
		WandDiv.IsDropped=0:WandDiv1.IsDropped=1
	Else
		PlaySoundAt SoundFX("solenoid",DOFContactors), sw51a
		WandDiv.IsDropped=1:WandDiv1.IsDropped=0
	End If
End Sub

Sub WandDiv_Timer()
	WandDiv.IsDropped=1:WandDiv1.IsDropped=0
	WandDiv.TimerEnabled = 0
End Sub

Sub Stagein_Hit()
	PlaySoundAt "kicker_enter_center", stagein
	controller.Switch(60) = 1
End Sub

Sub Stagein_UnHit()
	controller.Switch(60) = 0
End Sub

Dim MyBall, ELActive
ElActive = 0

Sub Elevator_Hit()
	PlaySoundAt "kicker_enter_center", stagein
	Set MyBall=ActiveBall
	Controller.Switch(57)=1
	ElActive = 1
End Sub

Sub Elevator_unHit()
	Controller.Switch(57)=false
End Sub

Dim LBall, EDown, EPos
EPos = 200
Edown = 1

Sub CreateLBall()
	Set LBall=LevBall.CreateBall
	LBall.Z = EPos
End Sub

Sub solElevator(enabled)
	If Enabled Then
		DOF 102, DOFOn
		EMotor.Enabled = 1
	Else
		DOF 102, DOFOff
		EMotor.Enabled = 0
		If Epos > 150 then 
			If ElActive = 1 then
				MyBall.Z=158
				MyBall.X=785
				Elactive = 0
				elevator.kick 90, 5
				controller.Switch(57)=false
				ActivateFlippers
			End If
		End If
	end If
end Sub

Sub Emotor_Timer()
	PlaysoundAt SoundFX("Motor",DOFGear), Stagein
	Dim ElDelt
	If Epos > 189.9 then
		ElDelt = 0.5
	Else
		ElDelt = 2.5
	End If

	If EDown = 0 Then
		Epos = Epos + ElDelt
		LBall.Z = EPos
		'LBall.visible = true
		el.z = EPos/2
		If EPos > 199 then
			EDown = 1
			'emotor.enabled = false
		End If
	else
		Epos = Epos - ElDelt
		LBall.Z = EPos
		'LBall.visible = False
		el.z = EPos/2
		If Epos < 16 Then	
			EDown = 0	
			'emotor.enabled = false
		End If
	end if	
	if Epos < 25 then
		Controller.Switch(59) = 0
		Controller.Switch(58) = 1
	elseif EPos > 198 then
		Controller.Switch(59) = 1
		Controller.Switch(58) = 0
	else 
		Controller.Switch(59) = 1
		Controller.Switch(58) = 1
	end if
End Sub

Sub SolStageKicker(enabled)
	If Enabled then 
		SKick
	End If
End Sub

Sub SKick()
	stagein.Kickz 160,25,80,0
	PlaySoundAt "popper_ball", stagein
	DOF 105, DOFPulse
End Sub

Dim DoorDir, CloseTime
DoorDir = 2
CloseTime = Now

Sub SolStageDoors(enabled)
	If enabled then
		DoorDir = 2
		DoorT.timerenabled = 1
		' Power is on keep it open. 
		CloseTime = DateAdd("s", 1000, Now)
		DOF 103,DOFOn
	Else	
		' Power is off, start to close if we remain in this state for more than 1s.
		CloseTime = DateAdd("s",1, Now)
	end if
End Sub

Dim DoorPos, DrOpn
DoorPos = 0:DrOpn = 0

Sub DoorT_Timer()
	' Power has dissipated, close.
	if  Now > CloseTime then
		DoorDir = -2
		DOF 103,DOFOn
	end if 
		
	DoorPos = DoorPos + DoorDir

	If DoorPos >= 40 then 
		DoorPos = 40
		DOF 103,DOFOff	
	ElseIf DoorPos < 0 then 
		DoorPos = 0
		DoorT.timerenabled = 0
		DOF 103,DOFOff
	Else
		PlaysoundAt SoundFX("Motor",DOFGear), Stagein
	End If

	DoorL.TransX = -DoorPos
	DoorR.TransX = DoorPos
End Sub

'***********************************************
 'Kickers, drains, poppers
'******************************************************
'				DRAIN & RELEASE
'******************************************************

Sub Drain_Hit()
	PlaySoundAt "drain", drain
	drain.destroyball
    bsTrough.AddBall 0
	'If  Then DisableFlippers
End Sub

Sub SolGenie(enabled)   'GenieTrough
	if enabled then bsGenie.ExitSol_On
	PlaySoundAt SoundFX("AutoPlunger",DOFContactors), sw28
End Sub


'**********Sling Shot Animations
' Rstep and Lstep  are the variables that increment the animation
'****************
Dim RStep, Lstep, RStep1

Sub RightSlingShot_Slingshot
	vpmTimer.PulseSw 22
       PlaySound SoundFX("right_slingshot",DOFContactors)
    RS.Visible = 0
    RS1.Visible = 1
    sling1.TransZ = -20
    RStep = 0
    RightSlingShot.TimerEnabled = 1

End Sub

Sub RightSlingShot_Timer
    Select Case RStep
        Case 3:RS1.Visible = 0:RS2.Visible = 1:sling1.TransZ = -10
        Case 4:RS2.Visible = 0:RS.Visible = 1:sling1.TransZ = 0:RightSlingShot.TimerEnabled = 0
    End Select
    RStep = RStep + 1
End Sub

Sub RightSlingShot1_Slingshot
	vpmTimer.PulseSw 46
       PlaySound SoundFX("right_slingshot", DOFContactors)
    RtS.Visible = 0
    RtS1.Visible = 1
    sling3.TransZ = -20
    RStep1 = 0
    RightSlingShot1.TimerEnabled = 1

End Sub

Sub RightSlingShot1_Timer
    Select Case RStep1
        Case 3:RtS1.Visible = 0:RtS2.Visible = 1:sling3.TransZ = -10
        Case 4:RtS2.Visible = 0:RtS.Visible = 1:sling3.TransZ = 0:RightSlingShot1.TimerEnabled = 0
    End Select
    RStep1 = RStep1 + 1
End Sub

Sub LeftSlingShot_Slingshot
	vpmTimer.PulseSw 19
   PlaySound SoundFX("left_slingshot", DOFContactors)
    LS.Visible = 0
    LS1.Visible = 1
    sling2.TransZ = -20
    LStep = 0
    LeftSlingShot.TimerEnabled = 1

End Sub

Sub LeftSlingShot_Timer
    Select Case LStep
        Case 3:LS1.Visible = 0:LS2.Visible = 1:sling2.TransZ = -10
        Case 4:LS2.Visible = 0:LS.Visible = 1:sling2.TransZ = 0:LeftSlingShot.TimerEnabled = 0
    End Select
    LStep = LStep + 1
End Sub

'AutomaticUpdates
Sub UpdatesTimer_Timer()
	RollingUpdate
	PrimBall1.x = ClearBall.x
	PrimBall1.y = ClearBall.y
	PrimBall1.z = ClearBall.z
	'lTest.x = lTest.x + .1
	BallControlTimer
	Cor.Update
End Sub

'************Bumper1

Sub Bumper1b_Hit()
	vpmTimer.PulseSw 69
    PlaySoundAt SoundFX("fx_bumper1",DOFContactors), Bumper1b
End Sub

'**********Drop Targets
Sub sw41_Hit()
	Controller.Switch(41) = 1
	PlaySoundAt SoundFX("droptarget",DOFDropTargets), sw41
End Sub

Sub sw42_Hit()
	Controller.Switch(42) = 1
	PlaySoundAt SoundFX("droptarget",DOFDropTargets), sw42
End Sub

Sub sw43_Hit()
	Controller.Switch(43) = 1
	PlaySoundAt SoundFX("droptarget",DOFDropTargets), sw43
End Sub

Sub sw44_Hit()
	Controller.Switch(44) = 1
	PlaySoundAt SoundFX("droptarget",DOFDropTargets), sw44
End Sub

Sub sw45_Hit()
	Controller.Switch(45) = 1
	PlaySoundAt SoundFX("droptarget",DOFDropTargets), sw45
End Sub

Sub DropReset(enabled)
	If enabled then
		Controller.Switch(41) = 0
		Controller.Switch(42) = 0
		Controller.Switch(43) = 0
		Controller.Switch(44) = 0
		Controller.Switch(45) = 0
		sw41.IsDropped = 0:sw42.IsDropped = 0:sw43.IsDropped = 0
		sw44.IsDropped = 0:sw45.IsDropped = 0
		PlaySoundAt SoundFx("drop_reset",DOFContactors), sw43
	end if
End Sub
'****Gates
Sub sw49_Hit()
	PlaySoundAt "gate", sw49
	vpmTimer.PulseSw 49
End Sub
'********Standup Targets 
Sub sw34_Hit()
	vpmTimer.PulseSw 34
    PlaySoundAt SoundFX("target",DOFTargets),sw34
End Sub

Sub sw31_Hit()
	vpmTimer.PulseSw 31
    PlaySoundAt SoundFX("target",DOFTargets),sw31
End Sub

Sub sw65_Hit()
	vpmTimer.PulseSw 65
    PlaySoundAt SoundFX("target",DOFTargets),sw65
End Sub

Sub sw70_Hit()
	vpmTimer.PulseSw 70
    PlaySoundAt SoundFX("target",DOFTargets),sw70
End Sub

Sub sw71_Hit()
	vpmTimer.PulseSw 71
    PlaySoundAt SoundFX("target",DOFTargets),sw71
End Sub

Sub sw72_Hit()
	vpmTimer.PulseSw 72
    PlaySoundAt SoundFX("target",DOFTargets),sw72
End Sub

'********Rollovers
Sub Sw17_hit()
	PlaySoundAt "sensor",sw17
	sensorStall Activeball
	Controller.Switch(17) = 1
End Sub

Sub Sw17_unhit()
	Controller.Switch(17) = 0
End Sub


Sub Sw18_hit()
	PlaySoundAt "sensor",sw18
	sensorStall Activeball
	vpmTimer.PulseSw 18
End Sub

Sub Sw23_hit()
	PlaySoundAt "sensor",sw23
	sensorStall Activeball
	vpmTimer.PulseSw 23
End Sub

Sub Sw24_hit()
	PlaySoundAt "sensor",sw24
	sensorStall Activeball
	vpmTimer.PulseSw 24
End Sub

Sub Sw33_hit()
	PlaySoundAt "sensor",sw33
	sensorStall Activeball
	controller.switch(33)=1
	ActivateFlippers
End Sub

Sub Sw33_unhit()
	controller.switch(33)=0
End Sub

Sub Sw35_hit()
	vpmTimer.PulseSw 35
End Sub


Sub Sw36_hit()
	PlaySoundAt "sensor",sw36
	sensorStall Activeball
	vpmTimer.PulseSw 36
End Sub

Sub Sw37_hit()
	PlaySoundAt "sensor",sw37
	sensorStall Activeball
	vpmTimer.PulseSw 37
End Sub

Sub Sw38_hit()
	PlaySoundAt "sensor",sw38
	sensorStall Activeball
	vpmTimer.PulseSw 38
End Sub

Sub Sw40_hit()
	PlaySoundAt "sensor",sw40
	sensorStall Activeball
	vpmTimer.PulseSw 40
End Sub

Sub sw51_Hit()
		vpmTimer.PulseSw 51
End Sub

Sub SpinnerTrig_Unhit()
	sensorStall Activeball
End Sub

Sub SensorStall(ball)
	Dim speedFactor
	speedFactor = 0.875
	If ballvel(ball) >= 33 Then speedfactor = 0.825
	ball.velx = ball.velx * speedFactor
	ball.vely = ball.vely * speedFactor
End Sub

Dim CriticsBall

Sub sw51a_Hit()
	Set CriticsBall = ActiveBall
	if ActiveBall.vely > 15 Then ActiveBall.vely = 15
	sw51a.timerenabled = true
	If trunkDiv.isdropped = 0 and BypassMagnet = 1 Then
		DOF 112, DOFOn
	Else
		vpmTimer.PulseSw 51
	End If
End Sub

Sub sw51a_Timer()
	If CriticsBall.z < 170 Then
		sw51a.timerenabled = false
		playsoundat "balldrop", CriticsBall
	Elseif CriticsBall.x < 360 Then
		sw51a.timerenabled = false
	End If
End Sub

Dim WireRampBall

Sub sw52_Hit()
	Set WireRampBall = ActiveBall
	Activeball.vely = 25
	sw52.timerenabled = true
	Controller.Switch(52) = 1
End Sub

Sub sw52_UnHit()
	Controller.Switch(52) = 0
End Sub

Sub sw52_Timer()
	playsoundat "WireRamp", Tophat
	If WireRampBall.z < 170 Then
		me.timerenabled = False
		StopSound "WireRamp"
	end if
End Sub


Sub Hathole_hit: PlaySoundat "fx_subway3", Hathole: bsGenie.AddBall Me : End Sub


'*******Genie Trough


Sub Sw30_hit()
	Controller.Switch(30) = 1
End Sub

Sub Sw30_Unhit()
	Controller.Switch(30) = 0
End Sub

Sub Sw29_hit()
	Controller.Switch(29) = 1
End Sub

Sub Sw29_Unhit()
	Controller.Switch(29) = 0
End Sub

Sub Sw28_hit()
	bsGenie.AddBall Me
	PlaySoundat "kicker_enter_center", sw28
End Sub
'*****Spinner
Sub Spinner_Spin()
	vpmTimer.PulseSw 66
    PlaySoundAt "fx_spinner", spinner
End Sub


'************************************
'       LUT - Darkness control
' 10 normal level & 10 warmer levels
'************************************

Dim bLutActive, LUTImage

Sub LoadLUT
	dim x
    bLutActive = False
    x = LoadValue(cGameName, "LUTImage")
    If(x <> "")Then LUTImage = x Else LUTImage = 0
    UpdateLUT
End Sub

Sub SaveLUT
    SaveValue cGameName, "LUTImage", LUTImage
End Sub

Sub NextLUT:LUTImage = (LUTImage + 1)MOD 22:UpdateLUT:SaveLUT:SetLUTLine "Color LUT image " & table1.ColorGradeImage:End Sub

Sub UpdateLUT
    Select Case LutImage
        Case 0:table1.ColorGradeImage = "LUT0":ChangeGiIntensity(.30)
        Case 1:table1.ColorGradeImage = "LUT1":ChangeGiIntensity(.35)
        Case 2:table1.ColorGradeImage = "LUT2":ChangeGiIntensity(.40)
        Case 3:table1.ColorGradeImage = "LUT3":ChangeGiIntensity(.45)
        Case 4:table1.ColorGradeImage = "LUT4":ChangeGiIntensity(.50)
        Case 5:table1.ColorGradeImage = "LUT5":ChangeGiIntensity(.55)
        Case 6:table1.ColorGradeImage = "LUT6":ChangeGiIntensity(.60)
        Case 7:table1.ColorGradeImage = "LUT7":ChangeGiIntensity(.65)
        Case 8:table1.ColorGradeImage = "LUT8":ChangeGiIntensity(.70)
        Case 9:table1.ColorGradeImage = "LUT9":ChangeGiIntensity(.75)
        Case 10:table1.ColorGradeImage = "LUT10":ChangeGiIntensity(.95)
        Case 11:table1.ColorGradeImage = "LUT Warm 0":ChangeGiIntensity(.30)
        Case 12:table1.ColorGradeImage = "LUT Warm 1":ChangeGiIntensity(.35)
        Case 13:table1.ColorGradeImage = "LUT Warm 2":ChangeGiIntensity(.40)
        Case 14:table1.ColorGradeImage = "LUT Warm 3":ChangeGiIntensity(.45)
        Case 15:table1.ColorGradeImage = "LUT Warm 4":ChangeGiIntensity(.50)
        Case 16:table1.ColorGradeImage = "LUT Warm 5":ChangeGiIntensity(.55)
        Case 17:table1.ColorGradeImage = "LUT Warm 6":ChangeGiIntensity(.60)
        Case 18:table1.ColorGradeImage = "LUT Warm 7":ChangeGiIntensity(.65)
        Case 19:table1.ColorGradeImage = "LUT Warm 8":ChangeGiIntensity(.70)
        Case 20:table1.ColorGradeImage = "LUT Warm 9":ChangeGiIntensity(.75)
        Case 21:table1.ColorGradeImage = "LUT Warm 10":ChangeGiIntensity(.95)
    End Select
End Sub

' New LUT postit
Function GetHSChar(String, Index)
    Dim ThisChar
    Dim FileName
    ThisChar = Mid(String, Index, 1)
    FileName = "PostIt"
    If ThisChar = " " or ThisChar = "" then
        FileName = FileName & "BL"
    ElseIf ThisChar = "<" then
        FileName = FileName & "LT"
    ElseIf ThisChar = "_" then
        FileName = FileName & "SP"
    Else
        FileName = FileName & ThisChar
    End If
    GetHSChar = FileName
End Function

Sub SetLUTLine(String)
    Dim Index
    Dim xFor
    Index = 1
    LUBack.imagea = "PostItNote"
    String = CL(String)
    For xFor = 1 to 40
        Eval("LU" &xFor).imageA = GetHSChar(String, Index)
        Index = Index + 1
    Next
End Sub

Sub HideLUT
    SetLUTLine ""
    LUBack.imagea = "PostitBL"
End Sub

Function CL(NumString) 'center line
    Dim Temp, TempStr
    If Len(NumString) > 40 Then NumString = Left(NumString, 40)
    Temp = (40 - Len(NumString)) \ 2
    TempStr = Space(Temp) & NumString & Space(Temp)
    CL = TempStr
End Function

Dim GiIntensity
GiIntensity = 1               'can be used by the LUT changing to increase the GI lights when the table is darker

Sub ChangeGiIntensity(factor) 'changes the intensity scale
    Dim bulb
    For each bulb in aGiLights
        bulb.IntensityScale = GiIntensity * factor
    Next
End Sub




'************************************
' Diverse Collection Hit Sounds v3.0
'************************************

Sub Metals_Thin_Hit(idx):PlaySoundAtBall "fx_MetalHit":End Sub
Sub Metals_Medium_Hit(idx):PlaySoundAtBall "fx_MetalWire":End Sub
Sub Metals2_Hit(idx):PlaySoundAtBall "fx_MetalWire":End Sub
Sub Rubbers_Hit(idx):PlaySoundAtBall "fx_rubber_band":End Sub
Sub aRubber_LongBands_Hit(idx):PlaySoundAtBall "fx_rubber_longband":End Sub
Sub aRubber_Posts_Hit(idx):PlaySoundAtBall "fx_rubber_post":End Sub
Sub Pins_Hit(idx):PlaySoundAtBall "fx_rubber_pin":End Sub
Sub Posts_Hit(idx):PlaySoundAtBall "fx_rubber_peg":End Sub
Sub Targets_Hit(idx):PlaySoundAtBall "fx_PlasticHit":End Sub
Sub Gates_Hit(idx):PlaySoundAtBall "fx_Gate":End Sub
Sub aWoods_Hit(idx):PlaySoundAtBall "fx_Woodhit":End Sub

'***************************************************************
'             Supporting Ball & Sound Functions v4.0
'***************************************************************

Dim TableWidth, TableHeight

TableWidth = Table1.width
TableHeight = Table1.height

Function Vol(ball) ' Calculates the Volume of the sound based on the ball speed
    Vol = Csng(BallVel(ball) ^2 / 2000)
End Function

Function Pan(ball) ' Calculates the pan for a ball based on the X position on the table. "table1" is the name of the table
    Dim tmp
    tmp = ball.x * 2 / TableWidth-1
    If tmp > 0 Then
        Pan = Csng(tmp ^10)
    Else
        Pan = Csng(-((- tmp) ^10))
    End If
End Function

Function Pitch(ball) ' Calculates the pitch of the sound based on the ball speed
    Pitch = BallVel(ball) * 20
End Function

Function BallVel(ball) 'Calculates the ball speed
    BallVel = (SQR((ball.VelX ^2) + (ball.VelY ^2)))
End Function

Function AudioFade(ball) 'only on VPX 10.4 and newer
    Dim tmp
    tmp = ball.y * 2 / TableHeight-1
    If tmp > 0 Then
        AudioFade = Csng(tmp ^10)
    Else
        AudioFade = Csng(-((- tmp) ^10))
    End If
End Function

Sub PlaySoundAt(soundname, tableobj) 'play sound at X and Y position of an object, mostly bumpers, flippers and other fast objects
    PlaySound soundname, 0, 1, Pan(tableobj), 0.2, 0, 0, 0, AudioFade(tableobj)
End Sub

Sub PlaySoundAtBall(soundname) ' play a sound at the ball position, like rubbers, targets, metals, plastics
    PlaySound soundname, 0, Vol(ActiveBall), pan(ActiveBall), 0.2, Pitch(ActiveBall) * 10, 0, 0, AudioFade(ActiveBall)
End Sub

Function RndNbr(n) 'returns a random number between 1 and n
    Randomize timer
    RndNbr = Int((n * Rnd) + 1)
End Function

'***********************************************
'   JP's VP10 Rolling Sounds + Ballshadow v4.0
'   uses a collection of shadows, aBallShadow
'***********************************************

Const tnob = 19   'total number of balls
Const lob = 3    'number of locked balls
Const maxvel = 42 'max ball velocity
ReDim rolling(tnob)
InitRolling

Sub InitRolling
    Dim i
    For i = 0 to tnob
        rolling(i) = False
    Next
End Sub

Sub RollingUpdate()
    Dim BOT, b, ballpitch, ballvol, speedfactorx, speedfactory
    BOT = GetBalls

    ' stop the sound of deleted balls
    For b = UBound(BOT) + 1 to tnob
        rolling(b) = False
        StopSound("fx_ballrolling" & b)
    Next

    ' exit the sub if no balls on the table
    If UBound(BOT) = lob - 1 Then Exit Sub 'there no extra balls on this table

    ' play the rolling sound for each ball and draw the shadow
    For b = lob to UBound(BOT)

        If BallVel(BOT(b))> 1 Then
            If BOT(b).z <30 Then
                ballpitch = Pitch(BOT(b))
                ballvol = Vol(BOT(b))
            Else
                ballpitch = Pitch(BOT(b)) + 50000 'increase the pitch on a ramp
                ballvol = Vol(BOT(b)) * 10
            End If
            rolling(b) = True
            PlaySound("fx_ballrolling" & b), -1, ballvol, Pan(BOT(b)), 0, ballpitch, 1, 0, AudioFade(BOT(b))
        Else
            If rolling(b) = True Then
                StopSound("fx_ballrolling" & b)
                rolling(b) = False
            End If
        End If

        ' rothbauerw's Dropping Sounds
        If BOT(b).VelZ <-1 and BOT(b).z <55 and BOT(b).z> 27 Then 'height adjust for ball drop sounds
            PlaySound "fx_balldrop", 0, ABS(BOT(b).velz) / 17, Pan(BOT(b)), 0, Pitch(BOT(b)), 1, 0, AudioFade(BOT(b))
        End If

        ' jps ball speed control
        If BOT(b).VelX AND BOT(b).VelY <> 0 Then
            speedfactorx = ABS(maxvel / BOT(b).VelX)
            speedfactory = ABS(maxvel / BOT(b).VelY)
            If speedfactorx <1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactorx
                BOT(b).VelY = BOT(b).VelY * speedfactorx
            End If
            If speedfactory <1 Then
                BOT(b).VelX = BOT(b).VelX * speedfactory
                BOT(b).VelY = BOT(b).VelY * speedfactory
            End If
        End If
		CheckXLocation(BOT(b))
    Next
End Sub

'*****************************
' Ball 2 Ball Collision Sound
'*****************************

Sub OnBallBallCollision(ball1, ball2, velocity)
    PlaySound("fx_collide"), 0, Csng(velocity) ^2 / 2000, Pan(ball1), 0, Pitch(ball1), 0, 0, AudioFade(ball1)
End Sub



Sub CheckXLocation(xball)
	eyesl.transx = (xball.x - table1.width/2)/100 - (xball.y - table1.height/2)/400
	eyesl.transz = -(xball.x - table1.width/2)/100 - (xball.y - table1.height/2)/400
	eyesr.transx = (xball.x - table1.width/2)/100 + (xball.y - table1.height/2)/400
	eyesr.transz = (xball.x - table1.width/2)/100 - (xball.y - table1.height/2)/400
End Sub




Sub Balldrop1_Hit()
    PlaySoundAt "Balldrop", Balldrop1
End Sub

Sub Balldrop2_Hit()
    PlaySoundAt "Balldrop", Balldrop2
End Sub

Sub Scoop_Hit()
    PlaySoundAt "Scoop_Enter", scoop
End Sub

'*** Spiral Ramp Sounds ***
Dim SpiralBall

Sub SpiralRamp_hit()
	if Activeball.vely < 0 Then
		Set SpiralBall = ActiveBall
		SpiralRamp.timerenabled = true
	Else
		SpiralRamp.timerenabled = false
		StopSound "WireRamp"
	End If
End Sub

Sub SpiralRamp_Timer()
	PlaySoundAt "WireRamp", SpiralBall

	'debug.print SpiralBall.x & chr(9) & spiralball.y & chr(9) & SpiralBall.z & chr(9) & SpiralBall.velx  & chr(9) & SpiralBall.vely & chr(9) & SpiralBall.velz
	If Not InRect(SpiralBall.x,SpiralBall.y,870,845,970,845,970,1060,870,1060) and SpiralBall.z < 70 Then
		me.timerenabled = False
		StopSound "WireRamp"
		playsoundat "balldrop", SpiralBall
	end if
End Sub

'***Hack for ball Speed off Spira
Sub SPIRALsPEEDuP_Hit()
	activeball.velx = activeball.velx * 3
	activeball.vely = activeball.vely * 3
End Sub
 '*****************************************************************
 'Functions
 '*****************************************************************

'*** PI returns the value for PI

Function PI()

	PI = 4*Atn(1)

End Function

'*** Determines if a Points (px,py) is inside a 4 point polygon A-D in Clockwise/CCW order
Function InRect(px,py,ax,ay,bx,by,cx,cy,dx,dy)
	Dim AB, BC, CD, DA
	AB = (bx*py) - (by*px) - (ax*py) + (ay*px) + (ax*by) - (ay*bx)
	BC = (cx*py) - (cy*px) - (bx*py) + (by*px) + (bx*cy) - (by*cx)
	CD = (dx*py) - (dy*px) - (cx*py) + (cy*px) + (cx*dy) - (cy*dx)
	DA = (ax*py) - (ay*px) - (dx*py) + (dy*px) + (dx*ay) - (dy*ax)
 
	If (AB <= 0 AND BC <=0 AND CD <= 0 AND DA <= 0) Or (AB >= 0 AND BC >=0 AND CD >= 0 AND DA >= 0) Then
		InRect = True
	Else
		InRect = False       
	End If
End Function

'*****************************************
'   rothbauerw's Manual Ball Control
'*****************************************

Dim BCup, BCdown, BCleft, BCright
Dim contBall, ControlBallInPlay, ControlActiveBall
Dim BCvel, BCyveloffset, BCboostmulti, BCboost

BCboost = 1				'Do Not Change - default setting
BCvel = 4				'Controls the speed of the ball movement
BCyveloffset = -0.01 	'Offsets the force of gravity to keep the ball from drifting vertically on the table, should be negative
BCboostmulti = 3		'Boost multiplier to ball veloctiy (toggled with the B key) 

ControlBallInPlay = false

Sub StartBallControl_Hit()
	Set ControlActiveBall = ActiveBall
	ControlBallInPlay = true
End Sub

Sub StopBallControl_Hit()
	ControlBallInPlay = false
End Sub	

Sub BallControlTimer()
	If contBall and EnableBallControl and ControlBallInPlay then
		If BCright = 1 Then
			ControlActiveBall.velx =  BCvel*BCboost
		ElseIf BCleft = 1 Then
			ControlActiveBall.velx = -BCvel*BCboost
		Else
			ControlActiveBall.velx = 0
		End If

		If BCup = 1 Then
			ControlActiveBall.vely = -BCvel*BCboost
		ElseIf BCdown = 1 Then
			ControlActiveBall.vely =  BCvel*BCboost
		Else
			ControlActiveBall.vely = bcyveloffset
		End If
	End If
End Sub