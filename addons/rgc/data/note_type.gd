class_name NoteType
extends RefCounted

static var _types: Dictionary = {} #[String, NoteType]

# todo: pass info in?
# this is for stuff like BPM change notes or such
# to actually control the game
func on_note_activated():
	pass

static func register(name: String, type: NoteType) -> NoteType:
	_types[name] = type
	return type

static func getType(name: String) -> NoteType:
	return _types[name] as NoteType
