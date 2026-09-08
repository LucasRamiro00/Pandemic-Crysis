extends Control


func _ready():
	var dados: Dictionary = GameManager.relatorio_do_dia

	var meta: int = int(dados.get("meta", GameManager.meta_pacientes_dia))
	var pacientes: int = int(dados.get("pacientes", 0))
	var cumpriu: bool = bool(dados.get("cumpriu_meta", false))
	var falhas: int = int(dados.get("falhas_seguidas", 0))

	$Pacientes.text = "PACIENTES ATENDIDOS: %d de %d" % [pacientes, meta]
	if not cumpriu:
		$Pacientes.text += "   (META NÃO CUMPRIDA)"

	$Acertos.text = "DIAGNÓSTICOS CORRETOS: " + str(dados.get("acertos", 0))
	$Erros.text = "ERROS: " + str(dados.get("erros", 0))
	$Saldo.text = "SALDO: $%d    (manutenção -$%d)" % [
		GameManager.caixa_hospital, int(dados.get("manutencao", 0))
	]

	if falhas > 0:
		$Erros.text += "     ATENÇÃO: %d de 3 dias sem cumprir a meta" % falhas
		$Erros.modulate = Color(1.0, 0.55, 0.4)


func _on_avancar_dia_button_pressed():
	get_tree().change_scene_to_file("res://LojaDeUpgrades.tscn")
