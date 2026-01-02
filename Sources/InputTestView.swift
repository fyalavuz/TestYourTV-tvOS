import SwiftUI
import GameController

struct InputTestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var monitor = ControllerMonitor()

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    statusRow

                    HStack(spacing: 32) {
                        InputCard(title: "D-pad / Touch") {
                            DpadVisualizer(
                                x: monitor.dpadX,
                                y: monitor.dpadY,
                                up: monitor.dpadUp,
                                down: monitor.dpadDown,
                                left: monitor.dpadLeft,
                                right: monitor.dpadRight
                            )
                        }

                        InputCard(title: "Buttons") {
                            ButtonsGrid(
                                profile: monitor.profile,
                                buttonA: monitor.buttonA,
                                buttonB: monitor.buttonB,
                                buttonX: monitor.buttonX,
                                buttonY: monitor.buttonY,
                                buttonMenu: monitor.buttonMenu,
                                buttonOptions: monitor.buttonOptions,
                                buttonHome: monitor.buttonHome
                            )
                        }

                        if monitor.profile == .extended {
                            InputCard(title: "Sticks & Triggers") {
                                ExtendedInputsView(
                                    leftStick: CGPoint(x: CGFloat(monitor.leftStickX), y: CGFloat(monitor.leftStickY)),
                                    rightStick: CGPoint(x: CGFloat(monitor.rightStickX), y: CGFloat(monitor.rightStickY)),
                                    leftStickPressed: monitor.leftStickPressed,
                                    rightStickPressed: monitor.rightStickPressed,
                                    leftTrigger: monitor.leftTriggerValue,
                                    rightTrigger: monitor.rightTriggerValue,
                                    leftShoulder: monitor.leftShoulderValue,
                                    rightShoulder: monitor.rightShoulderValue
                                )
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        Text("Input Test")
                            .font(.title.weight(.bold))
                            .foregroundStyle(.white)

                        Text("Use Siri Remote or a game controller to verify input events.")
                            .font(.callout)
                            .foregroundStyle(.secondary)

                        Divider().overlay(Color.white.opacity(0.2))

                        Text("Controller")
                            .font(.headline)
                            .foregroundStyle(.white)
                        InputValueRow(title: "Status", value: monitor.isConnected ? "Connected" : "Waiting")
                        InputValueRow(title: "Count", value: "\(monitor.controllerCount)")
                        InputValueRow(title: "Profile", value: monitor.profile.rawValue)
                        InputValueRow(title: "Name", value: monitor.controllerName)
                        if monitor.isConnected {
                            InputValueRow(title: "Vendor", value: monitor.vendorName)
                        }

                        Divider().overlay(Color.white.opacity(0.2))

                        Text("Last Input")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(lastInputSummary)
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(Color.white.opacity(0.08))
                            )

                        Divider().overlay(Color.white.opacity(0.2))

                        Text("D-pad")
                            .font(.headline)
                            .foregroundStyle(.white)
                        InputValueRow(title: "X", value: formatAxis(monitor.dpadX))
                        InputValueRow(title: "Y", value: formatAxis(monitor.dpadY))
                    }
                }
                .padding(.top, 40)
                .padding(.horizontal, 80)
                .padding(.bottom, 80)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var statusRow: some View {
        HStack(spacing: 20) {
            InfoBadge(title: "Controller", value: monitor.isConnected ? monitor.controllerName : "Not Connected")
            InfoBadge(title: "Profile", value: monitor.profile.rawValue)
            InfoBadge(title: "Last Input", value: monitor.lastEvent)
        }
    }

    private var lastInputSummary: String {
        guard let time = monitor.lastEventTime else {
            return "Waiting for input"
        }
        return "\(monitor.lastEvent) (\(formatRelativeTime(time)))"
    }

    private func formatAxis(_ value: Float) -> String {
        String(format: "%.2f", value)
    }

    private func formatRelativeTime(_ date: Date) -> String {
        let interval = max(0, Int(Date().timeIntervalSince(date)))
        if interval < 1 {
            return "just now"
        }
        if interval < 60 {
            return "\(interval)s ago"
        }
        let minutes = interval / 60
        if minutes < 60 {
            return "\(minutes)m ago"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h ago"
        }
        let days = hours / 24
        return "\(days)d ago"
    }
}

final class ControllerMonitor: ObservableObject {
    enum Profile: String {
        case none = "No Controller"
        case micro = "Micro Gamepad"
        case extended = "Extended Gamepad"
    }

    @Published var profile: Profile = .none
    @Published var controllerName: String = "No Controller"
    @Published var vendorName: String = "Not Connected"
    @Published var controllerCount: Int = 0
    @Published var isConnected: Bool = false
    @Published var lastEvent: String = "Waiting for input"
    @Published var lastEventTime: Date?

