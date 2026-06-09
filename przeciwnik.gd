extends CharacterBody2D

var hp: int = 20

func _ready() -> void:
	# Czerwony wygląd dla przeciwnika (wrogi)
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")
	sprite.scale = Vector2(0.35, 0.35)
	sprite.modulate = Color(0.9, 0.2, 0.2)
	add_child(sprite)

func take_damage(amount: int) -> void:
	hp -= amount
	
	# Efekt mrugnięcia przy uderzeniu
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.05)
	tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0), 0.05).set_delay(0.05)
	
	if hp <= 0:
		var winston = get_node("../Winston")
		if winston and winston.has_method("add_prestige"):
			winston.add_prestige(100) # 100 punktów prestiżu za pokonanie wroga
		queue_free()
