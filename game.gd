extends Node3D

@onready var throw_point = $ThrowPoint
@onready var floor = $Board/Body

const IMPULSE_FACTOR = 0.5
const TORQUE_FACTOR = 0.01

signal all_dice_stopped

var stopped_dice = 0

var dice: Array[Die] = []

func _ready():
	for die in $Dice.get_children():
		if die is Die:
			dice.push_back(die)

	# Connect dice signals
	for die in dice:
		if die is Die:
			die.stopped.connect(_on_die_stopped)
	
	all_dice_stopped.connect(calculate_score)

func _physics_process(delta):
	if Input.is_action_just_pressed("throw"):
		_reset()
		_throw_dice()

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

## Reset game state
func _reset():
	stopped_dice = 0
	for die in dice:
		die.thrown = false

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

func _on_die_stopped():
	stopped_dice += 1
	if stopped_dice >= dice.size():
		all_dice_stopped.emit()

func _on_die_collided(collided_with: Node, die: Die):
	if collided_with == floor:
		die.thrown = true
		die.body_entered.disconnect(_on_die_collided.bind(die))

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
	var non_zero_matches = []
	for die in dice_dict.values():
		if die: 
			non_zero_matches.push_back(die)
	
	non_zero_matches.sort()
	
	match non_zero_matches:
		[1, 1, 1, 1, 1, 1]: 
			print("Straight!")
			return 1500 # Straight 1-6
		[2, 2, 2]: 
			print("Three Pairs!")
			return 1000 # Three Pairs
		_: pass
	
	var has_two = non_zero_matches.any(func(n): n == 2)
	var has_three = non_zero_matches.any(func(n): n == 3)
	if has_two and has_three: return 1500 # Full House
	
	var singles = 0
	if dice_dict[1] > 0:
		singles += dice_dict[1] * 100 # Single 1's
	if dice_dict[5] > 0:
		singles += dice_dict[5] * 50 # Single 5's
	
	return singles
