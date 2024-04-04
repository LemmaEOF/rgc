@tool
extends EditorPlugin

var rgc_importer

func _enter_tree():
	# Initialization of the plugin goes here.
	rgc_importer = preload("res://addons/rgc/importer.gd")
	add_import_plugin(rgc_importer)


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_import_plugin(rgc_importer)
	rgc_importer = null
