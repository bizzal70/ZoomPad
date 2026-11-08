# ZoomPad

Big **+** and **-** buttons on screen that zoom the camera in and out. Made for playing World of Warcraft: Forever (client 1.60.x) on a Steam Deck: tap them on the touchscreen. They work with a mouse too.

## What it does

Forever's controller mode zooms only while you hold both bumpers and push the right stick, which is awkward on a handheld. ZoomPad puts two buttons on the right edge of the screen, under your right thumb:

- **Tap** + to zoom in one step, or - to zoom out one step.
- **Hold** either one to keep zooming until you lift your finger.
- **Drag** either button to move the pair somewhere else. Lock them once they are where you want them, so a drag can never move them by accident.

## Options

Click the spyglass button on the minimap to hide or show the zoom buttons; right-click it for the options. You can also type `/zoompad`, or use the addon's entry in the minimap's addon list.

| Setting | Command |
|---|---|
| Show or hide the zoom buttons | `/zoompad show`, `hide`, `toggle` |
| Lock them in place | `/zoompad lock` |
| Show or hide the minimap button | `/zoompad button` |
| Button size: small, medium or large | in the options |
| How far each tap zooms: small, medium or large | in the options |
| Put the buttons back where they started | `/zoompad reset` |
| Zoom one step (for a macro or key binding) | `/zoompad in`, `/zoompad out` |

## Good to know

- On a Steam Deck, the touchscreen acts as a mouse, so a tap is a click. If Steam Input is set to a layout that turns touches into something else, switch the touchscreen back to "Mouse" (or "Direct touch") for ZoomPad's buttons to respond.
- The game's Max Camera Distance setting still decides how far out the camera can go.

## More from this author

Other small addons for World of Warcraft: Forever, all free:

- **[MouseTip](https://www.curseforge.com/wow/addons/mousetip)** shows tooltips at your mouse cursor.
- **[GatherLog](https://github.com/bizzal70/GatherLog)** remembers ore, herbs, fishing pools, skinning spots, chests and rares across all your characters, and guides you back to the best spots.
- **[RangeShade](https://www.curseforge.com/wow/addons/rangeshade)** shades action buttons red when your target is out of range.
- **[JunkMate](https://github.com/bizzal70/JunkMate)** sells junk and repairs at vendors, and warns when your gear is wearing out.
- **[AltBoard](https://github.com/bizzal70/AltBoard)** shows all your characters at a glance: level, gold, rested and where you left them.
- **[SwiftQuest](https://github.com/bizzal70/SwiftQuest)** accepts quests and hands them in as soon as you talk to the quest giver, without ever choosing a reward for you.
- **[SessionRecap](https://github.com/bizzal70/SessionRecap)** keeps a running tally of your play session: gold, experience per hour, quests, gathering and loot.
- **[MacroKit](https://github.com/bizzal70/MacroKit)** adds ready-made macros for your class and spec, for all nine classes, and never overwrites your own.

## Installing

Copy this folder into `World of Warcraft\_forever_\Interface\AddOns\` as `ZoomPad`, restart the game, and enable ZoomPad on the character select screen.

## Developing

- `tools\Link-Addon.ps1` links this folder into the game's AddOns folder, so edits are live after `/reload`.
- `python tests/run.py` runs the tests (`pip install lupa` once). They run the addon in real Lua 5.1 against a fake of the game's API.
- `tools\Publish.ps1 -Message "..."` runs the tests and pushes to GitHub. GitHub runs the tests again on every push.

## Releasing

`tools\Publish.ps1 -Message "Release x.y.z" -Tag vx.y.z` publishes and tags. The tag makes GitHub package the addon, attach the zip to a GitHub release and, once the CurseForge project ID is in `ZoomPad.toc` and a `CF_API_KEY` or `CF_KEY` secret is in this repository, upload it to CurseForge.

Before each release: raise `## Version:` in `ZoomPad.toc` and add the version to `CHANGELOG.md`.

## Licence

MIT. See `LICENSE`.
