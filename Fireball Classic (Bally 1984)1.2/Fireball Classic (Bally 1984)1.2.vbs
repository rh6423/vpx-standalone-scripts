Option Explicit
Randomize

if Table1.showdt = false then ramp008.visible = 0:ramp011.visible = 0

ExecuteGlobal GetTextFile("controller.vbs")
If Err Then MsgBox "You need the controller.vbs in order to run this table, available in the vp10 package"
On Error Goto 0

LoadVPM "01120100", "BALLY.VBS", 3.02

Const cGameName="fbclass",cCredits="Fireball Classic (Bally 1984) by bigus1",UseSolenoids=2,UseLamps=1,UseGI=0,UseSync=0
Const SSolenoidOn="solon",SSolenoidOff="soloff",SFlipperOn="FlipperUp",SFlipperOff="FlipperDown",sCoin="coin3"

Set LampCallback=GetRef("UpdateMultipleLamps")

Sub SolLeftF(Enabled)
If Enabled Then PlaySound"LeftFlipper"
vpmSolFlipper LeftFlipper,nothing,Enabled
End Sub

Sub SolRightF(Enabled)
If Enabled Then PlaySound"RightFlipper"
vpmSolFlipper RightFlipper,nothing,Enabled
End Sub

Const sKnocker=15'11
Const SLSling=11'7
Const sRSling=12'8
Const sYLBumper=8'4
Const sBBumper=10'6
Const sYRBumper=9'5
Const sRSaucer=2'2
Const sLSaucer=1'1
Const sGate=17'12
Const sOuthole=13'9
Const sBallRelease=14'10
Const sRKicker=7'3
Const sCLO=18'13
Const sEnable=19'14

Dim bsTrough,bsLSaucer,bsRSaucer
Dim  Turntable,  MagnetsOn, MotorDirection,d


Class cTurntable
	private cX, cY, cSize, cMaxSpeed, cSpinUp, cSpinDown
	private cTempX, cTempY, cCurspeed, cMotorOn, cClockwise
	private cBalls

	Private Sub Class_Initialize
		set cBalls = CreateObject("Scripting.Dictionary")
		cMotorOn = false
		cCurSpeed = 0
		cClockwise = true
		cSpinUp = 10
		cSpinDown = 4
	End Sub

	Public Sub InitTurntable( aTrigger, inSpeed, inCW )
		cX = aTrigger.X  
		cY = aTrigger.Y
		cSize = aTrigger.Radius
		cMaxSpeed = Abs(inSpeed)
		cClockwise = (inCW = true)
	End Sub

	Public Property Let Speed( inSpeed )
		cMaxSpeed = Abs(inSpeed)
		cClockwise = (inSpeed >= 0)
	End Property
	
	Public Property Let Clockwise( inCW ) : cClockwise = (inCW = true): End Property		
	Public Property Let SpinUp( inSpinUp ) : cSpinUp = inSpinUp : End Property
	Public Property Let SpinDown( inSpinDown ) : cSpinDown = inSpinDown : End Property
	
	Public Property Get MaxSpeed : MaxSpeed = cSpeed : End Property
	Public Property Get Speed : Speed = cCurSpeed : End Property
	Public Property Get MotorState : MotorState = cMotorOn : End Property
	
	Public Sub MotorOn  : cMotorOn = true  : End Sub
	Public Sub MotorOff : cMotorOn = false : End Sub

	Public Sub AddBall( aBall ) : cBalls.Add aBall,0 : End Sub
	Public Sub RemoveBall( aBall ) : cBalls.Remove(aBall) : End Sub  
	
	Public Sub ProcessBalls()
		Dim tempObj
		for each tempObj in cBalls.Keys : AffectBall tempObj : next
	End Sub

	Public Sub ComputeSpin()
		if cMotorOn then
			if cCurSpeed < cMaxSpeed then
				cCurSpeed = cCurSpeed + cSpinUp / 100
				if cCurSpeed > cMaxSpeed then cCurSpeed = cMaxSpeed
			end if
		else
			if cCurSpeed > 0 then
				cCurSpeed = cCurSpeed - cSpinDown / 100
				if cCurSpeed < 0 then cCurSpeed = 0
			end if
		end if
	End Sub
	
	Public Function GetDist( aBall )
		if aBall is Nothing then
			GetDist = 100000
		else
			cTempX = aBall.X - cX
			cTempY = aBall.Y - cY
			GetDist = Sqr(cTempX*cTempX + cTempY*cTempY)
		end if
	End Function

	Public Sub AffectBall( aBall )
		if aBall is Nothing then Exit Sub
		
		if cCurSpeed > 0 then
			Dim Dist
			Dist = GetDist( aBall )
			if Dist > cSize then Exit Sub
			
			' Spin ball in direction of turntable motion.  Speed > 0 = clockwise.
			
			' Step 2: Determine amount of force to be applied to ball.
			' Determined by distance and current speed of turntable.
				
			Dim Force
			Force = (Dist * cCurSpeed / 8000)
			If cClockWise then Force = -Force
			
		    aBall.VelX = aBall.VelX + (cTempY * Force / Dist)
		    aBall.VelY = aBall.VelY - (cTempX * Force / Dist)
		end if
	End Sub
