class_name FloorManager
extends Node

signal floor_changed(floor_name: String)

var current_floor: String = "1F"
var floors: Dictionary = {}  # floor_name -> Node2D

func _ready() -> void:
	add_to_group("floor_manager")

func register_floor(floor_name: String, floor_node: Node2D) -> void:
	floors[floor_name] = floor_node
	floor_node.visible = (floor_name == current_floor)

func change_floor(target_floor: String, spawn_point: String = "default") -> void:
	if not floors.has(target_floor):
		print("Floor not found: ", target_floor)
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Player not found!")
		return
	
	# Get spawn position before hiding floors
	var target_node = floors[target_floor]
	var spawn = target_node.get_node_or_null("SpawnPoints/" + spawn_point)
	var spawn_pos = spawn.global_position if spawn else Vector2.ZERO
	
	# Get the TileMaps node in target floor
	var target_tilemaps = target_node.get_node_or_null("TileMaps")
	if not target_tilemaps:
		print("TileMaps not found in target floor!")
		return
	
	# Hide current floor
	if floors.has(current_floor):
		floors[current_floor].visible = false
	
	# Show target floor
	current_floor = target_floor
	floors[current_floor].visible = true
	
	# Move player to new floor's TileMaps
	player.teleport_to(target_tilemaps, spawn_pos)
	
	floor_changed.emit(current_floor)
	print("Changed to floor: ", current_floor)
