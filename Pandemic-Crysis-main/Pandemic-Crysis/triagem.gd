extends Control

# ---------------------------------------------------------------------------
# PANDEMIC CRYSIS - Tela de Triagem (Terminal Médico)
# Responsável: Pessoa 2
#
# ESCOPO DESTA TELA (só isto):
#   - Mostrar Dia/Semana, Caixa e o placar do turno
#   - Montar o prontuário com o relato do paciente
#   - Oferecer os botões de diagnóstico -> GameManager.processar_diagnostico()
#   - Botão "Encerrar Turno" -> GameManager.realizar_fechamento_de_caixa()
#
# FORA DO ESCOPO (outros integrantes):
#   - Relatório diário e loja de upgrades
#   - Avançar o dia (TimeManager.avancar_dia)
#   - Efeito dos upgrades no jogo
# ---------------------------------------------------------------------------

const CENA_RELATORIO: String = "res://RelatorioDiario.tscn"
const CENA_GAME_OVER: String = "res://game_over.tscn"
const CENA_MENU: String = "res://menu_principal.tscn"

# Quantos pacientes ALÉM da meta o jogador pode atender, se quiser.
# A meta continua sendo do GameManager; isto é só o teto da sala de espera.
const ATENDIMENTOS_ALEM_DA_META: int = 4

# Quanto custa pedir um exame complementar (revela mais um sintoma).
const CUSTO_EXAME: int = 50

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

@onready var lbl_dia: Label = %LblDia
@onready var lbl_dinheiro: Label = %LblDinheiro
@onready var lbl_pacientes: Label = %LblPacientes
@onready var lbl_placar: Label = %LblPlacar
@onready var lbl_paciente_nome: Label = %LblPacienteNome
@onready var lbl_sintomas: Label = %LblSintomas
@onready var grid_diagnosticos: GridContainer = %GridDiagnosticos
@onready var lbl_feedback: Label = %LblFeedback
@onready var btn_encerrar: Button = %BtnEncerrarTurno
@onready var btn_sair: Button = %BtnSair
@onready var btn_exame: Button = %BtnExame
@onready var painel_prontuario: PanelContainer = %PainelProntuario
@onready var painel_diagnostico: PanelContainer = %PainelDiagnostico

# Estado da tela
var paciente_atual: Doenca = null            # a doença REAL do paciente na maca
var doencas_disponiveis: Array[Doenca] = []  # doenças já liberadas pela semana
var sintomas_do_paciente: Array = []         # quadro completo, embaralhado
var sintomas_revelados: int = 0              # quantos deles o paciente relatou
var contador_paciente: int = 0
var turno_encerrado: bool = false
var jogo_acabou: bool = false
var saida_confirmando: bool = false


func _ready() -> void:
	GameManager.game_over_acionado.connect(_ao_acionar_game_over)
	TimeManager.novo_dia_iniciado.connect(_ao_iniciar_novo_dia)
	btn_encerrar.pressed.connect(_ao_encerrar_turno)
	btn_sair.pressed.connect(_ao_clicar_sair)
	btn_exame.pressed.connect(_ao_solicitar_exame)

	# A sala de espera reabre a cada carregamento da cena (novo dia)
	grid_diagnosticos.show()

	# Ajusta meta e manutenção conforme a semana antes de montar a tela
	GameManager.atualizar_dificuldade_da_semana(TimeManager.semana_atual)

	_aplicar_estilo()
	_atualizar_doencas_disponiveis()
	_montar_botoes_diagnostico()
	_chamar_proximo_paciente()
	_atualizar_hud()

	# Checkpoint: o início de cada dia é um ponto seguro para salvar
	GameManager.salvar_partida()


# --- Atalhos de teclado ---------------------------------------------------
# Teclas 1 a 9 escolhem o diagnóstico, E pede exame, Enter encerra o turno.
# Jogar de teclado cansa muito menos que mirar o mouse em botão.
func _unhandled_input(event: InputEvent) -> void:
	if turno_encerrado or not (event is InputEventKey):
		return
	if not event.pressed or event.echo:
		return

	var tecla: int = event.keycode

	if tecla >= KEY_1 and tecla <= KEY_9 and grid_diagnosticos.visible:
		var indice: int = tecla - KEY_1
		var botoes: Array = grid_diagnosticos.get_children()
		if indice < botoes.size():
			botoes[indice].pressed.emit()
			accept_event()
	elif tecla == KEY_E:
		_ao_solicitar_exame()
		accept_event()
	elif tecla == KEY_ENTER or tecla == KEY_KP_ENTER:
		if not btn_encerrar.disabled:
			_ao_encerrar_turno()
			accept_event()


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
	_estilizar_botao(btn_sair)
	_estilizar_botao(btn_exame)


