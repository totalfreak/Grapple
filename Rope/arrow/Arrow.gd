extends RigidBody2D

var hasBeenShot = false

const MAX_STRETCH = 1.20
const START_STRETCH = 0.5
var arrowScale = 0.5

onready var stretchTimer = Timer.new()

var sprite

func _ready():
	#set_scale(Vector2(START_STRETCH, 1.0))
	sprite = get_node("Sprite")
	set_fixed_process(true)


func _fixed_process(delta):
	self.set_scale(Vector2(self.arrowScale, 1))
	var direction = get_linear_velocity()
	var bodies = get_colliding_bodies()
	if hasBeenShot:
		self.arrowScale = 1.0
	if bodies.size() == 0 and hasBeenShot:
		var arrow_rot = get_angle_to(direction+self.get_global_pos()) + self.get_rot()+30
		self.set_rot(arrow_rot)

