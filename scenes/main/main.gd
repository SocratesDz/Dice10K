extends Node3D

@onready var start_button: Button = %StartButton
@onready var game_scene = preload("res://scenes/game/game.tscn") 
@onready var main_menu: Control = $MainMenu

var game_node: Game = null

func _ready():
    _init_game()
    start_button.pressed.connect(_start)

func _init_game():
    game_node = game_scene.instantiate()
    add_child(game_node)
    game_node.restart_game.connect(_restart_game)
    game_node.process_mode = Node.PROCESS_MODE_DISABLED
    
func _start():
    main_menu.visible = false
    game_node.process_mode = Node.PROCESS_MODE_INHERIT
    game_node.hud.visible = true

func _restart_game():
    if game_node:
        game_node.queue_free()
    _init_game()
    _start()
