class_name NoteType
extends RefCounted

static var _types: Dictionary = {} #[String, NoteType]

func get_minimum_arguments() -> int:
	return 0

# TODO: pass info in?
# this is for stuff like BPM change notes or such
# to actually control the game
func on_note_activated() -> void:
	pass

# TODO: will this do what I want? Only one way to find out...
signal register_note_types

static func register(name: String, type: NoteType) -> NoteType:
	if name in _types:
		printerr("Type named '{}' already registered", name)
		return _types[name]
	_types[name] = type
	return type

static func getType(name: String) -> NoteType:
	return _types[name] as NoteType
