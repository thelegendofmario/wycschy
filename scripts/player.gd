extends CharacterBody2D

class_name Player

@export var maxDist: float = 239.5
var bulletScene: PackedScene = preload("res://scenes/bullet.tscn")
var maxHealth: float = 10
@export var health: float = maxHealth
#var damage: int = 1
const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var auth_player
var listofpoints = []
var playerIndicator: Label = Label.new()
var invisible: bool = false
var can_teleport: bool = true
@export var username: String
@export var points: int
var index
signal killed


func _enter_tree() -> void:
	setup()
	get_exclusions()
	
	$PlayerCamera/HUD/Control/WarningLabel.hide()
	$PlayerCamera/HUD/Control/Control/ScoreContainer.hide()
	
	$PlayerCamera/HUD/Control/VBoxContainer/ProgressBar.max_value = $TeleportCooldown.wait_time
	$ProgressBar.max_value = maxHealth
	$UsernameLabel.text = username

func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority():
		$Sprite.modulate = Color.RED
		return
		
	calc_visibility()
	
	$ProgressBar.value = health
	
	$Gun.look_at(get_global_mouse_position())
	if get_global_mouse_position().x < position.x:
		$Gun/Sprite2D.flip_v = true
	else:
		$Gun/Sprite2D.flip_v = false
	
	var a: TileMapLayer = get_parent().get_node("Level")
	
	var aSet: TileSet = a.tile_set
	#aSet.phys
	
	$PlayerCamera/HUD/Control/VBoxContainer/ProgressBar.value = $TeleportCooldown.time_left
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
	
	if Input.is_action_just_pressed("shoot"):
		shoot.rpc(multiplayer.get_unique_id())
	
	if !invisible:
		$PlayerCamera/HUD/Control/WarningLabel.show()
	else:
		$PlayerCamera/HUD/Control/WarningLabel.hide()
	
	if invisible && Input.is_action_just_pressed("teleport") && $TeleportCooldown.is_stopped()&& can_teleport:
		position = get_global_mouse_position()
		invisible = false
		$TeleportCooldown.start()
		
	if Input.is_action_just_pressed("seeScores"):
		print(name)
		print(Global.scores)
		compute_scores()
		$PlayerCamera/HUD/Control/Control/ScoreContainer.show()
	if Input.is_action_just_released("seeScores"):
		$PlayerCamera/HUD/Control/Control/ScoreContainer.hide()
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
		invisible = true
	else:
		invisible = false

@rpc("call_local")
func shoot(shooter_pid):
	var bullet: Bullet = bulletScene.instantiate()
	bullet.set_multiplayer_authority(shooter_pid)
	bullet.transform = $Gun/Sprite2D/Muzzle.global_transform
	bullet.owner_index = get_parent().get_node(str(shooter_pid)).index
	print(bullet.owner_index)
	get_parent().add_child(bullet)
	

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

@rpc("any_peer")
func take_damage(amnt: int):
	health -= amnt
	print("I was hit by a bullet!")
	if health <= 0:
		respawn()

func respawn():
	global_position = get_parent().get_node("Level").get_child(randi_range(0, Global.players.size()-1)).global_position
	killed.emit(index)
	
	health = maxHealth

func get_exclusions():
	var exc: Area2D = get_parent().get_node("Exclude")
	exc.mouse_entered.connect(mouse_entered_exc)
	var good: Area2D = get_parent().get_node("MouseArea")
	good.mouse_entered.connect(mouse_entered_good)

#func make_score_display():
	#for i in Global.players:
		#var a: Label = Label.new()
		#a.text = "placeholder"
		#$PlayerCamera/HUD/Control/Control/ScoreContainer.add_child(a)

func compute_scores():
	var scoresLabels: Array[Label] = []
	var scores: Array[Array] = []
	for i: Label in $PlayerCamera/HUD/Control/Control/ScoreContainer.get_children():
		i.queue_free()
	for i in Global.players:
		var scr = str(Global.scores[i.index])
		scores.append([i.username, scr])
	
	scores.sort_custom(
		func(a, b):
			return a[1]>b[1]
	)
	
	for i in scores:
		var lbl: Label = Label.new()
		var st = ""
		if i[0] == username:
			lbl.add_theme_color_override("font_color", Color.RED)
		if i[1] == str(get_parent().winning_score-1):
			lbl.add_theme_font_size_override("font_size", 20)
			st = "!!"
		lbl.text = st+" "+i[0]+": "+i[1]+" "+st
		$PlayerCamera/HUD/Control/Control/ScoreContainer.add_child(lbl)

func mouse_entered_exc() -> void:
	print("mouse entered")
	can_teleport = false

func mouse_entered_good() -> void:
	print("mouse exited")
	can_teleport = true
