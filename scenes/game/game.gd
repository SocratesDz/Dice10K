class_name Game
extends Node3D

@onready var player_throw_point: Marker3D = $PlayerThrowPoint
@onready var cpu_throw_point: Marker3D = $CPUThrowPoint
@onready var floor_body: StaticBody3D = $Board/Body
@onready var throw_button: Button = %ThrowButton
@onready var player_score_label: Label = %PlayerScoreLabel
@onready var cpu_score_label: Label = %CPUScoreLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hud: Control = $HUD
@onready var play_again_button: Button = %PlayAgainButton
@onready var score_sfx_audio_player: AudioStreamPlayer = $ScoreSfxAudioPlayer
@onready var camera_3d: Camera3D = $Camera3D

@onready var scoring_label_scene = preload("res://scenes/scoring_label/scoring_label.tscn")

const IMPULSE_FACTOR = 1.2
const TORQUE_FACTOR = 0.05
const WINNING_SCORE = 10000
const CPU_TURN_DURATION = 2.0

signal all_dice_stopped
signal player_wins
signal player_loses
signal restart_game

enum TurnType {
    PLAYER, CPU
}

enum ScoreName {
    NO_SCORE,
    SINGLES,
    THREE_PAIRS,
    STRAIGHT,
    FULL_HOUSE,
    DOUBLE,
    THREE_OF_A_KIND,
    FOUR_OF_A_KIND,
    FIVE_OF_A_KIND,
    SIX_OF_A_KIND
}

const SCORE_LABELS = {
    ScoreName.NO_SCORE: "No luck",
    ScoreName.SINGLES: "Singles",
    ScoreName.THREE_PAIRS: "Three Pairs", 
    ScoreName.STRAIGHT: "Straight",
    ScoreName.FULL_HOUSE: "Full House",
    ScoreName.DOUBLE: "Double!",
    ScoreName.THREE_OF_A_KIND: "3 of a kind",
    ScoreName.FOUR_OF_A_KIND: "4 of a kind",
    ScoreName.FIVE_OF_A_KIND: "5 of a kind",
    ScoreName.SIX_OF_A_KIND: "6 of a kind"
}

var dice: Array[Die] = []
var player_score = 0
var cpu_score = 0
var current_turn = TurnType.PLAYER
var _stopped_dice = 0


func _ready():
    for die in $Dice.get_children():
        if die is Die:
            dice.push_back(die)

    # Connect dice signals
    for die in dice:
        die.sleeping_state_changed.connect(_on_die_stopped.bind(die))
    
    # Complete turn when all dice have stopped
    all_dice_stopped.connect(_complete_turn)
    
    # Throw dice when tapping on button
    throw_button.pressed.connect(_throw_dice_action)
    
    # End game signals
    player_wins.connect(_show_end_game_ui.bind(true))
    player_loses.connect(_show_end_game_ui.bind(false))
    
    # Restart game
    play_again_button.pressed.connect(_restart_game)
    
    player_score_label.text = _format_score(player_score, TurnType.PLAYER)
    cpu_score_label.text = _format_score(cpu_score, TurnType.CPU)


func _show_end_game_ui(player_won: bool):
    animation_player.play(&"end_game")
    if player_won:
        animation_player.queue(&"win_text_animation")
    else:
        animation_player.queue(&"lose_text_animation")
    animation_player.queue(&"show_play_again_btn")


func _restart_game():
    animation_player.play_backwards(&"end_game")
    await animation_player.animation_finished
    restart_game.emit()


func _throw_dice_action():
    _reset_dice()
    _hide_throw_button()
    _throw_dice()


## Reset game state
func _reset_dice():
    _stopped_dice = 0
    for die in dice:
        die.thrown = false


func _hide_throw_button():
    throw_button.visible = false


func _show_throw_button():
    throw_button.visible = true


func _complete_turn():
    var score_and_label = calculate_score()
    var score = score_and_label[0]
    var label = SCORE_LABELS[score_and_label[1]]
    if current_turn == TurnType.PLAYER:
        player_score += score
        player_score_label.text = _format_score(player_score, current_turn)
    else:
        cpu_score += score
        cpu_score_label.text = _format_score(cpu_score, current_turn)
    score_sfx_audio_player.play()
    _show_scoring_label(score, label)
    
    if player_score >= WINNING_SCORE:
        player_wins.emit()
    elif cpu_score >= WINNING_SCORE:
        player_loses.emit()
    else:
        if current_turn == TurnType.PLAYER:
            current_turn = TurnType.CPU
        else:
            current_turn = TurnType.PLAYER
        
        if current_turn == TurnType.PLAYER:
            _show_throw_button()
        else:
            await get_tree().create_timer(CPU_TURN_DURATION).timeout
            _throw_dice_action()


