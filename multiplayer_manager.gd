extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of November 2020:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 10567

# Max number of players.
const MAX_PEERS = 12

var peer = null

# Name for my player.
var player_name = "The Warrior"

@onready var players_spawn: Node = $"../PlayersSpawn"

# Names for remote players in id:name format.
var players = {}
var players_ready = []

var lobby_id := -1

# Signals to let lobby GUI know what's going on.
signal player_list_changed()
signal connection_failed()
signal connection_succeeded()
signal game_ended()
signal game_error(what)


func _process(delta):
	Steam.run_callbacks()

func _ready():
	Steam.steamInit(480)
	multiplayer.peer_connected.connect(self._player_connected)
	multiplayer.peer_disconnected.connect(self._player_disconnected)
	multiplayer.connected_to_server.connect(self._connected_ok)
	multiplayer.connection_failed.connect(self._connected_fail)
	multiplayer.server_disconnected.connect(self._server_disconnected)
	Steam.lobby_joined.connect(_on_lobby_joined.bind())
	Steam.lobby_created.connect(_on_lobby_created.bind())


func host_game():
	print("host game")
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, MAX_PEERS)

func _on_lobby_created(_connect: int, _lobby_id: int):
	print("_on_lobby_created")
	if _connect == 1:
		lobby_id = _lobby_id
		Steam.setLobbyData(_lobby_id, "name", "test_server")
		
		peer = SteamMultiplayerPeer.new()
		peer.create_host(0)
		multiplayer.set_multiplayer_peer(peer)
		
		add_player(1)
		
		print("Create lobby id:",str(lobby_id))
	else:
		print("Error on create lobby!")

func join_game(lobby_id, new_player_name):
	player_name = new_player_name
	Steam.joinLobby(int(lobby_id))

func _on_lobby_joined(lobby: int, permissions: int, locked: bool, response: int):
	if response == 1:
		var id = Steam.getLobbyOwner(lobby)
		if id != Steam.getSteamID():
			peer = SteamMultiplayerPeer.new()
			peer.create_client(id, 0)
			multiplayer.set_multiplayer_peer(peer)
			
			add_player(peer.get_unique_id())


func add_player(p_id):
	var player_scene = load("res://player.tscn")

	var host_player = player_scene.instantiate()
	host_player.name = str(p_id)
	host_player.set_multiplayer_authority(p_id)
	players_spawn.add_child(host_player)






# Callback from SceneTree.
func _player_connected(id):
	# Registration of a client beings here, tell the connected player that we are here.
	register_player.rpc_id(id, player_name)


# Callback from SceneTree.
func _player_disconnected(id):
	if has_node("/root/World"): # Game is in progress.
		if multiplayer.is_server():
			game_error.emit("Player " + players[id] + " disconnected")
			end_game()
	else: # Game is not in progress.
		# Unregister this player.
		unregister_player(id)

# Callback from SceneTree, only for clients (not server).
func _connected_ok():
	# We just connected to a server
	connection_succeeded.emit()

# Callback from SceneTree, only for clients (not server).
func _server_disconnected():
	game_error.emit("Server disconnected")
	end_game()

# Callback from SceneTree, only for clients (not server).
func _connected_fail():
	multiplayer.set_network_peer(null) # Remove peer
	connection_failed.emit()

# Lobby management functions.
@rpc("any_peer")
func register_player(new_player_name):
	var id = multiplayer.get_remote_sender_id()
	players[id] = new_player_name
	player_list_changed.emit()

func unregister_player(id):
	players.erase(id)
	player_list_changed.emit()

@rpc("call_local")
func load_world(): # I would have to check the hotjoin replication with that stuff
	# Change scene.
	var world = load("res://world.tscn").instantiate()
	get_tree().get_root().add_child(world)
	get_tree().get_root().get_node("Lobby").hide()

	get_tree().set_pause(false) # Unpause and unleash the game!



func begin_game():
	assert(multiplayer.is_server())
	load_world.rpc()

	var world = get_tree().get_root().get_node("World")
	var player_scene = load("res://player.tscn")

	var host_player = player_scene.instantiate()
	host_player.name = str(1)
	host_player.set_multiplayer_authority(1)
	world.get_node("Players").add_child(host_player)
	
	for p_id in players:
		var player = player_scene.instantiate()
		player.name = str(p_id)
		player.set_multiplayer_authority(p_id)
		player.set_player_name(player_name if p_id == multiplayer.get_unique_id() else players[p_id])
		world.get_node("Players").add_child(player)


func end_game():
	if has_node("/root/World"): # Game is in progress.
		# End it
		get_node("/root/World").queue_free()

	game_ended.emit()
	players.clear()
