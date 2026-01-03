import SwiftUI
import GameController

struct InputTestView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var monitor = ControllerMonitor()

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Input Diagnostics")
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            
            HStack(spacing: 24) {
                StatusPill(icon: "gamecontroller", title: "Device", value: monitor.isConnected ? monitor.controllerName : "Scanning...")
                StatusPill(icon: "cable.connector", title: "Profile", value: monitor.profile.rawValue)
            }
        }
        .padding(.top, 40)
    }

    private var mainVisualizerSection: some View {
        Group {
            if monitor.isConnected {
                connectedVisualizer
            } else {
                disconnectedPlaceholder
            }
        }
    }

    private var connectedVisualizer: some View {
        HStack(alignment: .top, spacing: 60) {
            // Left Section: Directional
            VStack(spacing: 30) {
                Text("DIRECTIONAL")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                DpadVisualizer(
                    x: monitor.dpadX, y: monitor.dpadY,
                    up: monitor.dpadUp, down: monitor.dpadDown,
                    left: monitor.dpadLeft, right: monitor.dpadRight
                )
                if monitor.profile == .extended {
                    StickVisualizer(
                        title: "L-STICK",
                        x: monitor.leftStickX, y: monitor.leftStickY,
                        isPressed: monitor.leftStickPressed
                    )
                }
            }
            .frame(width: 250)
            // Center Section: Buttons & Triggers
            VStack(spacing: 30) {
                Text("ACTIONS")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.secondary)
                ButtonsVisualizer(
                    a: monitor.buttonA, b: monitor.buttonB,
                    x: monitor.buttonX, y: monitor.buttonY,
                    menu: monitor.buttonMenu, options: monitor.buttonOptions,
                    home: monitor.buttonHome
                )
                if monitor.profile == .extended {
                    Divider().background(Color.white.opacity(0.1))
                    HStack(spacing: 40) {
                        TriggerVisualizer(title: "L1", value: monitor.leftShoulderValue > 0.1 ? 1.0 : 0.0)
                        TriggerVisualizer(title: "L2", value: monitor.leftTriggerValue)
                        TriggerVisualizer(title: "R2", value: monitor.rightTriggerValue)
                        TriggerVisualizer(title: "R1", value: monitor.rightShoulderValue > 0.1 ? 1.0 : 0.0)
                    }
                }
            }
            .frame(maxWidth: 500)
            // Right Section: Right Stick (if extended)
            Group {
                if monitor.profile == .extended {
                    VStack(spacing: 30) {
                        Text("CAMERA / R-STICK")
                            .font(.caption.weight(.bold))
                            .tracking(2)
                            .foregroundStyle(.secondary)
                        StickVisualizer(
                            title: "R-STICK",
                            x: monitor.rightStickX, y: monitor.rightStickY,
                            isPressed: monitor.rightStickPressed
                        )
                    }
                    .frame(width: 250)
                }
            }
        }
        .padding(40)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var disconnectedPlaceholder: some View {
        VStack(spacing: 20) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 100))
                .foregroundStyle(.white.opacity(0.2))
            Text("Connect a controller or use the Siri Remote")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 400)
        .background(Color.clear)
    }

    private var eventLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INPUT HISTORY")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 20)
            ZStack {
                if monitor.eventLog.isEmpty {
                    emptyEventPlaceholder
                } else {
                    EventLogList(eventLog: monitor.eventLog)
                }
            }
            .frame(height: 220)
            .background(Color.black.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.05), lineWidth: 1)
            )
        }
        .padding(.horizontal, 80)
        .padding(.bottom, 40)
    }

    private var emptyEventPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "antenna.radiowaves.left.and.right")
                .font(.title)
                .symbolEffect(.pulse, options: .repeating)
            Text("Waiting for input signal...")
                .font(.headline)
        }
        .foregroundStyle(.secondary.opacity(0.5))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: 40) {
                headerSection
                mainVisualizerSection
                eventLogSection
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    
    func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

// MARK: - Components

struct StatusPill: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
            Text(title + ":")
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.bold)
                .foregroundStyle(.white)
        }
        .font(.callout)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.08))
        .clipShape(Capsule())
    }
}

struct DpadVisualizer: View {
    let x, y: Float
    let up, down, left, right: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 160, height: 160)
            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 40, height: 140)
            Rectangle().fill(Color.white.opacity(0.1)).frame(width: 140, height: 40)
            if up { Arrow(angle: -90) }
            if down { Arrow(angle: 90) }
            if left { Arrow(angle: 180) }
            if right { Arrow(angle: 0) }
            Circle()
                .fill(Color.cyan)
                .frame(width: 20, height: 20)
                .offset(x: CGFloat(x) * 60, y: CGFloat(-y) * 60)
                .shadow(color: .cyan, radius: 5)
        }
    }
    
    func Arrow(angle: Double) -> some View {
        Image(systemName: "arrowtriangle.right.fill")
            .font(.title)
            .rotationEffect(.degrees(angle))
            .offset(x: angle == 0 ? 50 : (angle == 180 ? -50 : 0),
                    y: angle == 90 ? 50 : (angle == -90 ? -50 : 0))
            .foregroundStyle(.white)
            .shadow(color: .white, radius: 5)
    }
}

