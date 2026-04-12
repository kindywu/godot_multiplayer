## World.gd v4 — 彻底放弃 MultiplayerSpawner，改用手动 RPC spawn
##
## MultiplayerSpawner 在 Godot 4.2 有很多坑（spawn_path、authority、时序）
## 最可靠的方案：服务端直接 RPC 通知所有客户端，客户端自己实例化节点。
##
## 流程：
##   客户端就绪 → rpc 通知服务端
##   服务端 spawn 本地节点 + rpc 通知所有客户端也 spawn
##   客户端收到 → 实例化节点 + 设置属性

extends Node2D

@onready var players_node : Node2D = $Players

const PlayerScene := preload("res://scenes/Player.tscn")

var _peer_players : Dictionary = {}
var _player_count : int        = 0


func _ready() -> void:
	print("[World] _ready  is_server=%s  my_id=%d" % [
		GameManager.is_server(), multiplayer.get_unique_id()
	])

	if GameManager.is_server():
		GameManager.player_disconnected.connect(_on_peer_disconnected)
	else:
		await get_tree().process_frame
		print("[World] Client sending ready signal to server")
		_client_ready.rpc_id(1)


## ── 客户端 → 服务端：我准备好了 ────────────────────────────────────────────
@rpc("any_peer", "reliable", "call_remote")
func _client_ready() -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	print("[World] Server: peer %d is ready, spawning" % peer_id)
	_do_spawn(peer_id)


## ── 服务端执行 spawn ──────────────────────────────────────────────────────
func _do_spawn(peer_id: int) -> void:
	if _peer_players.has(peer_id):
		return

	var color  := _hue_color(_player_count)
	_player_count += 1
	var cx     := color.r
	var cy     := color.g
	var cz     := color.b

	# 服务端本地 spawn
	_spawn_local(peer_id, cx, cy, cz)

	# 通知所有客户端也 spawn 这个玩家
	_remote_spawn.rpc(peer_id, cx, cy, cz)

	# 同时把所有已有玩家告诉新客户端
	for existing_id in _peer_players:
		var ep : CharacterBody2D = _peer_players[existing_id]
		var ec : Color = ep.player_color
		_remote_spawn.rpc_id(peer_id, existing_id, ec.r, ec.g, ec.b)


## ── 服务端 → 所有客户端：请 spawn 这个玩家 ──────────────────────────────
@rpc("authority", "reliable", "call_remote")
func _remote_spawn(peer_id: int, r: float, g: float, b: float) -> void:
	print("[World] Client received spawn for peer %d" % peer_id)
	_spawn_local(peer_id, r, g, b)


## ── 本地实例化玩家节点（服务端和客户端都用） ──────────────────────────────
func _spawn_local(peer_id: int, r: float, g: float, b: float) -> void:
	if players_node.has_node("P%d" % peer_id):
		return

	var player : CharacterBody2D = PlayerScene.instantiate()
	player.name          = "P%d" % peer_id
	player.owner_peer_id = peer_id
	player.player_color  = Color(r, g, b)
	player.position      = Vector2.ZERO

	players_node.add_child(player)
	player._refresh_visuals()

	_peer_players[peer_id] = player
	print("[World] _spawn_local P%d  color=(%s,%s,%s)" % [peer_id, r, g, b])


## ── 服务端 → 所有客户端：删除玩家 ──────────────────────────────────────────
@rpc("authority", "reliable", "call_remote")
func _remote_despawn(peer_id: int) -> void:
	_despawn_local(peer_id)

func _despawn_local(peer_id: int) -> void:
	if _peer_players.has(peer_id):
		_peer_players[peer_id].queue_free()
		_peer_players.erase(peer_id)
		print("[World] Despawned P%d" % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
	_despawn_local(peer_id)
	_remote_despawn.rpc(peer_id)


## ── 颜色 ────────────────────────────────────────────────────────────────────
func _hue_color(index: int) -> Color:
	return Color.from_hsv(fmod(index * 137.508, 360.0) / 360.0, 0.8, 0.9)
