extends KinematicBody2D

export var max_speed = 200
export var max_distance_to_parent = 48;
export var max_chain_length = 4
var travel_radius = 300
var world_origin = Vector2.ZERO
var velocity = Vector2.ZERO
var speed = 200
var rotation_vector = Vector2.ZERO

var number_of_children = 0
var parent: Node = null
var child: Node = null

var runner_color = Color("#50ce42");
var chaser_color = Color("#ce4256");

signal detected_significant_chain

onready var polygon = $RunnerBody
onready var blind_timer = $BlindTimer
onready var eyes = $FRONT/Front
onready var tween = $Tween

enum Types {
	CHASER=1,
	RUNNER=2
}

var type = Types.RUNNER

var line_of_sight_range = atan(10)

func _ready() -> void:
	randomize()
	become_runner()
	scatter()
	connect("detected_significant_chain", get_parent(), "on_Organism_Chain_detected")

func _physics_process(delta: float) -> void:
	check_chain()
	
	var direction_to_parent = rotation_vector
	var distance_to_parent = 0
	var distance_to_parent_ratio = 1
	
	if parent != null:
		if parent.type == Types.CHASER && type == Types.RUNNER || parent == self:
			forget_parent()
		else:
			direction_to_parent = global_position.direction_to(parent.global_position)
			distance_to_parent = global_position.distance_to(parent.global_position)
			if distance_to_parent > 0:
				distance_to_parent_ratio = distance_to_parent / max_distance_to_parent
	
	speed = max_speed * distance_to_parent_ratio
	
	rotation_vector = direction_to_parent
	rotation = atan2(direction_to_parent.y, direction_to_parent.x)
	
	move(delta)

func move(delta: float) -> void:
	velocity = rotation_vector * speed
	
	var angle_to_world_origin = world_origin.angle_to_point(global_position)
	if not tween.is_active() && parent == null:
		if not (rotation - angle_to_world_origin > -line_of_sight_range && rotation - angle_to_world_origin < line_of_sight_range):
			if global_position.distance_squared_to(world_origin) >= travel_radius * travel_radius:
				tween.interpolate_property(self, "rotation", rotation, angle_to_world_origin, 1.0, Tween.EASE_OUT)
				tween.interpolate_property(self, "rotation_vector", rotation_vector, Vector2(cos(rotation), sin(rotation)), 1.0, Tween.EASE_OUT)
				tween.start()
				eyes.disabled = true
				blind_timer.start()

func check_chain() -> void:
	if child == null || child.type != type:
		var tree_result = loop_parents()
		if tree_result[1] >= max_chain_length:
			tree_result[0].scatter_all_children()
			
			match type:
				Types.RUNNER:
					tree_result[0].become_chaser()
				
				Types.CHASER:
					tree_result[0].become_runner()

func runner_state_update(delta: float) -> void:
	pass

func chaser_state_update(delta: float) -> void:
	pass

func scatter() -> void:
	var new_rotation = randf() * 360 * PI / 180
	rotation_vector = Vector2(cos(new_rotation), sin(new_rotation))
	rotate(new_rotation)
	
	eyes.disabled = true
	blind_timer.start()

func scatter_all_children() -> void:
	if child == null:
		scatter()
	else:
		child.scatter_all_children()

func forget_parent() -> void:
	if parent != null:
		parent.number_of_children -= 1
		parent.child = null
		parent = null
		scatter()

func become_chaser():
	polygon.color = chaser_color
	type = Types.CHASER

func become_runner():
	polygon.color = runner_color
	type = Types.RUNNER

func loop_parents(tree_count = 0):
	if parent == null || parent.type != type:
		return [ self, tree_count ]
	else:
		tree_count += 1
		return parent.loop_parents(tree_count)

func _on_FRONT_body_entered(body: Node) -> void:
	if body.type == type || type == Types.CHASER && body.type == Types.RUNNER:
		if parent == null && body != null && body.child == null && body.parent != self && body != self:
			body.child = self
			parent = body

func _on_FRONT_body_exited(body: Node) -> void:
	if body == parent:
		forget_parent()


func _on_BlindTimer_timeout() -> void:
	eyes.disabled = false
