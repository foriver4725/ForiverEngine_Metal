extension Lattice2 {
    static let zero = Lattice2(0, 0)
    static let one = Lattice2(1, 1)
    static let right = Lattice2(1, 0)
    static let left = Lattice2(-1, 0)
    static let up = Lattice2(0, 1)
    static let down = Lattice2(0, -1)

    static func + (
        lhs: Lattice2,
        rhs: Lattice2
    ) -> Lattice2 {
        Lattice2(
            lhs.x &+ rhs.x,
            lhs.y &+ rhs.y
        )
    }

    static func - (
        lhs: Lattice2,
        rhs: Lattice2
    ) -> Lattice2 {
        Lattice2(
            lhs.x &- rhs.x,
            lhs.y &- rhs.y
        )
    }
}
