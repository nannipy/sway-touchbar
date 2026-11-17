import Foundation

@main struct AdjustmentTests {
    static func main() {
        let gesture = Adjustment(initial: 0.5, origin: 40)
        assert(!gesture.isSwipe(at: 43))
        assert(gesture.isSwipe(at: 44))
        assert(gesture.value(at: 40, width: 100) == 0.5)
        assert(gesture.value(at: 90, width: 100) == 1)
        assert(gesture.value(at: -100, width: 100) == 0)
        assert(gesture.value(at: 200, width: 0) == 1)
        assert(isAppWindow(layer: 0, width: 800, height: 600, alpha: 1))
        assert(!isAppWindow(layer: 0, width: 800, height: 600, alpha: 0))
        assert(!isAppWindow(layer: 25, width: 800, height: 600, alpha: 1))
        assert(!isAppWindow(layer: 0, width: 1, height: 600, alpha: 1))
        assert(!isAppWindow(layer: -1, width: 800, height: 600, alpha: 1))
        print("Gesture and window filter tests passed")
    }
}
