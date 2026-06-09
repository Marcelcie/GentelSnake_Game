extends CharacterBody2D

signal stats_changed

# Podstawowe statystyki z grafik
var level: int = 1
var xp: int = 0
var max_xp: int = 100

var health: float = 120.0
var max_health: float = 120.0

var mana: float = 80.0
var max_mana: float = 80.0

# Statystyki grywalne
var szyk: int = 12 # Zwiększa dochód z prestiżu
var maniery: int = 18 # Zwiększa moc/ilość strzałów rykoszetowych
var wigor: int = 16 # Zwiększa prędkość skrętu i leczenie

var speed: float = 250.0
var turn_speed: float = 3.5

# Długość ogona
var dlugosc: int = 8
var segment_distance: float = 24.0
var path_history: Array[Vector2] = []
var segments: Array[Sprite2D] = []

# Zamarzanie
var temperature: float = 100.0
var max_temperature: float = 100.0
var temp_decrease_rate: float = 8.0 # spadek na sekundę poza ciepłą strefą
var temp_increase_rate: float = 20.0 # wzrost w ciepłej strefie
var in_warm_zone: bool = false
var is_stopped: bool = false

# Prestiż (Waluta)
var prestige_points: int = 0

# Pociski
var can_shoot: bool = true
var shoot_cooldown: float = 0.5

func _ready() -> void:
	# Dostosuj głowę (Winston)
	$Sprite2D.texture = preload("res://icon.svg")
	$Sprite2D.scale = Vector2(0.4, 0.4)
	$Sprite2D.modulate = Color(0.15, 0.65, 0.2) # Arystokratyczny zielony
	
	# Dostosuj kolizję do mniejszej skali
	var shape = $CollisionShape2D.shape as RectangleShape2D
	if shape:
		shape.size = Vector2(50, 50)
		
	# Inicjalizacja ogona
	update_segments_count()
	emit_signal("stats_changed")

func _physics_process(delta: float) -> void:
	# Obsługa zamarzania i leczenia
	handle_temperature_and_health(delta)
	
	# Zatrzymanie postaci w ciepłej strefie
	if in_warm_zone and Input.is_key_pressed(KEY_E):
		is_stopped = !is_stopped
		velocity = Vector2.ZERO
		# Małe opóźnienie by uniknąć wielokrotnego przełączenia
		set_physics_process(false)
		await get_tree().create_timer(0.3).timeout
		set_physics_process(true)
		return
	
	if is_stopped:
		velocity = Vector2.ZERO
		update_tail(delta)
		return
		
	# Sterowanie wężem
	var direction = Input.get_axis("ui_left", "ui_right")
	# Wigor wpływa na prędkość skrętu
	var current_turn_speed = turn_speed * (1.0 + (wigor - 10) * 0.05)
	rotation += direction * current_turn_speed * delta
	
	# Ruch węża w kierunku rotacji
	velocity = Vector2.RIGHT.rotated(rotation) * speed
	
	var collision = move_and_collide(velocity * delta)
	if collision:
		# Fizyka odbicia od ściany
		velocity = velocity.bounce(collision.get_normal())
		# Obrót Winstona w nowym kierunku
		rotation = velocity.angle()
		
	update_tail(delta)
	
	# Strzał rykoszetem (Spacja)
	if Input.is_key_pressed(KEY_SPACE) and can_shoot:
		shoot_ricochet()

func handle_temperature_and_health(delta: float) -> void:
	if in_warm_zone:
		# Odzyskiwanie temperatury
		temperature = min(temperature + temp_increase_rate * delta, max_temperature)
		if is_stopped:
			# Regeneracja zdrowia w ciepłej strefie, gdy wąż odpoczywa (Wigor wpływa na to)
			var heal_amount = 5.0 * (1.0 + (wigor - 10) * 0.1) * delta
			health = min(health + heal_amount, max_health)
	else:
		# Zamarzanie poza ciepłą strefą
		temperature = max(temperature - temp_decrease_rate * delta, 0.0)
		is_stopped = false # Nie można stać w miejscu poza bezpieczną strefą!
		
		# Obrażenia od zamarznięcia
		if temperature <= 0.0:
			health = max(health - 15.0 * delta, 0.0)
			
	emit_signal("stats_changed")

