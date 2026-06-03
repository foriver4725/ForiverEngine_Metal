final class TrackedValue<T: Equatable> {
    private var value: T
    private var dirty: Bool = true

    init(_ initValue: T) {
        self.value = initValue
    }

    func setValue(_ newValue: T) {
        if value != newValue {
            dirty = true
            value = newValue
        }
    }

    func forceSetValue(_ newValue: T) {
        dirty = true
        value = newValue
    }

    func getValue() -> T {
        value
    }

    func dropDirty() -> Bool {
        if dirty {
            dirty = false
            return true
        }

        return false
    }
}
