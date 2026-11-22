extends RefCounted
## Serializacao da mochila (formato preservado).
## Chamado pelos wrappers em main.gd para preservar o comportamento do jogo.

static func serialize_backpack(backpack_slots: Array[Vector2i]) -> Array:
	var data := []
	for slot in backpack_slots:
		data.append([slot.x,slot.y])
	return data
