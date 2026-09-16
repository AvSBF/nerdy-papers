extends CanvasLayer

@onready var label : Label = $Label

@onready var interactor : Node = get_node("../Interactor")

func _ready() -> void:
	interactor.target_changed.connect(_update_prompt)
	interactor.held_paper_changed.connect(_update_prompt)
	label.hide()

func _update_prompt(_arg: Variant = null) -> void:
	if not interactor.held_papers.is_empty():
		label.text = "[G] to throw"
		label.show()
		return
	var target : Node = interactor.current_target
	if target != null and target.is_in_group("button"):
		label.text = "[E] to interact"
		label.show()
	elif target != null and target.is_in_group("paper"):
		label.text = "[E] to pick up"
		label.show()
	else:
		label.hide()