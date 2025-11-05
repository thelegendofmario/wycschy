class_name Player
extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var auth_player
@export var maxDist: float = 239.5
var listofpoints = []
var visibilityIndicator: Label = Label.new()
var playerIndicator: Label = Label.new()
var invisible: bool = false
var can_teleport: bool = true

func _enter_tree() -> void:
	setup()
	$PlayerCamera/HUD/VBoxContainer.add_child(visibilityIndicator)
	
	$PlayerCamera/HUD/VBoxContainer/ProgressBar.max_value = $TeleportCooldown.wait_time

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		$Sprite.modulate = Color.RED
		return
		
	else:
		calc_visibility()
	
	var a: TileMapLayer = get_parent().get_node("Level")
	
	var aSet: TileSet = a.tile_set
	aSet.phys
	
	$PlayerCamera/HUD/VBoxContainer/ProgressBar.value = $TeleportCooldown.time_left
	# Handle jump.
	var direction_vert := Input.get_axis("up", "down")
	if direction_vert:
		velocity.y = direction_vert * SPEED
	else:
		velocity.y = move_toward(velocity.y, 0, SPEED)
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
	if invisible && Input.is_action_just_pressed("teleport") && $TeleportCooldown.is_stopped()&& can_teleport:
		position = get_global_mouse_position()
		invisible = false
		$TeleportCooldown.start()
	move_and_slide()


# at the beginning of the visibility section, grab the authority player.
# then, loop over every player (except for the authority player), and set each of their visibilty to the raycat to the autority player
func calc_visibility() -> void:
	var players_list: Array = Global.players.duplicate()
	players_list.erase(self)
	players_list.erase(auth_player)
	#print(w, h)
	var seen_by: int = 0
	for i: Player in players_list:
		var m_tl = self.get_node("TLeft").global_position
		var m_tr = self.get_node("TRight").global_position
		var m_bl = self.get_node("BLeft").global_position
		var m_br = self.get_node("BRight").global_position
		

		var tl = i.get_node("TLeft").global_position
		var tR = i.get_node("TRight").global_position
		var bl = i.get_node("BLeft").global_position
		var br = i.get_node("BRight").global_position
		#print("b",tl, tr, bl, br)
		
		var querys: Array[PhysicsRayQueryParameters2D] = [
			PhysicsRayQueryParameters2D.create(tl, m_tl, collision_mask),
			PhysicsRayQueryParameters2D.create(tR, m_tr, collision_mask),
			PhysicsRayQueryParameters2D.create(bl, m_bl, collision_mask),
			PhysicsRayQueryParameters2D.create(br, m_br, collision_mask),
		]
		
		var hits = 0
		for query in querys:
			var space_state = get_world_2d().direct_space_state
			var exclude = []
			for x in range(Global.players.size()): # looping through the player list and getting bounding box corners for them
				exclude.append(Global.players[x])
				exclude.append(Global.players[x].get_node("TLeft")) 
				exclude.append(Global.players[x].get_node("TRight")) 
				exclude.append(Global.players[x].get_node("BLeft"))
				exclude.append(Global.players[x].get_node("BRight"))
			query.exclude = exclude
			var result = space_state.intersect_ray(query)
			if result:
				hits +=1
		
		var dist = position.distance_to(i.position)
		
		if hits>=3 or dist>maxDist:
			i.hide()
			seen_by -= 1
			#print("hiding...")

		else:
			i.show()
			seen_by += 1
			#print(dist)

	if seen_by == -len(players_list):
		visibilityIndicator.text = "invisible..."
		invisible = true
	else:
		visibilityIndicator.text = "visible by one or more nodes!!"
		invisible = false


func get_my_player():
	for player in Global.players:
		print("line 94 (player): ", player)
		print("line 95 (player.is_multiplayer_authority()): " ,player.is_multiplayer_authority())
		if player.name == str(get_multiplayer_authority()):
			return player
		 
func setup():
	set_multiplayer_authority(int(str(name)))
	auth_player = get_my_player()
	print("line 13 (auth_player, int(str(name))): ", auth_player, " ", int(str(name)))
	if !is_multiplayer_authority():
		$PointLight2D.queue_free()
