import SwiftUI
import WebKit
import Combine

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var webView = WKWebView()
    @State private var cancellables = Set<AnyCancellable>()
    @ObservedObject var speechRecognizer = SpeechRecognizer.shared
    @ObservedObject var speechSynthesizer = SpeechSynthesizer.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack {
                    WebView(webView: webView, onReceiveMessage: handleMessage)
                }
                .navigationTitle("Voxed")
                .navigationBarTitleDisplayMode(NavigationBarItem.TitleDisplayMode.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            webView.reload()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .tint(colorScheme == .dark ? .white : .black)
                        }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gear")
                                .tint(colorScheme == .dark ? .white : .black)
                        }
                    }
                }
            }
        }
        .onAppear {
            setupSubscriptions()
        }
    }
    
    private func setupSubscriptions() {
        speechRecognizer.$isRecording.sink { isRecording in
            if isRecording {
                webView.evaluateJavaScript("window.showStopButton();")
            } else {
                webView.evaluateJavaScript("window.showRecordButton();")
            }
        }.store(in: &cancellables)
        
        speechSynthesizer.$isSpeaking.sink { isSpeaking in
            if isSpeaking {
                webView.evaluateJavaScript("window.showStopButton();")
            } else {
                webView.evaluateJavaScript("window.showRecordButton();")
            }
        }.store(in: &cancellables)
    }
    
    func handleMessage(_ message: WKScriptMessage) {
        if message.name == "startRecording" {
            speechRecognizer.startRecording { text in
                let escapedText = text.replacingOccurrences(of: "\"", with: "\\\"")
                webView.evaluateJavaScript("window.setTextFromApp(\"\(escapedText)\");")
            }
        } else if message.name == "startSpeaking" {
            speechSynthesizer.speak(text: message.body as? String ?? "")
        } else if message.name == "stopRecordingOrSpeaking" {
            if speechRecognizer.isRecording {
                speechRecognizer.stopRecording()
            } else if speechSynthesizer.isSpeaking {
                speechSynthesizer.stopSpeaking()
            }
        } else if message.name == "stopRecording" {
            if speechRecognizer.isRecording {
                speechRecognizer.stopRecording()
            }
        }
    }
}


struct WebView: UIViewRepresentable {
    var webView: WKWebView
    var onReceiveMessage: (WKScriptMessage) -> Void
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        webView.navigationDelegate = context.coordinator
        webView.configuration.userContentController.add(context.coordinator, name: "startRecording")
        webView.configuration.userContentController.add(context.coordinator, name: "startSpeaking")
        webView.configuration.userContentController.add(context.coordinator, name: "stopRecordingOrSpeaking")
        webView.configuration.userContentController.add(context.coordinator, name: "stopRecording")
        webView.load(URLRequest(url: URL(string: "https://chat.openai.com")!))
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {}
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebView
        
        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            guard let scriptPath = Bundle.main.path(forResource: "BridgeScript", ofType: "js"),
                  let scriptContent = try? String(contentsOfFile: scriptPath) else {
                return
            }
            guard let cssUrl = Bundle.main.url(forResource: "Styles", withExtension: "css"),
                  let cssContent = try? Data(contentsOf: cssUrl) else {
                return
            }
            let cssContentBase64 = cssContent.base64EncodedString()
            let cssInjectContent = "const style = document.createElement('style'); style.innerHTML = atob('\(cssContentBase64)'); document.head.appendChild(style); "
            webView.evaluateJavaScript(cssInjectContent + scriptContent)
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            parent.onReceiveMessage(message)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
