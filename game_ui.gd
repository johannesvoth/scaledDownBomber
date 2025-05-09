extends Control

@onready var multiplayer_manager: Node = $"../MultiplayerManager"


func _ready():
	multiplayer_manager.connection_succeeded.connect(self._on_connection_success)

func _on_host_pressed():
	$Connect.hide()
	multiplayer_manager.host_game()

func _on_join_pressed():
	var ip = $Connect/IPAddress.text
	var player_name = $Connect/Name.text
	multiplayer_manager.join_game(ip, player_name)

func _on_connection_success():
	$Connect.hide()
	$Players.show()