End Class


Sub Table1_Init()
	KickerLane.CreateBall
KickerLane.Kick 180,4
	On Error Resume Next
	With Controller
		.GameName=cGameName
		If Err Then MsgBox "Can't start Game" & cGameName & vbNewLine & Err.Description:Exit Sub
		.SplashInfoLine=cCredits
		.HandleMechanics=0
		.ShowDMDOnly=True
		.ShowFrame=False
		.ShowTitle=False
 		.Run
		.Hidden=1
		If Err Then MsgBox Err.Description
	End With
	On Error Goto 0
'		Controller.Dip(3)=(12)'enables Credits Display and Match Feature

'	Controller.Dip(0)=(0*1 + 0*2 + 0*4 + 0*8 + 0*16 + 0*32 + 0*64 + 0*128) '01-08
'	Controller.Dip(1)=(0*1 + 0*2 + 0*4 + 0*8 + 0*16 + 0*32 + 0*64 + 1*128) '09-16
'	Controller.Dip(2)=(0*1 + 0*2 + 0*4 + 0*8 + 1*16 + 0*32 + 1*64 + 0*128) '17-24
'	Controller.Dip(3)=(1*1 + 1*2 + 1*4 + 1*8 + 1*16 + 1*32 + 0*64 + 0*128) '25-32

'Switch 16 = Recall Bonus Lights
'	On  = Yes
'	Off = No

'Switch 21 = Boop Ball Arrow On With
'	On  = 4X
'	Off = 5X

'Switch 23 = End Of Game Kickouts
'	On  = Balls Kick Out Of Saucers On Game Over
'	Off = Balls Do Not Kick Out Of Saucers On Game Over

'Switch 31 = Number of Balls
'	On  = 5
'	Off = 3

	PinMAMETimer.Interval=PinMAMEInterval  
	PinMAMETimer.Enabled=1
	vpmNudge.TiltSwitch=15
	vpmNudge.Sensitivity=3
	vpmNudge.TiltObj=Array(BumperYellowLeft,BumperYellowRight,BumperBlue,LeftSlingshot,RightSlingshot,Wall64,Wall105,Wall107,Wall139,Wall140,Wall153,Wall154)

	Set bsTrough=New cvpmBallStack
	bsTrough.InitSw 8,28,29,30,0,0,0,0
	bsTrough.InitKick BallRelease,90,5
	bsTrough.InitExitSnd "ballrel","solon"
	bsTrough.Balls = 3
'    bsTrough.AddBall 1

	Set bsLSaucer=New cvpmBallStack
	bsLSaucer.InitSaucer OdinKicker,24,155,5
	bsLSaucer.InitExitSnd "popper","popper"

	Set bsRSaucer=New cvpmBallStack
	bsRSaucer.InitSaucer WotanKicker,23,170,5
	bsRSaucer.InitExitSnd "popper","popper"

Set Turntable = New cTurntable
TurnTable.InitTurntable TurnTable1, 20, false
	TurnTable.SpinUp = 4
	TurnTable.SpinDown = 6
			TurnTable.MotorOn
	MagnetsOn = 1
	MotorDirection = -1

Plunger1.Pullback
End Sub 

