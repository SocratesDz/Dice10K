extends Node3D

@onready var dice = $Dice.get_children()
@onready var throw_point = $ThrowPoint

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _physics_process(delta):
	if Input.is_action_just_pressed("throw"):
		throw_dice()

func throw_dice():
	# Set die to marker point
	for i in dice.size():
		var die = dice[i]
		# Position dice horizontally in linear fashion
		die.position = throw_point.position + ((i - dice.size()/2) * Vector3(0.20, 0, 0))
		die.rotation = Vector3.ZERO
		# Apply impulse forward
		die.apply_impulse(Vector3.FORWARD * 0.03)
		# Apply torque impulse
		die.apply_torque_impulse(Vector3(-1.0, 0, 0) * 0.01)
