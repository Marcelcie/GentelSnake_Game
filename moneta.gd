extends Area2D

@export var prestige_value: int = 50

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Wizualny reprezentant monety
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")
	sprite.scale = Vector2(0.2, 0.2)
	sprite.modulate = Color(1.0, 0.85, 0.2) # Złoty kolor
	add_child(sprite)
	
	# Delikatna animacja lewitowania w powietrzu
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -6.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 6.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Winston" and body.has_method("add_prestige"):
		# Odłącz sygnał, żeby nie zebrać wielokrotnie
		body_entered.disconnect(_on_body_entered)
		body.add_prestige(prestige_value)
		
		# Efekt powiększenia i zanikania przy zebraniu
		var tween = create_tween()
		tween.parallel().tween_property(self, "scale", Vector2(1.8, 1.8), 0.15)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
		tween.tween_callback(queue_free)
