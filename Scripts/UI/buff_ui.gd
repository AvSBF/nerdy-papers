extends CanvasLayer

@onready var value_label : Label = $Panel/Margin/VBox/TopRow/Value
@onready var progress_bar : ProgressBar = $Panel/Margin/VBox/Progress

func _ready():
	get_tree().get_first_node_in_group("round_controller").deposits_changed.connect(change_label)

func change_label(total_deposited : int, buff_threshold : int):
	value_label.text = "%d / %d" %[total_deposited, buff_threshold]
	progress_bar.max_value = buff_threshold
	progress_bar.value = total_deposited
