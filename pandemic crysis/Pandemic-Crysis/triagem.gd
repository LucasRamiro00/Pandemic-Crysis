extends Control

# ---------------------------------------------------------------------------
# PANDEMIC CRYSIS - Tela de Triagem (Terminal Médico)
# Responsável: Pessoa 2
#
# ESCOPO DESTA TELA (só isto):
#   - Mostrar Dia/Semana e o Caixa do hospital
#   - Montar o prontuário com os sintomas do paciente
#   - Oferecer os botões de diagnóstico -> GameManager.processar_diagnostico()
#   - Botão "Encerrar Turno" -> GameManager.realizar_fechamento_de_caixa()
#
# FORA DO ESCOPO (parte da Pessoa 3):
#   - Exibir o relatório diário (RelatorioDiario.tscn)
#   - Loja de upgrades (LojaDeUpgrades.tscn / comprar_upgrade)
#   - Avançar o dia (TimeManager.avancar_dia) e recarregar esta cena
# Ao encerrar o turno, esta tela apenas ENTREGA o controle para a cena da
# Pessoa 3. Quando ela avançar o dia e voltar para cá, o _ready() reconstrói
# tudo com os valores atualizados dos autoloads.
#
# Nenhum arquivo dos outros integrantes é modificado: a tela apenas consome
# as funções e sinais públicos que já existiam nos autoloads.
# ---------------------------------------------------------------------------

# Caminho da cena da Pessoa 3. Se ela ainda não existir, a tela encerra o
# expediente sem quebrar o jogo (assim dá para testar a Triagem sozinha).
const CENA_RELATORIO: String = "res://RelatorioDiario.tscn"
const CENA_GAME_OVER: String = "res://game_over.tscn"

# Paleta do terminal médico
const COR_BOTAO: Color = Color(0.16, 0.28, 0.32)
const COR_BOTAO_HOVER: Color = Color(0.22, 0.40, 0.45)
const COR_BOTAO_PRESS: Color = Color(0.10, 0.20, 0.24)
const COR_BOTAO_OFF: Color = Color(0.14, 0.16, 0.18)
const COR_PAINEL: Color = Color(0.11, 0.14, 0.17)
const COR_BORDA: Color = Color(0.24, 0.38, 0.42)

# Ficha do paciente - apenas ambientação visual, não afeta nenhuma regra
const NOMES: Array[String] = [
	"Ana", "Bruno", "Carla", "Diego", "Eliane", "Fábio", "Gisele", "Heitor",
	"Isabel", "João", "Karina", "Lucas", "Marta", "Nelson", "Olívia", "Paulo",
	"Renata", "Sérgio", "Tatiana", "Vitor"
]
const SOBRENOMES: Array[String] = [
	"Almeida", "Barbosa", "Cardoso", "Duarte", "Esteves", "Ferreira",
	"Gomes", "Henriques", "Junqueira", "Lima", "Moreira", "Nogueira",
	"Oliveira", "Pereira", "Queiroz", "Ramos", "Santos", "Teixeira"
]

# Nós da interface (marcados como "Nome único" na cena, por isso o "%")
@onready var lbl_dia: Label = %LblDia
@onready var lbl_dinheiro: Label = %LblDinheiro
@onready var lbl_pacientes: Label = %LblPacientes
@onready var lbl_paciente_nome: Label = %LblPacienteNome
@onready var lbl_sintomas: Label = %LblSintomas
@onready var grid_diagnosticos: GridContainer = %GridDiagnosticos
@onready var lbl_feedback: Label = %LblFeedback
@onready var btn_encerrar: Button = %BtnEncerrarTurno
@onready var painel_prontuario: PanelContainer = %PainelProntuario
@onready var painel_diagnostico: PanelContainer = %PainelDiagnostico

# Estado da tela
var paciente_atual: Doenca = null            # a doença REAL do paciente na maca
var doencas_disponiveis: Array[Doenca] = []  # doenças já liberadas pela semana atual
var contador_paciente: int = 0
var turno_encerrado: bool = false
var jogo_acabou: bool = false


