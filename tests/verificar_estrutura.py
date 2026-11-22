"""Validacoes estaticas: execute python3 tests/verificar_estrutura.py na raiz."""
from pathlib import Path
import re

root = Path(__file__).resolve().parents[1]
project = root / 'Projeto-Godot'
main = (project / 'main.gd').read_text(encoding='utf-8')
modules = {
    'terreno': ['ground', 'make_rock'],
    'materiais': ['character_texture', 'material'],
    'visual': ['mesh_part', 'collider'],
    'inventario': ['sync_inventory_slots', 'sync_hotbar'],
    'interface': ['hotbar_style'],
    'receitas': ['expand_basic_pattern', 'matches_basic_recipe', 'matches_recipe'],
    'construcao': ['find_wall_snap', 'wall_intersects_other_wall'],
    'salvamento': ['serialize_backpack'],
}

for name, functions in modules.items():
    path = project / 'sistemas' / (name + '.gd')
    assert path.is_file(), f'Modulo ausente: {path}'
    script = path.read_text(encoding='utf-8')
    assert 'extends RefCounted' in script, f'Modulo invalido: {name}'
    assert f'res://sistemas/{name}.gd' in main, f'Preload ausente: {name}'
    for method in functions:
        assert re.search(r'^static func ' + method + r'\(', script, re.M), (name, method)
        assert re.search(r'^func ' + method + r'\(', main, re.M), f'Wrapper ausente: {method}'

assert 'const HOTBAR_SIZE := 9' in main
assert 'KEY_E and (moving or inventory)' in main
assert 'user://clareira-nativa.json' in main
assert 'var cylinder_mesh_cache: Dictionary = {}' in main
assert 'var next_hud_refresh := 0.0' in main
assert 'distance_squared > 28.0 * 28.0' in main

for file in ['project.godot','main.tscn','main.gd']:
    assert (project / file).is_file(), file
print('OK: 8 sistemas, wrappers, caminho do save e controles preservados')
