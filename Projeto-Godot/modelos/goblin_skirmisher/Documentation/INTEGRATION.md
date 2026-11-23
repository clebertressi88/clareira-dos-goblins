# Goblin Skirmisher integration notes

110 distinct provider stock motions with exact action IDs and loadouts in animation-catalog.json. Alternate formats do not add to the count. Native skeleton tracks retain authored Hips travel; some clips move and others stay in place. Root motion extraction, looping, transitions and character control are your game's responsibility.

The living goblin is approximately 1.35 m tall in rest pose. Body: 8,323 triangles. Separate dagger: 1,527 triangles, approximately 0.43 m long, rigidly attached to RightHand in the included equipped previews. Fitted vest and trousers deform with the body. The WeaponGrip morph closes the right hand around the dagger in equipped previews; unequipped previews retain the open hand. Set WeaponGrip to 1 (Godot/Unreal) or 100 (Unity) when equipping your character. There are no individual finger bones or facial animations. The dagger uses nine designated stock combat/guard loadouts; the remaining motions use empty hands by default. The socket configuration is provided with Source.

Vault, ladder, stair and climb motions require matching environment geometry. Falls, rolls and stand-up clips need ground-contact and transition adjustment for your game. Some motions include stylized extremes. Preview repeat is a control, not a seamless-loop guarantee. Stock catalog names are retained; sword motions are demonstrated using the supplied dagger. Gesture names do not imply articulated finger or face animation.

No gameplay AI, ragdoll, controller or engine-to-engine retargeter is included. Textures use base color with ordinary rough lit materials. Native previews were tested on Godot 4.7.2, Unity 6000.6.2f1 and Unreal 5.8 on macOS; other versions/platforms need validation. Unreal uses the included custom skeleton, not the Epic mannequin skeleton.

The dungeon, publisher branding, music and trailer effects are presentation material and are not included as game assets. Reference images were AI-generated. AI services generated the model, textures, rig and stock motion retargeting, followed by local conversion and QA. Reimporting source files requires choosing their location on your own computer.
