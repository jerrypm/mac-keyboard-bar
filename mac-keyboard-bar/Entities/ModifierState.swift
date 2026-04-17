import CoreGraphics

struct ModifierState: Equatable {

    // MARK: - Keys

    enum Key {
        case shift, command, option, control, fn
    }

    // MARK: - Properties

    var shift = false
    var command = false
    var option = false
    var control = false
    var fn = false

    // MARK: - Mutations

    mutating func toggle(_ key: Key) {
        switch key {
        case .shift: shift.toggle()
        case .command: command.toggle()
        case .option: option.toggle()
        case .control: control.toggle()
        case .fn: fn.toggle()
        }
    }

    mutating func clearOneShot() {
        shift = false
        command = false
        option = false
        control = false
        fn = false
    }

    // MARK: - CGEvent Flags

    var cgEventFlags: CGEventFlags {
        var flags: CGEventFlags = []
        if shift   { flags.insert(.maskShift) }
        if command { flags.insert(.maskCommand) }
        if option  { flags.insert(.maskAlternate) }
        if control { flags.insert(.maskControl) }
        if fn      { flags.insert(.maskSecondaryFn) }
        return flags
    }
}