# --- HUD ------------------------------------------------------------------

func _atualizar_hud() -> void:
	lbl_dia.text = "Dia %d  |  Semana %d" % [TimeManager.dia_atual, TimeManager.semana_atual]
	lbl_dinheiro.text = "Caixa: R$ %d" % GameManager.caixa_hospital
	lbl_pacientes.text = "Pacientes: %d / %d" % [
		GameManager.pacientes_atendidos_hoje,
		GameManager.meta_pacientes_dia
	]
	lbl_placar.text = "Acertos: %d  |  Erros: %d" % [
		GameManager.diagnosticos_corretos_hoje,
		GameManager.erros_cometidos_hoje
	]
	_atualizar_botao_encerrar()


# --- Prontuário -----------------------------------------------------------

func _atualizar_doencas_disponiveis() -> void:
	doencas_disponiveis.clear()
	for doenca in GameManager.banco_de_doencas:
		if doenca.semana_de_aparicao <= TimeManager.semana_atual:
			doencas_disponiveis.append(doenca)

	if doencas_disponiveis.is_empty():
		for doenca in GameManager.banco_de_doencas:
			doencas_disponiveis.append(doenca)


func _chamar_proximo_paciente() -> void:
	# A fila do dia termina no teto de atendimentos (meta + extras).
	# Decisão de INTERFACE: não altera nenhuma regra dos controladores.
	var teto_do_dia: int = GameManager.meta_pacientes_dia + ATENDIMENTOS_ALEM_DA_META
	if GameManager.pacientes_atendidos_hoje >= teto_do_dia:
		# Atingido o limite do dia, o expediente fecha sozinho.
		lbl_paciente_nome.text = "Sala de espera vazia"
		lbl_sintomas.text = "-  Todos os pacientes do dia foram atendidos."
		paciente_atual = null
		grid_diagnosticos.hide()
		_atualizar_botao_exame()
		_encerrar_automaticamente()
		return

	if doencas_disponiveis.is_empty():
		lbl_paciente_nome.text = "Nenhuma doença cadastrada no banco (.tres)"
		lbl_sintomas.text = ""
		paciente_atual = null
		_atualizar_botao_exame()
		return

	contador_paciente += 1
	paciente_atual = doencas_disponiveis.pick_random()
	lbl_paciente_nome.text = "Ficha #%03d  -  %s, %d anos" % [
		contador_paciente, _gerar_nome_paciente(), randi_range(18, 89)
	]
	_sortear_relato_do_paciente()
	_atualizar_prontuario()


func _gerar_nome_paciente() -> String:
	return "%s %s" % [NOMES.pick_random(), SOBRENOMES.pick_random()]


# O paciente relata só PARTE do quadro. É isso que impede o jogador de
# decorar "sintoma X = doença Y": com o relato incompleto, dois quadros
# diferentes podem parecer iguais e é preciso pesar as possibilidades.
func _sortear_relato_do_paciente() -> void:
	sintomas_do_paciente = paciente_atual.sintomas.duplicate()
	sintomas_do_paciente.shuffle()

	var total: int = sintomas_do_paciente.size()
	if total >= 4:
		sintomas_revelados = randi_range(2, total - 1)
	elif total == 3:
		sintomas_revelados = randi_range(2, 3)
	else:
		sintomas_revelados = total


func _atualizar_prontuario() -> void:
	if sintomas_do_paciente.is_empty():
		lbl_sintomas.text = "-  Paciente não relatou sintomas."
	else:
		var linhas: PackedStringArray = []
		for i in range(sintomas_revelados):
			linhas.append("-  " + str(sintomas_do_paciente[i]))
		lbl_sintomas.text = "\n".join(linhas)

	_atualizar_botao_exame()


# --- Exame complementar ---------------------------------------------------

func _atualizar_botao_exame() -> void:
	if paciente_atual == null or turno_encerrado:
		btn_exame.disabled = true
		btn_exame.text = "Solicitar exame (R$ %d)" % CUSTO_EXAME
		return

	if sintomas_revelados >= sintomas_do_paciente.size():
		btn_exame.disabled = true
		btn_exame.text = "Exames concluídos"
	else:
		btn_exame.disabled = GameManager.caixa_hospital < CUSTO_EXAME
		btn_exame.text = "Solicitar exame (R$ %d)" % CUSTO_EXAME