SolCallback(sKnocker)="vpmSolSound ""knocker"","
SolCallback(sLSling)="vpmSolSound ""sling""," 
SolCallback(sRSling)="vpmSolSound""sling""," 
SolCallback(sYLBumper)="vpmSolSound ""jet3"","  
SolCallback(sBBumper)="vpmSolSound ""jet3"","  
SolCallback(sYRBumper)="vpmSolSound ""jet3"","  
SolCallBack(sRSaucer)="bsRSaucer.SolOut"
SolCallBack(sLSaucer)="bsLSaucer.SolOut"
SolCallback(sGate)="vpmSolDiverter Gate,""diverter"","
SolCallback(sOuthole)="SolBallEntry"
SolCallback(sBallRelease)="bsTrough.SolOut"
SolCallback(sRKicker)="vpmSolAutoPlunger Plunger1, 0,"
SolCallback(sLLFlipper)="SolLeftF" 
SolCallback(sLRFlipper)="SolRightF" 
SolCallback(sEnable)="vpmNudge.SolGameOn"

Sub SpindiskTimer_timer
spindisk.ObjRotZ = spindisk.ObjRotZ -1
End Sub

Sub SpinSound_timer
PlaySound "motor", 1, 0.01, AudioPan(spindisk), 0,0,0, 1, AudioFade(spindisk) 
End Sub

Sub TurnTable1_Hit()   : Turntable.AddBall  ActiveBall : End Sub
Sub TurnTable1_UnHit() :Turntable.RemoveBall ActiveBall : End Sub
Sub MagnetTimer_Timer():Turntable.ProcessBalls:Turntable.ComputeSpin:End Sub
Sub MotorTimer_Timer()
	Dim x, y
	if y > 1050 then MotorDirection = -1
	if y < 800 then MotorDirection = 1
End Sub
'--------------------------------------------------------------------------------

Sub Table1_KeyUp(ByVal KeyCode)
    If vpmKeyUp(KeyCode) Then Exit Sub  
    If KeyCode=PlungerKey Then PlaySound"Plunger":Plunger.Fire
End Sub  

Sub Table1_KeyDown(ByVal KeyCode)
     If vpmKeyDown(KeyCode) Then Exit Sub 
    If KeyCode=PlungerKey Then Plunger.Pullback
End Sub  

Sub RightSlingshot_Slingshot:vpmTimer.PulseSw(1):F6.duration 1,200,0:End Sub 	'switch 1
Sub LeftSlingshot_Slingshot:vpmTimer.PulseSw(2):F5.duration 1,200,0:End Sub 	'switch 2
Sub BumperBlue_Hit:vpmTimer.PulseSw(3):End Sub 				'switch 3
Sub BumperYellowRight_Hit:vpmTimer.PulseSw(4):End Sub 		'switch 4
Sub BumperYellowLeft_Hit:vpmTimer.PulseSw(5):End Sub 		'switch 5
Sub Wall64_Slingshot:vpmTimer.PulseSw(7):PlaySound "fx_rubber2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall):End Sub
Sub Wall78_Slingshot:vpmTimer.PulseSw(7):PlaySound "fx_rubber2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall):End Sub
Sub Wall105_Slingshot:vpmTimer.PulseSw(7):PlaySound "fx_rubber2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall):End Sub
Sub Wall107_Slingshot:vpmTimer.PulseSw(7):PlaySound "fx_rubber2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall):End Sub
Sub Wall139_Slingshot:vpmTimer.PulseSw(7):PlaySound "fx_rubber2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall):End Sub
Sub Wall140_Slingshot:vpmTimer.PulseSw(7):PlaySound "fx_rubber2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall):End Sub
Sub Wall153_Slingshot:vpmTimer.PulseSw(7):PlaySound "fx_rubber2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall):End Sub
Sub Wall154_Slingshot:vpmTimer.PulseSw(7):PlaySound "fx_rubber2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall):End Sub
Sub Wall155_Slingshot:vpmTimer.PulseSw(7):PlaySound "fx_rubber2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall):End Sub
Sub Drain_Hit:Drain.DestroyBall:bsTrough.EntrySol_On:bsTrough.AddBall 0:Playsound "fx_drain": End Sub 					'Switch 8 28/29/30 Trough
 Sub SolBallEntry(Enabled)
 	If Enabled Then
 		bsTrough.EntrySol_On	 		
 		bsTrough.AddBall 0 		
 	End If
 End Sub
