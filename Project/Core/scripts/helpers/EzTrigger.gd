@tool
extends Object
## Simple code interface, later translated to match the game's format.[br]
## You can discover more details about the original format at [url=https://github.com/FlipThoseTitle/Vectorier-Editor/wiki/Triggers]Vectorier's trigger Github wiki[/url]
## 
## EzTrigger offers the user a easier language to code triggers in, then automatically converts that to the correct format.[br]
## Instead of typing
## [codeblock]
## <Init>
##  <SetVariable Name="$AI" Value="0"/>
## </Init>
## <Loop>
##  <Actions>
##   <Camera Follow="_$Model"/>
##  </Actions>
## </Loop>
## [/codeblock]
## 
## We could simply do
## [br][codeblock]
## var $AI = 0
## loop
## cameraFollow _$Model
## [/codeblock][br]
## 
## In our trigger command, simple, readable and easy to understand, no?
## [b][br]Cheatsheet[/b]:[br]
## --------------------------[br]
## [i]activate <ActionID>[br]
## appendValue <Name> <Value> // Appends a value to a variable[br]
## cameraFollow <Model> // Commands the camera to follow said model, use _$Model to reference the model who's triggering said command.[br]
## cameraSmoothness <Number> // Sets camera smoothness [br]
## cameraStop <1|0> // Sets either the camera should be stopped or not.[br]
## cameraZoom <Number> // Sets camera zoom[br]
## [br]
## // Message commands[br]
## * message <Text> color <Color> frames <Frames> appear <Style> disappear <Style>[br]
## * message <Text> color <Color> frames <Frames>[br]
## * message <Text> color <Color>[br]
## * message <Text> frames <Frames>[br]
## * message <Text> [br]
## [br]
## loss <Model> <Frames> // Triggers a game loss[br]
## victory <Model> <Frames> // Triggers a game victory[br]
## endgame <Result> <Model> <Frames> // Triggers a game end depending on the <Result>[br]
## forceAnimation <AnimName> model <Model> frame <Frame> reversed <0|1> // Forces <AnimName> animation in the specified model.[br]
## sound <Name> // Plays a sound[br]
## control <On|Off> <Model> // Toggles movement in specified <Model>[br]
## setTimer <Frames> // Sets a timer, when that timer ends, all loops with the Timeout event in this command will be triggered.[br]
## setVariable <Name> <Value>[br]
## pressKey <Up|Down|Left|Right> <Model> // Presses a specified key in <Model>[br]
## transform <Id> // Triggers a transform with specified <Id>[br]
## wait <Frames> // Waits <Frames> before the next action.[br]
## [/i]
## --------------------------[br][br]
## [b]Events[/b][br]
## use the [code]event[/code] keyword followed by the event name.[br]
## Example input: [code]event Enter[/code][br]
## Example output: [code]<Enter/>[/code] in the output trigger xml's [code]Events[/code] block[br]
## Format: [code]event <eventName>[/code][br][br]
## --------------------------[br][br]
## [b]Condition checking[/b][br]
## use the [code]if[/code] keyword followed by the value to be compared, the operator and the value to compare with.[br]
## Example input: [code]if ?getModel[Player].worldPositionX > ?getModel[Hunter].worldPositionX[/code][br]
## Example output: [code]<Greater Value1="?getModel[Player].worldPositionX" Value2="?getModel[Hunter].worldPositionX"/>[/code][br] in the output trigger xml's [code]Conditions[/code] block
## You can use the [code]=[/code], [code]<[/code] and [code]>[/code] operators.[br]
## Format: [code]if <value> = <value2>[/code][br]
## And that should be everything.

class_name EzTrigger

class EzTriggerDocument:

	var vars = {}
	var loops = {}

	func toString() -> String:
		var root = XMLNode.new("Root")
		var init = root.get_child_or_add("Init")

		for _var: String in vars:
			var xml = XMLNode.new("SetVariable", {"Name":_var, "Value":vars.get(_var)}, true)
			init.append(xml)

		for loopId: String in loops:
			var loopData: Dictionary = loops.get(loopId)
			var loopXml: XMLNode = root.get_child_or_add("Loop", {} if loopId.begins_with("!unnamed") else {"Name":loopId})


			var chooseBlock: XMLNode = null

			for loopAction: String in loopData.get(&"actions"):
				var actionsXML: XMLNode = loopXml.get_child_or_add("Actions")
				if loopAction.ends_with("_r"):
					var loopActionB = loopAction.substr(0, loopAction.find("_r"))
					if !chooseBlock:
						chooseBlock = XMLNode.new("Choose", {"Order":"Random", "Set":1})
						actionsXML.append(chooseBlock)
					chooseBlock.append(
						XML.parse_str(loopActionB).root
					)
				else:
					chooseBlock = null
					actionsXML.append(
						XML.parse_str(loopAction).root
					)

			for loopCondition in loopData.get(&"conditions"):
				var conditionsXML: XMLNode = loopXml.get_child_or_add("Conditions")
				conditionsXML.append(
					XML.parse_str(loopCondition).root
				)

			for loopEvent in loopData.get(&"events"):
				var eventsXML: XMLNode = loopXml.get_child_or_add("Events")
				eventsXML.append(
					XMLNode.new(loopEvent, {}, true)
				)

		return root.dump_str(true, 1, 1, false)
