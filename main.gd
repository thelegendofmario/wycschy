extends Node2D

var hit = 0
const port = 22526 
var peer = ENetMultiplayerPeer.new()
@export var PLAYER: PackedScene
@onready var multiplayer_ui = $UI/Multiplayer
@onready var end_ui = $UI/EndUI
var winning_score = 1
@export var scores: Array
#var players : Array[Player] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasModulate.color = Color(0.392, 0.392, 0.392)
	print(IP.get_local_addresses())
	$PlayerSpawner.spawn_function = add_player
	$UI/Multiplayer/HSplitContainer/VBoxContainer/IP.text = IP.get_local_addresses()[0]
	end_ui.hide()
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	for player in Global.players:
		Global.scores[Global.players.find(player)] = player.points
	scores = Global.scores
	if scores.has(winning_score):
		var idx = scores.find(winning_score)
		var winner = get_node(Global.playerNames[idx]).username
		print(Global.playerNames[idx])
		print(Global.players[idx].username)
		print(winner, " is the winner! scores for reference: ", Global.scores, " player list: ", Global.playerNames)
		end_ui.show()
		$UI/EndUI/VBoxContainer/WinnerLabel.text = str(winner+" is the winner!!")
		get_tree().paused = true
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
	Global.scores.append(player.points)
	print(Global.players)
	print(Global.scores)
	player.index = len(Global.scores)-1
	print(Global.scores[player.index])
	return player
