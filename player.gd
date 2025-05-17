class_name Player
extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var auth_player
var listofpoints = []

func _enter_tree() -> void:
	set_multiplayer_authority(int(str(name)))
	auth_player = get_my_player()
	print("line 13 (auth_player, int(str(name))): ", auth_player, " ", int(str(name)))

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		$Sprite.modulate = Color.RED
		if !has_visibility():
			hide()
		else:
			show()
	if not is_on_floor():
		velocity += get_gravity() * delta

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
	move_and_slide()


# at the beginning of the visibility section, grab the authority player.
# then, loop over every player (except for the authority player), and set each of their visibilty to the raycat to the autority player

func has_visibility():
	var players_list = Global.players.duplicate()
	players_list.erase(self)
	players_list.erase(auth_player)
	#print(w, h)
	for i in players_list:
		var m_tl = auth_player.get_node("TLeft").global_position
		var m_tr = auth_player.get_node("TRight").global_position
		var m_bl = auth_player.get_node("BLeft").global_position
		var m_br = auth_player.get_node("BRight").global_position
		#print("a", m_tl, m_tr, m_bl, m_br)

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
			
		if hits:
			#print(false, auth_player, self)
			return false
		else:
			#print(true, auth_player, self)
			return true
			
func get_my_player():
	for player in Global.players:
		print("line 94 (player): ", player)
		print("line 95 (player.is_multiplayer_authority()): " ,player.is_multiplayer_authority())
		if player.name == str(get_multiplayer_authority()):
			#print("line 97 (true)")
			return player
		
