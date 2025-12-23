class_name Stairs
extends Area2D

@export var target_floor: String = "B1"
@export var spawn_point: String = "from_1F"
@export var requires_permission: bool = false
@export var permission_npc: String = ""  # NPC id who grants permission

var floor_manager: FloorManager = null

func _ready() -> void:
	add_to_group("stairs")
	floor_manager = get_tree().get_first_node_in_group("floor_manager")
	
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		try_use_stairs()
		get_viewport().set_input_as_handled()

func _on_mouse_entered() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func try_use_stairs() -> void:
	if requires_permission and not check_permission():
		show_blocked_message()
		return
	
	if floor_manager:
		floor_manager.change_floor(target_floor, spawn_point)

func check_permission() -> bool:
	if permission_npc == "":
		return true
	
	# Find the NPC and check if they gave permission (has_cigarette)
	var npcs = get_tree().get_nodes_in_group("npcs")
	for npc in npcs:
		if npc.dialogue_data.get("npc_id", "") == permission_npc:
			# Bouncer lets you pass if you lit their cigarette and didn't burn them
			return npc.has_cigarette and not npc.is_burned
	return false

func show_blocked_message() -> void:
	var dm = get_tree().get_first_node_in_group("dialogue_manager")
	if dm:
		dm.start_dialogue(self, [
			{"speaker": "???", "text": "樓梯被擋住了。也許該先跟保鏢打好關係..."}
		])

func get_dialogue_branch(_key: String) -> Array:
	return []
