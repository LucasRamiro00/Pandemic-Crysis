extends Control

@onready var lbl_titulo: Label = %LblTitulo
@onready var lbl_resumo: Label = %LblResumo
@onready var lbl_avaliacao: Label = %LblAvaliacao
@onready var btn_menu: Button = %BtnMenu


func _ready() -> void:
	btn_menu.pressed.connect(_ao_voltar_ao_menu)

	var caixa: int = GameManager.caixa_hospital
	lbl_titulo.text = "CAMPANHA CONCLUÍDA"
	lbl_resumo.text = "O hospital resistiu aos %d dias de pandemia.\nCaixa final: R$ %d" % [
		TimeManager.LIMITE_DIAS_TOTAIS, caixa
	]
	lbl_avaliacao.text = _avaliar(caixa)
	lbl_avaliacao.modulate = _cor_da_avaliacao(caixa)

	GameManager.apagar_save()


func _avaliar(caixa: int) -> String:
	if caixa >= 8000:
		return "AVALIAÇÃO: EXCELÊNCIA EM GESTÃO HOSPITALAR"
	elif caixa >= 4000:
		return "AVALIAÇÃO: HOSPITAL ESTÁVEL E BEM ADMINISTRADO"
	elif caixa >= 1500:
		return "AVALIAÇÃO: OPERAÇÃO MANTIDA COM DIFICULDADE"
	return "AVALIAÇÃO: SOBREVIVÊNCIA NO LIMITE DOS RECURSOS"


func _cor_da_avaliacao(caixa: int) -> Color:
	if caixa >= 4000:
		return Color(0.45, 0.95, 0.55)
	elif caixa >= 1500:
		return Color(0.85, 0.9, 1.0)
	return Color(1.0, 0.85, 0.4)


func _ao_voltar_ao_menu() -> void:
	get_tree().change_scene_to_file("res://menu_principal.tscn")
