import Foundation

nonisolated enum QuranReciter: String, CaseIterable, Identifiable, Sendable {
    case alafasy = "alafasy"
    case sudais = "sudais"
    case maher = "maher"
    case husary = "husary"
    case minshawi = "minshawi"
    case ayoub = "ayoub"
    case abdulbasit = "abdulbasit"
    case yasseraldosari = "yasseraldosari"
    case shuraim = "shuraim"
    case ghamdi = "ghamdi"

    var id: String { rawValue }

    var everyAyahFolder: String {
        switch self {
        case .alafasy: return "Alafasy_128kbps"
        case .maher: return "MaherAlMuaiqly128kbps"
        case .husary: return "Husary_128kbps"
        case .minshawi: return "Minshawy_Murattal_128kbps"
        case .sudais: return "Abdurrahmaan_As-Sudais_192kbps"
        case .ayoub: return "Muhammad_Ayyoub_128kbps"
        case .abdulbasit: return "Abdul_Basit_Murattal_192kbps"
        case .yasseraldosari: return "Yasser_Ad-Dussary_128kbps"
        case .shuraim: return "Saood_ash-Shuraym_128kbps"
        case .ghamdi: return "Ghamadi_40kbps"
        }
    }

    var displayName: String {
        switch self {
        case .alafasy: return "Mishary Rashid Alafasy"
        case .maher: return "Maher Al-Muaiqly"
        case .husary: return "Mahmoud Khalil Al-Hussary"
        case .minshawi: return "Al-Minshawi"
        case .sudais: return "Abdur-Rahman As-Sudais"
        case .ayoub: return "Muhammad Ayyub"
        case .abdulbasit: return "Abdul Basit Abdul Samad"
        case .yasseraldosari: return "Yasser Al-Dosari"
        case .shuraim: return "Saud Ash-Shuraim"
        case .ghamdi: return "Saad Al-Ghamdi"
        }
    }

    var arabicName: String {
        switch self {
        case .alafasy: return "مشاري راشد العفاسي"
        case .maher: return "ماهر المعيقلي"
        case .husary: return "محمود خليل الحصري"
        case .minshawi: return "المنشاوي"
        case .sudais: return "عبدالرحمن السديس"
        case .ayoub: return "محمد أيوب"
        case .abdulbasit: return "عبدالباسط عبدالصمد"
        case .yasseraldosari: return "ياسر الدوسري"
        case .shuraim: return "سعود الشريم"
        case .ghamdi: return "سعد الغامدي"
        }
    }

    var isFree: Bool {
        switch self {
        case .alafasy, .sudais, .maher: return true
        default: return false
        }
    }
}
