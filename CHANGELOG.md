# ZoomPad

## 0.3.2

- The zoom buttons and the minimap button now appear once you actually use a controller (a button or a stick), not merely when one is connected: some PCs report controllers that are not being used. They then stay until you log out, so tapping the screen does not hide them.

## 0.3.1

- The minimap button also goes away while no controller is connected, like the zoom buttons. `/zoompad` still opens the options.

## 0.3.0

- The zoom buttons now only appear while a controller is connected (a Steam Deck's own controls count), and go away when you play with mouse and keyboard. The minimap button's icon is grey while they are away. Turn this off in the options, or with `/zoompad always`.

## 0.2.3

- Fixed: the minimap button drew no icon or border (wrong texture paths), so it sat invisibly on top of other buttons. It now shows its spyglass icon, and is put back at its starting place below-left of the minimap once.

## 0.2.2

- Fixed: the minimap button could keep following the mouse after a drag, and then move together with another addon's button sitting on top of it. It now stops the moment you let go.

## 0.2.1

- The minimap button now starts below and to the left of the minimap, instead of sitting on top of other addons' buttons. If you had not moved it yet, it moves there by itself. You can still drag it anywhere round the rim.

## 0.2.0

- A minimap button: click it to hide or show the zoom buttons, right-click for the options, drag it round the minimap. Its icon turns grey while the zoom buttons are hidden. `/zoompad button` or the options hide the minimap button itself.

## 0.1.0

- First version: + and - buttons on screen that zoom the camera, for the Steam Deck's touchscreen. Tap for one step, hold to keep zooming, drag to move, lock in place. Button size and zoom per tap can be set in the options (`/zoompad`).
