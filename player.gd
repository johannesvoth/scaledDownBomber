extends CharacterBody2D

const MOTION_SPEED = 90.0
const BOMB_RATE = 0.5

@export
var stunned = false

@onready
var last_bomb_time = BOMB_RATE

func _ready():
	stunned = false
	if str(name).is_valid_int():
		set_multiplayer_authority(str(name).to_int())


func _physics_process(delta):
	
	if !is_multiplayer_authority():
		return
	
	var m = Vector2()
	if Input.is_action_pressed("move_left"):
		m += Vector2(-1, 0)
	if Input.is_action_pressed("move_right"):
		m += Vector2(1, 0)
	if Input.is_action_pressed("move_up"):
		m += Vector2(0, -1)
	if Input.is_action_pressed("move_down"):
		m += Vector2(0, 1)

	var motion = m
	var bombing = Input.is_action_pressed("set_bomb")
	# And increase the bomb cooldown spawning one if the client wants to.
	last_bomb_time += delta
	if not stunned and bombing and last_bomb_time >= BOMB_RATE:
		last_bomb_time = 0.0
		get_node("../../BombSpawner").spawn([position, str(name).to_int()])


	if not stunned:
		velocity = motion * MOTION_SPEED
		move_and_slide()

	# Also update the animation based on the last known player input state


func set_player_name(value):
	get_node("label").text = value


@rpc("call_local")
func exploded(_by_who):
	if stunned:
		return
	stunned = true
	get_node("anim").play("stunned")
