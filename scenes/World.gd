extends Node2D

export(float) var travel_radius = 128.0
export(int, 2, 1000000000) var significant_chain_length = 4
export(int, 8, 1000000000) var Organism_Count = 20

onready var Organism = preload("res://scenes/Organism/Organism.tscn")

func _ready() -> void:
	randomize()
	
	for i in Organism_Count:
		var org = Organism.instance()
		add_child(org)
		var randm_angle: float = randf() * 360.0
		org.global_position = Globals.world_origin + Globals.world_radius * Vector2(cos(randm_angle), sin(randm_angle))
		org.rotation = Globals.world_origin.angle_to_point(org.global_position)
		org.significant_chain_length = significant_chain_length
		org.travel_radius = travel_radius * 0.8 + rand_range(0, travel_radius * 0.2)
		org.world_origin = Globals.world_origin
		org.connect("significant_chain_detected_under_runner", self, "on_Organism_Chain_detected")

func create_new_organism(position: Vector2) -> void:
	var org = Organism.instance()
	add_child(org)
	
	org.global_position = position
	org.rotation = randf() * 360.0 * PI / 180.0
	org.significant_chain_length = significant_chain_length
	org.travel_radius = travel_radius * 0.8 + rand_range(0, travel_radius * 0.2)
	org.world_origin = Globals.world_origin
	
	org.connect("significant_chain_detected_under_runner", self, "on_Organism_Chain_detected")

func on_Organism_Chain_detected(parent_position: Vector2) -> void:
	create_new_organism(parent_position)
