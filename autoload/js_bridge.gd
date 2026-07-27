
extends Node

func _ready():
	if OS.has_feature("web"):
		# Notify the shell that the main scene is rendered and ready
		JavaScriptBridge.eval("""
            if (window._shell && window._shell.onGodotReady) {
                window._shell.onGodotReady();
            }
		""")
