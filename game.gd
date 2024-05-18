extends Node3D

@onready var throw_point = $ThrowPoint
@onready var floor_body = $Board/Body
@onready var throw_button = %ThrowButton
@onready var score_label = %ScoreLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

const IMPULSE_FACTOR = 0.5
const TORQUE_FACTOR = 0.01
const WINNING_SCORE = 10000

signal all_dice_stopped
signal player_wins
signal player_loses

var stopped_dice = 0
var dice: Array[Die] = []
var turn_start = false
var player_score = 0
var cpu_score = 0


func _ready():
    for die in $Dice.get_children():
        if die is Die:
            dice.push_back(die)

    # Connect dice signals
    for die in dice:
        die.stopped.connect(_on_die_stopped)
    
    # Complete turn when all dice have stopped
    all_dice_stopped.connect(_complete_turn)
    
    # Throw dice when tapping on button
    throw_button.pressed.connect(_throw_dice_action)
    
    # End game signals
    player_wins.connect(_show_end_game_ui.bind(true))
    player_loses.connect(_show_end_game_ui.bind(false))
    
    score_label.text = str(player_score)
    
    turn_start = true


func _show_end_game_ui(player_won: bool):
    animation_player.play(&"end_game")
    if player_won:
        animation_player.queue(&"win_text_animation")
    else:
        animation_player.queue(&"lose_text_animation")
    animation_player.queue(&"show_play_again_btn")


func _physics_process(_delta: float):
    if turn_start and Input.is_action_just_pressed("throw"):
        _throw_dice_action()


func _throw_dice_action():
    turn_start = false
    _reset_dice()
    _hide_throw_button()
    _throw_dice()


## Reset game state
func _reset_dice():
    stopped_dice = 0
    for die in dice:
        die.thrown = false
        # Is die.thrown being set to true after this?


func _hide_throw_button():
    throw_button.visible = false


func _show_throw_button():
    throw_button.visible = true


func _complete_turn():
    player_score += calculate_score()
    score_label.text = str(player_score)
    if player_score >= WINNING_SCORE:
        player_wins.emit()
    elif cpu_score >= WINNING_SCORE:
        player_loses.emit()
    else:
        _show_throw_button()
        turn_start = true


func _throw_dice():
    # Set dice around marker throw point
    for i in dice.size():
        var die = dice[i]
        # Position dice horizontally in linear fashion
        var margin_x = 0.20
        die.position = throw_point.position + \
            ((i - dice.size()/2) * Vector3(margin_x, 0, 0))
        die.rotation = Vector3.ZERO
        die.set_linear_velocity(Vector3.ZERO)
        # Apply impulse forward
        die.apply_impulse(Vector3.FORWARD * IMPULSE_FACTOR)
        # Apply torque impulse
        die.apply_torque_impulse(Vector3.FORWARD * TORQUE_FACTOR)
        # Detect when die hits floor
        die.body_entered.connect(_on_die_collided.bind(die))


func _on_die_stopped():
    stopped_dice += 1
    # Keep a reference to the node so the die is unique. 
    # It seems I'm getting more than one signal emission.
    if stopped_dice >= dice.size():
        all_dice_stopped.emit()


func _on_die_collided(collided_with: Node, die: Die):
    if collided_with == floor_body:
        die.thrown = true
        die.body_entered.disconnect(_on_die_collided.bind(die))


func calculate_score() -> int:
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
    var total_score = [n_of_a_kind, other_scores].max()
    print(total_score)
    return total_score


func _n_of_a_kind(dice_dict: Dictionary) -> int:
    var double_trip_counter = 0
    var double_trip_score = 0
    for key in dice_dict:
        var value = dice_dict[key]
        match [key, value]:
            [1, var n] when n >= 3:
                return 1000*(2**(n-3))
            [var m, var n] when n >= 3:
                var score = 100*m*(n-2)
                # Handle Double Trips when 2 sets of a 3 of a kind are hit.
                if n == 3:
                    print("3 of a kind!")
                    double_trip_score += score
                    double_trip_counter += 1
                if double_trip_counter == 2:
                    return (score + double_trip_score) * double_trip_counter
                return score
            _: pass
    return 0


func _collective_score_kinds(dice_dict: Dictionary) -> int:
    var non_zero_matches = dice_dict.values().filter(func(n): return n != 0)
    non_zero_matches.sort()
    
    match non_zero_matches:
        [1, 1, 1, 1, 1, 1]: 
            print("Straight!")
            return 1500 # Straight 1-6
        [2, 2, 2]: 
            print("Three Pairs!")
            return 1000 # Three Pairs
        _: pass
    
    var has_two = non_zero_matches.any(func(n): return n == 2)
    var has_three = non_zero_matches.any(func(n): return n == 3)
    if has_two and has_three: return 1500 # Full House
    
    var singles = 0
    if dice_dict[1] > 0:
        singles += dice_dict[1] * 100 # Single 1's
    if dice_dict[5] > 0:
        singles += dice_dict[5] * 50 # Single 5's
    
    return singles