Sub OdinMushroom_Hit:vpmTimer.PulseSw(12):F3.duration 1,200,0:End Sub 			'switch 12
Sub ZipperMushroom_Hit:vpmTimer.PulseSw(13):F4.duration 1,200,0:End Sub 		'switch 13
Sub WotanMushroom_Hit:vpmTimer.PulseSw(14):F22.duration 1,200,0:End Sub 			'switch 14
Sub SkillShot1002_Hit:Controller.Switch(17)=1:F7.duration 1,200,0:End Sub 		'switch 17
Sub SkillShot1002_unHit:Controller.Switch(17)=0:End Sub 	'switch 17
Sub WheelTrigger1_Hit:Controller.Switch(18)=1:End Sub		'switch 18
Sub WheelTrigger1_unHit:Controller.Switch(18)=0:End Sub		'switch 18
Sub WheelTrigger2_Hit:Controller.Switch(18)=1:End Sub		'switch 18
Sub WheelTrigger2_unHit:Controller.Switch(18)=0:End Sub		'switch 18
Sub WheelTrigger3_Hit:Controller.Switch(18)=1:End Sub		'switch 18
Sub WheelTrigger3_unHit:Controller.Switch(18)=0:End Sub		'switch 18
Sub WheelTrigger4_Hit:Controller.Switch(18)=1:End Sub		'switch 18
Sub WheelTrigger4_unHit:Controller.Switch(18)=0:End Sub		'switch 18
Sub WheelTrigger5_Hit:Controller.Switch(18)=1:End Sub		'switch 18
Sub WheelTrigger5_unHit:Controller.Switch(18)=0:End Sub		'switch 18
Sub ButtonKickerOffRight_Hit:Controller.Switch(19)=1:Controller.Switch(18)=1:End Sub
Sub ButtonKickerOffRight_unHit:Controller.Switch(19)=0:Controller.Switch(18)=0:End Sub
Sub ButtonKickerOffLeft_Hit:Controller.Switch(19)=1:Controller.Switch(18)=1:End Sub
Sub ButtonKickerOffLeft_unHit:Controller.Switch(19)=0:Controller.Switch(18)=0:End Sub
Sub ButtonKickerOn_Hit:Controller.Switch(20)=1:Controller.Switch(18)=1:End Sub
Sub ButtonKickerOn_unHit:Controller.Switch(20)=0:Controller.Switch(18)=0:End Sub
Sub RightOutlane_Hit:Controller.Switch(21)=1:End Sub		'switch 21
Sub RightOutlane_unHit:Controller.Switch(21)=0:End Sub		'switch 21
Sub LeftOutlane_Hit:Controller.Switch(22)=1:End Sub			'switch 22
Sub LeftOutlane_unHit:Controller.Switch(22)=0:End Sub		'switch 22
Sub WotanKicker_Hit:bsRSaucer.AddBall 0::F4.duration 1,200,0:playsound "KickerEnter":Controller.Switch(23)=1:End Sub 			'switch 23
Sub WotanKicker_unHit:Controller.Switch(23)=0:End Sub 	
Sub OdinKicker_Hit:bsLSaucer.AddBall 0::F11.duration 1,200,0:playsound "KickerEnter":Controller.Switch(24)=1:End Sub 			'switch 24
Sub OdinKicker_unHit:Controller.Switch(24)=0:End Sub 
Sub LaneTarget_Hit:vpmTimer.PulseSw(25):F11.duration 1,200,0:End Sub				'switch 25
Sub OdinTrigger2_Hit:Controller.Switch(31)=1:End Sub		'switch 31
Sub OdinTrigger2_unHit:Controller.Switch(31)=0:End Sub		'switch 31
Sub SkillShot1001_Hit:Controller.Switch(32)=1:End Sub		'switch 32
Sub SkillShot1001_unHit:Controller.Switch(32)=0:End Sub		'switch 32
Sub Trigger004_Hit:Light013.state = 2:End Sub
Sub Trigger004_unHit:Light013.state = 0:End Sub
Sub Gate1_Hit : playsound "sgate" : End Sub
Sub Gate3_Hit : playsound "sgate" : End Sub
Sub SkillGate_Hit : playsound "sgate" : End Sub

