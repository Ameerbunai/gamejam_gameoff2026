extends StaticBody3D


signal time_selected(timeline: String)

func interact() -> void:
	time_selected.emit("past")
	print("TIME SHIFT: PAST")