func update_tail(_delta: float) -> void:
	if path_history.is_empty() or path_history[0].distance_to(global_position) > 2.0:
		path_history.push_front(global_position)
		var needed_history_length = dlugosc * segment_distance * 2
		if path_history.size() > needed_history_length:
			path_history.resize(needed_history_length)
			
	# Pozycjonowanie każdego segmentu
	for i in range(segments.size()):
		var target_distance = (i + 1) * segment_distance
		var seg_pos = global_position
		var accumulated_dist = 0.0
		var prev_pt = global_position
		
		for j in range(path_history.size()):
			var pt = path_history[j]
			var d = prev_pt.distance_to(pt)
			if accumulated_dist + d >= target_distance:
				var t = (target_distance - accumulated_dist) / d
				seg_pos = prev_pt.lerp(pt, t)
				break
			accumulated_dist += d
			prev_pt = pt
			
		segments[i].global_position = seg_pos
		
		# Segmenty stają się coraz mniejsze ku końcowi ogona
		var factor = 1.0 - (float(i) / float(dlugosc)) * 0.6
		segments[i].scale = Vector2(0.35 * factor, 0.35 * factor)

func update_segments_count() -> void:
	# Usunięcie starych segmentów
	for seg in segments:
		if is_instance_valid(seg):
			seg.queue_free()
	segments.clear()
	
	# Tworzenie nowych segmentów
	for i in range(dlugosc):
		var segment = Sprite2D.new()
		segment.texture = preload("res://icon.svg")
		segment.scale = Vector2(0.3, 0.3)
		# Kolor segmentów przechodzący od zielonego do ciemnozielonego
		var lerp_factor = float(i) / float(dlugosc)
		segment.modulate = Color(0.15, 0.65 - lerp_factor * 0.3, 0.2)
		# Dodajemy za pomocą call_deferred do rodzica poziomu
		get_parent().add_child.call_deferred(segment)
		segments.append(segment)

func enter_warm_zone() -> void:
	in_warm_zone = true
	emit_signal("stats_changed")

func exit_warm_zone() -> void:
	in_warm_zone = false
	is_stopped = false
	emit_signal("stats_changed")

func add_prestige(amount: int) -> void:
	# Szyk zwiększa ilość zdobywanych punktów
	var bonus_factor = 1.0 + (szyk - 10) * 0.05
	prestige_points += int(amount * bonus_factor)
	emit_signal("stats_changed")

func shoot_ricochet() -> void:
	can_shoot = false
	# Oblicz cooldown (Maniery przyspieszają strzelanie)
	var current_cooldown = shoot_cooldown / (1.0 + (maniery - 10) * 0.05)
	
	# Wystrzel pocisk (Krok 3)
	var pocisk_scene = load("res://pocisk.tscn")
	if pocisk_scene:
		var pocisk = pocisk_scene.instantiate()
		pocisk.global_position = global_position + Vector2.RIGHT.rotated(rotation) * 40.0
		pocisk.velocity = Vector2.RIGHT.rotated(rotation) * 500.0
		pocisk.damage = 10 + (maniery - 10) * 2
		get_parent().add_child(pocisk)
		
	get_tree().create_timer(current_cooldown).timeout.connect(_reset_shoot)

func _reset_shoot() -> void:
	can_shoot = true

func _draw() -> void:
	# Rysowanie cylindra Sir Winstona na jego głowie!
	# Rondo kapelusza
	draw_rect(Rect2(-16, -18, 32, 4), Color(0.1, 0.1, 0.1))
	# Komin kapelusza
	draw_rect(Rect2(-10, -40, 20, 22), Color(0.1, 0.1, 0.1))
	# Czerwona wstążka na kapeluszu
	draw_rect(Rect2(-10, -22, 20, 4), Color(0.8, 0.1, 0.1))


