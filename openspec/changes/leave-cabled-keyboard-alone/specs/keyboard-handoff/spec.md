## ADDED Requirements

### Requirement: Leave a keyboard connected by cable alone

The system SHALL recognise the selected keyboard when it is plugged into this Mac
by cable and SHALL treat it as connected to this Mac. While it is on a cable,
getkbd SHALL NOT claim it, release it, or change its Bluetooth pairing.

#### Scenario: Keyboard is plugged in by cable

- **WHEN** an Apple USB device with the selected keyboard's product ID is
  attached to this Mac
- **THEN** getkbd SHALL report the keyboard as connected by cable and SHALL NOT
  start a claim or a release, whatever the monitor, hub, sleep, or manual signals

#### Scenario: Cable is plugged in during a claim

- **WHEN** the keyboard is plugged in by cable while a claim is in progress
- **THEN** getkbd SHALL stop the claim before it removes the pairing and SHALL
  end it without an error or an automatic retry

#### Scenario: Cable is unplugged

- **WHEN** the keyboard is unplugged from its cable
- **THEN** getkbd SHALL resume claiming and releasing it from the current local
  signals

#### Scenario: Keyboard selection changes while on a cable

- **WHEN** the selected keyboard is changed while the previous one is on a cable
- **THEN** getkbd SHALL apply the new selection without releasing the previous
  keyboard

#### Scenario: Menu while on a cable

- **WHEN** the keyboard is connected by cable
- **THEN** the menu SHALL show "Keyboard connected by cable" and SHALL offer no
  keyboard action, also when Bluetooth is off
