import SwiftUI
import UserNotifications
import Security

@main
struct PushDemoApp: App {
    @UIApplicationDelegateAdaptor(PushDelegate.self) var delegate
    var body: some Scene { WindowGroup { DemoView(model: DemoModel.shared) } }
}

final class PushDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { @MainActor in await DemoModel.shared.register(token) }
    }
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        Task { @MainActor in DemoModel.shared.status = "APNs registration: \(error.localizedDescription)" }
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let title = notification.request.content.title
        Task { @MainActor in DemoModel.shared.receipt = "Received: \(title) at \(Date().formatted(date: .omitted, time: .standard))" }
        completionHandler([.banner, .sound])
    }
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let payload = response.notification.request.content.userInfo["chatwoot"] as? [String: Any]
        let inboxID = payload?["inbox_id"] as? Int
        let conversationID = payload?["conversation_id"] as? Int
        Task { @MainActor in
            await DemoModel.shared.openNotification(inboxID: inboxID, conversationID: conversationID)
            completionHandler()
        }
    }
}

struct CustomerSession: Codable {
    var host: String
    var websiteToken: String
    var authToken: String
    var inboxID: Int
    var deviceID: Int?
}

enum SessionStore {
    private static var query: [String: Any] { [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "chatwoot-push-demo", kSecAttrAccount as String: "customer-session"] }
    static func load() -> CustomerSession? {
        var request = query
        request[kSecReturnData as String] = true
        var result: CFTypeRef?
        guard SecItemCopyMatching(request as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return nil }
        return try? JSONDecoder().decode(CustomerSession.self, from: data)
    }
    static func save(_ session: CustomerSession?) throws {
        guard let session else { SecItemDelete(query as CFDictionary); return }
        let data = try JSONEncoder().encode(session)
        let update = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if update == errSecItemNotFound {
            var item = query
            item[kSecValueData as String] = data
            item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            guard SecItemAdd(item as CFDictionary, nil) == errSecSuccess else { throw DemoError.message("Could not save customer session in Keychain") }
        } else if update != errSecSuccess { throw DemoError.message("Could not update customer session in Keychain") }
    }
}

enum DemoError: LocalizedError {
    case message(String)
    var errorDescription: String? { switch self { case .message(let text): return text } }
}

@MainActor
final class DemoModel: ObservableObject {
    static let shared = DemoModel()
    @Published var host = "http://localhost:3127"
    @Published var websiteToken = UserDefaults.standard.string(forKey: "websiteToken") ?? ""
    @Published var inboxID = "1"
    @Published var environment = "development"
    @Published var status = "Connect to your Website inbox to begin."
    @Published var message = "Hello from the iOS push demo"
    @Published var messages: [String] = []
    @Published var destination = ""
    @Published var receipt = ""
    @Published var busy = false
    @Published var connected = false
    private var session: CustomerSession?

    init() {
        session = SessionStore.load()
        if let session {
            host = session.host; websiteToken = session.websiteToken; inboxID = String(session.inboxID)
            connected = true; status = "Customer session restored."
        }
    }

