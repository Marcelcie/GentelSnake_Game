extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Winston" and body.has_method("enter_warm_zone"):
		body.enter_warm_zone()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Winston" and body.has_method("exit_warm_zone"):
		body.exit_warm_zone()
