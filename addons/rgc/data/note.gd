class_name Note
extends RefCounted # TODO: make a Resource for editor loading?

var type: NoteType
var beat: float
var args: Array # arbitrary types/length, be careful!

func _init(type: NoteType, beat: float, args: Array):
	self.type = type
	self.beat = beat
	self.args = args
