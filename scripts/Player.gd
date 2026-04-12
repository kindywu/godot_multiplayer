## Player.gd v4
##
## 不再依赖 MultiplayerSynchronizer。
## 位置同步改为：服务端每帧广播位置给所有客户端。
##
## Node tree:
##   Player (CharacterBody2D)
##   ├─ ColorRect   (40×40 方块)
##   └─ Label       (显示 peer_id)

extends CharacterBody2D

@export var player_color  : Color = Color.WHITE
@export var owner_peer_id : int   = 0

@onready var color_rect : ColorRect = $ColorRect
@onready var label      : Label     = $Label

# 客户端用：平滑插值目标位置
var _target_pos : Vector2 = Vector2.ZERO


func _ready() -> void:
	_target_pos = position
	print("[Player] _ready  owner=%d  is_server=%s" % [owner_peer_id, GameManager.is_server()])


func _physics_process(delta: float) -> void:
	if GameManager.is_server():
		# 服务端：处理本玩家输入已在 RPC 中完成，这里只负责广播位置
		_sync_position.rpc(position.x, position.y)
	else:
		# 客户端：平滑插值到服务端广播的位置
		position = position.lerp(_target_pos, 15.0 * delta)

		# 本地玩家：采集输入发给服务端
		if multiplayer.get_unique_id() == owner_peer_id:
			var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
			if dir != Vector2.ZERO:
				_send_input.rpc_id(1, dir.normalized().x, dir.normalized().y)


## 客户端 → 服务端：发送输入方向
@rpc("any_peer", "unreliable_ordered", "call_remote")
func _send_input(dx: float, dy: float) -> void:
	if multiplayer.get_remote_sender_id() != owner_peer_id:
		return
	position += Vector2(dx, dy) * GameManager.MOVE_SPEED * get_physics_process_delta_time()


## 服务端 → 所有客户端：广播位置
@rpc("authority", "unreliable_ordered", "call_remote")
func _sync_position(x: float, y: float) -> void:
	_target_pos = Vector2(x, y)


## 由 World 在 spawn 后调用，刷新颜色和标签
func _refresh_visuals() -> void:
	if color_rect:
		color_rect.color = player_color
	if label:
		label.text = "P%d" % owner_peer_id
