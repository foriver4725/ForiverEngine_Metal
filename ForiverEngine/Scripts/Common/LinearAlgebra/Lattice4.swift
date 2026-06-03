extension Lattice4 {
    static func + (
        lhs: Lattice4,
        rhs: Lattice4
    ) -> Lattice4 {
        Lattice4(
            lhs.x &+ rhs.x,
            lhs.y &+ rhs.y,
            lhs.z &+ rhs.z,
            lhs.w &+ rhs.w
        )
    }

    static func - (
        lhs: Lattice4,
        rhs: Lattice4
    ) -> Lattice4 {
        Lattice4(
            lhs.x &- rhs.x,
            lhs.y &- rhs.y,
            lhs.z &- rhs.z,
            lhs.w &- rhs.w
        )
    }
}
