class_name Chart
extends Resource

var charter: String
var offset: float
var rating: float
var notes: Array[Note]

func _init(charter: String, offset: float, rating: float, notes: Array[Note]):
	self.charter = charter
	self.offset = offset
	self.rating = rating
	self.notes = notes