var parserRegEx := RegEx.new()

const parseVarRegex: String = r"var\s+(.*[^ ])\s*=\s*(\w+)"
const parseLoopRegex: String = r"loop\s*(\w+)?(?: *)"
const parseEventRegex: String = r"event\s+(.*[^ ])(?: *)"
const parseConditionExpressionRegex: String = r"\s*(\S+)\s*(=|>|<)\s*(\S+)"

const parseLoopActionsRegex: Dictionary[String, String] = {
	r"activate\s+(.+[^ ]?)?" : "<Activate ActionID=\"$1\"/>",
	r"appendValue\s+([^\s]+)\s+([^\s]+)" : "<AppendValue Name=\"$1\" Value=\"$2\"/>",
	r"cameraFollow\s+([^\s]+)" : "<Camera Follow=\"$1\"/>",
	r"cameraSmoothness\s+([\d.]+)" : "<Camera Smoothness=\"$1\"/>",
	r"cameraStop\s+(\d+)" : "<Camera Stop=\"$1\"/>",
	r"cameraZoom\s+([\d.]+)" : "<Camera Zoom=\"$1\"/>",
	r"message\s+(.+?)\s+color\s+([^\s]+)\s+frames\s+(\d+)\s+appear\s+([^\s]+)\s+disappear\s+([^\s]+)" : "<MessageOnScreen Text=\"$1\" Color=\"$2\" Frames=\"$3\" AppearStyle=\"$4\" DisappearStyle=\"$5\"/>",
	r"message\s+(.+?)\s+color\s+([^\s]+)\s+frames\s+(\d+)" : "<MessageOnScreen Text=\"$1\" Color=\"$2\" Frames=\"$3\" AppearStyle=\"Fade\" DisappearStyle=\"Fade\"/>",
	r"message\s+(.+?)\s+color\s+([^\s]+)" : "<MessageOnScreen Text=\"$1\" Color=\"$2\" Frames=\"120\" AppearStyle=\"Fade\" DisappearStyle=\"Fade\"/>",
	r"message\s+(.+?)\s+frames\s+(\d+)" : "<MessageOnScreen Text=\"$1\" Color=\"#FFFFFFFF\" Frames=\"$2\" AppearStyle=\"Fade\" DisappearStyle=\"Fade\"/>",
	r"message\s+(.+?)" : "<MessageOnScreen Text=\"$1\" Color=\"#FFFFFFFF\" Frames=\"120\" AppearStyle=\"Fade\" DisappearStyle=\"Fade\"/>",
	r"loss\s+([^\s]+)\s+(\d+)" : "<EndGame Result=\"Loss\" Model=\"$1\" Frames=\"$2\"/>",
	r"victory\s+([^\s]+)\s+(\d+)" : "<EndGame Result=\"Victory\" Model=\"$1\" Frames=\"$2\"/>",
	r"endgame\s+([^\s]+)\s+([^\s]+)\s+(\d+)" : "<EndGame Result=\"$1\" Model=\"$2\" Frames=\"$3\"/>",
	r"forceAnimation\s+([^\s]+)\s+model\s+([^\s]+)\s+frame\s+(\d+)\s+reversed\s+(\d+)" : "<ForceAnimation Name=\"$1\" Model=\"$2\" Frame=\"$3\" Reversed=\"$4\"/>",
	r"kill\s+([^\s]+)" : "<Kill Model=\"$1\"/>",
	r"sound\s+([^\s]+)" : "<Sound Name=\"$1\"/>",
	r"control\s+([^\s]+)\s+([^\s]+)" : "<Control Switch=\"$1\" Model=\"$2\"/>",
	r"setTimer\s+(\d+)" : "<SetTimer Frames=\"$1\"/>",
	r"setVariable\s+([^\s]+)\s+([^\s]+)" : "<SetVariable Name=\"$1\" Value=\"$2\"/>",
	r"pressKey\s+([^\s]+)\s+([^\s]+)" : "<Press Key=\"$1\" Model=\"$2\"/>",
	r"transform\s+([^\s]+)" : "<Transform Name=\"$1\"/>",
	r"wait\s+(\d+)[^ ]?" : "<Wait Frames=\"$1\"/>"
}

