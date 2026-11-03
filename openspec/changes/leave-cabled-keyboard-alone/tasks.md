## 1. Implementation

- [x] 1.1 Watch Apple USB devices and recognise the selected keyboard by the product ID from its Bluetooth Device ID record
- [x] 1.2 Report a keyboard on a cable as connected here, notify ownership when the cable state changes, and never remove its pairing in claim or release
- [x] 1.3 Skip automatic and manual claims and releases while the keyboard is on a cable, settle an operation the cable interrupted, and apply selection changes without a release
- [x] 1.4 Show "Keyboard connected by cable" with no keyboard action

## 2. Verification

- [x] 2.1 Add checks: no claim or release on a cable across hub, manual, sleep and wake changes; a claim interrupted by the cable ends without error or retry; unplugging resumes claims; selection changes do not release; the menu line
- [x] 2.2 Install on this Mac, plug the keyboard into the dock, and confirm getkbd leaves the pairing and Touch ID in place; unplug and confirm normal hand-over (2026-11-03: no claim or release while on the cable; Touch ID registered 8.2-8.3 s after the keyboard appeared over USB, against 14-15 s over Bluetooth)
- [ ] 2.3 Install on the other Mac and confirm a real switch through the dock
