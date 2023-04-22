import AVFoundation
import SwiftUI

class SpeechSynthesizer: NSObject, ObservableObject {
  @AppStorage("enableSpeaking") var enableSpeaking: Bool = true
  @AppStorage("speakingLanguage") var speakingLanguage: String = "en-US"
    
  @Published var isSpeaking: Bool = false
  static let shared = SpeechSynthesizer()
  private var speechSynthesizer: AVSpeechSynthesizer
  
  override init() {
    try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
    try? AVAudioSession.sharedInstance().setActive(true)
    speechSynthesizer = AVSpeechSynthesizer()
    super.init()
    speechSynthesizer.delegate = self
  }
  
  func speak(text: String) {
    guard !speechSynthesizer.isPaused else { return }
    guard enableSpeaking else { return }
    
    let utterance = AVSpeechUtterance(string: text)
    utterance.voice = .init(language: speakingLanguage)
    utterance.postUtteranceDelay = 0.3;
    
    let avSession = AVAudioSession.sharedInstance()
    try? avSession.setCategory(AVAudioSession.Category.playback, options: .mixWithOthers)
    
    speechSynthesizer.speak(utterance)
  }
  
  func stopSpeaking() {
    guard speechSynthesizer.isSpeaking else { return }
    speechSynthesizer.stopSpeaking(at: .immediate)
  }
}

extension SpeechSynthesizer: AVSpeechSynthesizerDelegate {
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
    isSpeaking = true
  }
  
  func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
    isSpeaking = false
  }
}
