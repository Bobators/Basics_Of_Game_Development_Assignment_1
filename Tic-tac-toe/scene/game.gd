extends Control

const CELL_EMPTY = ""
const CELL_X = "X"
const CELL_O = "O"

@onready var buttons = $GridContainer.get_children()
@onready var label = $Label

var current_player
var board

func _ready():
	label.text = CELL_X + "'s turn"
	var button_index = 0
	for button in buttons:
		button.text = CELL_EMPTY
		button.connect("pressed", Callable(self, "_on_button_click").bind(button_index))  # 使用 Callable + bind
		button_index += 1
	reset_game()

func _on_button_click(index):
	var x = index % 3  # 列
	var y = index / 3  # 行
	var button = buttons[index]

	if board[y][x] == CELL_EMPTY:
		button.text = current_player
		board[y][x] = current_player
		current_player = CELL_O if current_player == CELL_X else CELL_X
		label.text = current_player + "'s turn"

func reset_game():
	current_player = CELL_X
	board = [
		[CELL_EMPTY, CELL_EMPTY, CELL_EMPTY],
		[CELL_EMPTY, CELL_EMPTY, CELL_EMPTY],
		[CELL_EMPTY, CELL_EMPTY, CELL_EMPTY]
	]
	for button in buttons:
		button.text = CELL_EMPTY