struct StickVisualizer: View {
    let title: String
    let x, y: Float
    let isPressed: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    .background(isPressed ? Color.white.opacity(0.1) : Color.clear)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                
                Path { path in
                    path.move(to: CGPoint(x: 60, y: 10))
                    path.addLine(to: CGPoint(x: 60, y: 110))
                    path.move(to: CGPoint(x: 10, y: 60))
                    path.addLine(to: CGPoint(x: 110, y: 60))
                }
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 24, height: 24)
                    .offset(x: CGFloat(x) * 50, y: CGFloat(-y) * 50)
                    .shadow(color: .cyan, radius: 8)
            }
            Text(title)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
        }
    }
}

struct ButtonsVisualizer: View {
    let a, b, x, y, menu, options, home: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            HStack(spacing: 20) {
                ButtonCircle(label: "X", pressed: x, color: .blue).offset(y: 20)
                VStack(spacing: 60) {
                    ButtonCircle(label: "Y", pressed: y, color: .yellow)
                    ButtonCircle(label: "A", pressed: a, color: .green)
                }
                ButtonCircle(label: "B", pressed: b, color: .red).offset(y: 20)
            }
            HStack(spacing: 30) {
                SystemButton(label: "MENU", pressed: menu)
                SystemButton(label: "HOME", pressed: home)
                SystemButton(label: "OPT", pressed: options)
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
                .fill(pressed ? color : Color.white.opacity(0.08))
                .frame(width: 64, height: 64)
                .overlay(Circle().stroke(pressed ? color.opacity(0.8) : Color.white.opacity(0.2), lineWidth: 2))
                .shadow(color: pressed ? color : .clear, radius: 10)
            Text(label).font(.title2.weight(.black)).foregroundStyle(pressed ? .black : .white)
        }
        .scaleEffect(pressed ? 0.95 : 1.0)
        .animation(.spring(duration: 0.1), value: pressed)
    }
}

struct SystemButton: View {
    let label: String
    let pressed: Bool
    var body: some View {
        Text(label).font(.caption.weight(.bold)).foregroundStyle(pressed ? .black : .white.opacity(0.6)).padding(.horizontal, 12).padding(.vertical, 6).background(pressed ? Color.white : Color.white.opacity(0.1)).clipShape(Capsule())
    }
}

struct TriggerVisualizer: View {
    let title: String
    let value: Float
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.1)).frame(width: 24, height: 80)
                RoundedRectangle(cornerRadius: 6).fill(Color.cyan).frame(width: 24, height: 80 * CGFloat(value)).shadow(color: .cyan, radius: value > 0 ? 5 : 0)
            }
            Text(title).font(.caption2.weight(.bold)).foregroundStyle(.secondary)
        }
    }
}

struct EventLogList: View {
    let eventLog: [InputEvent]
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(eventLog.indices, id: \.self) { index in
                        let event = eventLog[index]
                        HStack {
                            Text(timeStringStatic(event.date))
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                            Text(event.name)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(index == 0 ? .cyan : .white)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(index == 0 ? Color.cyan.opacity(0.1) : Color.white.opacity(0.02))
                        .cornerRadius(8)
                        .id(index)
                    }
                }
                .padding()
            }
            .onChange(of: eventLog.count) { _ in
                withAnimation {
                    proxy.scrollTo(0, anchor: .top)
                }
            }
        }
    }
}

private func timeStringStatic(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter.string(from: date)
}

