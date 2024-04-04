@tool
extends EditorImportPlugin

func _get_importer_name():
	return "rgc.chart"
	
func _get_visible_name():
	return "Chart"

func _get_recognized_extensions():
	return ["rgc"]
	
func _get_resource_type():
	return "Chart"
