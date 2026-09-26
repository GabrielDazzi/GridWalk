import Foundation

extension Bundle {
    // tests can't reach another target's Bundle.module directly
    static var gridWalkKit: Bundle { .module }
}