func _ready() -> void:
	GameManager.game_over_acionado.connect(_ao_acionar_game_over)
	TimeManager.novo_dia_iniciado.connect(_ao_iniciar_novo_dia)
	btn_encerrar.pressed.connect(_ao_encerrar_turno)

	# A sala de espera reabre a cada carregamento da cena (novo dia)
	grid_diagnosticos.show()

	_aplicar_estilo()
	_atualizar_doencas_disponiveis()
	_montar_botoes_diagnostico()
	_chamar_proximo_paciente()
	_atualizar_hud()


# --- Estilo visual --------------------------------------------------------

func _criar_estilo(cor: Color) -> StyleBoxFlat:
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = cor
	estilo.set_corner_radius_all(6)
	estilo.set_content_margin_all(10)
	estilo.set_border_width_all(1)
	estilo.border_color = COR_BORDA
	return estilo


func _estilizar_botao(botao: Button) -> void:
	botao.add_theme_stylebox_override("normal", _criar_estilo(COR_BOTAO))
	botao.add_theme_stylebox_override("hover", _criar_estilo(COR_BOTAO_HOVER))
	botao.add_theme_stylebox_override("pressed", _criar_estilo(COR_BOTAO_PRESS))
	botao.add_theme_stylebox_override("disabled", _criar_estilo(COR_BOTAO_OFF))
	botao.add_theme_stylebox_override("focus", _criar_estilo(COR_BOTAO_HOVER))


func _aplicar_estilo() -> void:
	painel_prontuario.add_theme_stylebox_override("panel", _criar_estilo(COR_PAINEL))
	painel_diagnostico.add_theme_stylebox_override("panel", _criar_estilo(COR_PAINEL))
	_estilizar_botao(btn_encerrar)


# --- HUD (dia, semana, dinheiro, meta) ------------------------------------

func _atualizar_hud() -> void:
	lbl_dia.text = "Dia %d  |  Semana %d" % [TimeManager.dia_atual, TimeManager.semana_atual]
	lbl_dinheiro.text = "Caixa: R$ %d" % GameManager.caixa_hospital
	lbl_pacientes.text = "Pacientes hoje: %d / %d" % [
		GameManager.pacientes_atendidos_hoje,
		GameManager.meta_pacientes_dia
	]


# --- Prontuário -----------------------------------------------------------

func _atualizar_doencas_disponiveis() -> void:
	# Só entram no jogo as doenças cuja semana de aparição já chegou
	doencas_disponiveis.clear()
	for doenca in GameManager.banco_de_doencas:
		if doenca.semana_de_aparicao <= TimeManager.semana_atual:
			doencas_disponiveis.append(doenca)

	# Segurança: se nenhuma passar no filtro, usa o banco inteiro
	if doencas_disponiveis.is_empty():
		for doenca in GameManager.banco_de_doencas:
			doencas_disponiveis.append(doenca)


func _chamar_proximo_paciente() -> void:
	# A fila do dia termina quando a meta de atendimentos é atingida.
	# Decisão de INTERFACE: evita atendimentos infinitos no mesmo turno sem
	# alterar nenhuma regra dos controladores.
	if GameManager.pacientes_atendidos_hoje >= GameManager.meta_pacientes_dia:
		lbl_paciente_nome.text = "Sala de espera vazia"
		lbl_sintomas.text = "-  Todos os pacientes do dia foram atendidos."
		paciente_atual = null
		grid_diagnosticos.hide()
		return

	if doencas_disponiveis.is_empty():
		lbl_paciente_nome.text = "Nenhuma doença cadastrada no banco (.tres)"
		lbl_sintomas.text = ""
		paciente_atual = null
		return

	contador_paciente += 1
	paciente_atual = doencas_disponiveis.pick_random()
	lbl_paciente_nome.text = "Ficha #%03d  -  %s, %d anos" % [
		contador_paciente, _gerar_nome_paciente(), randi_range(18, 89)
	]
	lbl_sintomas.text = _formatar_sintomas(paciente_atual)


func _gerar_nome_paciente() -> String:
	return "%s %s" % [NOMES.pick_random(), SOBRENOMES.pick_random()]


