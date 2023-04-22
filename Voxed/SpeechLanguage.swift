enum SpeechLanguage: String, CaseIterable, Identifiable {
  case enUS = "en-US"
  case esES = "es-ES"
  case jaJP = "ja-JP"
  case frFR = "fr-FR"
  case deDE = "de-DE"
  case zhCN = "zh-CN"
  case ruRU = "ru-RU"
  case itIT = "it-IT"
  case ptBR = "pt-BR"
  case arSA = "ar-SA"
  
  var id: String {
    self.rawValue
  }
  
  var displayName: String {
    switch self {
    case .enUS:
      return "English (US)"
    case .esES:
      return "Español (ES)"
    case .jaJP:
      return "日本語 (JP)"
    case .frFR:
      return "Français (FR)"
    case .deDE:
      return "Deutsch (DE)"
    case .zhCN:
      return "中文 (CN)"
    case .ruRU:
      return "Русский (RU)"
    case .itIT:
      return "Italiano (IT)"
    case .ptBR:
      return "Português (BR)"
    case .arSA:
      return "العربية (SA)"
    }
  }
}
