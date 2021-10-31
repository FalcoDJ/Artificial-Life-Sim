#
# HERE IS THE PLAN:
#
#	The whole organism is driven by a state machine
#
#	Each frame update is called:
#		*1. look for parent if I donot have a parent. ( if am I runner, I only follow runners )
#		2. if I am the leader in a group of 4 of my type, I change types, and if I am a runner, I scatter 
#		   my children after making a new one, or else destroy my children if I am a chaser
#		*3. If I am the leader, Instead of bouncing off of walls I always like to move back
#		   toward the center of the world once I have moved a certain distance away from it
#		*4. I try to stay a certain distance away from my parent
#		5. If I am a runner, when I have been scatter I don't look for a parent for 1 second.
#

extends KinematicBody2D
class_name Organism

export(float) var speed = 200
export var max_distance_to_parent = 48
export var min_distance_to_parent = 8
var significant_chain_length = 4
var travel_radius = 300
var world_origin = Vector2.ZERO

onready var runner_body = $RunnerBody
onready var chaser_body = $ChaserBody
onready var eyes = $FRONT/Front
onready var tween = $Tween
onready var blind_timer = $BlindTimer

enum Types {
	RUNNER=0,
	CHASER=1
}

var type = Types.RUNNER

var rotation_vector = Vector2.ZERO

var line_of_sight_range = atan(10)
var actual_speed = speed

var parent: Node = null
var child: Node = null

signal significant_chain_detected_under_runner

func _ready() -> void:
	become_runner()

func _physics_process(delta: float) -> void:
	match type:
		Types.RUNNER:
			runner_state_update(delta)
		
		Types.CHASER:
			chaser_state_update(delta)
	
	move_organism(delta)

func move_organism(delta: float) -> void:
	var angle_to_world_origin = world_origin.angle_to_point(global_position)
	
	var angle_to_parent = rotation
	var distance_to_parent = 0
	var distance_to_parent_ratio = 1
	
	if parent != null:
		if parent == self:
			parent.child = null
			parent = null
		else:
			angle_to_parent = parent.global_position.angle_to_point(global_position)
			distance_to_parent = global_position.distance_to(parent.global_position)
			if distance_to_parent > 0:
				distance_to_parent_ratio = max(distance_to_parent, min_distance_to_parent) / max_distance_to_parent
	
	actual_speed = speed * distance_to_parent_ratio
	
	rotation = angle_to_parent
	
	if !tween.is_active() && parent == null:
		if not (rotation - angle_to_world_origin > -line_of_sight_range && rotation - angle_to_world_origin < line_of_sight_range):
			if global_position.distance_squared_to(world_origin) >= travel_radius * travel_radius:
				tween.interpolate_property(self, "rotation", rotation, angle_to_world_origin, 1.0, Tween.EASE_OUT)
				tween.start()
	
	rotation_vector = Vector2(cos(rotation), sin(rotation))
	move_and_collide(rotation_vector * actual_speed * delta)

func become_runner():
	runner_body.visible = true
	chaser_body.visible = false
	type = Types.RUNNER

func become_chaser():
	chaser_body.visible = true
	runner_body.visible = false
	type = Types.CHASER

func runner_state_update(delta: float) -> void:
	if parent != null && parent.type == Types.CHASER:
		parent = null
	elif parent == null:
		var children: Array = find_significant_chain()
		if children.size() >= significant_chain_length:
			become_chaser()
			
			for org in children:
				if org == self: continue
				
				scatter()

func chaser_state_update(delta: float) -> void:
	if parent == null || parent.type != type:
		var children: Array = find_significant_chain();
		if children.size() >= significant_chain_length:
			
			emit_signal("significant_chain_detected_under_runner", global_position)
			
			for org in children:
				if org == self: continue
				
				org.queue_free()

func scatter():
	rotation = randf() * 360 * PI / 180
	
	move_organism(0.01)
	
	eyes.disabled = true
	blind_timer.start(1.0)
	

func find_significant_chain() -> Array:
	var children = loop_children_of_type()
	return children

func loop_children_of_type(children = Array()) -> Array:
	children.push_back(self)
	
	if child == null || child.type != type || children.size() >= significant_chain_length:
		return children
	else:
		child.loop_children_of_type(children)
		return children

func get_last_child_regardless_of_type():
	if child == null:
		return self
	else:
		return child.get_last_child_regardless_of_type()

func get_highest_parent_regardless_of_type():
	if parent == null:
		return self
	else:
		return parent.get_highest_parent_regardless_of_type()

func _on_FRONT_body_entered(body: Node) -> void:
	if parent == null && body.child == null && body != self && body.parent != self && body != child:
		if type == Types.CHASER || type == Types.RUNNER && body.type == Types.RUNNER:
			body.child = self
			parent = body

func _on_FRONT_body_exited(body: Node) -> void:
	if body.child == self:
		body.child = null
		parent = null

func _on_BlindTimer_timeout() -> void:
	eyes.disabled = false
