@tool
extends ClassTrigger
## Forces a animation on 1 or more models.

const AnimList: Array[StringName] = [&"Arrest",&"Stand",&"StandLose",&"StandToRun",&"RunForward",&"RunFromStand",&"RunReverse",&"RunFast",&"RunFastFromRun",&"RunInhibition",&"RunFromInhibition",&"RunReverseFromInhibition",&"RunFastInhibition",&"RunFastInhibitionToAnything",&"Sliding",&"Crawling",&"CrawlingFromRun",&"CrawlingToRun",&"CrawlingFromFastRun",&"CrawlingFly",&"CrawlingFlyFromRun",&"Fly",&"FlyPanic",&"FlyPanicReverse",&"Jump",&"JumpFromStand",&"JumpOneLeg",&"JumpOneLegFly",&"JumpOneLegLanding",&"JumpOneLegHigh",&"JumpOneLegHighFly",&"JumpOff",&"ShortJump",&"ShortJumpLanding",&"HurdleJump",&"HurdleLanding",&"WallJump",&"WallJumpFly",&"WallJumpLanding",&"WallRun",&"WallRunMiddle",&"WallRunCling",&"WallRunFly",&"WallRunLanding",&"WallRunLandingToRun",&"WallRunFromFail",&"WallRunFromFailReverse",&"WallHop",&"LandingLow",&"LandingMiddle",&"LandingStop",&"LandingRoll",&"LandingBackward",&"LandingBackwardToRun",&"LandingBackwardToStand",&"JumpAndRoll",&"DiveRoll",&"JumpDownRoll",&"RollForwardStart",&"WallBackRollStart",&"WallBackRollEnd",&"SlideSimple",&"FastSlideSimple",&"SlideToStand",&"SlideLanding",&"SlopeRun",&"SlopeJump",&"SlopeLanding",&"SlopeSlide",&"SlopeSlideJump",&"SlopeSlideFall",&"CollisionAndRoll",&"Stumble",&"TableCollision",&"LongTableCollision",&"FlyCollision",&"FlyCollisionLanding",&"WallCollisionFromRun",&"WallCollisionFromSlide",&"WallCollisionFromRoll",&"WallCollisionBackward",&"SpeedVault",&"SpeedVaultFly",&"PopVault",&"MonkeyVault",&"DashVault",&"ReverseVault",&"GateVault",&"BarrelVault",&"SpinVault",&"WallSpeedVault",&"VertVault",&"TurnVault",&"RocketVault",&"RailFlipVault",&"DoubleSpinVault",&"JumpSpinVault",&"DivingKong",&"KingKongToFlip",&"KingKongToBend",&"KingKongJumpoff",&"FrontFlipTwoLegs",&"FrontflipLegsUp",&"BackFlip",&"SideFlip",&"ObstacleFrontflip",&"CheatGainer",&"Webster",&"WebsterWithSalto",&"DoubleBack",&"AirSpin",&"AirBomb",&"Sidebomb",&"FlyingArrow",&"Spin360",&"SpinBicycle",&"SlowSpin",&"HandSpring",&"HandspringToRoll",&"JumpTumble",&"JumpWheel",&"Swallow",&"TripleTrickToSwalow",&"Swing",&"CoolSwing",&"TripleSwing",&"FlippingSwing",&"DoubleJump",&"DoubleJumpRoll",&"cs_SwarmSecond",&"cs_SwarmThird",&"cs_SwarmFirst",&"cs_ScanerIdle",&"cs_ScanerToRun",&"cs_Scaner",&"cs_ScanerSkipIdle",&"cs_Button",&"Awaken",&"AwakenUplift",&"AwakenLying",&"AwakenMirror",&"AwakenUpliftMirror",&"AwakenLyingMirror",&"cs_SwarmSecondMirror",&"cs_SwarmThirdMirror",&"cs_SwarmFirstMirror",&"cs_ScanerIdleMirror",&"cs_ScanerToRunMirror",&"cs_ScanerMirror",&"cs_ButtonMirror",&"CS00RunForward",&"CS00RunFastFromRun",&"CS01DownTownMain",&"CS01DownTownSecond",&"CS01DownTownHelper",&"CS01aDownTownMain",&"CS01aDownTownSecond",&"CS01aDownTownCoil",&"CS02DownTownHelpBotPart1",&"CS02DownTownHelpBotPart2",&"CS02DownTownHunter",&"CS02DownTownPlayerPart1",&"CS02DownTownPlayerPart1WithTruck",&"CS02DownTownPlayerPart1WithTruckCOM",&"CS02DownTownPlayerPart1WithTruckWall",&"CS02DownTownPlayerPart2WithTruck",&"CS02DownTownFlashMemory",&"CS02DownTownTruck",&"CSYardCS01PlayerPart1",&"CSYardCS01Truck",&"CSYardCS02PlayerPart1",&"CSYardCS02GirlPart1",&"CSYardCS02Lift",&"CSYardCS02LiftNew",&"CSYardCS02Rope",&"CSYardCS02PlayerPart2",&"CSYardCS02GirlPart2",&"CSYardCS02Glider",&"CSTechParkCS01Player",&"CSTechParkCS01Glider",&"CSTechParkCS01Girl",&"CSTechParkCS01MainGlider",&"CSBikeStartingBike",&"CSBikeStartingPlayer",&"CSPlayerBikeCrash",&"CSBikeStartingBikeAndPlayer"]
const AnimFrameList: PackedInt32Array = [21,3,45,1,9,33,40,3,6,40,69,73,13,2,1,8,37,17,8,8,9,6,10,5,60,7,11,18,6,9,33,5,15,5,16,32,34,44,25,21,31,3,32,37,45,37,27,30,23,23,36,50,22,3,6,15,23,7,15,28,31,17,33,9,8,16,14,1,53,9,14,12,4,16,15,28,6,32,11,9,11,11,16,13,7,13,12,20,14,15,30,7,6,10,16,7,15,4,16,7,7,8,8,7,8,15,16,5,8,7,15,7,17,15,2,7,10,15,7,6,7,7,5,1,0,0,1,1,0,0,0,3,0,0,3,0,0,1,0,0,0,0,0,1,1,0,0,0,93,0,0,0,0,0,0,52,5,0,0,0,0,0,0,0,0,0,0,0,0,0,0,135,0,0,0]

