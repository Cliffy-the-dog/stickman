class_name WaveData
extends Resource

@export_group("Wave Content")
## Add enemy entries here. Each entry has a monster scene and its spawn count.
@export var enemies: Array[WaveEnemy] = []
## Delay (in seconds) between spawning each enemy in this wave
@export var spawn_delay: float = 0.5
