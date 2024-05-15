class_name Die
extends RigidBody3D

@onready var faces = $Faces
@onready var face_value_map: Dictionary = {
	$Faces/RayCast3D1: 1,
	$Faces/RayCast3D2: 2,
	$Faces/RayCast3D3: 3,
	$Faces/RayCast3D4: 4,
	$Faces/RayCast3D5: 5,
	$Faces/RayCast3D6: 6
}

var cast = false


func _physics_process(delta):
	if not cast and stopped_moving():
		cast = true

## Return the value of the dice. If no face is strictly up, returns 0.
func get_value() -> int:
	var face_up: RayCast3D = null
	for raycast in faces.get_children():
		var ray_cast_direction = to_global(raycast.target_position)
		if (ray_cast_direction - Vector3.UP).length_squared() < 1:
			face_up = raycast
	if face_up:
		return face_value_map[face_up]
	else: 
		return 0

func stopped_moving() -> bool:
	return linear_velocity.length_squared() < 0.001
