extends Object
class_name ComplexNameHandler

var ComplexNames = {
# regex : regex sub ($number for groups)
	RegEx.create_from_string(r"Model\s*\[\s*(.+?)\s*\]") : r"?getModel[$1]" ,
	RegEx.create_from_string(r"ModelNode\s*\[\s*(.+?)\s*,\s*(.+?)\s*\]") : r"?getModel[$1].getNode[$2]" ,
	RegEx.create_from_string(r"IsCameraOn\s*\[\s*(.+?)\s*\]") : r"?getModel[$1].isCameraFollow" ,
	RegEx.create_from_string(r"IsControlled\s*\[\s*(.+?)\s*\]") : r"?getModel[$1].isControlled" ,
	RegEx.create_from_string(r"ModelCondition\s*\[\s*(.+?)\s*\]" ):  r"?getModel[$1].condition"
}

func ParseComplexName(Content: String) -> String:
	var result = Content
	for Regex in ComplexNames: 
		var RegexLine: String = ComplexNames[Regex]
		var Result = Regex.search(result)
		if Result:
			result = Regex.sub(result, RegexLine, true)

	return result