Set Lights(1)=L1
Set Lights(2)=L2
Set Lights(3)=L3
Set Lights(4)=L4
Set Lights(5)=L5
Set Lights(6)=L6
Set Lights(7)=L7
 Set Lights(9)=L9
Set Lights(17)=L17
Set Lights(18)=L18
Set Lights(19)=L19
Set Lights(20)=L20
Set Lights(21)=L21
Lights(22) = array(Light22,Light22b,Light22c,Light22d)   'Bumpers
Set Lights(23)=L23
Set Lights(25)=L25
Set Lights(33)=L33
Set Lights(34)=L34
Set Lights(35)=L35
Set Lights(36)=L36
Set Lights(37)=L37
Set Lights(38)=L38
Set Lights(39)=L39
Set Lights(41)=L41
Set Lights(42)=L42
Set Lights(49)=L49
Set Lights(50)=L50
Set Lights(51)=L51
Set Lights(52)=L52
Set Lights(53)=L53
Set Lights(54)=L54
Set Lights(55)=L55
Set Lights(56)=L56
Set Lights(57)=L57
Set Lights(58)=L58
Set Lights(59)=L59

Sub UpdateGI
Dim xx
if L54.state = 1 Then
for each xx in GILights: xx.state = 1:SpindiskTimer.enabled = 1:SpinSound.enabled = 1: next
Else
for each xx in GILights: xx.state = 0:SpindiskTimer.enabled = 0:SpinSound.enabled = 0: next
end If
End Sub

 Dim N13,O13,N27,O27,N29,O29,N45,O45,N61,O61
 N13=0:O13=0:N27=0:O27=0:N29=0:O29=0:N45=0:O45=0:N61=0:O61=0
 
 Sub UpdateMultipleLamps
 	N13=Controller.Lamp(13) 'Ball In Play
 	N27=Controller.Lamp(27) 'Match
 	N29=Controller.Lamp(29) 'High Score
 	N45=Controller.Lamp(45) 'Game Over
 	N61=Controller.Lamp(61) 'Tilt
	If N13<>O13 Then 'Ball In Play
		If N13 Then
			EMReel5.SetValue 1
		Else
			EMReel5.SetValue 0
		End If
		O13=N13
	End If
	If N27<>O27 Then 'Match
		If N27 Then
			EMReel4.SetValue 1
		Else
			EMReel4.SetValue 0
		End If
		O27=N27
	End If
	If N29<>O29 Then 'High Score
		If N29 Then
			EMReel2.SetValue 1
		Else
			EMReel2.SetValue 0
		End If
		O29=N29
	End If
	If N45<>O45 Then 'Game Over
		If N45 Then
			EMReel1.SetValue 1
		Else
			EMReel1.SetValue 0
		End If
		O45=N45
	End If
	If N61<>O61 Then 'Tilt
		If N61 Then
			EMReel3.SetValue 1
		Else
			EMReel3.SetValue 0
		End If
		O61=N61
	End If
 End Sub
 
 'Bally Fireball Classic
 'added by Inkochnito
 Sub editDips
 	Dim vpmDips : Set vpmDips = New cvpmDips
 	With vpmDips
 		.AddForm 700,400,"Fireball Classic - DIP switches"
 		.AddFrame 0,0,190,"Maximum credits",&H03000000,Array("10 credits",0,"15 credits",&H01000000,"25 credits",&H02000000,"40 credits",&H03000000)'dip 25&26
 		.AddFrame 0,76,190,"Initial bonus special",&H000000C0,Array("50K",0,"100K",&H00000040,"150K",&H00000080,"200K",&H000000C0)'dip 7&8
 		.AddFrame 0,152,190,"Additional bonus special",&H00000020,Array("with 50K",0,"with 100K",&H00000020)'dip 6
 		.AddFrame 0,198,190,"Bonus specials per game",&H00002000,Array("1 bonus special",0,"2 bonus specials",&H00002000)'dip 14
 		.AddFrame 0,244,190,"Lane specials per game",&H00004000,Array("1",0,"2",&H00004000)'dip 15
 		.AddChk 0,295,190,Array("Match feature",&H08000000)'dip 28
 		.AddChk 0,310,190,Array("Credits displayed",&H04000000)'dip 27
 		.AddChk 0,325,190,Array("Bonus held in memory",32768)'dip 16
 		.AddFrame 205,0,190,"Balls per game",&HC0000000,Array ("2 balls",&HC0000000,"3 balls",0,"4 balls",&H80000000,"5 balls",&H40000000)'dip 31&32
 		.AddFrame 205,76,190,"Boop ball arrow on with multiplier",&H00300000,Array("none",0,"2X",&H00100000,"3X",&H00200000,"5X",&H00300000)'dip 21&22
 		.AddFrame 205,152,190,"Captive balls at game over",&H00400000,Array("stay captive",0,"are kicked out",&H00400000)'dip 23
 		.AddFrame 205,198,190,"Ball on playfield",&H00800000,Array("off",0,"on",&H00800000)'dip 24
 		.AddFrame 205,244,190,"Replay limit",&H10000000,Array("1 replay per game",0,"unlimited replays",&H10000000)'dip 29
 		.AddFrame 205,290,190,"Attract sound",&H20000000,Array("off",0,"on",&H20000000)'dip 30
 		.AddLabel 50,350,350,20,"Set selftest position 16,17,18 and 19 to 03 for the best gameplay."
 		.AddLabel 50,370,300,20,"After hitting OK, press F3 to reset game with new settings."
 		.ViewDips
 	End With
 End Sub
 Set vpmShowDips = GetRef("editDips")
 
 '*********************************************************************