@export var models: Array[ClassModel]
@export var animation_reversed: bool = false

@export_custom(PROPERTY_HINT_TYPE_STRING, "", PROPERTY_USAGE_STORAGE) var _anim_to_force_index: int = 0

func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name" : "Animation to force" ,
			"type" : TYPE_INT ,
			"hint" : PROPERTY_HINT_ENUM ,
			"hint_string" : ",".join(AnimList)
		}
	]

func _get(property: StringName) -> Variant:
	if property == &"Animation to force":
		return _anim_to_force_index
	return null

func _set(property: StringName, value: Variant) -> bool:
	if property == &"Animation to force":
		_anim_to_force_index = value
		return true
	return false

func get_xml_node() -> XMLNode:
	var ParseInput =  "@normal"

	for model in models:
		if not model.attributes.has("Name"): continue
		if not model.attributes.has("AI"): continue

		ParseInput += "\nloop"
		ParseInput += "\nif 'Model[_$Model].AI' = '%s'" % model.attributes.AI
		ParseInput += "\nforce_anim '%s' on '%s' frame=%d reversed=%d" % [
			AnimList.get(_anim_to_force_index), 
			model.attributes.get("Name"), 
			AnimFrameList.get(_anim_to_force_index) ,
			int(animation_reversed)]

	Command = Helper.eztrigger.Parse(ParseInput)
	UseEzTrigger = true
	return super.get_xml_node()
