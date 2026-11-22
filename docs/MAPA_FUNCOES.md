# Mapa das funcoes do Clareira dos Goblins

Este indice indica **a funcao exata e o numero da linha** na branch de reorganizacao. Links abrem o codigo no GitHub.

Os utilitarios mais reutilizados ja estao em [`Projeto-Godot/sistemas/`](../Projeto-Godot/sistemas/). O arquivo `main.gd` permanece como coordenador. Para sistemas e fluxos, veja [ARQUITETURA.md](ARQUITETURA.md).

## Inicializacao e recursos

- [`_ready()`](../Projeto-Godot/main.gd#L127) — linha 127
- [`character_texture()`](../Projeto-Godot/main.gd#L143) — linha 143
- [`material()`](../Projeto-Godot/main.gd#L146) — linha 146
- [`setup_world()`](../Projeto-Godot/main.gd#L149) — linha 149
- [`make_rock()`](../Projeto-Godot/main.gd#L189) — linha 189
- [`mesh_part()`](../Projeto-Godot/main.gd#L192) — linha 192
- [`ball()`](../Projeto-Godot/main.gd#L195) — linha 195
- [`box()`](../Projeto-Godot/main.gd#L198) — linha 198
- [`cylinder()`](../Projeto-Godot/main.gd#L201) — linha 201
- [`collider()`](../Projeto-Godot/main.gd#L214) — linha 214

## Jogador e terreno

- [`make_player()`](../Projeto-Godot/main.gd#L217) — linha 217
- [`make_stone_axe_head()`](../Projeto-Godot/main.gd#L288) — linha 288
- [`ground()`](../Projeto-Godot/main.gd#L295) — linha 295
- [`load_chunks()`](../Projeto-Godot/main.gd#L298) — linha 298
- [`create_chunk()`](../Projeto-Godot/main.gd#L313) — linha 313

## Goblins amigaveis e patrulha

- [`village()`](../Projeto-Godot/main.gd#L348) — linha 348
- [`spawn_friendly_goblin()`](../Projeto-Godot/main.gd#L360) — linha 360
- [`get_campfire_center()`](../Projeto-Godot/main.gd#L383) — linha 383
- [`choose_goblin_destination()`](../Projeto-Godot/main.gd#L395) — linha 395
- [`update_villagers()`](../Projeto-Godot/main.gd#L430) — linha 430
- [`speak_to_goblin()`](../Projeto-Godot/main.gd#L488) — linha 488

## Objetos e estruturas

- [`spawn_object()`](../Projeto-Godot/main.gd#L514) — linha 514
- [`build_wood_wall()`](../Projeto-Godot/main.gd#L631) — linha 631
- [`make_vine()`](../Projeto-Godot/main.gd#L666) — linha 666

## Modelagem dos personagens

- [`goblin_head()`](../Projeto-Godot/main.gd#L673) — linha 673
- [`goblin_ear()`](../Projeto-Godot/main.gd#L702) — linha 702
- [`sculpt_part()`](../Projeto-Godot/main.gd#L731) — linha 731
- [`limb_pivot()`](../Projeto-Godot/main.gd#L736) — linha 736
- [`move_parts_to_limb()`](../Projeto-Godot/main.gd#L742) — linha 742
- [`walk_pose()`](../Projeto-Godot/main.gd#L749) — linha 749
- [`goblin()`](../Projeto-Godot/main.gd#L777) — linha 777
- [`protagonist_details()`](../Projeto-Godot/main.gd#L880) — linha 880
- [`creature()`](../Projeto-Godot/main.gd#L895) — linha 895
- [`wolf_face()`](../Projeto-Godot/main.gd#L918) — linha 918
- [`wolf_armor()`](../Projeto-Godot/main.gd#L929) — linha 929
- [`animal_model()`](../Projeto-Godot/main.gd#L943) — linha 943
- [`impact()`](../Projeto-Godot/main.gd#L1016) — linha 1016
- [`stagger()`](../Projeto-Godot/main.gd#L1032) — linha 1032
- [`timber()`](../Projeto-Godot/main.gd#L1046) — linha 1046

## Interface e hotbar

- [`make_ui()`](../Projeto-Godot/main.gd#L1071) — linha 1071
- [`hotbar_style()`](../Projeto-Godot/main.gd#L1158) — linha 1158
- [`make_meter()`](../Projeto-Godot/main.gd#L1161) — linha 1161
- [`sync_inventory_slots()`](../Projeto-Godot/main.gd#L1180) — linha 1180
- [`item_received()`](../Projeto-Godot/main.gd#L1183) — linha 1183
- [`sync_hotbar()`](../Projeto-Godot/main.gd#L1193) — linha 1193
- [`update_player_hud()`](../Projeto-Godot/main.gd#L1196) — linha 1196
- [`sprint_step()`](../Projeto-Godot/main.gd#L1214) — linha 1214
- [`clear_menu()`](../Projeto-Godot/main.gd#L1228) — linha 1228
- [`center_panel()`](../Projeto-Godot/main.gd#L1234) — linha 1234
- [`label()`](../Projeto-Godot/main.gd#L1243) — linha 1243
- [`button()`](../Projeto-Godot/main.gd#L1248) — linha 1248
- [`show_menu()`](../Projeto-Godot/main.gd#L1256) — linha 1256
- [`begin()`](../Projeto-Godot/main.gd#L1284) — linha 1284
- [`open_craft()`](../Projeto-Godot/main.gd#L1290) — linha 1290

## Inventario e criacao

- [`show_inventory()`](../Projeto-Godot/main.gd#L1298) — linha 1298
- [`assign_hotbar()`](../Projeto-Godot/main.gd#L1456) — linha 1456
- [`inventory_drag()`](../Projeto-Godot/main.gd#L1469) — linha 1469
- [`can_drop_inventory()`](../Projeto-Godot/main.gd#L1480) — linha 1480
- [`drop_inventory()`](../Projeto-Godot/main.gd#L1487) — linha 1487
- [`hotbar_drag()`](../Projeto-Godot/main.gd#L1510) — linha 1510
- [`can_drop_hotbar()`](../Projeto-Godot/main.gd#L1521) — linha 1521
- [`drop_hotbar()`](../Projeto-Godot/main.gd#L1528) — linha 1528
- [`craft_drag()`](../Projeto-Godot/main.gd#L1547) — linha 1547
- [`can_drop_craft()`](../Projeto-Godot/main.gd#L1557) — linha 1557
- [`drop_craft()`](../Projeto-Godot/main.gd#L1563) — linha 1563
- [`can_return_craft()`](../Projeto-Godot/main.gd#L1576) — linha 1576
- [`return_craft()`](../Projeto-Godot/main.gd#L1579) — linha 1579
- [`remove_craft_units()`](../Projeto-Godot/main.gd#L1584) — linha 1584
- [`inventory_storage_input()`](../Projeto-Godot/main.gd#L1588) — linha 1588

## Receitas e crafting

- [`craft_status()`](../Projeto-Godot/main.gd#L1597) — linha 1597
- [`craft_relief()`](../Projeto-Godot/main.gd#L1616) — linha 1616
- [`style_craft_button()`](../Projeto-Godot/main.gd#L1624) — linha 1624
- [`craft_available()`](../Projeto-Godot/main.gd#L1631) — linha 1631
- [`select_craft_material()`](../Projeto-Godot/main.gd#L1638) — linha 1638
- [`clear_craft()`](../Projeto-Godot/main.gd#L1646) — linha 1646
- [`craft_cell_input()`](../Projeto-Godot/main.gd#L1651) — linha 1651
- [`fill_craft_cell()`](../Projeto-Godot/main.gd#L1660) — linha 1660
- [`prepare_recipe()`](../Projeto-Godot/main.gd#L1672) — linha 1672
- [`expand_basic_pattern()`](../Projeto-Godot/main.gd#L1693) — linha 1693
- [`matches_basic_recipe()`](../Projeto-Godot/main.gd#L1696) — linha 1696
- [`basic_recipe()`](../Projeto-Godot/main.gd#L1699) — linha 1699
- [`matches_recipe()`](../Projeto-Godot/main.gd#L1729) — linha 1729
- [`craft_basic()`](../Projeto-Godot/main.gd#L1732) — linha 1732

## Mochila e edificacoes

- [`serialize_backpack()`](../Projeto-Godot/main.gd#L1764) — linha 1764
- [`open_backpack()`](../Projeto-Godot/main.gd#L1767) — linha 1767
- [`show_backpack()`](../Projeto-Godot/main.gd#L1781) — linha 1781
- [`backpack_select_item()`](../Projeto-Godot/main.gd#L1829) — linha 1829
- [`backpack_slot_clicked()`](../Projeto-Godot/main.gd#L1833) — linha 1833
- [`backpack_slot_input()`](../Projeto-Godot/main.gd#L1852) — linha 1852
- [`withdraw_from_backpack()`](../Projeto-Godot/main.gd#L1860) — linha 1860
- [`unequip_backpack()`](../Projeto-Godot/main.gd#L1869) — linha 1869
- [`find_wall_snap()`](../Projeto-Godot/main.gd#L1881) — linha 1881
- [`wall_intersects_other_wall()`](../Projeto-Godot/main.gd#L1884) — linha 1884
- [`place_craft()`](../Projeto-Godot/main.gd#L1887) — linha 1887
- [`toggle_stock()`](../Projeto-Godot/main.gd#L1918) — linha 1918

## Controles e ciclo do jogo

- [`_unhandled_input()`](../Projeto-Godot/main.gd#L1929) — linha 1929
- [`_physics_process()`](../Projeto-Godot/main.gd#L1968) — linha 1968
- [`update_crouch()`](../Projeto-Godot/main.gd#L2043) — linha 2043

## Animais e IA

- [`update_wolf_spawns()`](../Projeto-Godot/main.gd#L2060) — linha 2060
- [`update_mobs()`](../Projeto-Godot/main.gd#L2090) — linha 2090
- [`update_rabbit()`](../Projeto-Godot/main.gd#L2126) — linha 2126
- [`respawn()`](../Projeto-Godot/main.gd#L2157) — linha 2157
- [`toggle_view()`](../Projeto-Godot/main.gd#L2166) — linha 2166
- [`update_camera()`](../Projeto-Godot/main.gd#L2172) — linha 2172

## Interacoes e combate

- [`ray()`](../Projeto-Godot/main.gd#L2189) — linha 2189
- [`primary()`](../Projeto-Godot/main.gd#L2206) — linha 2206
- [`secondary()`](../Projeto-Godot/main.gd#L2310) — linha 2310
- [`any_bench_placed()`](../Projeto-Godot/main.gd#L2344) — linha 2344
- [`drop_selected()`](../Projeto-Godot/main.gd#L2350) — linha 2350
- [`eat()`](../Projeto-Godot/main.gd#L2370) — linha 2370
- [`bench_near()`](../Projeto-Godot/main.gd#L2376) — linha 2376
- [`build_hut()`](../Projeto-Godot/main.gd#L2384) — linha 2384
- [`store_object()`](../Projeto-Godot/main.gd#L2400) — linha 2400
- [`remove_object()`](../Projeto-Godot/main.gd#L2405) — linha 2405
- [`notice()`](../Projeto-Godot/main.gd#L2416) — linha 2416

## Persistencia e salvamento

- [`load_game()`](../Projeto-Godot/main.gd#L2420) — linha 2420
- [`save_game()`](../Projeto-Godot/main.gd#L2461) — linha 2461
- [`_notification()`](../Projeto-Godot/main.gd#L2474) — linha 2474

## Rede local multiplayer

- [`host_game()`](../Projeto-Godot/main.gd#L2478) — linha 2478
- [`join_game()`](../Projeto-Godot/main.gd#L2489) — linha 2489
- [`send_position()`](../Projeto-Godot/main.gd#L2506) — linha 2506
- [`remove_remote()`](../Projeto-Godot/main.gd#L2525) — linha 2525
- [`disconnect_game()`](../Projeto-Godot/main.gd#L2530) — linha 2530
- [`disconnected()`](../Projeto-Godot/main.gd#L2537) — linha 2537

