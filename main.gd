extends Node2D

var hit = 0
const port = 22526 
var peer = ENetMultiplayerPeer.new()
@export var PLAYER: PackedScene
@onready var multiplayer_ui = $UI/Multiplayer
#var players : Array[Player] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasModulate.color = Color(0.392, 0.392, 0.392)
	print(IP.get_local_addresses())
	$PlayerSpawner.spawn_function = add_player

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	pass

func _on_host_pressed() -> void:
	peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(
		func(pid):
			#print("peer " + str(pid))
			$PlayerSpawner.spawn(pid)
	)
	
	$PlayerSpawner.spawn(multiplayer.get_unique_id())
	multiplayer_ui.hide()

func _on_join_pressed() -> void:
	peer.create_client($UI/Multiplayer/HSplitContainer/VBoxContainer/LineEdit.text, port)
	multiplayer.multiplayer_peer = peer
	multiplayer_ui.hide()
	
func add_player(id):
	var player: Player = PLAYER.instantiate()
	player.name = str(id)
	player.global_position = $Level.get_child(Global.players.size()).global_position
	var aName = $UI/Multiplayer/HSplitContainer/VBoxContainer/LineEdit2.text
	player.username = aName
	
	Global.players.append(player)
	Global.playerNames.append(player.name)
	Global.usernames.append(aName)
	return player
