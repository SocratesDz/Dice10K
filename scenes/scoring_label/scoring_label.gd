class_name ScoringLabel
extends Control

@export var score_amount_text: String
@export var score_name_text: String

@onready var score_text = %ScoreText
@onready var score_name = %ScoreName
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready():
    score_text.text = score_amount_text
    score_name.text = score_name_text
    animation_player.play("score_fade_out")
    await animation_player.animation_finished
    queue_free()
