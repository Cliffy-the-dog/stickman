extends Control

## Draws connector lines between skill nodes on a Control canvas (Node2D cannot live under Controls).

var _connections: Array[Dictionary] = []


# Clears cached connections and redraws the line layer.
func rebuild_all() -> void:
	_connections.clear()

	for node in get_tree().get_nodes_in_group("skill_nodes"):
		if not node.has_method("get_line_anchor"):
			continue
		if not ("child_nodes" in node):
			continue

		var start_pos: Vector2 = node.get_line_anchor()
		var parent_unlocked: bool = node.get("is_unlocked") or node.get("is_owned")

		for child_node in node.child_nodes:
			if child_node == null or not child_node.has_method("get_line_anchor"):
				continue
			var end_pos: Vector2 = child_node.get_line_anchor()
			_connections.append({
				"from": start_pos,
				"to": end_pos,
				"unlocked": parent_unlocked,
			})

	queue_redraw()


# Renders all skill-tree connector lines.
func _draw() -> void:
	for connection in _connections:
		var line_color := (
			Color(0.35, 0.85, 1.0, 0.9)
			if connection.unlocked
			else Color(0.45, 0.45, 0.45, 0.8)
		)
		draw_line(connection.from, connection.to, line_color, 12.0, true)
