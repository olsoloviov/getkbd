## Why

On 2026-11-03 the Magic Keyboard with Touch ID was plugged by cable into a dock on the Mac that the monitor was showing. A keyboard on a cable works over USB and its Bluetooth link is down, so getkbd saw it as not connected and started claiming it. The reconnect attempts failed, and after the third one getkbd removed the pairing and tried to pair again. A keyboard on a cable does not pair over Bluetooth (`IOReturn 4`), so it was left unpaired and Touch ID went away until the cable was unplugged.

## What Changes

- Recognise the selected keyboard when it is plugged into this Mac by cable: an Apple USB device with the product ID from the keyboard's Bluetooth Device ID record.
- While it is on a cable, treat it as connected here and do not claim it, release it, or change its pairing, whatever the monitor and hub signals say. Manual Get and Release do nothing.
- A claim in progress when the cable is plugged in stops before it removes the pairing, and ends without an error or a retry.
- The menu shows "Keyboard connected by cable" with no keyboard action, also when Bluetooth is off.
- Changing the keyboard selection does not release a keyboard that is on a cable.
- Unplugging the cable resumes normal hand-over.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `keyboard-handoff`: a keyboard connected by cable is left alone.

## Impact

- New `WiredKeyboardMonitor` watches Apple USB devices through IOKit notifications; no new permission is needed.
- `KeyboardControlling` gains `isConnectedByCable`, defaulting to false. `IOBluetoothKeyboardController` reads the product ID from the Bluetooth Device ID record and keeps it for when the record is gone.
- `OwnershipController` skips every claim and release while the keyboard is on a cable; `OwnershipSnapshot` and `MenuStatus` report it.
