extends Node2D

@export var move_speed: float = 100.0
@export var arrival_threshold: float = 1.0

var target_position: Vector2
var path: PackedVector2Array
var is_moving: bool = false

var layer0: TileMapLayer = null
var layer1: TileMapLayer = null

func _ready() -> void:
	add_to_group("player")
	update_tilemap_refs()
	
	if layer0:
		var current_tile = layer0.local_to_map(global_position)
		global_position = layer0.map_to_local(current_tile)

func update_tilemap_refs() -> void:
	# Find tilemaps relative to current parent
	layer0 = get_parent().get_node_or_null("Layer0")
	layer1 = get_parent().get_node_or_null("Layer1")

func _is_dialogue_active() -> bool:
	var dm = get_tree().get_first_node_in_group("dialogue_manager")
	return dm != null and dm.is_active

func _is_minigame_active() -> bool:
	var mg = get_tree().get_first_node_in_group("lighter_minigame")
	return mg != null and mg.is_active

func _unhandled_input(event: InputEvent) -> void:
	if _is_dialogue_active() or _is_minigame_active():
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not layer0:
				update_tilemap_refs()
			if not layer0:
				return
			
			var click_pos = get_global_mouse_position()
			
			var new_path = MovementUtils.get_path_to_tile(
				global_position,
				click_pos,
				layer0,
				layer1
			)
			
			if not new_path.is_empty():
				path = new_path
				is_moving = true
				target_position = path[0]
				if target_position.distance_to(global_position) < arrival_threshold:
					_advance_to_next_target()

func _physics_process(delta: float) -> void:
	if not is_moving or path.is_empty():
		return
	
	var distance_to_target = global_position.distance_to(target_position)
	
	if distance_to_target < arrival_threshold:
		global_position = target_position
		_advance_to_next_target()
	else:
		var direction = (target_position - global_position).normalized()
		var movement = direction * move_speed * delta
		if movement.length() > distance_to_target:
			movement = direction * distance_to_target
		global_position += movement

func _advance_to_next_target() -> void:
	path.remove_at(0)
	
	if path.is_empty():
		is_moving = false
		return
	
	target_position = path[0]
	if target_position.distance_to(global_position) < arrival_threshold:
		_advance_to_next_target()

func teleport_to(new_parent: Node, position: Vector2) -> void:
	# Reparent player to new floor
	get_parent().remove_child(self)
	new_parent.add_child(self)
	global_position = position
	is_moving = false
	path.clear()
	update_tilemap_refs()
