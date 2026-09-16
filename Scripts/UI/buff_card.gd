class_name BuffCard
extends Button

signal chosen(card: BuffCard)

const GREEN_COLOR := Color(0.16, 0.55, 0.32)
const RED_COLOR := Color(0.65, 0.2, 0.18)

@onready var top_stripe : ColorRect = $Margin/VBox/TopStripe
@onready var type_label : Label = $Margin/VBox/TypeLabel
@onready var title_label : Label = $Margin/VBox/TitleLabel
@onready var desc_label : Label = $Margin/VBox/DescLabel

var card_type : String = "green"

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(data: Dictionary) -> void:
	card_type = str(data.get("type", "green"))
	var color := GREEN_COLOR if card_type == "green" else RED_COLOR
	top_stripe.color = color
	type_label.text = "БАФФ" if card_type == "green" else "ДЕБАФФ"
	title_label.text = str(data.get("title", "Без названия"))
	desc_label.text = str(data.get("desc", "Заглушка"))

func _on_pressed() -> void:
	chosen.emit(self)