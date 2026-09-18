class_name BuffCard
extends Button

signal chosen(card: BuffCard)

const GREEN_COLOR := Color(0.16, 0.55, 0.32)
const RED_COLOR := Color(0.65, 0.2, 0.18)
const YELLOW_COLOR := Color(0.75, 0.55, 0.15)

@onready var top_stripe : ColorRect = $Margin/VBox/TopStripe
@onready var type_label : Label = $Margin/VBox/TypeLabel
@onready var title_label : Label = $Margin/VBox/TitleLabel
@onready var desc_label : Label = $Margin/VBox/DescLabel

var card_type : String = "green"
var buff_id : String

func _ready() -> void:
	pressed.connect(_on_pressed)

func setup(data: Dictionary) -> void:
	card_type = str(data.get("type", "green"))
	buff_id = data.get("buff_id","")
	var color : Color = GREEN_COLOR if card_type == "green" else (RED_COLOR if card_type == "red" else YELLOW_COLOR)
	top_stripe.color = color
	type_label.add_theme_color_override("font_color", color)
	type_label.text = "BUFF" if card_type == "green" else ("DEBUFF" if card_type == "red" else "RANDOM")
	title_label.text = str(data.get("title", "Без названия"))
	desc_label.text = str(data.get("desc", "Заглушка"))

func _on_pressed() -> void:
	chosen.emit(self)
