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
	var sum = 0
	for key in dice_matches:
		sum += dice_matches[key]
	if sum != 6:
		print("wrong outcome!")
	return 0

func _on_die_stopped():
	stopped_dice += 1
	if stopped_dice >= dice.size():
		all_dice_stopped.emit()

func _on_die_collided(collided_with: Node, die: Die):
	if collided_with == floor:
		die.thrown = true
		die.body_entered.disconnect(_on_die_collided.bind(die))
