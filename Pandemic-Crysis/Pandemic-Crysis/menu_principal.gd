extends Control

func _ready() -> void:
	pass 
func _process(delta: float) -> void:
	pass


func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Triagem.tscn")
		

func _on_sair_pressed() -> void:
	get_tree().quit()
