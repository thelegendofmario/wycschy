extends Area2D
class_name Bullet
var speed: int = 2000
var damage =1
var owner_index
@export var playerOwned: String

func _process(delta: float) -> void:
	position += transform.x * speed * delta



func _on_body_entered(body: Node2D) -> void:
	if !is_multiplayer_authority():
		return
	
	if body is Player:
		print("hit player!!")
		if body.health <= 1:
			print(owner_index, " just killed player of index ", body.index)
			Global.players[owner_index].points += 1
			#print(owner_index, "'s score is now ", Global.scores[owner_index])
		else:
			print(body.health)
		body.take_damage.rpc_id(body.get_multiplayer_authority(), 1)

	
	print("body entered")
	remove.rpc()

@rpc("call_local")
func remove():
	queue_free()

#func _on_area_entered(area: Area2D) -> void:
	#if !is_multiplayer_authority():
		#print("!!")
		#return
	#
	#if area.is_in_group("PlayerCollision"):
		#print("take damage :D")
		#area.get_parent().take_damage(damage)
		#queue_free()
	#
	#
	#if !area.is_in_group("mouse"):
		#print(area.get_groups())
		#queue_free()