'                 Positional Sound Playback Functions
'*********************************************************************

' Play a sound, depending on the X,Y position of the table element (especially cool for surround speaker setups, otherwise stereo panning only)
' parameters (defaults): loopcount (1), volume (1), randompitch (0), pitch (0), useexisting (0), restart (1))
' Note that this will not work (currently) for walls/slingshots as these do not feature a simple, single X,Y position
Sub PlayXYSound(soundname, tableobj, loopcount, volume, randompitch, pitch, useexisting, restart)
	PlaySound soundname, loopcount, volume, AudioPan(tableobj), randompitch, pitch, useexisting, restart, AudioFade(tableobj)
End Sub

' Similar subroutines that are less complicated to use (e.g. simply use standard parameters for the PlaySound call)
Sub PlaySoundAt(soundname, tableobj)
    PlaySound soundname, 1, 1, AudioPan(tableobj), 0,0,0, 1, AudioFade(tableobj)
End Sub

Sub PlaySoundAtBall(soundname)
    PlaySoundAt soundname, ActiveBall
End Sub


'*********************************************************************
'                     Supporting Ball & Sound Functions
'*********************************************************************

Function AudioFade(tableobj) ' Fades between front and back of the table (for surround systems or 2x2 speakers, etc), depending on the Y position on the table. "table1" is the name of the table
	Dim tmp
    tmp = tableobj.y * 2 / table1.height-1
    If tmp > 0 Then
		AudioFade = Csng(tmp ^10)
    Else
        AudioFade = Csng(-((- tmp) ^10) )
    End If
End Function

Function AudioPan(tableobj) ' Calculates the pan for a tableobj based on the X position on the table. "table1" is the name of the table
    Dim tmp
    tmp = tableobj.x * 2 / table1.width-1
    If tmp > 0 Then
        AudioPan = Csng(tmp ^10)
    Else
        AudioPan = Csng(-((- tmp) ^10) )
    End If
End Function

Function Vol(ball) ' Calculates the Volume of the sound based on the ball speed
    Vol = Csng(BallVel(ball) ^2 / 8000)
End Function

Function Pitch(ball) ' Calculates the pitch of the sound based on the ball speed
    Pitch = BallVel(ball) * 20
End Function

Function BallVel(ball) 'Calculates the ball speed
    BallVel = INT(SQR((ball.VelX ^2) + (ball.VelY ^2) ) )
End Function

'*****************************************
'      JP's VP10 Rolling Sounds
'*****************************************

Const tnob = 4 ' total number of balls
ReDim rolling(tnob)
InitRolling

Sub InitRolling
    Dim i
    For i = 0 to tnob
        rolling(i) = False
    Next
End Sub

