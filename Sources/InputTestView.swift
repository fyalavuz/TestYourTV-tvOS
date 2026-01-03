import SwiftUI
import GameController

struct InputTestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var monitor = ControllerMonitor()

    var body: some View {
        ZStack {
            AmbientBackground()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 40) {
                    // Header & Status
                    VStack(spacing: 20) {
                        Text("Input Test")
                            .font(.system(size: 52, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        HStack(spacing: 20) {
                            StatusBadge(icon: "gamecontroller.fill", title: "Device", value: monitor.isConnected ? monitor.controllerName : "None")
                            StatusBadge(icon: "cable.connector", title: "Profile", value: monitor.profile.rawValue)
                            StatusBadge(icon: "hand.tap.fill", title: "Last Input", value: monitor.lastEvent)
                        }
                    }
                    .padding(.top, 40)

                    if monitor.isConnected {
                        // Main Visualization Grid
                        Grid(horizontalSpacing: 40, verticalSpacing: 40) {
                            GridRow {
                                // Left: D-pad / Left Stick
                                InputPanel(title: "Directional") {
                                    HStack(spacing: 40) {
                                        DpadVisualizer(
                                            x: monitor.dpadX, y: monitor.dpadY,
                                            up: monitor.dpadUp, down: monitor.dpadDown,
                                            left: monitor.dpadLeft, right: monitor.dpadRight
                                        )
                                        
                                        if monitor.profile == .extended {
                                            StickVisualizer(
                                                title: "L-Stick",
                                                x: monitor.leftStickX, y: monitor.leftStickY,
                                                isPressed: monitor.leftStickPressed
                                            )
                                        }
                                    }
                                }
                                .gridCellColumns(monitor.profile == .extended ? 2 : 1)
                                
                                // Right: Buttons / Right Stick
                                InputPanel(title: "Action Buttons") {
                                    HStack(spacing: 40) {
                                        ButtonsVisualizer(
                                            a: monitor.buttonA, b: monitor.buttonB,
                                            x: monitor.buttonX, y: monitor.buttonY,
                                            menu: monitor.buttonMenu, options: monitor.buttonOptions,
                                            home: monitor.buttonHome
                                        )
                                        
                                        if monitor.profile == .extended {
                                            StickVisualizer(
                                                title: "R-Stick",
                                                x: monitor.rightStickX, y: monitor.rightStickY,
                                                isPressed: monitor.rightStickPressed
                                            )
                                        }
                                    }
                                }
                                .gridCellColumns(monitor.profile == .extended ? 2 : 1)
                            }
                            
                            if monitor.profile == .extended {
                                GridRow {
                                    // Triggers
                                    InputPanel(title: "Triggers & Shoulders") {
                                        HStack(spacing: 60) {
                                            TriggerBar(title: "L1", value: monitor.leftShoulderValue)
                                            TriggerBar(title: "L2", value: monitor.leftTriggerValue)
                                            TriggerBar(title: "R2", value: monitor.rightTriggerValue)
                                            TriggerBar(title: "R1", value: monitor.rightShoulderValue)
                                        }
                                    }
                                    .gridCellColumns(4)
                                }
                            }
                        }
                    } else {
                        // Connection Prompt
                        VStack(spacing: 20) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 100))
                                .foregroundStyle(.white.opacity(0.2))
                            Text("Connect a Game Controller or use the Siri Remote")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 400)
                        .glassSurface()
                    }
                    
                    // Log
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Input Log")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(lastInputSummary)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.white)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.3))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 80)
                    .padding(.bottom, 80)
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var lastInputSummary: String {
        guard let time = monitor.lastEventTime else { return "No input detected" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return "[\(formatter.string(from: time))] \(monitor.lastEvent)"
    }
}

// MARK: - Components

struct InputPanel<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
            
            content
        }
        .padding(30)
        .glassSurface(cornerRadius: 24, strokeOpacity: 0.1)
    }
}

struct StatusBadge: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.cyan)
            
            VStack(alignment: .leading) {
                Text(title.uppercased())
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

struct DpadVisualizer: View {
    let x, y: Float
    let up, down, left, right: Bool
    
    var body: some View {
        ZStack {
            // Cross
            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)).frame(width: 40, height: 120)
            RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.1)).frame(width: 120, height: 40)
            
            // Active Indicators
            if up { Arrow(angle: -90) }
            if down { Arrow(angle: 90) }
            if left { Arrow(angle: 180) }
            if right { Arrow(angle: 0) }
            
            // Analog Dot
            Circle()
                .fill(Color.cyan)
                .frame(width: 16, height: 16)
                .offset(x: CGFloat(x) * 40, y: CGFloat(-y) * 40)
        }
        .frame(width: 140, height: 140)
    }
    
    func Arrow(angle: Double) -> some View {
        Image(systemName: "arrowtriangle.right.fill")
            .rotationEffect(.degrees(angle))
            .offset(x: angle == 0 ? 40 : (angle == 180 ? -40 : 0),
                    y: angle == 90 ? 40 : (angle == -90 ? -40 : 0))
            .foregroundStyle(.white)
    }
}

struct ButtonsVisualizer: View {
    let a, b, x, y, menu, options, home: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ButtonCircle(label: "X", pressed: x, color: .blue)
                VStack(spacing: 30) {
                    ButtonCircle(label: "Y", pressed: y, color: .yellow)
                    ButtonCircle(label: "A", pressed: a, color: .green)
                }
                ButtonCircle(label: "B", pressed: b, color: .red)
            }
            
            HStack(spacing: 20) {
                SmallButton(label: "Menu", pressed: menu)
                SmallButton(label: "Opt", pressed: options)
                SmallButton(label: "Home", pressed: home)
            }
        }
    }
}

struct ButtonCircle: View {
    let label: String
    let pressed: Bool
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(pressed ? color : Color.white.opacity(0.1))
                .frame(width: 50, height: 50)
            Text(label)
                .font(.headline.weight(.bold))
                .foregroundStyle(pressed ? .black : .white)
        }
        .scaleEffect(pressed ? 0.9 : 1.0)
        .animation(.spring(duration: 0.1), value: pressed)
    }
}

struct SmallButton: View {
    let label: String
    let pressed: Bool
    
    var body: some View {
        Text(label)
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(pressed ? Color.white : Color.white.opacity(0.1))
            .foregroundStyle(pressed ? .black : .white)
            .clipShape(Capsule())
    }
}

struct StickVisualizer: View {
    let title: String
    let x, y: Float
    let isPressed: Bool
    
    var body: some View {
        VStack {
            ZStack {
                Circle().stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .frame(width: 100, height: 100)
                    .background(isPressed ? Color.white.opacity(0.1) : Color.clear)
                    .clipShape(Circle())
                
                Circle().fill(Color.cyan)
                    .frame(width: 20, height: 20)
                    .offset(x: CGFloat(x) * 40, y: CGFloat(-y) * 40)
            }
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct TriggerBar: View {
    let title: String
    let value: Float
    
    var body: some View {
        VStack {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 20, height: 100)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.cyan)
                    .frame(width: 20, height: 100 * CGFloat(value))
            }
            Text(title).font(.caption.weight(.bold)).foregroundStyle(.white)
        }
    }
}

// ControllerMonitor logic
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

#Preview {
    InputTestView()
}