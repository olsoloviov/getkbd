import Foundation
@preconcurrency import IOKit

/// Tracks Apple USB devices so that a keyboard plugged in by cable can be recognised.
///
/// A Magic Keyboard on a cable is a USB device with Apple's USB vendor ID and the same product
/// ID it reports over Bluetooth. While it is on the cable its Bluetooth link is down, so the
/// Bluetooth state alone would make it look absent.
@MainActor
final class WiredKeyboardMonitor {
    static let appleUSBVendorID = 0x05AC

    var onChange: (() -> Void)?

    private struct DeviceEvent: Sendable {
        let registryID: UInt64
        let productID: Int?
        let isRemoval: Bool
    }

    private var attachedProductIDs: [UInt64: Int] = [:]
    private var notificationPort: IONotificationPortRef?
    private var notificationSource: CFRunLoopSource?
    private var matchingIterator: io_iterator_t = 0
    private var terminatedIterator: io_iterator_t = 0
    private var isStarted = false

    func isAttached(productID: Int) -> Bool {
        attachedProductIDs.values.contains(productID)
    }

    func start() {
        guard !isStarted else { return }
        guard let notificationPort = IONotificationPortCreate(kIOMainPortDefault) else {
            GetKbdLog.error("keyboard.cable.monitor.failed", "Unable to create an IOKit notification port")
            return
        }
        guard let notificationSource = IONotificationPortGetRunLoopSource(notificationPort)?.takeUnretainedValue() else {
            IONotificationPortDestroy(notificationPort)
            GetKbdLog.error("keyboard.cable.monitor.failed", "Unable to create an IOKit run-loop source")
            return
        }

        self.notificationPort = notificationPort
        self.notificationSource = notificationSource
        CFRunLoopAddSource(CFRunLoopGetMain(), notificationSource, CFRunLoopMode.defaultMode)

        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        guard IOServiceAddMatchingNotification(
            notificationPort,
            kIOFirstMatchNotification,
            Self.appleDeviceMatching(),
            Self.deviceMatched,
            context,
            &matchingIterator
        ) == kIOReturnSuccess else {
            stop()
            GetKbdLog.error("keyboard.cable.monitor.failed", "Unable to register USB arrival notification")
            return
        }
        Self.events(from: matchingIterator, isRemoval: false).forEach { handle($0) }

        guard IOServiceAddMatchingNotification(
            notificationPort,
            kIOTerminatedNotification,
            Self.appleDeviceMatching(),
            Self.deviceRemoved,
            context,
            &terminatedIterator
        ) == kIOReturnSuccess else {
            stop()
            GetKbdLog.error("keyboard.cable.monitor.failed", "Unable to register USB removal notification")
            return
        }
        Self.events(from: terminatedIterator, isRemoval: true).forEach { handle($0) }
        isStarted = true
    }

    func stop() {
        if matchingIterator != 0 {
            IOObjectRelease(matchingIterator)
            matchingIterator = 0
        }
        if terminatedIterator != 0 {
            IOObjectRelease(terminatedIterator)
            terminatedIterator = 0
        }
        if let notificationSource, let notificationPort {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), notificationSource, CFRunLoopMode.defaultMode)
            IONotificationPortDestroy(notificationPort)
        }
        notificationSource = nil
        notificationPort = nil
        attachedProductIDs.removeAll()
        isStarted = false
    }

    private func handle(_ event: DeviceEvent) {
        if event.isRemoval {
            guard attachedProductIDs.removeValue(forKey: event.registryID) != nil else { return }
        } else if let productID = event.productID {
            attachedProductIDs[event.registryID] = productID
        } else {
            return
        }
        guard isStarted else { return }
        onChange?()
    }

    private static func appleDeviceMatching() -> CFMutableDictionary {
        // A bare idVendor key matches nothing for IOUSBHostDevice; it has to be a property match.
        let matching = IOServiceMatching("IOUSBHostDevice") as NSMutableDictionary
        matching[kIOPropertyMatchKey] = ["idVendor": appleUSBVendorID]
        return matching
    }

    private static let deviceMatched: IOServiceMatchingCallback = { context, iterator in
        guard let context else { return }
        let monitor = Unmanaged<WiredKeyboardMonitor>.fromOpaque(context).takeUnretainedValue()
        let events = events(from: iterator, isRemoval: false)
        Task { @MainActor [weak monitor] in
            events.forEach { monitor?.handle($0) }
        }
    }

    private static let deviceRemoved: IOServiceMatchingCallback = { context, iterator in
        guard let context else { return }
        let monitor = Unmanaged<WiredKeyboardMonitor>.fromOpaque(context).takeUnretainedValue()
        let events = events(from: iterator, isRemoval: true)
        Task { @MainActor [weak monitor] in
            events.forEach { monitor?.handle($0) }
        }
    }

    private static func events(from iterator: io_iterator_t, isRemoval: Bool) -> [DeviceEvent] {
        var events: [DeviceEvent] = []
        while case let service = IOIteratorNext(iterator), service != 0 {
            defer { IOObjectRelease(service) }
            var registryID: UInt64 = 0
            guard IORegistryEntryGetRegistryEntryID(service, &registryID) == kIOReturnSuccess else { continue }
            let productID = isRemoval ? nil : (IORegistryEntryCreateCFProperty(
                service, "idProduct" as CFString, kCFAllocatorDefault, 0
            )?.takeRetainedValue() as? NSNumber)?.intValue
            events.append(DeviceEvent(registryID: registryID, productID: productID, isRemoval: isRemoval))
        }
        return events
    }
}