    private func request(_ path: String, method: String = "GET", body: [String: Any]? = nil) async throws -> [String: Any] {
        let base = session?.host ?? host
        guard var url = URLComponents(string: base + "/api/v1/widget/" + path), ["http", "https"].contains(url.scheme), url.host != nil else {
            throw DemoError.message("Enter a valid Chatwoot server URL.")
        }
        url.queryItems = [URLQueryItem(name: "website_token", value: session?.websiteToken ?? websiteToken)]
        guard let endpoint = url.url else { throw DemoError.message("Invalid server URL") }
        var request = URLRequest(url: endpoint)
        request.httpMethod = method
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let session { request.setValue(session.authToken, forHTTPHeaderField: "X-Auth-Token") }
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }
        let (data, response) = try await URLSession.shared.data(for: request)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
            throw DemoError.message(json["error"] as? String ?? json["message"] as? String ?? "Request failed. Check the server and configuration.")
        }
        return json
    }

    func connect() async {
        busy = true; defer { busy = false }
        do {
            guard let id = Int(inboxID), !websiteToken.isEmpty else { throw DemoError.message("Enter the Website token and inbox ID.") }
            host = host.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            let json = try await request("config", method: "POST")
            guard let config = json["website_channel_config"] as? [String: Any], let auth = config["auth_token"] as? String else { throw DemoError.message("The server did not return a customer session.") }
            session = CustomerSession(host: host, websiteToken: websiteToken, authToken: auth, inboxID: id)
            try SessionStore.save(session)
            connected = true; status = "Connected. Send a message, then enable notifications."
        } catch { status = error.localizedDescription }
    }

    func enableNotifications() async {
        do {
            guard session != nil else { throw DemoError.message("Connect first.") }
            let allowed = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            guard allowed else { throw DemoError.message("Notifications are disabled. Enable them in iOS Settings.") }
            status = "Permission granted. Requesting APNs device token…"
            UIApplication.shared.registerForRemoteNotifications()
        } catch { status = error.localizedDescription }
    }

    func register(_ token: String) async {
        do {
            guard session != nil else { return }
            let json = try await request("mobile_push_devices", method: "POST", body: ["device_token": token, "environment": environment, "name": UIDevice.current.name])
            guard let id = json["id"] as? Int else { throw DemoError.message("Registration response is missing the device ID.") }
            session?.deviceID = id
            try SessionStore.save(session)
            status = "Device registered. Send a test notification from Chatwoot."
        } catch { status = "Device registration: \(error.localizedDescription)" }
    }

    func send() async {
        busy = true; defer { busy = false }
        do {
            _ = try await request("messages", method: "POST", body: ["message": ["content": message, "timestamp": Int(Date().timeIntervalSince1970)]])
            status = "Message sent. Reply from the local Chatwoot inbox."
            await refresh()
        } catch { status = error.localizedDescription }
    }

    func refresh() async {
        do {
            let json = try await request("messages")
            let items = json["payload"] as? [[String: Any]] ?? []
            messages = items.compactMap { item in
                guard let content = item["content"] as? String else { return nil }
                return ((item["message_type"] as? Int == 0) ? "You: " : "Support: ") + content
            }
        } catch { status = error.localizedDescription }
    }

    func openNotification(inboxID: Int?, conversationID: Int?) async {
        guard let session, inboxID == session.inboxID else {
            status = "Notification belongs to another inbox or a signed-out session."; return
        }
        destination = conversationID.map { "Conversation #\($0)" } ?? "Test notification"
        status = "Notification tap received."
        // This proof shows the destination only. The full SDK will fetch the exact
        // authorized conversation instead of treating the widget's latest thread as the target.
    }

    func reset() async {
        busy = true; defer { busy = false }
        do {
            if let id = session?.deviceID { _ = try await request("mobile_push_devices/\(id)", method: "DELETE") }
            try SessionStore.save(nil)
            session = nil; connected = false; messages = []; destination = ""
            UIApplication.shared.unregisterForRemoteNotifications()
            status = "Device unregistered and customer session cleared."
        } catch { status = "Could not unregister. Session retained so you can retry: \(error.localizedDescription)" }
    }
}

struct DemoView: View {
    @ObservedObject var model: DemoModel
    var body: some View {
        NavigationStack {
            Form {
                if !model.receipt.isEmpty { Section("Push received on this device") { Text(model.receipt) } }
                Section("Website inbox") {
                    TextField("Chatwoot URL", text: $model.host)
                    TextField("Website token", text: $model.websiteToken)
                    TextField("Inbox ID", text: $model.inboxID).keyboardType(.numberPad)
                    if !model.connected { Button("Connect") { Task { await model.connect() } } }
                }.textInputAutocapitalization(.never).autocorrectionDisabled().disabled(model.connected || model.busy)
                if model.connected {
                    Section("Push notifications") {
                        Picker("APNs environment", selection: $model.environment) {
                            Text("Development").tag("development")
                            Text("Production").tag("production")
                        }
                        Button("Enable notifications") { Task { await model.enableNotifications() } }
                        Text("Choose the environment matching your signed build. Debug uses development.").font(.caption)
                    }
                    Section("Conversation") {
                        TextField("Message", text: $model.message)
                        Button("Send message") { Task { await model.send() } }.disabled(model.busy || model.message.isEmpty)
                        Button("Refresh replies") { Task { await model.refresh() } }
                        ForEach(Array(model.messages.enumerated()), id: \.offset) { _, text in Text(text) }
                    }
                }
                Section("Status") { Text(model.status).textSelection(.enabled) }
                if !model.destination.isEmpty { Section("Notification destination") { Text(model.destination) } }
                if model.connected { Button("Unregister and reset", role: .destructive) { Task { await model.reset() } }.disabled(model.busy) }
            }.navigationTitle("Push demo")
        }
    }
}
