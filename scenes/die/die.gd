class_name Die
extends RigidBody3D

signal stopped

@onready var faces = $Faces
@onready var face_value_map: Dictionary = {
    $Faces/RayCast3D1: 1,
    $Faces/RayCast3D2: 2,
    $Faces/RayCast3D3: 3,
    $Faces/RayCast3D4: 4,
    $Faces/RayCast3D5: 5,
    $Faces/RayCast3D6: 6
}

@export var thrown = false

## Return the value of the dice. If no face is strictly up, returns 0.
func get_value() -> int:
    var face_up: RayCast3D = null
    for raycast in faces.get_children():
        var ray_cast_direction = to_global(raycast.target_position)
        if ray_cast_direction.distance_to(global_position + Vector3.UP) < 1:
            face_up = raycast
    if face_up:
        return face_value_map[face_up]
    else: 
        return 0
