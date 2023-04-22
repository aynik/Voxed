import SwiftUI

struct SettingsView: View {
  @AppStorage("listeningLanguage") var listeningLanguage: String = "en-US"
  @AppStorage("enableSpeaking") var enableSpeaking: Bool = true
  @AppStorage("speakingLanguage") var speakingLanguage: String = "en-US"
  
  var body: some View {
    NavigationView {
      Form {
          Section(header: Text("Listening Settings")) {
              listeningLanguagePicker()
          }
          Section(header: Text("Speaking Settings")) {
              speakingToggle()
              speakingLanguagePicker()
          }
      }
      .navigationBarTitleDisplayMode(.inline)
    }
  }
  
  // Listening language picker component
  private func listeningLanguagePicker() -> some View {
    Picker("Listening Language", selection: $listeningLanguage) {
      ForEach(SpeechLanguage.allCases) { language in
        Text(language.displayName).tag(language.rawValue)
      }
    }
  }
  
  // Text to speech toggle component
  private func speakingToggle() -> some View {
    Toggle(isOn: $enableSpeaking) {
      Text("Enable Speaking")
    }
  }
  
  // Speaking language picker component
  private func speakingLanguagePicker() -> some View {
    Picker("Speaking Language", selection: $speakingLanguage) {
      ForEach(SpeechLanguage.allCases) { language in
        Text(language.displayName).tag(language.rawValue)
      }
    }
  }
}