# Paga para revelar mais um sintoma do paciente atual.
# Transforma a incerteza do relato parcial numa decisão: vale a pena gastar
# para ter certeza, ou é melhor arriscar o diagnóstico?
func _ao_solicitar_exame() -> void:
	if turno_encerrado or paciente_atual == null:
		return
	if sintomas_revelados >= sintomas_do_paciente.size():
		return
	if GameManager.caixa_hospital < CUSTO_EXAME:
		lbl_feedback.text = "Caixa insuficiente para solicitar exames."
		lbl_feedback.modulate = Color(1.0, 0.85, 0.4)
		return

	GameManager.caixa_hospital -= CUSTO_EXAME
	sintomas_revelados += 1

	lbl_feedback.text = "Exame realizado (-R$ %d). Novo achado no prontuário." % CUSTO_EXAME
	lbl_feedback.modulate = Color(0.75, 0.85, 1.0)

	_atualizar_prontuario()
	_atualizar_hud()


# --- Botões de diagnóstico ------------------------------------------------

func _montar_botoes_diagnostico() -> void:
	for filho in grid_diagnosticos.get_children():
		filho.queue_free()

	var indice: int = 1
	for doenca in doencas_disponiveis:
		var botao := Button.new()
		# O número serve de atalho de teclado (teclas 1 a 9)
		if indice <= 9:
			botao.text = "%d. %s" % [indice, doenca.nome]
		else:
			botao.text = doenca.nome
		botao.custom_minimum_size = Vector2(0, 44)
		botao.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_estilizar_botao(botao)
		botao.pressed.connect(_ao_escolher_diagnostico.bind(doenca))
		grid_diagnosticos.add_child(botao)
		indice += 1


func _ao_escolher_diagnostico(escolha: Doenca) -> void:
	if turno_encerrado or paciente_atual == null:
		return

	var acertou: bool = GameManager.processar_diagnostico(escolha, paciente_atual)

	# A penalidade pode ter falido o hospital: o sinal de game over já veio e
	# a troca de cena está a caminho, então não chamamos o próximo paciente.
	if jogo_acabou:
		return

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


# --- Encerrar turno -------------------------------------------------------

func _ao_encerrar_turno() -> void:
	if turno_encerrado:
		return
	turno_encerrado = true
	btn_encerrar.disabled = true
	grid_diagnosticos.hide()
	_atualizar_botao_exame()

	GameManager.realizar_fechamento_de_caixa()

	if jogo_acabou:
		return

	_atualizar_hud()
	_ir_para_relatorio()


# Fecha o turno sozinho ao bater o limite do dia. A pausa curta existe para
# o jogador enxergar o resultado do último atendimento antes da troca de tela.
func _encerrar_automaticamente() -> void:
	if turno_encerrado:
		return
	btn_encerrar.disabled = true
	await get_tree().create_timer(1.5).timeout
	if not turno_encerrado:
		btn_encerrar.disabled = false
		_ao_encerrar_turno()


func _atualizar_botao_encerrar() -> void:
	if turno_encerrado:
		return
	var cumpriu: bool = GameManager.pacientes_atendidos_hoje >= GameManager.meta_pacientes_dia
	if cumpriu:
		btn_encerrar.text = "Encerrar Turno  (meta cumprida)  -  manutenção R$ %d" % GameManager.custo_manutencao_diaria
	else:
		btn_encerrar.text = "Encerrar Turno  -  manutenção R$ %d" % GameManager.custo_manutencao_diaria


func _ir_para_relatorio() -> void:
	if ResourceLoader.exists(CENA_RELATORIO):
		get_tree().change_scene_to_file(CENA_RELATORIO)
	else:
		lbl_paciente_nome.text = "Turno finalizado"
		lbl_sintomas.text = ""
		lbl_feedback.text = "Expediente encerrado. Bom descanso, doutor."
		lbl_feedback.modulate = Color(0.75, 0.85, 1.0)
		btn_encerrar.text = "Encerrar Turno"
		push_warning("Cena %s ainda não existe no projeto." % CENA_RELATORIO)


# --- Sair da partida ------------------------------------------------------

# Dois cliques de propósito: o primeiro pede confirmação, o segundo salva e sai.
func _ao_clicar_sair() -> void:
	if not saida_confirmando:
		saida_confirmando = true
		btn_sair.text = "Sair e salvar?"
		return
	# Salva antes de sair: o jogador volta no mesmo dia, com o mesmo caixa.
	# Só o paciente que estava na maca é sorteado de novo.
	GameManager.salvar_partida()
	get_tree().change_scene_to_file(CENA_MENU)


# --- Reações aos sinais dos sistemas --------------------------------------

func _ao_iniciar_novo_dia(_dia: int, _semana: int) -> void:
	_atualizar_hud()


func _ao_acionar_game_over(_motivo: String) -> void:
	jogo_acabou = true
	turno_encerrado = true
	btn_encerrar.disabled = true
	get_tree().change_scene_to_file(CENA_GAME_OVER)
