extends Control

const CUSTO_LEITOS: int = 500
const CUSTO_TREINAMENTO: int = 750
const CUSTO_TERMINAL: int = 1000

@onready var btn_leitos: Button = %AmpliarLeitosButton
@onready var btn_treinamento: Button = %TreinarFuncionariosButton
@onready var btn_terminal: Button = %ButtModernizarTerminalButtonon


func _ready():
	_atualizar_tela()


func _atualizar_tela() -> void:
	%Saldo.text = "SALDO: $" + str(GameManager.caixa_hospital)

	var extras: int = GameManager.limite_de_leitos - GameManager.LEITOS_INICIAIS
	btn_leitos.text = "Ampliar Leitos ($%d)  -  hoje: +%d pacientes por dia" % [CUSTO_LEITOS, extras]
	btn_leitos.disabled = not _pode_comprar("ampliar_leitos", CUSTO_LEITOS)
	if not GameManager.upgrade_disponivel("ampliar_leitos"):
		btn_leitos.text = "Ampliar Leitos  -  capacidade máxima atingida"

	var custo_exame: int = max(10, int(round(50 * GameManager.bonus_velocidade_exame)))
	btn_treinamento.text = "Treinar Funcionários ($%d)  -  exame hoje: $%d" % [CUSTO_TREINAMENTO, custo_exame]
	btn_treinamento.disabled = not _pode_comprar("treinar_funcionarios", CUSTO_TREINAMENTO)
	if not GameManager.upgrade_disponivel("treinar_funcionarios"):
		btn_treinamento.text = "Treinar Funcionários  -  equipe no máximo"

	if GameManager.terminal_modernizado:
		btn_terminal.text = "Terminal Modernizado  -  já adquirido"
		btn_terminal.disabled = true
	else:
		btn_terminal.text = "Modernizar Terminal ($%d)  -  revela 1 sintoma a mais" % CUSTO_TERMINAL
		btn_terminal.disabled = not _pode_comprar("modernizar_terminal", CUSTO_TERMINAL)


func _pode_comprar(tipo: String, custo: int) -> bool:
	return GameManager.upgrade_disponivel(tipo) and GameManager.caixa_hospital >= custo


func _on_ampliar_leitos_button_pressed():
	if GameManager.comprar_upgrade("ampliar_leitos", CUSTO_LEITOS):
		_atualizar_tela()


func _on_treinar_funcionarios_button_pressed():
	if GameManager.comprar_upgrade("treinar_funcionarios", CUSTO_TREINAMENTO):
		_atualizar_tela()


func _on_modernizar_terminal_button_pressed():
	if GameManager.comprar_upgrade("modernizar_terminal", CUSTO_TERMINAL):
		_atualizar_tela()


func _on_proximo_dia_pressed() -> void:
	GameManager.salvar_partida()
	TimeManager.avancar_dia()

	if TimeManager.dias_totais_jogados > TimeManager.LIMITE_DIAS_TOTAIS:
		get_tree().change_scene_to_file("res://Vitoria.tscn")
		return
	get_tree().change_scene_to_file("res://Triagem.tscn")


func _on_button_pressed() -> void:
	pass
