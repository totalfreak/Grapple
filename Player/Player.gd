extends KinematicBody2D

var SHOOT_SPEED = 100
const MAX_SHOOT_SPEED = 500
var arrow = preload("res://Rope/arrow/Arrow.tscn")


var hasShot = false
var isHoldingShoot = false



onready var shootTimer = Timer.new()
var new_arrow

# Angle in degrees towards either side that the player can consider "floor"
const FLOOR_ANGLE_TOLERANCE = 40
const WALK_FORCE = 1000
const WALK_MIN_SPEED = 100
const WALK_MAX_SPEED = 150
const STOP_FORCE = 1300
const JUMP_SPEED = 200
const JUMP_MAX_AIRBORNE_TIME = 0.2
const GRAVITY = 300.0

const SLIDE_STOP_VELOCITY = 1.0 # One pixel per second
const SLIDE_STOP_MIN_TRAVEL = 1.0 # One pixel

var velocity = Vector2()
var on_air_time = 100
var jumping = false

var prev_jump_pressed = false
var health = 10


func _ready():
	set_fixed_process(true)
	set_process_input(true)
	
	shootTimer.connect("timeout",self,"shootTimeOut")
	add_child(shootTimer)
	shootTimer.start()


func _fixed_process(delta):
	
	var force = Vector2(0, GRAVITY)
	
	var stop = true
	
	var walk_left = Input.is_action_pressed("move_left")
	var walk_right = Input.is_action_pressed("move_right")
	var jump = Input.is_action_pressed("move_jump")
	
	if (walk_left):
		if (velocity.x <= WALK_MIN_SPEED and velocity.x > -WALK_MAX_SPEED):
			force.x -= WALK_FORCE
			stop = false
	elif (walk_right):
		if (velocity.x >= -WALK_MIN_SPEED and velocity.x < WALK_MAX_SPEED):
			force.x += WALK_FORCE
			stop = false
	
	if (stop):
		var vsign = sign(velocity.x)
		var vlen = abs(velocity.x)
		
		vlen -= STOP_FORCE*delta
		if (vlen < 0):
			vlen = 0
		
		velocity.x = vlen*vsign
	
	# Integrate forces to velocity
	velocity += force*delta
	
	# Integrate velocity into motion and move
	var motion = velocity*delta
	
	# Move and consume motion
	motion = move(motion)
	
	var floor_velocity = Vector2()
	
	if (is_colliding()):
		# You can check which tile was collision against with this
		# print(get_collider_metadata())
		
		# Ran against something, is it the floor? Get normal
		var n = get_collision_normal()
		
		if (rad2deg(acos(n.dot(Vector2(0, -1)))) < FLOOR_ANGLE_TOLERANCE):
			# If angle to the "up" vectors is < angle tolerance
			# char is on floor
			on_air_time = 0
			floor_velocity = get_collider_velocity()
		
		if (on_air_time == 0 and force.x == 0 and get_travel().length() < SLIDE_STOP_MIN_TRAVEL and abs(velocity.x) < SLIDE_STOP_VELOCITY and get_collider_velocity() == Vector2()):
			# Since this formula will always slide the character around, 
			# a special case must be considered to to stop it from moving 
			# if standing on an inclined floor. Conditions are:
			# 1) Standing on floor (on_air_time == 0)
			# 2) Did not move more than one pixel (get_travel().length() < SLIDE_STOP_MIN_TRAVEL)
			# 3) Not moving horizontally (abs(velocity.x) < SLIDE_STOP_VELOCITY)
			# 4) Collider is not moving
			
			revert_motion()
			velocity.y = 0.0
		else:
			# For every other case of motion, our motion was interrupted.
			# Try to complete the motion by "sliding" by the normal
			motion = n.slide(motion)
			velocity = n.slide(velocity)
			# Then move again
			move(motion)
	
	if (floor_velocity != Vector2()):
		# If floor moves, move with floor
		move(floor_velocity*delta)
	
	if (jumping and velocity.y > 0):
		# If falling, no longer jumping
		jumping = false
	
	if (on_air_time < JUMP_MAX_AIRBORNE_TIME and jump and not prev_jump_pressed and not jumping):
		# Jump must also be allowed to happen if the character left the floor a little bit ago.
		# Makes controls more snappy.
		velocity.y = -JUMP_SPEED
		jumping = true
	
	on_air_time += delta
	prev_jump_pressed = jump

	#Shooting stuff here
	if isHoldingShoot and !hasShot:
		var arrow_rot = get_angle_to(get_global_mouse_pos()) + self.get_rot()+80
		new_arrow.set_rot(arrow_rot)
		new_arrow.set_global_pos(self.get_global_pos())
		if SHOOT_SPEED < MAX_SHOOT_SPEED:
			SHOOT_SPEED += 5
			new_arrow.arrowScale += .5*delta

func _input(event):
	if event.is_action_pressed("shoot") and !isHoldingShoot and !hasShot:
		new_arrow = arrow.instance()
		get_parent().add_child(new_arrow)
		isHoldingShoot = true
	elif event.is_action_released("shoot") and isHoldingShoot and !hasShot:
		shoot()
	if event.is_action_released("shoot_cancel") and isHoldingShoot:
		isHoldingShoot = false
		new_arrow.queue_free()

func shoot():
	hasShot = true
	var rigidbody_vector = (get_global_mouse_pos() - self.get_pos()).normalized()
	new_arrow.set_linear_velocity(rigidbody_vector * SHOOT_SPEED)
	new_arrow.hasBeenShot = true
	shootTimer.set_wait_time( 0.5 )
	shootTimer.start()
	isHoldingShoot = false
	SHOOT_SPEED = 100

func shootTimeOut():
	hasShot = false


func damage(dmg):
	health-=dmg
	if health <= 0:
		die()

func die():
	#self.queue_free()
	pass