Sub RollingTimer_Timer()
    Dim BOT, b
    BOT = GetBalls

	' stop the sound of deleted balls
    For b = UBound(BOT) + 1 to tnob
        rolling(b) = False
        StopSound("fx_ballrolling" & b)
    Next

	' exit the sub if no balls on the table
    If UBound(BOT) = -1 Then Exit Sub

	' play the rolling sound for each ball

    For b = 0 to UBound(BOT)
      If BallVel(BOT(b) ) > 1 Then
        rolling(b) = True
        if BOT(b).z < 40 Then ' Ball on playfield
          PlaySound("fx_ballrolling" & b), -1, Vol(BOT(b) ), AudioPan(BOT(b) ), 0, Pitch(BOT(b) ), 1, 0, AudioFade(BOT(b) )
        Else ' Ball on raised ramp
          PlaySound("fx_ballrolling" & b), -1, Vol(BOT(b) )*.5, AudioPan(BOT(b) ), 0, Pitch(BOT(b) )+50000, 1, 0, AudioFade(BOT(b) )
        End If
      Else
        If rolling(b) = True Then
          StopSound("fx_ballrolling" & b)
          rolling(b) = False
        End If
      End If
 ' play ball drop sounds
        If BOT(b).VelZ < -1 and BOT(b).z < 55 and BOT(b).z > 27 Then 'height adjust for ball drop sounds
            PlaySound "fx_ball_drop" & b, 0, ABS(BOT(b).velz)/17, AudioPan(BOT(b)), 0, Pitch(BOT(b)), 1, 0, AudioFade(BOT(b))
        End If
    Next
End Sub

'**********************
' Ball Collision Sound
'**********************

Sub OnBallBallCollision(ball1, ball2, velocity)
	PlaySound("fx_collide"), 0, Csng(velocity) ^2 / 2000, AudioPan(ball1), 0, Pitch(ball1), 0, 0, AudioFade(ball1)
End Sub

 '**********************
'Flipper Shadows
'***********************
Sub RealTime_Timer
  lfs.RotZ = LeftFlipper.CurrentAngle
  rfs.RotZ = RightFlipper.CurrentAngle
BallShadowUpdate
UpdateGI
End Sub


Sub BallShadowUpdate()
Dim BallShadow
BallShadow = Array (BallShadow1,BallShadow2,BallShadow3,BallShadow4,BallShadow5,BallShadow6)
    Dim BOT, b
    BOT = GetBalls
    ' hide shadow of deleted balls
    If UBound(BOT)<(tnob-1) Then
        For b = (UBound(BOT) + 1) to (tnob-1)
            BallShadow(b).visible = 0
        Next
    End If
    ' exit the Sub if no balls on the table
    If UBound(BOT) = -1 Then Exit Sub
    ' render the shadow for each ball
    For b = 0 to UBound(BOT)
		BallShadow(b).X = BOT(b).X
		ballShadow(b).Y = BOT(b).Y + 10                       
        If BOT(b).Z > 20 and BOT(b).Z < 200 Then
            BallShadow(b).visible = 1
        Else
            BallShadow(b).visible = 0
        End If
if BOT(b).z > 30 Then 
ballShadow(b).height = BOT(b).Z - 20
ballShadow(b).opacity = 80
Else
ballShadow(b).height = BOT(b).Z - 24
ballShadow(b).opacity = 80
End If
    Next	
End Sub

Sub Rubbers_Hit(idx)
 	dim finalspeed
  	finalspeed=SQR(activeball.velx * activeball.velx + activeball.vely * activeball.vely)
 	If finalspeed > 20 then 
		PlaySound "fx_rubber2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall)
	End if
	If finalspeed >= 6 AND finalspeed <= 20 then
 		RandomSoundRubber()
 	End If
End Sub

Sub RandomSoundRubber()
	Select Case Int(Rnd*3)+1
		Case 1 : PlaySound "rubber_hit_1", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall)
		Case 2 : PlaySound "rubber_hit_2", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall)
		Case 3 : PlaySound "rubber_hit_3", 0, Vol(ActiveBall)*8, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall)
	End Select
End Sub

Sub LeftFlipper_Collide(parm)
 	RandomSoundFlipper()
End Sub

Sub RightFlipper_Collide(parm)
 	RandomSoundFlipper()
End Sub

