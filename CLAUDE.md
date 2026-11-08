# ZoomPad

On-screen + and - buttons that zoom the camera, made for the Steam Deck touchscreen. One addon, one repository: `bizzal70/ZoomPad`. Built 2026-11-08 at the user's request after the controller research (`reports\WoW Forever controller addon ideas.md` in the user's CLAUDE folder); the user chose touchscreen buttons only (no key bindings, no auto zoom on mount).

## Workflow

- **No local `.git`.** GitHub holds all history. Publish with `tools\Publish.ps1 -Message "..."`, which uses a throwaway temp clone and runs the tests first.
- **Layout:** the addon's own files (`ZoomPad.toc`, `Core.lua`, `Pad.lua`, `Options.lua`) sit at the top of the project, because that is what the release packager expects. `tests/`, `tools/` and `.github/` are development-only and are left out of the released zip by `.pkgmeta`.
- **Testing in game:** `tools\Link-Addon.ps1` junctions this folder into the client's `Interface\AddOns` as `ZoomPad`. Edits are live after `/reload`; a new file or a TOC change needs a full client restart.
- **Client install:** `C:\Program Files (x86)\World of Warcraft\_forever_\` (`Wow.exe`, product `wowf`), the live client since launch (4 November 2026). The beta folder `_classic_beta_` was removed on 2026-11-02, and its saved data went with it.
- **Tests:** `python tests/run.py` runs the addon in real Lua 5.1 (the `lupa` pip package) against a fake WoW API in `tests/wow_stub.lua`, loading the files the TOC lists. The tests run before every publish and again on GitHub. They prove the addon's own logic only; whether the real client behaves like the stub can only be checked in game. `tests/wow_stub.lua` is a copy of the one in the GatherTrail project and is free to drift.
- **Releases:** a tag starting with `v` runs `.github/workflows/release.yml`, which uses the BigWigs packager. CurseForge and Wago uploads are skipped until their project IDs are in the TOC and their tokens are in the repository secrets. The packager recognises this client: a trial release on 2026-10-13 built `ZoomPad-vX.Y.Z-forever.zip` as game version 1.60.1, containing only the addon's files. The uploads to CurseForge and Wago themselves have not been tried.

## How it works

- `Core.lua`: settings, slash commands, `ns.Zoom(direction)` which calls `CameraZoomIn` / `CameraZoomOut` with the chosen step (1, 2 or 4 yards) inside `pcall`, and says once if the game refuses.
- `Pad.lua`: the two buttons. A zoom happens on mouse up for a tap (so a drag never zooms), and repeatedly while held (first repeat after `ns.HOLD_DELAY`, then every `ns.HOLD_EVERY`). Dragging moves the pad unless locked; the place is saved as `{point, relativePoint, x, y}`.
- `Options.lua`: the options window, in the shared plain-colour style.
- `MinimapButton.lua` (0.2.0, at the user's request): click toggles the pad (`ns.SetPadShown`), right-click opens the options, drag slides it round the rim (`minimapAngle`, default 3.6); the icon is desaturated while the pad is hidden.
- Forever's own controller zoom is LB+RB held with the right stick forward or back (Blizzard's gamepad article, 2026-11).
- Not yet verified in game: whether `CameraZoomIn`/`CameraZoomOut` are allowed for addons on Forever (the wiki shows no protection, 2026-11-08), whether they work in combat, and how Steam Deck touch reaches the game in Forever's gamepad mode.

## Client facts

Everything below, unless marked verified, comes from community sources during the beta (Warcraft Wiki, GitHub ports, fan guides), not from Blizzard docs. Builds change. Verify in game before relying on any of it.

- Local client was 1.60.1.70338 on 2026-10-11 (beta, `WowB.exe`); the live client is 1.60.1.70707 (2026-10-30, `_forever_\Wow.exe`). The TOC interface number for live is not yet confirmed; check `select(4, GetBuildInfo())` in game.
- TOC: `## Interface: 16001` (verified in game on build 70338).
- TOC flavor suffix is `_Forever.toc` or `_Camelot.toc`. The TOC `[Game]` variable expands to `Camelot`. Game type for `AllowLoadGameType` is `forever` / `camelot`.
- The client is Retail-based: Midnight 12.x API and UI architecture, not the Classic API. Port from Retail code.
- `WOW_PROJECT_ID` is `18` on build 70338 (verified in game 2026-10-11, along with interface 16001, by a starter addon since removed). Community guides written against earlier builds say it is 1 (`WOW_PROJECT_MAINLINE`); that is out of date, so Retail code gated on `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE` will not run here. The name of the constant for 18 is not yet known. Prefer testing for the specific API you need over branching on either number.
- Lua 5.1: no `goto`, no `//`, no bitwise operators (use `bit.band` etc.), no `require`. The TOC is the module loader. Start files with `local addonName, ns = ...`.
- Removed globals: `GetItemInfo`, `GetSpellInfo`, `UnitAura`/`UnitBuff`/`UnitDebuff`, `GetTalentInfo`, `GetNumTalentTabs`, `CombatLogGetCurrentEventInfo`, `InterfaceOptionsFrame_OpenToCategory`. Use `C_Item`, `C_Spell`, `C_UnitAuras`, `C_Traits`, and the `Settings` API.
- `C_Spell.GetSpellInfo` returns a table. Item and spell data can be nil until cached.
- Registering an event that does not exist throws and aborts the file. Wrap speculative `RegisterEvent` calls in `pcall`.
- Secret values (Midnight combat restrictions) are active. In combat, `UnitHealth`, aura data, and some names and booleans can be secret: arithmetic, comparison, and printing fail. Guard with `issecretvalue`, and pass values straight to widgets (`StatusBar:SetValue`, `Cooldown:SetCooldownFromDurationObject`) instead of doing Lua math. Combat-log parsing is not available.
- Check `InCombatLockdown()` before touching protected frames and defer to `PLAYER_REGEN_ENABLED`.
- SavedVariables: initialise in `ADDON_LOADED`. Early beta builds reportedly wrote them but did not read them back; on build 70338 they are read back (confirmed in game 2026-10-11).
