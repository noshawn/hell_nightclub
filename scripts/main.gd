extends Node2D

@onready var floor_manager: FloorManager = $FloorManager
@onready var floor_1f: Node2D = $Floor1F
@onready var floor_b1: Node2D = $FloorB1
@onready var floor_b2: Node2D = $FloorB2

func _ready() -> void:
	print("Welcome to Hell Night Club - 1F")
	print("Click to move, click NPCs to talk")
	print("Light their cigarettes to unlock their stories...")
	
	# Register floors
	floor_manager.register_floor("1F", floor_1f)
	floor_manager.register_floor("B1", floor_b1)
	floor_manager.register_floor("B2", floor_b2)

func _process(_delta: float) -> void:
	pass