Sub RandomSoundFlipper()
	Select Case Int(Rnd*3)+1
		Case 1 : PlaySound "flip_hit_1", 0, Vol(ActiveBall)*20, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall)
		Case 2 : PlaySound "flip_hit_2", 0, Vol(ActiveBall)*20, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall)
		Case 3 : PlaySound "flip_hit_3", 0, Vol(ActiveBall)*20, AudioPan(ActiveBall), 0, Pitch(ActiveBall), 1, 0, AudioFade(ActiveBall)
	End Select
End Sub

'************************************
'          LEDs Display
'************************************

Dim Digits(32)

'Assign 7-digit output to reels
Set Digits(0) = a0
Set Digits(1) = a1
Set Digits(2) = a2
Set Digits(3) = a3
Set Digits(4) = a4
Set Digits(5) = a6
Set Digits(6) = a5
Set Digits(7) = b0
Set Digits(8) = b1
Set Digits(9) = b2
Set Digits(10) = b3
Set Digits(11) = b4
Set Digits(12) = b5
Set Digits(13) = b6
Set Digits(14) = c0
Set Digits(15) = c1
Set Digits(16) = c2
Set Digits(17) = c3
Set Digits(18) = c4
Set Digits(19) = c5
Set Digits(20) = c6
Set Digits(21) = d0
Set Digits(22) = d1
Set Digits(23) = d2
Set Digits(24) = d3
Set Digits(25) = d4
Set Digits(26) = d5
Set Digits(27) = d6
Set Digits(28) = e0
Set Digits(29) = e1
Set Digits(30) = f0
Set Digits(31) = f1

Sub UpdateLEDs_Timer
    On Error Resume Next
    Dim ChgLED, ii, jj, chg, stat
    ChgLED = Controller.ChangedLEDs(&H0000003f, &Hffffffff)
    If Not IsEmpty(ChgLED)Then
        For ii = 0 To UBound(ChgLED)
            chg = chgLED(ii, 1):stat = chgLED(ii, 2)
                Select Case stat
                    Case 0:Digits(chgLED(ii, 0)).SetValue 0    'empty
                    Case 63:Digits(chgLED(ii, 0)).SetValue 1   '0
                    Case 6:Digits(chgLED(ii, 0)).SetValue 2    '1
                    Case 91:Digits(chgLED(ii, 0)).SetValue 3   '2
                    Case 79:Digits(chgLED(ii, 0)).SetValue 4   '3
                    Case 102:Digits(chgLED(ii, 0)).SetValue 5  '4
                    Case 109:Digits(chgLED(ii, 0)).SetValue 6  '5
                    Case 124:Digits(chgLED(ii, 0)).SetValue 7  '6
                    Case 125:Digits(chgLED(ii, 0)).SetValue 7  '6
                    Case 252:Digits(chgLED(ii, 0)).SetValue 7  '6
                    Case 7:Digits(chgLED(ii, 0)).SetValue 8    '7
                    Case 127:Digits(chgLED(ii, 0)).SetValue 9  '8
                    Case 103:Digits(chgLED(ii, 0)).SetValue 10 '9
                    Case 111:Digits(chgLED(ii, 0)).SetValue 10 '9
                    Case 231:Digits(chgLED(ii, 0)).SetValue 10 '9
                    Case 128:Digits(chgLED(ii, 0)).SetValue 0  'empty
                    Case 191:Digits(chgLED(ii, 0)).SetValue 1  '0
                    Case 832:Digits(chgLED(ii, 0)).SetValue 2  '1
                    Case 896:Digits(chgLED(ii, 0)).SetValue 2  '1
                    Case 768:Digits(chgLED(ii, 0)).SetValue 2  '1
                    Case 134:Digits(chgLED(ii, 0)).SetValue 2  '1
                    Case 219:Digits(chgLED(ii, 0)).SetValue 3  '2
                    Case 207:Digits(chgLED(ii, 0)).SetValue 4  '3
                    Case 230:Digits(chgLED(ii, 0)).SetValue 5  '4
                    Case 237:Digits(chgLED(ii, 0)).SetValue 6  '5
                    Case 253:Digits(chgLED(ii, 0)).SetValue 7  '6
                    Case 135:Digits(chgLED(ii, 0)).SetValue 8  '7
                    Case 255:Digits(chgLED(ii, 0)).SetValue 9  '8
                    Case 239:Digits(chgLED(ii, 0)).SetValue 10 '9
                End Select
       Next
    End If
End Sub
