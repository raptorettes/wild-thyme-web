# Launch Godot editor
dev:
    nohup godot project.godot &> /dev/null & disown

# Run opening scene
play:
    godot run --path . --scene levels/game_level.tscn

# Serve the preview files
serve:
    bunx vite /run/media/raptor/lump/game dev files/godot/game_runs
