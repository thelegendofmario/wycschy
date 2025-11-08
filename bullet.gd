extends Area2D
class_name Bullet
var speed: int = 2000
var damage =1

func _process(delta: float) -> void:
	position += transform.x * speed * delta



func _on_body_entered(body: Node2D) -> void:
	if !is_multiplayer_authority():
		return
	
	if body.is_in_group("PlayerCollision"):
		print("hit player!!")
	
	print("body enterd")
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
