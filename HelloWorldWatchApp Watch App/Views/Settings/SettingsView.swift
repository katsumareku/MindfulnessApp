import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = MeditationSettings()
    
    var body: some View {
        List {
            NavigationLink(destination: SoundPickerView(settings: settings)) {
                HStack {
                    Text("Default Sound")
                    Spacer()
                    Text(settings.currentSound.name)
                        .foregroundColor(.gray)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
            Section(header: Text("Display")) {
                Toggle("Dark Mode", isOn: .constant(false))
                    .disabled(true)
            }
            
            Section(header: Text("Notifications")) {
                Toggle("Session Reminders", isOn: .constant(false))
                    .disabled(true)
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("Settings")
    }
}