    @Published var dpadX: Float = 0
    @Published var dpadY: Float = 0
    @Published var dpadUp: Bool = false
    @Published var dpadDown: Bool = false
    @Published var dpadLeft: Bool = false
    @Published var dpadRight: Bool = false

    @Published var buttonA: Bool = false
    @Published var buttonB: Bool = false
    @Published var buttonX: Bool = false
    @Published var buttonY: Bool = false
    @Published var buttonMenu: Bool = false
    @Published var buttonOptions: Bool = false
    @Published var buttonHome: Bool = false

    @Published var leftShoulderValue: Float = 0
    @Published var rightShoulderValue: Float = 0
    @Published var leftTriggerValue: Float = 0
    @Published var rightTriggerValue: Float = 0

    @Published var leftStickX: Float = 0
    @Published var leftStickY: Float = 0
    @Published var rightStickX: Float = 0
    @Published var rightStickY: Float = 0
    @Published var leftStickPressed: Bool = false
    @Published var rightStickPressed: Bool = false

    private var activeController: GCController?
    private var connectObserver: NSObjectProtocol?
    private var disconnectObserver: NSObjectProtocol?
    private var currentObserver: NSObjectProtocol?

    init() {
        connectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self else { return }
            if let controller = notification.object as? GCController {
                self.setActiveController(controller)
            } else {
                self.refreshControllers()
            }
        }

        disconnectObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshControllers()
        }

        currentObserver = NotificationCenter.default.addObserver(
            forName: .GCControllerDidBecomeCurrent,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            self?.setActiveController(controller)
        }

        refreshControllers()
        GCController.startWirelessControllerDiscovery { }
    }

    deinit {
        if let connectObserver {
            NotificationCenter.default.removeObserver(connectObserver)
        }
        if let disconnectObserver {
            NotificationCenter.default.removeObserver(disconnectObserver)
        }
        if let currentObserver {
            NotificationCenter.default.removeObserver(currentObserver)
        }
        GCController.stopWirelessControllerDiscovery()
    }

    private func refreshControllers() {
        let controllers = GCController.controllers()
        controllerCount = controllers.count
        if let current = GCController.current ?? controllers.first {
            setActiveController(current)
        } else {
            clearState()
        }
    }

    private func setActiveController(_ controller: GCController) {
        clearHandlers()

        activeController = controller
        controllerCount = GCController.controllers().count
        let vendor = controller.vendorName
        controllerName = vendor ?? (controller.microGamepad != nil ? "Siri Remote" : "Controller")
        vendorName = vendor ?? "Unknown"
        isConnected = true

        if let micro = controller.microGamepad {
            profile = .micro
            configureMicroGamepad(micro)
        } else if let extended = controller.extendedGamepad {
            profile = .extended
            configureExtendedGamepad(extended)
        } else {
            profile = .none
        }
    }

    private func configureMicroGamepad(_ gamepad: GCMicroGamepad) {
        gamepad.valueChangedHandler = { [weak self] gamepad, element in
            self?.updateMicro(gamepad, element: element)
        }
        updateMicro(gamepad, element: nil)
    }

    private func updateMicro(_ gamepad: GCMicroGamepad, element: GCControllerElement?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.dpadX = gamepad.dpad.xAxis.value
            self.dpadY = gamepad.dpad.yAxis.value
            self.dpadUp = gamepad.dpad.up.isPressed
            self.dpadDown = gamepad.dpad.down.isPressed
            self.dpadLeft = gamepad.dpad.left.isPressed
            self.dpadRight = gamepad.dpad.right.isPressed
            self.buttonA = gamepad.buttonA.isPressed
            self.buttonX = gamepad.buttonX.isPressed
            self.buttonMenu = gamepad.buttonMenu.isPressed
            self.buttonB = false
            self.buttonY = false
            self.buttonOptions = false
            self.buttonHome = false
            self.leftShoulderValue = 0
            self.rightShoulderValue = 0
            self.leftTriggerValue = 0
            self.rightTriggerValue = 0
            self.leftStickX = 0
            self.leftStickY = 0
            self.rightStickX = 0
            self.rightStickY = 0
            self.leftStickPressed = false
            self.rightStickPressed = false

            self.setLastEvent(name: self.eventName(for: element, micro: gamepad, extended: nil))
        }
    }

    private func configureExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        gamepad.valueChangedHandler = { [weak self] gamepad, element in
            self?.updateExtended(gamepad, element: element)
        }
        updateExtended(gamepad, element: nil)
    }

    private func updateExtended(_ gamepad: GCExtendedGamepad, element: GCControllerElement?) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.dpadX = gamepad.dpad.xAxis.value
            self.dpadY = gamepad.dpad.yAxis.value
            self.dpadUp = gamepad.dpad.up.isPressed
            self.dpadDown = gamepad.dpad.down.isPressed
            self.dpadLeft = gamepad.dpad.left.isPressed
            self.dpadRight = gamepad.dpad.right.isPressed

            self.buttonA = gamepad.buttonA.isPressed
            self.buttonB = gamepad.buttonB.isPressed
            self.buttonX = gamepad.buttonX.isPressed
            self.buttonY = gamepad.buttonY.isPressed
            self.buttonMenu = gamepad.buttonMenu.isPressed
            self.buttonOptions = gamepad.buttonOptions?.isPressed ?? false
            self.buttonHome = gamepad.buttonHome?.isPressed ?? false

            self.leftShoulderValue = gamepad.leftShoulder.value
            self.rightShoulderValue = gamepad.rightShoulder.value
            self.leftTriggerValue = gamepad.leftTrigger.value
            self.rightTriggerValue = gamepad.rightTrigger.value

            self.leftStickX = gamepad.leftThumbstick.xAxis.value
            self.leftStickY = gamepad.leftThumbstick.yAxis.value
            self.rightStickX = gamepad.rightThumbstick.xAxis.value
            self.rightStickY = gamepad.rightThumbstick.yAxis.value
            self.leftStickPressed = gamepad.leftThumbstickButton?.isPressed ?? false
            self.rightStickPressed = gamepad.rightThumbstickButton?.isPressed ?? false

            self.setLastEvent(name: self.eventName(for: element, micro: nil, extended: gamepad))
        }
    }

    private func eventName(for element: GCControllerElement?, micro: GCMicroGamepad?, extended: GCExtendedGamepad?) -> String {
        guard let element else { return "Waiting for input" }
        if let micro {
            if element == micro.dpad { return "D-pad" }
            if element == micro.buttonA { return "Button A" }
            if element == micro.buttonX { return "Button X" }
            if element == micro.buttonMenu { return "Menu" }
        }
        if let extended {
            if element == extended.dpad { return "D-pad" }
            if element == extended.buttonA { return "Button A" }
            if element == extended.buttonB { return "Button B" }
            if element == extended.buttonX { return "Button X" }
            if element == extended.buttonY { return "Button Y" }
            if element == extended.buttonMenu { return "Menu" }
            if let options = extended.buttonOptions, element == options { return "Options" }
            if let home = extended.buttonHome, element == home { return "Home" }
            if element == extended.leftShoulder { return "Left Shoulder" }
            if element == extended.rightShoulder { return "Right Shoulder" }
            if element == extended.leftTrigger { return "Left Trigger" }
            if element == extended.rightTrigger { return "Right Trigger" }
            if element == extended.leftThumbstick { return "Left Stick" }
            if element == extended.rightThumbstick { return "Right Stick" }
            if let leftButton = extended.leftThumbstickButton, element == leftButton { return "Left Stick Button" }
            if let rightButton = extended.rightThumbstickButton, element == rightButton { return "Right Stick Button" }
        }
        return "Input"
    }

    private func setLastEvent(name: String) {
        if name == "Waiting for input" {
            return
        }
        lastEvent = name
        lastEventTime = Date()
    }

    private func clearHandlers() {
        if let micro = activeController?.microGamepad {
            micro.valueChangedHandler = nil
        }
        if let extended = activeController?.extendedGamepad {
            extended.valueChangedHandler = nil
        }
    }

    private func clearState() {
        activeController = nil
        profile = .none
        controllerName = "No Controller"
        vendorName = "Not Connected"
        isConnected = false
        lastEvent = "Waiting for input"
        lastEventTime = nil
        controllerCount = 0

        dpadX = 0
        dpadY = 0
        dpadUp = false
        dpadDown = false
        dpadLeft = false
        dpadRight = false

        buttonA = false
        buttonB = false
        buttonX = false
        buttonY = false
        buttonMenu = false
        buttonOptions = false
        buttonHome = false

        leftShoulderValue = 0
        rightShoulderValue = 0
        leftTriggerValue = 0
        rightTriggerValue = 0

        leftStickX = 0
        leftStickY = 0
        rightStickX = 0
        rightStickY = 0
        leftStickPressed = false
        rightStickPressed = false
    }
}

private struct InputCard<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
            content
        }
        .frame(width: 340)
        .glassSurface(cornerRadius: 22, strokeOpacity: 0.16)
    }
}

private struct DpadVisualizer: View {
    let x: Float
    let y: Float
    let up: Bool
    let down: Bool
    let left: Bool
    let right: Bool

