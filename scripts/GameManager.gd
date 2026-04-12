## GameManager.gd — Autoload singleton
extends Node

const PORT        : int   = 5000
const MAX_CLIENTS : int   = 8
const MOVE_SPEED  : float = 300.0

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)

enum Mode { NONE, SERVER, CLIENT }
var mode : Mode = Mode.NONE


func start_server() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_CLIENTS)
	if err != OK:
		push_error("Failed to start server: " + error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.SERVER
	multiplayer.peer_connected.connect(func(id): player_connected.emit(id))
	multiplayer.peer_disconnected.connect(func(id): player_disconnected.emit(id))
	print("[Server] Listening on port %d" % PORT)
	return OK


func start_client(address: String = "127.0.0.1") -> Error:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, PORT)
	if err != OK:
		push_error("Failed to start client: " + error_string(err))
		return err
	multiplayer.multiplayer_peer = peer
	mode = Mode.CLIENT
	multiplayer.connected_to_server.connect(func(): print("[Client] Connected! id=%d" % multiplayer.get_unique_id()))
	multiplayer.connection_failed.connect(func(): push_error("[Client] Connection failed!"))
	print("[Client] Connecting to %s:%d" % [address, PORT])
	return OK


func is_server() -> bool:
	return mode == Mode.SERVER

func is_client() -> bool:
	return mode == Mode.CLIENT