func _throw_dice():
    # Set dice around marker throw point
    for i in dice.size():
        var die = dice[i]
        
        var turn_direction_modifier = 0
        var dice_target_position = Vector3.ZERO
        match current_turn:
            TurnType.PLAYER:
                turn_direction_modifier = 1
                dice_target_position = player_throw_point.position
            TurnType.CPU:
                turn_direction_modifier = -1
                dice_target_position = cpu_throw_point.position
        
        # Position dice in a circular pattern around the marker point
        var margin = 0.25
        var horizontal_angle = (i * TAU)/dice.size()
        var vertical_angle = PI/3 * turn_direction_modifier
        var offset = Vector3.UP * margin
        var final_position = dice_target_position + offset\
            .rotated(Vector3.FORWARD, horizontal_angle)\
            .rotated(Vector3.LEFT, vertical_angle)
        die.position = final_position
        
        # Set initial random rotation
        die.rotation = Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI))
        
        die.set_linear_velocity(Vector3.ZERO)
        # Apply impulse forward
        die.apply_impulse(Vector3.FORWARD * IMPULSE_FACTOR * turn_direction_modifier)
        # Apply torque impulse
        die.apply_torque_impulse(Vector3.FORWARD * TORQUE_FACTOR * turn_direction_modifier)
        # Detect when die hits floor
        die.body_entered.connect(_on_die_collided.bind(die))


func _on_die_stopped(die: Die):
    if die.thrown and die.sleeping:
        _stopped_dice += 1

    if _stopped_dice >= dice.size():
        all_dice_stopped.emit()


func _show_scoring_label(score: int, label: String):
    var average_position = dice\
        .reduce(func(acc, die): return acc + die.position, Vector3.ZERO)
    average_position = average_position/dice.size()
    var label_position = camera_3d.unproject_position(to_global(average_position))
    
    var scoring_label: ScoringLabel = scoring_label_scene.instantiate()
    scoring_label.score_amount_text = "+%d" % [score]
    scoring_label.score_name_text = label
    scoring_label.position = label_position
    scoring_label.z_index = -1
    hud.add_child(scoring_label)


func _on_die_collided(collided_with: Node, die: Die):
    if collided_with == floor_body:
        die.thrown = true
        die.body_entered.disconnect(_on_die_collided.bind(die))


func _format_score(score: int, turn_type: TurnType) -> String:
    if turn_type == TurnType.PLAYER:
        return "PLAYER\n%d" % [score]
    else:
        return "%d\nCPU" % [score]


func calculate_score() -> Array:
    var dice_matches = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
    for die in dice:
        var die_value = die.get_value()
        if die_value:
            dice_matches[die_value] += 1
    print(dice_matches)
    
    # DEBUG: Verify dice matches sum is six
    var sum = 0
    for key in dice_matches:
        sum += dice_matches[key]
    if sum != 6:
        print("wrong outcome!")
    # DEBUG_END

    var n_of_a_kind = _n_of_a_kind(dice_matches)
    var other_scores = _collective_score_kinds(dice_matches)
    var total_score = []
    if n_of_a_kind[0] > other_scores[0]:
        total_score = n_of_a_kind
    else:
        total_score = other_scores
        
    print("Score: %d; %s" % [total_score[0], SCORE_LABELS[total_score[1]]])
    return total_score


func _n_of_a_kind(dice_dict: Dictionary) -> Array:
    var double_trip_counter = 0
    var double_trip_score = 0
    for key in dice_dict:
        var value = dice_dict[key]
        match [key, value]:
            [1, var n] when n >= 3:
                return [1000*(2**(n-3)), n+3] # n = 3 => ScoreName.THREE_OF_A_KIND
            [var m, var n] when n >= 3:
                var score = 100*m*(n-2)
                # Handle Double Trips when 2 sets of a 3 of a kind are hit.
                if n == 3:
                    double_trip_score += score
                    double_trip_counter += 1
                if double_trip_counter == 2:
                    return [(score + double_trip_score) * double_trip_counter, ScoreName.DOUBLE]
                return [score, n+3] # n = 3 => ScoreName.THREE_OF_A_KIND
            _: pass
    return [0, ScoreName.NO_SCORE]


func _collective_score_kinds(dice_dict: Dictionary) -> Array:
    var non_zero_matches = dice_dict.values().filter(func(n): return n != 0)
    non_zero_matches.sort()
    
    match non_zero_matches:
        [1, 1, 1, 1, 1, 1]:
            return [1500, ScoreName.STRAIGHT] # Straight 1-6
        [2, 2, 2]:
            return [1000, ScoreName.THREE_PAIRS] # Three Pairs
        _: pass
    
    var has_two = non_zero_matches.any(func(n): return n == 2)
    var has_three = non_zero_matches.any(func(n): return n == 3)
    if has_two and has_three:
        return [1500, ScoreName.FULL_HOUSE] # Full House
    
    var singles = 0
    if dice_dict[1] > 0:
        singles += dice_dict[1] * 100 # Single 1's
    if dice_dict[5] > 0:
        singles += dice_dict[5] * 50 # Single 5's
    
    var single_score_name = 0
    if singles:
        single_score_name = 1
    return [singles, single_score_name]
