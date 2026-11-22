extends RefCounted
## Sincronizacao de slots e barra rapida.
## Chamado pelos wrappers em main.gd para preservar o comportamento do jogo.

static func sync_inventory_slots(inventory_slots: Array[int], stock: Array, reserve: Array, item_count: int) -> void:
	# Um slot de inventário guarda uma pilha de um tipo de item.
	# Tipos sem unidades são liberados; a ordem escolhida pelo jogador permanece.
	for index in range(inventory_slots.size()):
		var item: int = inventory_slots[index]
		if item>=0 and stock[item]<=0 and reserve[item]<=0:
			inventory_slots[index] = -1
	for item in range(item_count):
		if (stock[item]>0 or reserve[item]>0) and not inventory_slots.has(item):
			var free := inventory_slots.find(-1)
			if free>=0:
				inventory_slots[free] = item

static func sync_hotbar(bar_items: Array, stock: Array, item_count: int, hotbar_manual: bool) -> void:
	for i in range(bar_items.size()):
		var item: int = bar_items[i]
		if item>=0 and stock[item]<=0:
			bar_items[i] = -1
	if not hotbar_manual:
		for item in range(item_count):
			if stock[item]>0 and not bar_items.has(item):
				var slot := bar_items.find(-1)
				if slot>=0:
					bar_items[slot] = item
