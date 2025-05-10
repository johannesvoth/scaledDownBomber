extends MultiplayerSpawner
@onready var player_spawner: MultiplayerSpawner = $"."
@onready var players_spawn: Node = $"../PlayersSpawn"

func _ready() -> void:
	player_spawner.spawn_function = spawn_player

func spawn_player(p_id):
	var player_scene = load("res://player.tscn")

	var host_player = player_scene.instantiate()
	host_player.name = str(p_id)
	
	players_spawn.add_child(host_player)