func _formatar_sintomas(doenca: Doenca) -> String:
	if doenca.sintomas.is_empty():
		return "-  Paciente não relatou sintomas."

	# Embaralha a ordem para o jogador ler o quadro em vez de decorar a lista
	var sintomas_embaralhados: Array = doenca.sintomas.duplicate()
	sintomas_embaralhados.shuffle()

	var linhas: PackedStringArray = []
	for sintoma in sintomas_embaralhados:
		linhas.append("-  " + str(sintoma))
	return "\n".join(linhas)


# --- Botões de diagnóstico ------------------------------------------------

func _montar_botoes_diagnostico() -> void:
	# Limpa os botões antigos (a lista muda quando a semana avança)
	for filho in grid_diagnosticos.get_children():
		filho.queue_free()

	for doenca in doencas_disponiveis:
		var botao := Button.new()
		botao.text = "Tratar como: %s" % doenca.nome
		botao.custom_minimum_size = Vector2(0, 44)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_estilizar_botao(botao)
		# bind() envia a doença escolhida junto com o sinal de clique
		botao.pressed.connect(_ao_escolher_diagnostico.bind(doenca))
		grid_diagnosticos.add_child(botao)


func _ao_escolher_diagnostico(escolha: Doenca) -> void:
	if turno_encerrado or paciente_atual == null:
		return

	var acertou: bool = GameManager.processar_diagnostico(escolha, paciente_atual)

	if acertou:
		lbl_feedback.text = "Diagnóstico correto: %s  (+R$ %d)" % [
			paciente_atual.nome, paciente_atual.recompensa_financeira
		]
		lbl_feedback.modulate = Color(0.45, 0.95, 0.55)
	else:
		lbl_feedback.text = "Erro de triagem! Era %s, você tratou como %s." % [
			paciente_atual.nome, escolha.nome
		]
		lbl_feedback.modulate = Color(1.0, 0.45, 0.45)

	_atualizar_hud()
	_chamar_proximo_paciente()

	# Sinaliza que o expediente já pode ser fechado
	if paciente_atual == null and not turno_encerrado:
		btn_encerrar.text = "Encerrar Turno  (meta cumprida)"


# --- Encerrar turno -------------------------------------------------------

func _ao_encerrar_turno() -> void:
	if turno_encerrado:
		return
	turno_encerrado = true
	btn_encerrar.disabled = true
	grid_diagnosticos.hide()

	# Cobra a manutenção, avalia a meta e emite o sinal do relatório.
	# Quem ESCUTA esse sinal e desenha o relatório é a tela da Pessoa 3.
	GameManager.realizar_fechamento_de_caixa()

	# Se o fechamento causou falência ou interdição, o sinal de game over já
	# foi emitido e a troca de cena está a caminho: não vamos para o relatório.
	if jogo_acabou:
		return

	_atualizar_hud()
	_ir_para_relatorio()


func _ir_para_relatorio() -> void:
	if ResourceLoader.exists(CENA_RELATORIO):
		get_tree().change_scene_to_file(CENA_RELATORIO)
	else:
		# Fallback: se a cena de gestão ainda não existir no projeto, a tela
		# encerra o expediente sem quebrar o jogo. O aviso técnico vai só para
		# o painel de Saída do editor, nunca para o jogador.
		lbl_paciente_nome.text = "Turno finalizado"
		lbl_sintomas.text = ""
		lbl_feedback.text = "Expediente encerrado. Bom descanso, doutor."
		lbl_feedback.modulate = Color(0.75, 0.85, 1.0)
		btn_encerrar.text = "Encerrar Turno"
		push_warning("Cena %s ainda não existe no projeto." % CENA_RELATORIO)


# --- Reações aos sinais dos sistemas --------------------------------------

func _ao_iniciar_novo_dia(_dia: int, _semana: int) -> void:
	# Emitido pelo TimeManager quando a Pessoa 3 avança o dia
	_atualizar_hud()


func _ao_acionar_game_over(_motivo: String) -> void:
	jogo_acabou = true
	turno_encerrado = true
	btn_encerrar.disabled = true
	get_tree().change_scene_to_file(CENA_GAME_OVER)
