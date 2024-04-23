class_name NoteType
extends RefCounted # TODO: make a Resource for editor loading?

static var _types: Dictionary = {} #[String, NoteType]

func get_minimum_arguments() -> int: # abstract
	return 0

# TODO: pass info in?
# this is for stuff like BPM change notes or such
# to actually control the game
func on_note_activated() -> void: # abstract
	pass

# TODO: will this do what I want? Only one way to find out...
signal register_note_types

static func register(name: String, type: NoteType) -> NoteType:
	if name in _types:
		printerr("Type named '{}' already registered", name)
		return _types[name]
	_types[name] = type
	return type

static func get_type(name: String) -> NoteType:
	return _types[name] as NoteType