struct InputEvent: Identifiable {
    let id = UUID()
    let date: Date
    let name: String
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
    @Published var eventLog: [InputEvent] = []

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
        connectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main) { [weak self] n in self?.refreshControllers() }
        disconnectObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main) { [weak self] _ in self?.refreshControllers() }
        currentObserver = NotificationCenter.default.addObserver(forName: .GCControllerDidBecomeCurrent, object: nil, queue: .main) { [weak self] n in if let c = n.object as? GCController { self?.setActiveController(c) } }
        refreshControllers()
        GCController.startWirelessControllerDiscovery { }
    }

    deinit {
        [connectObserver, disconnectObserver, currentObserver].compactMap { $0 }.forEach { NotificationCenter.default.removeObserver($0) }
        GCController.stopWirelessControllerDiscovery()
    }

    private func refreshControllers() {
        let controllers = GCController.controllers()
        controllerCount = controllers.count
        if let current = GCController.current ?? controllers.first { setActiveController(current) } else { clearState() }
    }

    private func setActiveController(_ controller: GCController) {
        clearHandlers()
        activeController = controller
        controllerName = controller.vendorName ?? (controller.microGamepad != nil ? "Siri Remote" : "Controller")
        isConnected = true
        if let micro = controller.microGamepad { profile = .micro; configureMicroGamepad(micro) }
        else if let extended = controller.extendedGamepad { profile = .extended; configureExtendedGamepad(extended) }
        else { profile = .none }
    }

    private func configureMicroGamepad(_ gamepad: GCMicroGamepad) {
        gamepad.valueChangedHandler = { [weak self] g, e in self?.updateMicro(g, element: e) }
        updateMicro(gamepad, element: nil)
    }

    private func updateMicro(_ gamepad: GCMicroGamepad, element: GCControllerElement?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dpadX = gamepad.dpad.xAxis.value; self.dpadY = gamepad.dpad.yAxis.value
            self.dpadUp = gamepad.dpad.up.isPressed; self.dpadDown = gamepad.dpad.down.isPressed
            self.dpadLeft = gamepad.dpad.left.isPressed; self.dpadRight = gamepad.dpad.right.isPressed
            self.buttonA = gamepad.buttonA.isPressed; self.buttonX = gamepad.buttonX.isPressed
            self.buttonMenu = gamepad.buttonMenu.isPressed
            if let e = element { self.logEvent(name: self.eventName(for: e, micro: gamepad, extended: nil)) }
        }
    }

    private func configureExtendedGamepad(_ gamepad: GCExtendedGamepad) {
        gamepad.valueChangedHandler = { [weak self] g, e in self?.updateExtended(g, element: e) }
        updateExtended(gamepad, element: nil)
    }

    private func updateExtended(_ gamepad: GCExtendedGamepad, element: GCControllerElement?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.dpadX = gamepad.dpad.xAxis.value; self.dpadY = gamepad.dpad.yAxis.value
            self.dpadUp = gamepad.dpad.up.isPressed; self.dpadDown = gamepad.dpad.down.isPressed
            self.dpadLeft = gamepad.dpad.left.isPressed; self.dpadRight = gamepad.dpad.right.isPressed
            self.buttonA = gamepad.buttonA.isPressed; self.buttonB = gamepad.buttonB.isPressed
            self.buttonX = gamepad.buttonX.isPressed; self.buttonY = gamepad.buttonY.isPressed
            self.buttonMenu = gamepad.buttonMenu.isPressed
            self.buttonOptions = gamepad.buttonOptions?.isPressed ?? false
            self.buttonHome = gamepad.buttonHome?.isPressed ?? false
            self.leftShoulderValue = gamepad.leftShoulder.value; self.rightShoulderValue = gamepad.rightShoulder.value
            self.leftTriggerValue = gamepad.leftTrigger.value; self.rightTriggerValue = gamepad.rightTrigger.value
            self.leftStickX = gamepad.leftThumbstick.xAxis.value; self.leftStickY = gamepad.leftThumbstick.yAxis.value
            self.rightStickX = gamepad.rightThumbstick.xAxis.value; self.rightStickY = gamepad.rightThumbstick.yAxis.value
            self.leftStickPressed = gamepad.leftThumbstickButton?.isPressed ?? false
            self.rightStickPressed = gamepad.rightThumbstickButton?.isPressed ?? false
            if let e = element { self.logEvent(name: self.eventName(for: e, micro: nil, extended: gamepad)) }
        }
    }

    private func eventName(for element: GCControllerElement, micro: GCMicroGamepad?, extended: GCExtendedGamepad?) -> String {
        if let m = micro {
            if element == m.dpad { return "D-pad Move" }
            if element == m.buttonA { return "Select" }
            if element == m.buttonX { return "Play/Pause" }
            if element == m.buttonMenu { return "Menu" }
        }
        if let x = extended {
            if element == x.dpad { return "D-pad" }
            if element == x.buttonA { return "Button A" }
            if element == x.buttonB { return "Button B" }
            if element == x.buttonX { return "Button X" }
            if element == x.buttonY { return "Button Y" }
            if element == x.buttonMenu { return "Menu" }
            if let o = x.buttonOptions, element == o { return "Options" }
            if let h = x.buttonHome, element == h { return "Home" }
            if element == x.leftShoulder { return "L1" }
            if element == x.rightShoulder { return "R1" }
            if element == x.leftTrigger { return "L2" }
            if element == x.rightTrigger { return "R2" }
            if element == x.leftThumbstick { return "L-Stick" }
            if element == x.rightThumbstick { return "R-Stick" }
        }
        return "Input"
    }

    private func logEvent(name: String) {
        let event = InputEvent(date: Date(), name: name)
        eventLog.insert(event, at: 0)
        if eventLog.count > 20 { eventLog.removeLast() }
    }

    private func clearHandlers() {
        activeController?.microGamepad?.valueChangedHandler = nil
        activeController?.extendedGamepad?.valueChangedHandler = nil
    }

    private func clearState() {
        activeController = nil; profile = .none; isConnected = false; eventLog = []
    }
}

#Preview {
    InputTestView()
}