func read(_content: String) -> EzTriggerDocument:
	var split := _content.dedent().split("\n", false)
	var isInit: bool = true
	var noLoops: bool = "$noLoops" in split[0]
	var noVars: bool = "$noDV" in split[0]

	var doc: EzTriggerDocument = EzTriggerDocument.new()
	if !noVars: doc.vars = {
		"$Active" = 1 ,
		"Flag1" = 0
	}
	var currentLoop: String = "!unnamed" if noLoops else ""
	if noLoops: doc.loops.set("!unnamed", {&"events":[],&"actions":[],&"conditions":[],&"using":[],&"templates":[]})

	var lineIdx: int = 0
	var unnamedLoopIdx: int = 0

	for line in split:
		if noLoops and lineIdx == 0: lineIdx += 1; continue

		if isInit and line.begins_with("var"):
			doc.vars.merge(parseVariable(line, parserRegEx))
		else: 
			isInit = false

			if line.begins_with("loop") and !noLoops:
				var loopData: Dictionary = parseLoop(line, parserRegEx)

				if loopData.keys()[0].is_empty(): # handling unnamed loops
					loopData.set("!unnamed%d" % unnamedLoopIdx, loopData.values()[0])
					loopData.erase("")
					unnamedLoopIdx += 1

				doc.loops.merge(loopData)
				currentLoop = loopData.keys()[0]
			else:
				if currentLoop.is_empty() and !noLoops:
					printerr("[EzTrigger] Tried parsing a loop-dependent declaration without a present loop!")
					break
				elif line.begins_with("event"):
					doc.loops.get(currentLoop).get(&"events").append(parseEvent(line, parserRegEx))
				elif line.begins_with("if"):
					for condition in parseCondition(line, parserRegEx):
						doc.loops.get(currentLoop).get(&"conditions").append(condition)
				elif line.begins_with("randomAction: "):
					var linePreProccess: String = line.substr(13)
					var subjects: PackedStringArray = linePreProccess.split(",", false)
					for subject in subjects:
						for action in parseAction(subject.strip_edges(), parserRegEx):
							doc.loops.get(currentLoop).get(&"actions").append(action + "_r")
				else:
					for action in parseAction(line, parserRegEx):
						doc.loops.get(currentLoop).get(&"actions").append(action)

		lineIdx += 1

	#print(doc.vars)
	#print("---")
	#print(doc.loops)
	#print("---")

	return doc

static func parseVariable(subject: String, regEx: RegEx) -> Dictionary:
	if !subject.begins_with("var"): return {}
	regEx.compile(parseVarRegex)
	var vars: Dictionary = {}

	var _match: RegExMatch = regEx.search(subject)
	vars.set(_match.get_string(1), _match.get_string(2))

	return vars

static func parseLoop(subject: String, regEx: RegEx) -> Dictionary:
	regEx.compile(parseLoopRegex)
	var rMatch : RegExMatch = regEx.search(subject)
	return {
		rMatch.get_string(1) : {&"events":[],&"actions":[],&"conditions":[],&"using":[],&"templates":[]}
	}

static func parseEvent(subject: String, regEx: RegEx) -> String:
	regEx.compile(parseEventRegex)
	var rMatch : RegExMatch = regEx.search(subject)
	return rMatch.get_string(1)

static func parseCondition(subject: String, regEx: RegEx) -> PackedStringArray:
	var result: PackedStringArray = []
	regEx.compile(parseConditionExpressionRegex)
	var _matches: Array[RegExMatch] = regEx.search_all(subject)

	const operatorDictionary := {
		"=" : "Equal" ,
		">" : "Greater" ,
		"<" : "Less"}

	for _match: RegExMatch in _matches:
		var operatorString: String = operatorDictionary.get(_match.get_string(2))
		result.append(
			'<%s Value1="%s" Value2="%s" />' % [
				operatorString, 
				_match.get_string(1), 
				_match.get_string(3)]
		)

	return result

static func parseAction(subject: String, regEx: RegEx) -> PackedStringArray:
	var result: PackedStringArray = []

	for candidateRegex in parseLoopActionsRegex.keys():
		var candidateString: String = parseLoopActionsRegex.get(candidateRegex)
		regEx.compile(candidateRegex)
		var _match: RegExMatch = regEx.search(subject)
		if !_match: continue
		result.append(regEx.sub(subject, candidateString, true))

	return result

static func quickConvert(ezTriggerContent: String) -> String:
	var i = EzTrigger.new()
	var doc = i.read(ezTriggerContent)
	print(doc.vars)
	return doc.toString()
