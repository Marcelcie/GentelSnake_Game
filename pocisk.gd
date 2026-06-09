extends CharacterBody2D

var damage: int = 10
var bounces_left: int = 3

func _ready() -> void:
	# Podstawowy wygląd pocisku - mały złoty krąg (rykoszetujący promień)
	var sprite = Sprite2D.new()
	sprite.texture = preload("res://icon.svg")
	sprite.scale = Vector2(0.15, 0.15)
	sprite.modulate = Color(1.0, 0.9, 0.3) # Jasnozłoty/żółty rykoszet
	add_child(sprite)
	
	# Usunięcie pocisku po 5 sekundach na wypadek gdyby utknął
	get_tree().create_timer(5.0).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	var collision = move_and_collide(velocity * delta)
	if collision:
		var collider = collision.get_collider()
		
		# Sprawdzenie czy trafiliśmy w przeciwnika
		if collider.has_method("take_damage"):
			collider.take_damage(damage)
			queue_free()
			return
			
		# Fizyka odbicia (rykoszet)
		velocity = velocity.bounce(collision.get_normal())
		# Obrót pocisku w kierunku ruchu
		rotation = velocity.angle()
		
		bounces_left -= 1
		if bounces_left <= 0:
			queue_free()
