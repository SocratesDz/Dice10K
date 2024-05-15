extends Node3D

@onready var dice = $Dice.get_children()
@onready var throw_point = $ThrowPoint

const IMPULSE_FACTOR = 0.5
const TORQUE_FACTOR = 0.01

func _physics_process(delta):
	if Input.is_action_just_pressed("throw"):
		throw_dice()
	
	# If all dice stopped moving
	var stopped_dice = 0
	for die in dice:
		if(die.stopped_moving()):
			stopped_dice += 1
	if stopped_dice == 6:
		calculate_score()

func throw_dice():
	# Set die to marker point
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

func calculate_score() -> int:
	var dice_chances = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
	for die: Die in dice:
		var die_value = die.get_value()
		if die_value:
			dice_chances[die_value] += 1
	print(dice_chances)
	return 0
