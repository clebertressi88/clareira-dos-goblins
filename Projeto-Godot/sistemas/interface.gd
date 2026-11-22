extends RefCounted
## Estilos visuais reutilizaveis da interface.
## Chamado pelos wrappers em main.gd para preservar o comportamento do jogo.

static func hotbar_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(7)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.shadow_color = Color("#80000000")
	style.shadow_size = 3
	return style
