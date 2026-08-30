#region POSITION MATH
			#var p0 := interval.start
			#var p1 := interval.support
			#var p2 := interval.finish
#
			#var t := float(current_frame) / interval.duration_frames
#
			#var point := Helper.quadratic_bezier(p0, p1, p2, t)
#
			#set("global_position", origin + point)
#endregion
@tool
extends ClassObject
class_name ClassTransform
