class_name YuppieNPC
extends NPC

func _ready() -> void:
	super._ready()

func get_dialogue() -> Array:
	if is_burned:
		return get_dialogue_branch("burned_return")
	
	if not has_cigarette:
		if talked_count == 0:
			talked_count += 1
			return get_dialogue_branch("first_meeting")
		else:
			return get_dialogue_branch("return_no_cigarette")
	else:
		if talked_count == 1:
			talked_count += 1
			return get_dialogue_branch("after_cigarette")
		else:
			return get_dialogue_branch("after_cigarette_return")

func light_cigarette() -> void:
	super.light_cigarette()
	talked_count += 1

func on_burned() -> void:
	super.on_burned()
	var sprite = get_node_or_null("Sprite2D")
	if sprite:
		sprite.modulate = Color(0.3, 0.3, 0.3, 1)
