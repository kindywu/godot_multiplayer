## Main.gd
extends Control

@onready var status_label  : Label    = $Panel/VBox/StatusLabel
@onready var address_input : LineEdit = $Panel/VBox/AddressInput

const WorldScene := preload("res://scenes/World.tscn")


func _ready() -> void:
	$Panel/VBox/ServerButton.pressed.connect(_on_server_pressed)
	$Panel/VBox/ClientButton.pressed.connect(_on_client_pressed)

	# Command-line: godot -- server   or   godot -- client 1.2.3.4
	var args := OS.get_cmdline_user_args()
	if args.size() >= 1:
		await get_tree().process_frame
		if args[0] == "server":
			_launch_server()
		elif args[0] == "client":
			_launch_client(args[1] if args.size() >= 2 else "127.0.0.1")


func _on_server_pressed() -> void:
	_launch_server()

func _on_client_pressed() -> void:
	_launch_client(address_input.text.strip_edges())


func _launch_server() -> void:
	status_label.text = "Starting server…"
	if GameManager.start_server() == OK:
		get_tree().change_scene_to_packed(WorldScene)

func _launch_client(address: String) -> void:
	if address.is_empty():
		address = "127.0.0.1"
	status_label.text = "Connecting to %s…" % address
	if GameManager.start_client(address) == OK:
		await get_tree().create_timer(0.5).timeout
		get_tree().change_scene_to_packed(WorldScene)
