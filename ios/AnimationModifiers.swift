import SwiftUI

struct PressScaleEffect: ViewModifier {
    @State private var isPressed = false
    var scale: CGFloat = 0.95
    var haptic: HapticScenario? = .buttonTap

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
                if pressing {
                    haptic?.feedback()
                }
            }, perform: {})
    }
}

struct FadeInAnimation: ViewModifier {
    @State private var isVisible = false
    var delay: Double = 0

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(.easeOut(duration: 0.4).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

struct SlideInAnimation: ViewModifier {
    @State private var isVisible = false
    var delay: Double = 0
    var direction: Edge = .leading

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(x: isVisible ? 0 : (direction == .leading ? -30 : 30))
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

struct StaggeredListAnimation: ViewModifier {
    let index: Int
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 15)
            .animation(.easeOut(duration: 0.35).delay(Double(index) * 0.05), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

struct CardHoverEffect: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .shadow(
                color: isHovered ? .black.opacity(0.15) : .black.opacity(0.08),
                radius: isHovered ? 8 : 4,
                x: 0,
                y: isHovered ? 4 : 2
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func pressScale(scale: CGFloat = 0.95, haptic: HapticScenario? = .buttonTap) -> some View {
        modifier(PressScaleEffect(scale: scale, haptic: haptic))
    }

    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInAnimation(delay: delay))
    }

    func slideIn(delay: Double = 0, from direction: Edge = .leading) -> some View {
        modifier(SlideInAnimation(delay: delay, direction: direction))
    }

    func staggered(index: Int) -> some View {
        modifier(StaggeredListAnimation(index: index))
    }

    func cardHover() -> some View {
        modifier(CardHoverEffect())
    }
}

struct AnimatedButtonStyle: ButtonStyle {
    var scale: CGFloat = 0.95
    var haptic: HapticScenario? = .buttonTap

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed {
                    haptic?.feedback()
                }
            }
    }
}

struct AnimatedNavigationTransition: ViewModifier {
    @State private var isActive = false

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 1 : 0)
            .offset(x: isActive ? 0 : 20)
            .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isActive)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isActive = true
                }
            }
    }
}

extension View {
    func navigationTransition() -> some View {
        modifier(AnimatedNavigationTransition())
    }
}