    var body: some View {
        VStack(spacing: 16) {
            AxisPad(x: x, y: y, highlight: up || down || left || right)
                .frame(width: 200, height: 200)

            HStack(spacing: 12) {
                AxisValue(title: "X", value: x)
                AxisValue(title: "Y", value: y)
            }

            HStack(spacing: 10) {
                DirectionIndicator(symbol: "arrow.up", isActive: up)
                DirectionIndicator(symbol: "arrow.left", isActive: left)
                DirectionIndicator(symbol: "arrow.right", isActive: right)
                DirectionIndicator(symbol: "arrow.down", isActive: down)
            }
        }
    }
}

private struct AxisPad: View {
    let x: Float
    let y: Float
    let highlight: Bool

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let range = size * 0.32
            let knobSize = size * 0.12
            let accent = Color(red: 0.18, green: 0.90, blue: 0.95)

            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(highlight ? 0.5 : 0.2), lineWidth: highlight ? 2 : 1)

                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 2, height: size * 0.7)
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: size * 0.7, height: 2)

                Circle()
                    .fill(accent)
                    .frame(width: knobSize, height: knobSize)
                    .offset(
                        x: CGFloat(max(-1, min(1, x))) * range,
                        y: CGFloat(max(-1, min(1, -y))) * range
                    )
                    .shadow(color: accent.opacity(0.6), radius: 10)
            }
        }
    }
}

private struct AxisValue: View {
    let title: String
    let value: Float

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(String(format: "%.2f", value))
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}

private struct DirectionIndicator: View {
    let symbol: String
    let isActive: Bool

    var body: some View {
        let accent = Color(red: 0.18, green: 0.90, blue: 0.95)
        Image(systemName: symbol)
            .font(.headline.weight(.bold))
            .foregroundStyle(isActive ? .black : .white)
            .frame(width: 36, height: 36)
            .background(
                Circle()
                    .fill(isActive ? accent : Color.white.opacity(0.12))
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(isActive ? 0.9 : 0.2), lineWidth: 1)
            )
    }
}

private struct ButtonsGrid: View {
    let profile: ControllerMonitor.Profile
    let buttonA: Bool
    let buttonB: Bool
    let buttonX: Bool
    let buttonY: Bool
    let buttonMenu: Bool
    let buttonOptions: Bool
    let buttonHome: Bool

    var body: some View {
        let buttons: [(String, Bool)] = profile == .extended
            ? [
                ("A", buttonA),
                ("B", buttonB),
                ("X", buttonX),
                ("Y", buttonY),
                ("Menu", buttonMenu),
                ("Options", buttonOptions),
                ("Home", buttonHome)
            ]
            : [
                ("A", buttonA),
                ("X", buttonX),
                ("Menu", buttonMenu)
            ]

        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(buttons.indices, id: \.self) { index in
                let button = buttons[index]
                ButtonIndicator(label: button.0, isPressed: button.1)
            }
        }
    }
}

private struct ButtonIndicator: View {
    let label: String
    let isPressed: Bool

    var body: some View {
        let accent = Color(red: 0.18, green: 0.90, blue: 0.95)
        HStack(spacing: 10) {
            Circle()
                .fill(isPressed ? accent : Color.white.opacity(0.2))
                .frame(width: 14, height: 14)
                .shadow(color: accent.opacity(isPressed ? 0.6 : 0), radius: 6)

            Text(label)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(isPressed ? 0.18 : 0.08))
        )
    }
}

private struct ExtendedInputsView: View {
    let leftStick: CGPoint
    let rightStick: CGPoint
    let leftStickPressed: Bool
    let rightStickPressed: Bool
    let leftTrigger: Float
    let rightTrigger: Float
    let leftShoulder: Float
    let rightShoulder: Float

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StickVisualizer(title: "Left Stick", x: Float(leftStick.x), y: Float(leftStick.y), isPressed: leftStickPressed)
                StickVisualizer(title: "Right Stick", x: Float(rightStick.x), y: Float(rightStick.y), isPressed: rightStickPressed)
            }

            AnalogMeterRow(title: "L1", value: leftShoulder)
            AnalogMeterRow(title: "R1", value: rightShoulder)
            AnalogMeterRow(title: "L2", value: leftTrigger)
            AnalogMeterRow(title: "R2", value: rightTrigger)
        }
    }
}

private struct StickVisualizer: View {
    let title: String
    let x: Float
    let y: Float
    let isPressed: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            AxisPad(x: x, y: y, highlight: isPressed)
                .frame(width: 120, height: 120)
        }
    }
}

private struct AnalogMeterRow: View {
    let title: String
    let value: Float

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                Text(String(format: "%.2f", value))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
            }

            ProgressTrack(progress: Double(max(0, min(1, value))))
                .frame(height: 6)
        }
    }
}

private struct InputValueRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            Spacer(minLength: 0)

            Text(value)
                .font(.callout.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .minimumScaleFactor(0.8)
                .allowsTightening(true)
        }
    }
}

#Preview {
    InputTestView()
}
