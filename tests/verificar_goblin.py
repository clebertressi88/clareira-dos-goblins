"""Verificacao do GLB integrado aos goblins (executado no GitHub Actions)."""
from pathlib import Path
import json
import struct

root = Path(__file__).resolve().parents[1]
asset = root / "Projeto-Godot/modelos/goblins/goblin.glb"
assert asset.is_file(), f"Arquivo 3D ausente: {asset}"
data = asset.read_bytes()
magic, version, length = struct.unpack_from("<4sII", data, 0)
assert magic == b"glTF" and version == 2 and length == len(data)
json_length, chunk_type = struct.unpack_from("<II", data, 12)
assert chunk_type == 0x4E4F534A
gltf = json.loads(data[20:20 + json_length])
assert gltf.get("meshes"), "GLB sem malhas"
assert gltf.get("images"), "GLB sem texturas"
main = (root / "Projeto-Godot/main.gd").read_text(encoding="utf-8")
script = (root / "Projeto-Godot/personagens/goblin_visual.gd").read_text(encoding="utf-8")
assert "GoblinModelo.anexar(o)" in main
assert "not protagonist and GoblinModelo.anexar(o)" in main
assert "GoblinModelo.animar(model, velocity, dt, grounded)" in main
assert "res://modelos/goblins/goblin.glb" in script
print("OK: GLB valido, texturizado e integrado somente aos NPCs goblins")
