## Context

`IOBluetoothKeyboardController` derives the keyboard state from Bluetooth alone. A Magic Keyboard on a cable keeps its Bluetooth pairing but has no Bluetooth connection, so getkbd reports it as disconnected. Every claim starts by removing the pairing (or, with a reconnect step, removes it after reconnecting fails), and pairing over Bluetooth fails while the cable is in. The trace on 2026-11-03 showed claims at 17:00:10, 17:00:19 and 17:00:39, the pairing removed at 17:01:00, pairing failing with `IOReturn 4` at 17:01:16, and Touch ID removed at 17:01:00.9.

## Decisions

- **Identify the cable by USB product ID.** On a cable the keyboard is an `IOUSBHostDevice` with Apple's USB vendor ID (0x05AC) and the product ID it reports over Bluetooth (0x029A for the Magic Keyboard with Touch ID). The Bluetooth address is not visible over USB. The product ID comes from the Device ID service record (0x1200, attribute 0x0202) that macOS keeps with the pairing, so it needs no connection. It is cached in memory, because the record goes with the pairing.
- **Watch USB through IOKit notifications**, as `USBHubMonitor` does, filtered to Apple's vendor ID. IOKit registry notifications need no Input Monitoring permission, unlike an `IOHIDManager`.
- **Report the keyboard as `connectedLocal` while it is on a cable**, with `isConnectedByCable` alongside. A change of the cable state alone notifies ownership.
- **Ownership does nothing while the keyboard is on a cable.** `reconcile` returns early, clearing failures and pending automatic attempts; `beginOperation`, manual Get and manual Release are refused. An operation that finishes after the cable appeared is settled without an error or a retry.
- **Guard inside the controller too.** `connect()` checks for the cable at its start and again just before removing the pairing, and the controller cancels a claim that is waiting to pair when the cable appears. `disconnect()` refuses with a readable error.
- **Selection changes apply without a release** while the keyboard is on a cable, since there is nothing getkbd can release.

## Risks / Trade-offs

- Two keyboards of the same model, one on a cable and one selected over Bluetooth, would be confused. getkbd selects one keyboard and the product ID is model-wide; the serial number over USB does not match the Bluetooth address, so there is nothing better to compare.
- The product ID is unknown if getkbd starts while the keyboard is on a cable and this Mac has no pairing record for it. macOS pairs the keyboard over the cable when it is plugged in, which creates the record, so this resolves itself.
- With the cable in, the other Mac's getkbd may still try to claim the keyboard over Bluetooth and fail. That does no harm here and is the same as when the keyboard is out of range.
