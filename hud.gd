extends CanvasLayer

@onready var winston = get_node("../Winston")

@onready var health_bar = $Control/MarginContainer/VBoxContainer/HealthBar
@onready var temp_bar = $Control/MarginContainer/VBoxContainer/TempBar
@onready var prestige_label = $Control/MarginContainer/VBoxContainer/PrestigeLabel

@onready var warn_label = $Control/CenterContainer/VBoxContainer/WarnLabel
@onready var rest_prompt = $Control/CenterContainer/VBoxContainer/RestPrompt

@onready var upgrade_menu = $Control/UpgradeMenu
@onready var lvl_label = $Control/UpgradeMenu/MarginContainer/VBoxContainer/LvlLabel
@onready var szyk_label = $Control/UpgradeMenu/MarginContainer/VBoxContainer/SzykBox/SzykLabel
@onready var maniery_label = $Control/UpgradeMenu/MarginContainer/VBoxContainer/ManieryBox/ManieryLabel
@onready var wigor_label = $Control/UpgradeMenu/MarginContainer/VBoxContainer/WigorBox/WigorLabel
@onready var dlugosc_label = $Control/UpgradeMenu/MarginContainer/VBoxContainer/DlugoscBox/DlugoscLabel

func _ready() -> void:
	if winston:
		winston.stats_changed.connect(update_ui)
		update_ui()
		
	# Podpięcie przycisków ulepszeń
	$Control/UpgradeMenu/MarginContainer/VBoxContainer/SzykBox/UpgradeSzyk.pressed.connect(_on_upgrade_szyk_pressed)
	$Control/UpgradeMenu/MarginContainer/VBoxContainer/ManieryBox/UpgradeManiery.pressed.connect(_on_upgrade_maniery_pressed)
	$Control/UpgradeMenu/MarginContainer/VBoxContainer/WigorBox/UpgradeWigor.pressed.connect(_on_upgrade_wigor_pressed)
	$Control/UpgradeMenu/MarginContainer/VBoxContainer/DlugoscBox/UpgradeDlugosc.pressed.connect(_on_upgrade_dlugosc_pressed)
	
	upgrade_menu.visible = false
	warn_label.visible = false
	rest_prompt.visible = false

func _process(_delta: float) -> void:
	if not winston:
		return
		
	# Ostrzeżenia o zimnie
	if winston.temperature < 30.0 and winston.temperature > 0.0 and not winston.in_warm_zone:
		warn_label.text = "ZIMNO NARASTA... Znajdź ciepło!"
		warn_label.visible = true
		var pulse = 0.5 + sin(Time.get_ticks_msec() * 0.01) * 0.5
		warn_label.modulate = Color(1.0, pulse, pulse)
	elif winston.temperature <= 0.0 and not winston.in_warm_zone:
		warn_label.text = "WINSTON ZAMARZA!"
		warn_label.visible = true
		warn_label.modulate = Color(1.0, 0.1, 0.1)
	else:
		warn_label.visible = false
		
	# Prompt o zatrzymaniu w ciepłej strefie
	if winston.in_warm_zone and not winston.is_stopped:
		rest_prompt.text = "[Naciśnij E, aby bezpiecznie odpocząć i otworzyć menu]"
		rest_prompt.visible = true
	elif winston.in_warm_zone and winston.is_stopped:
		rest_prompt.text = "[Naciśnij E, aby wznowić podróż]"
		rest_prompt.visible = true
	else:
		rest_prompt.visible = false
		
	upgrade_menu.visible = winston.is_stopped

func update_ui() -> void:
	if not winston:
		return
	health_bar.value = winston.health
	health_bar.max_value = winston.max_health
	
	temp_bar.value = winston.temperature
	temp_bar.max_value = winston.max_temperature
	
	prestige_label.text = "Prestiż: %d" % winston.prestige_points
	
	# Etykiety menu ulepszeń
	lvl_label.text = "Sir Winston - Poziom %d" % winston.level
	szyk_label.text = "Szyk (Styl): %d (+5%% prestiżu)\nKoszt: %d pkt" % [winston.szyk, winston.szyk * 10]
	maniery_label.text = "Maniery (Strzał): %d (+5%% szybkostrzelności)\nKoszt: %d pkt" % [winston.maniery, winston.maniery * 10]
	wigor_label.text = "Wigor (Zwrotność): %d (+5%% skrętności)\nKoszt: %d pkt" % [winston.wigor, winston.wigor * 10]
	dlugosc_label.text = "Długość ogona: %d segmentów\nKoszt: %d pkt" % [winston.dlugosc, winston.dlugosc * 50]

func _on_upgrade_szyk_pressed() -> void:
	var cost = winston.szyk * 10
	if winston.prestige_points >= cost:
		winston.prestige_points -= cost
		winston.szyk += 1
		winston.level += 1
		winston.emit_signal("stats_changed")

func _on_upgrade_maniery_pressed() -> void:
	var cost = winston.maniery * 10
	if winston.prestige_points >= cost:
		winston.prestige_points -= cost
		winston.maniery += 1
		winston.level += 1
		winston.emit_signal("stats_changed")

func _on_upgrade_wigor_pressed() -> void:
	var cost = winston.wigor * 10
	if winston.prestige_points >= cost:
		winston.prestige_points -= cost
		winston.wigor += 1
		winston.level += 1
		winston.emit_signal("stats_changed")

func _on_upgrade_dlugosc_pressed() -> void:
	var cost = winston.dlugosc * 50
	if winston.prestige_points >= cost:
		winston.prestige_points -= cost
		winston.dlugosc += 1
		winston.update_segments_count()
		winston.level += 1
		winston.emit_signal("stats_changed")
