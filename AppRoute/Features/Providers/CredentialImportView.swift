import SwiftUI
import UniformTypeIdentifiers

struct CredentialImportView: View {
    @Environment(AppSession.self) private var session
    @State private var isImporterPresented = false
    @State private var statusMessage: String?
    @State private var isBusy = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                ScreenHeader(
                    eyebrow: session.policy.providerKind?.displayName ?? "Credentials",
                    title: title,
                    subtitle: subtitle
                )

                if session.policy.providerKind == .nordManual {
                    nordForm
                } else {
                    importButton
                }

                if let statusMessage {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom) {
            Button(isBusy ? "Checking…" : "Validate and continue") {
                Task { await validate() }
            }
            .buttonStyle(.glassProminent)
            .disabled(isBusy)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Credentials")
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [UTType.plainText, UTType.data, UTType.item]
        ) { result in
            Task { await importFile(result) }
        }
    }

    private var title: String {
        switch session.policy.providerKind {
        case .nordManual:
            "Nord service credentials"
        case .openVPN:
            "Import an OpenVPN profile"
        case .wireGuard:
            "Import a WireGuard config"
        case .none:
            "Add credentials"
        }
    }

    private var subtitle: String {
        switch session.policy.providerKind {
        case .nordManual:
            "Use the service username and password from Nord's manual setup, not your account login. AppRoute is compatible with NordVPN manual configurations — it is not an official NordVPN integration. NordLynx is out of scope."
        case .openVPN:
            "Choose a .ovpn file. AppRoute parses remote, protocol, and metadata on device. A full OpenVPN handshake is not wired into the V1 tunnel."
        case .wireGuard:
            "Choose a .conf file. The private key is stored only in Keychain and is never logged."
        case .none:
            "Choose a provider first."
        }
    }

    private var nordForm: some View {
        @Bindable var session = session
        return VStack(alignment: .leading, spacing: 12) {
            TextField("Service username", text: $session.nordUsername)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            SecureField("Service password", text: $session.nordPassword)
                .textContentType(.password)
            Text("Account emails are rejected on purpose. Nord's manual IKEv2/OpenVPN credentials look like a service username, not an email address.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(.background.secondary, in: .rect(cornerRadius: 20))
    }

    private var importButton: some View {
        Button("Choose file") {
            isImporterPresented = true
        }
        .buttonStyle(.glass)
    }

    private func importFile(_ result: Result<URL, Error>) async {
        do {
            let url = try result.get()
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
            let data = try Data(contentsOf: url)
            guard let kind = session.policy.providerKind else { return }
            let input: ProviderCredentialInput
            switch kind {
            case .nordManual:
                throw AppRouteError.invalidCredentialInput
            case .openVPN:
                input = .openVPNFile(data)
            case .wireGuard:
                input = .wireGuardFile(data)
            }
            try await session.provider(for: kind).importCredentials(input)
            statusMessage = "Imported on this iPhone. Secrets stay in Keychain."
            errorMessage = nil
        } catch let error as AppRouteError {
            errorMessage = error.userFacingMessage
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func validate() async {
        isBusy = true
        defer { isBusy = false }
        do {
            guard let kind = session.policy.providerKind else { return }
            let provider = session.provider(for: kind)
            if kind == .nordManual {
                try await provider.importCredentials(
                    .nordService(username: session.nordUsername, password: session.nordPassword)
                )
            }
            try await provider.validateCredentials()
            session.record(.credentialsValidated)
            errorMessage = nil
            session.onboardingPath.append(.serverPicker)
        } catch let error as AppRouteError {
            errorMessage = error.userFacingMessage
            session.lastError = error
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
