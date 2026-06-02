extension Lattice3 {
    static let zero = Lattice3(0, 0, 0)
    static let one = Lattice3(1, 1, 1)
    static let right = Lattice3(1, 0, 0)
    static let left = Lattice3(-1, 0, 0)
    static let up = Lattice3(0, 1, 0)
    static let down = Lattice3(0, -1, 0)
    static let forward = Lattice3(0, 0, 1)
    static let backward = Lattice3(0, 0, -1)
}
