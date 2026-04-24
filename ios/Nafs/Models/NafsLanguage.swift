import SwiftUI

nonisolated enum NafsLanguage: String, Sendable {
    case english = "en"
    case arabic = "ar"

    static var current: NafsLanguage {
        let saved = UserDefaults.standard.string(forKey: "nafs_language") ?? "en"
        return NafsLanguage(rawValue: saved) ?? .english
    }

    static func save(_ language: NafsLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: "nafs_language")
    }

    var isArabic: Bool { self == .arabic }
    var isRTL: Bool { self == .arabic }
    var layoutDirection: LayoutDirection { isRTL ? .rightToLeft : .leftToRight }
}

@Observable
@MainActor
class LanguageManager {
    var current: NafsLanguage = NafsLanguage.current

    func switchTo(_ language: NafsLanguage) {
        NafsLanguage.save(language)
        current = language
    }

    var isArabic: Bool { current.isArabic }
    var layoutDirection: LayoutDirection { current.layoutDirection }
}

enum L10n {
    static func text(_ english: String, _ arabic: String) -> String {
        NafsLanguage.current.isArabic ? arabic : english
    }
}

struct LocalizedText {
    let en: String
    let ar: String

    func value(for lang: NafsLanguage) -> String {
        lang.isArabic ? ar : en
    }

    var localized: String {
        NafsLanguage.current.isArabic ? ar : en
    }
}

enum NafsStrings {
    static let assalamuAlaikum = LocalizedText(en: "Assalamu Alaikum", ar: "السلام عليكم")
    static let hasanatBalance = LocalizedText(en: "HASANAT BALANCE", ar: "رصيد الحسنات")
    static let currentStreak = LocalizedText(en: "Current Streak", ar: "السلسلة الحالية")
    static let prayerTimes = LocalizedText(en: "Prayer Times", ar: "مواقيت الصلاة")
    static let quickLog = LocalizedText(en: "Quick Log", ar: "تسجيل سريع")
    static let gardenOfDeeds = LocalizedText(en: "Garden of Deeds", ar: "حديقة الأعمال")
    static let days = LocalizedText(en: "days", ar: "أيام")
    static let day = LocalizedText(en: "day", ar: "يوم")
    static let hasanat = LocalizedText(en: "Hasanat", ar: "حسنات")

    static let fajr = LocalizedText(en: "Fajr", ar: "الفجر")
    static let dhuhr = LocalizedText(en: "Dhuhr", ar: "الظهر")
    static let asr = LocalizedText(en: "Asr", ar: "العصر")
    static let maghrib = LocalizedText(en: "Maghrib", ar: "المغرب")
    static let isha = LocalizedText(en: "Isha", ar: "العشاء")

    static func prayerName(_ prayer: PrayerName) -> String {
        switch prayer {
        case .fajr: return fajr.localized
        case .dhuhr: return dhuhr.localized
        case .asr: return asr.localized
        case .maghrib: return maghrib.localized
        case .isha: return isha.localized
        }
    }

    static let tabHome = LocalizedText(en: "Home", ar: "الرئيسية")
    static let tabQuran = LocalizedText(en: "Quran", ar: "القرآن")
    static let tabHabits = LocalizedText(en: "Habits", ar: "العبادات")
    static let tabFocus = LocalizedText(en: "Focus", ar: "التركيز")
    static let tabNafsAI = LocalizedText(en: "Nafs AI", ar: "نفس AI")
    static let tabMore = LocalizedText(en: "More", ar: "المزيد")

    static let logHabits = LocalizedText(en: "Log Habits", ar: "تسجيل العبادات")
    static let prayer = LocalizedText(en: "Prayer", ar: "الصلاة")
    static let fardSalahOnTime = LocalizedText(en: "Fard Salah on time", ar: "صلاة الفريضة في وقتها")
    static let quran10Min = LocalizedText(en: "Quran (10 min)", ar: "القرآن (١٠ دقائق)")
    static let dhikrSession = LocalizedText(en: "Dhikr session (100)", ar: "جلسة ذكر")
    static let log = LocalizedText(en: "Log", ar: "سجّل")

    static let features = LocalizedText(en: "Features", ar: "المميزات")
    static let growth = LocalizedText(en: "Growth", ar: "النمو")
    static let guidedPlans = LocalizedText(en: "Guided Plans", ar: "الخطط الإرشادية")
    static let sendDua = LocalizedText(en: "Send a Du'a", ar: "أرسل دعاء")
    static let appBlocker = LocalizedText(en: "App Blocker", ar: "حاجب التطبيقات")
    static let circles = LocalizedText(en: "Circles", ar: "الحلقات")
    static let progress = LocalizedText(en: "Progress", ar: "التقدم")
    static let fajrAlarm = LocalizedText(en: "Fajr Alarm", ar: "منبه الفجر")
    static let settings = LocalizedText(en: "Settings", ar: "الإعدادات")
    static let muhasabah = LocalizedText(en: "Muhasabah", ar: "المحاسبة")
    static let qiblaFinder = LocalizedText(en: "Qibla Finder", ar: "اتجاه القبلة")
    static let dhikr = LocalizedText(en: "Dhikr", ar: "ذكر")
    static let hasanatWallet = LocalizedText(en: "Hasanat Wallet", ar: "محفظة الحسنات")
    static let myJourney = LocalizedText(en: "My Journey", ar: "رحلتي")

    static let profile = LocalizedText(en: "Profile", ar: "الملف الشخصي")
    static let notifications = LocalizedText(en: "Notifications", ar: "الإشعارات")
    static let language = LocalizedText(en: "Language", ar: "اللغة")
    static let app = LocalizedText(en: "App", ar: "التطبيق")
    static let account = LocalizedText(en: "Account", ar: "الحساب")
    static let about = LocalizedText(en: "About", ar: "حول التطبيق")
    static let rateNafs = LocalizedText(en: "Rate Nafs", ar: "قيّم نفس")
    static let shareNafs = LocalizedText(en: "Share Nafs", ar: "شارك نفس")
    static let darkMode = LocalizedText(en: "Dark Mode", ar: "الوضع الليلي")
    static let comingSoon = LocalizedText(en: "Coming soon", ar: "قريباً")

    static let startFreeTrial = LocalizedText(en: "Start My Free Trial", ar: "ابدأ تجربتك المجانية")
    static let sevenDaysFree = LocalizedText(en: "7 days free. Cancel anytime.", ar: "٧ أيام مجاناً. إلغاء في أي وقت.")
    static let mostPopular = LocalizedText(en: "Most Popular", ar: "الأكثر شعبية")
    static let restorePurchases = LocalizedText(en: "Restore purchases", ar: "استعادة المشتريات")

    static let continueReading = LocalizedText(en: "Continue Reading", ar: "متابعة القراءة")
    static let bookmarks = LocalizedText(en: "Bookmarks", ar: "الإشارات المرجعية")
    static let chooseReciter = LocalizedText(en: "Choose Reciter", ar: "اختر القارئ")
    static let searchSurah = LocalizedText(en: "Search surah name or number", ar: "ابحث عن اسم السورة أو رقمها")
    static let loadingSurah = LocalizedText(en: "Loading Surah...", ar: "جارٍ تحميل السورة...")
    static let retry = LocalizedText(en: "Retry", ar: "إعادة المحاولة")

    static let onboardingHookTitle1 = LocalizedText(en: "What if one app could strengthen ", ar: "ماذا لو كان تطبيق واحد يقوّي ")
    static let onboardingHookEveryPart = LocalizedText(en: "every part", ar: "كل جزء")
    static let onboardingHookTitle2 = LocalizedText(en: " of your deen?", ar: " من دينك؟")
    static let onboardingHookBody = LocalizedText(en: "Quran. Prayer. Dhikr. Accountability. Knowledge. All in one place — working together.", ar: "القرآن. الصلاة. الذكر. المحاسبة. العلم. كلها في مكان واحد — تعمل معاً.")
    static let showMe = LocalizedText(en: "Show me \u{2192}", ar: "\u{2190} أرني")

    static let insight1Title = LocalizedText(en: "Muslims today are more connected to their phones than to their deen.", ar: "المسلمون اليوم أكثر اتصالاً بهواتفهم من دينهم.")
    static let insight1Body = LocalizedText(en: "The average Muslim spends 6 hours on their phone daily — but less than 20 minutes on ibadah.", ar: "المسلم العادي يقضي ٦ ساعات يومياً على هاتفه — وأقل من ٢٠ دقيقة في العبادة.")
    static let insight1Card = LocalizedText(en: "Nafs was built to flip that equation.", ar: "نفس بُني لقلب هذه المعادلة.")
    static let thatEndsToday = LocalizedText(en: "That ends today \u{2192}", ar: "\u{2190} ينتهي هذا اليوم")

    static let deenAreasTitle = LocalizedText(en: "What areas of your deen do\nyou want to strengthen?", ar: "ما جوانب دينك التي\nتريد تقويتها؟")
    static let selectAllApply = LocalizedText(en: "Select all that apply", ar: "اختر كل ما ينطبق")
    static let continueBtn = LocalizedText(en: "Continue", ar: "متابعة")

    static let salahTitle = LocalizedText(en: "How would you describe your\nrelationship with Salah right now?", ar: "كيف تصف علاقتك\nبالصلاة الآن؟")
    static let quranTitle = LocalizedText(en: "How is your relationship\nwith the Quran?", ar: "كيف علاقتك\nبالقرآن؟")
    static let knowledgeTitle = LocalizedText(en: "What Islamic knowledge do\nyou want to explore?", ar: "ما العلم الإسلامي الذي\nتريد استكشافه؟")
    static let phoneTitle = LocalizedText(en: "How does your phone\naffect your deen?", ar: "كيف يؤثر هاتفك\nعلى دينك؟")
    static let challengeTitle = LocalizedText(en: "What is your biggest spiritual\nchallenge right now?", ar: "ما أكبر تحدٍّ روحي\nتواجهه الآن؟")
    static let featuresTitle = LocalizedText(en: "Which Nafs features\nexcite you most?", ar: "ما مميزات نفس التي\nتحمسك أكثر؟")
    static let strictnessTitle = LocalizedText(en: "How strict do you want Nafs\nto be with your screen time?", ar: "ما مدى صرامة نفس التي\nتريدها مع وقت الشاشة؟")

    static let nameTitle = LocalizedText(en: "What should we call you?", ar: "ماذا نناديك؟")
    static let nameSubtitle = LocalizedText(en: "Nafs is personal. So is your journey.", ar: "نفس شخصي. وكذلك رحلتك.")
    static let nameField = LocalizedText(en: "Your first name", ar: "اسمك الأول")

    static let locationTitle = LocalizedText(en: "Allow Nafs to find\nyour prayer times", ar: "اسمح لنفس بإيجاد\nمواقيت صلاتك")
    static let locationBody = LocalizedText(en: "Nafs uses your location only to calculate accurate prayer times for your exact city. Your location is never stored, never shared, and never leaves your device.", ar: "يستخدم نفس موقعك فقط لحساب مواقيت صلاة دقيقة لمدينتك. لن يتم تخزين أو مشاركة موقعك أبداً.")
    static let locationGranted = LocalizedText(en: "Location access granted", ar: "تم منح صلاحية الموقع")
    static let allowLocation = LocalizedText(en: "Allow Location Access", ar: "السماح بالوصول للموقع")
    static let skipForNow = LocalizedText(en: "Skip for now", ar: "تخطي الآن")

    static let jazakAllah = LocalizedText(en: "JazakAllah Khair", ar: "جزاك الله خيراً")
    static let personalizedReady = LocalizedText(en: "Your complete Islamic companion is ready.", ar: "رفيقك الإسلامي الشامل جاهز.")
    static let buildMyPlan = LocalizedText(en: "Build my plan \u{2192}", ar: "\u{2190} ابنِ خطتي")
    static let personalizedBullet1 = LocalizedText(en: "Strengthening your Salah & Quran connection", ar: "تقوية صلتك بالصلاة والقرآن")
    static let personalizedBullet2 = LocalizedText(en: "Answering your Islamic questions with Nafs AI", ar: "الإجابة على أسئلتك الإسلامية مع نفس AI")
    static let personalizedBullet3 = LocalizedText(en: "Helping you use your time the way Allah intended", ar: "مساعدتك في استخدام وقتك كما أراد الله")

    static let loadingText1 = LocalizedText(en: "Building your personal Islamic plan...", ar: "نبني خطتك الإسلامية الشخصية...")
    static let loadingText2 = LocalizedText(en: "Calculating your spiritual profile...", ar: "نحسب ملفك الروحي...")
    static let loadingText3 = LocalizedText(en: "Preparing your Quran journey...", ar: "نجهز رحلتك مع القرآن...")
    static let loadingText4 = LocalizedText(en: "Setting up your Nafs companion...", ar: "نجهز رفيقك نفس...")

    static let scoreTitle = LocalizedText(en: "Your Islamic Life Assessment, ", ar: "تقييم حياتك الإسلامية، ")
    static let deenStrength = LocalizedText(en: "Your Deen Strength Score", ar: "مقياس قوة دينك")

    static let insight2Stat = LocalizedText(en: "1st", ar: "أول")
    static let insight2Label = LocalizedText(en: "thing asked about", ar: "شيء يُسأل عنه")
    static let insight2Sub = LocalizedText(en: "Salah is the first thing you will be asked about on the Day of Judgment", ar: "الصلاة أول ما يُحاسب عليه العبد يوم القيامة")
    static let insight2Quote = LocalizedText(en: "The first thing the servant will be accountable for on the Day of Resurrection is the prayer.", ar: "أول ما يحاسب عليه العبد يوم القيامة الصلاة.")
    static let insight2Attr = LocalizedText(en: "Sunan an-Nasa'i", ar: "سنن النسائي")
    static let iWantBetterSalah = LocalizedText(en: "I want better Salah \u{2192}", ar: "\u{2190} أريد صلاة أفضل")

    static let insight3Stat = LocalizedText(en: "24/7", ar: "٢٤/٧")
    static let insight3Label = LocalizedText(en: "Islamic scholar", ar: "عالم إسلامي")
    static let insight3Sub = LocalizedText(en: "Nafs AI is your personal Islamic companion available around the clock", ar: "نفس AI رفيقك الإسلامي الشخصي المتاح على مدار الساعة")
    static let insight3Quote = LocalizedText(en: "Seeking knowledge is an obligation upon every Muslim.", ar: "طلب العلم فريضة على كل مسلم.")
    static let insight3Attr = LocalizedText(en: "Sunan Ibn Majah", ar: "سنن ابن ماجه")
    static let iNeedThis = LocalizedText(en: "I need this \u{2192}", ar: "\u{2190} أحتاج هذا")

    static let paywallReady = LocalizedText(en: "Your complete Islamic\ncompanion is ready.", ar: "رفيقك الإسلامي\nالشامل جاهز.")
    static let seePricing = LocalizedText(en: "See pricing \u{2192}", ar: "\u{2190} شاهد الأسعار")
    static let seeMyPlan = LocalizedText(en: "See my plan \u{2192}", ar: "\u{2190} شاهد خطتي")
    static let continueFreePlan = LocalizedText(en: "Continue with free plan", ar: "متابعة بالخطة المجانية")
    static let subscribeNow = LocalizedText(en: "Subscribe Now", ar: "اشترك الآن")
    static let nafsPremium = LocalizedText(en: "Nafs Premium", ar: "نفس بريميوم")
    static let planExpires = LocalizedText(en: "Your personalized plan is ready.", ar: "خطتك الشخصية جاهزة.")
    static let afterThat = LocalizedText(en: "Start today and take control of your time.", ar: "ابدأ اليوم وتحكم بوقتك.")
    static let coffeeCompare1 = LocalizedText(en: "A coffee is $5.", ar: "القهوة بـ ٥ دولارات.")
    static let coffeeCompare3 = LocalizedText(en: "One costs you time. The other gives it back.", ar: "واحدة تأخذ وقتك. والأخرى تعيده لك.")
    static let everyDayWithout = LocalizedText(en: "Every day without Nafs is another day your phone wins.\nYou've already done the hard part — you showed up.", ar: "كل يوم بدون نفس هو يوم آخر يفوز فيه هاتفك.\nلقد فعلت الجزء الصعب — أنت هنا.")
    static let cancelAnytime = LocalizedText(en: "Cancel anytime from Settings.", ar: "إلغاء في أي وقت من الإعدادات.")
    static let sevenDaysNoCharge = LocalizedText(en: "7-day free trial, then $39.99/year. Auto-renews. Cancel anytime.", ar: "تجربة مجانية ٧ أيام، ثم ٣٩.٩٩$/سنة. يتجدد تلقائياً. إلغاء في أي وقت.")
    static let trialDisclosure = LocalizedText(en: "After the 7-day free trial, your subscription auto-renews at $39.99/year unless canceled at least 24 hours before the end of the trial period.", ar: "بعد التجربة المجانية لمدة ٧ أيام، يتجدد اشتراكك تلقائياً بسعر ٣٩.٩٩$/سنة ما لم يتم الإلغاء قبل ٢٤ ساعة على الأقل من نهاية فترة التجربة.")
    static let subscriptionTerms = LocalizedText(en: "Payment will be charged to your Apple ID account at confirmation of purchase. Subscription automatically renews unless it is canceled at least 24 hours before the end of the current period.", ar: "سيتم خصم المبلغ من حساب Apple ID الخاص بك عند تأكيد الشراء. يتجدد الاشتراك تلقائياً ما لم يتم إلغاؤه قبل ٢٤ ساعة على الأقل من نهاية الفترة الحالية.")
    static let privacyPolicy = LocalizedText(en: "Privacy Policy", ar: "سياسة الخصوصية")
    static let termsOfUse = LocalizedText(en: "Terms of Use", ar: "شروط الاستخدام")
    static let freeTitle = LocalizedText(en: "Free", ar: "مجاني")
    static let justATaste = LocalizedText(en: "Just a taste", ar: "مجرد تذوق")
    static let premiumTitle = LocalizedText(en: "Premium", ar: "بريميوم")
    static let completeDeen = LocalizedText(en: "Your complete deen companion", ar: "رفيقك الكامل في الدين")
    static let masjidQuote = LocalizedText(en: "Like sitting outside a masjid, hearing the adhan but unable to enter.", ar: "كأنك تجلس خارج المسجد، تسمع الأذان ولا تستطيع الدخول.")

    static let trustNoData = LocalizedText(en: "No data ever sold. Everything stays on your device.", ar: "لا بيع للبيانات أبداً. كل شيء يبقى على جهازك.")
    static let trustReminder = LocalizedText(en: "We'll remind you 24 hours before your trial ends.", ar: "سنذكرك قبل ٢٤ ساعة من انتهاء تجربتك.")
    static let trustCancel = LocalizedText(en: "Cancel anytime in 10 seconds from Settings.", ar: "إلغاء في أي وقت خلال ١٠ ثوانٍ من الإعدادات.")
    static let trustJoin = LocalizedText(en: "Built for Muslims who want to reclaim their time.", ar: "صُمم للمسلمين الذين يريدون استعادة وقتهم.")
    static let trustBuilt = LocalizedText(en: "Built by Muslims, for Muslims — with one goal: help you strengthen every part of your deen.", ar: "بُني بواسطة مسلمين، للمسلمين — بهدف واحد: مساعدتك في تقوية كل جزء من دينك.")
    static let trustBeAmong = LocalizedText(en: "Strengthen your deen with a complete Islamic companion.", ar: "قوّي دينك مع رفيق إسلامي شامل.")

    static let weeklyTitle = LocalizedText(en: "Weekly", ar: "أسبوعي")
    static let monthlyTitle = LocalizedText(en: "Monthly", ar: "شهري")
    static let yearlyTitle = LocalizedText(en: "Yearly", ar: "سنوي")
    static let tryItOut = LocalizedText(en: "Try it out", ar: "جرّبه")
    static let lessThanWeek = LocalizedText(en: "Less than $0.77/week", ar: "أقل من ٠.٧٧$/أسبوع")
    static let sevenDayTrial = LocalizedText(en: "7-day free trial", ar: "تجربة مجانية ٧ أيام")
    static let perWeek = LocalizedText(en: "/week", ar: "/أسبوع")
    static let perMonth = LocalizedText(en: "/month", ar: "/شهر")
    static let perYear = LocalizedText(en: "/year", ar: "/سنة")
    static let restoringText = LocalizedText(en: "Restoring...", ar: "جارٍ الاستعادة...")

    static let playFromAyah = LocalizedText(en: "Play from here", ar: "شغّل من هنا")
    static let askNafsAI = LocalizedText(en: "Ask Nafs AI", ar: "اسأل نفس AI")
    static let bookmarked = LocalizedText(en: "Bookmarked", ar: "تم الحفظ")
    static let bookmark = LocalizedText(en: "Bookmark", ar: "حفظ")

    static let deenSalah = LocalizedText(en: "My Salah consistency", ar: "انتظامي في الصلاة")
    static let deenQuran = LocalizedText(en: "My connection with the Quran", ar: "صلتي بالقرآن")
    static let deenDhikr = LocalizedText(en: "My dhikr and remembrance of Allah", ar: "ذكري وتذكري لله")
    static let deenKnowledge = LocalizedText(en: "My knowledge of Islam", ar: "معرفتي بالإسلام")
    static let deenScreentime = LocalizedText(en: "My relationship with my phone and screen time", ar: "علاقتي بهاتفي ووقت الشاشة")
    static let deenDiscipline = LocalizedText(en: "My spiritual discipline and nafs", ar: "انضباطي الروحي ونفسي")
    static let deenAccountability = LocalizedText(en: "My accountability with family and friends", ar: "محاسبتي مع العائلة والأصدقاء")
    static let deenAll = LocalizedText(en: "All of the above", ar: "كل ما سبق")

    static let salahAll5 = LocalizedText(en: "Alhamdulillah — I pray all 5 consistently", ar: "الحمد لله — أصلي الخمس بانتظام")
    static let salahMost = LocalizedText(en: "I pray most prayers but struggle with some", ar: "أصلي معظم الصلوات لكن أعاني مع بعضها")
    static let salahSometimes = LocalizedText(en: "I pray sometimes but want to be more consistent", ar: "أصلي أحياناً لكن أريد أن أكون أكثر انتظاماً")
    static let salahDrifted = LocalizedText(en: "I have drifted and want to come back", ar: "ابتعدت وأريد العودة")
    static let salahNew = LocalizedText(en: "I am new to Islam and learning", ar: "أنا جديد في الإسلام وأتعلم")

    static let quranDaily = LocalizedText(en: "I read daily — I want to go deeper", ar: "أقرأ يومياً — أريد التعمق أكثر")
    static let quranSometimes = LocalizedText(en: "I read sometimes but want more consistency", ar: "أقرأ أحياناً لكن أريد المزيد من الانتظام")
    static let quranRarely = LocalizedText(en: "I rarely read — I want to build this habit", ar: "نادراً ما أقرأ — أريد بناء هذه العادة")
    static let quranMemorize = LocalizedText(en: "I want to memorize more Quran", ar: "أريد حفظ المزيد من القرآن")
    static let quranStarting = LocalizedText(en: "I am just starting my Quran journey", ar: "بدأت للتو رحلتي مع القرآن")

    static let knTafsir = LocalizedText(en: "Tafsir — understanding the Quran deeply", ar: "التفسير — فهم القرآن بعمق")
    static let knHadith = LocalizedText(en: "Hadith — the teachings of the Prophet \u{FDFA}", ar: "الحديث — تعاليم النبي \u{FDFA}")
    static let knHistory = LocalizedText(en: "Islamic history — the Sahaba and scholars", ar: "التاريخ الإسلامي — الصحابة والعلماء")
    static let knFiqh = LocalizedText(en: "Fiqh — Islamic rulings for daily life", ar: "الفقه — الأحكام الشرعية للحياة اليومية")
    static let knSeerah = LocalizedText(en: "Seerah — the life of the Prophet \u{FDFA}", ar: "السيرة — حياة النبي \u{FDFA}")
    static let knAqeedah = LocalizedText(en: "Aqeedah — Islamic belief and creed", ar: "العقيدة — الإيمان والمعتقد الإسلامي")

    static let phoneDistract = LocalizedText(en: "My phone distracts me from prayer", ar: "هاتفي يشتتني عن الصلاة")
    static let phoneScrolling = LocalizedText(en: "I spend hours scrolling when I should be doing ibadah", ar: "أقضي ساعات في التصفح بدل العبادة")
    static let phoneFine = LocalizedText(en: "My phone is mostly fine — I want other features", ar: "هاتفي لا بأس — أريد مميزات أخرى")
    static let phoneIntentional = LocalizedText(en: "I want to use my phone more intentionally for my deen", ar: "أريد استخدام هاتفي بشكل أكثر نية لديني")

    static let challengeConsistency = LocalizedText(en: "Consistency — I start strong then fall off", ar: "الاستمرارية — أبدأ بقوة ثم أتوقف")
    static let challengeKnowledge = LocalizedText(en: "Knowledge — I want to understand Islam better", ar: "العلم — أريد فهم الإسلام بشكل أفضل")
    static let challengeConnection = LocalizedText(en: "Connection — I feel distant from Allah", ar: "الصلة — أشعر بالبعد عن الله")
    static let challengeDiscipline = LocalizedText(en: "Discipline — my nafs controls me more than I control it", ar: "الانضباط — نفسي تتحكم بي أكثر مما أتحكم بها")
    static let challengeCommunity = LocalizedText(en: "Community — I lack Islamic accountability in my life", ar: "المجتمع — أفتقر للمحاسبة الإسلامية في حياتي")
    static let challengeBalance = LocalizedText(en: "Balance — managing deen and dunya together", ar: "التوازن — إدارة الدين والدنيا معاً")

    static let featureScreentime = LocalizedText(en: "Earning screen time through ibadah", ar: "كسب وقت الشاشة من خلال العبادة")
    static let featureQuranReader = LocalizedText(en: "Full Quran reader with beautiful reciters", ar: "قارئ القرآن الكامل مع قراء رائعين")
    static let featureAI = LocalizedText(en: "Nafs AI — personal Islamic companion", ar: "نفس AI — رفيقك الإسلامي الشخصي")
    static let featureGarden = LocalizedText(en: "Garden of Deeds — watching my worship come to life", ar: "حديقة الأعمال — مشاهدة عبادتي تنبض بالحياة")
    static let featureCircles = LocalizedText(en: "Circles — accountability with family and friends", ar: "الحلقات — المحاسبة مع العائلة والأصدقاء")
    static let featurePlans = LocalizedText(en: "Guided spiritual plans for life challenges", ar: "خطط روحية إرشادية لتحديات الحياة")
    static let featureMuhasabah = LocalizedText(en: "Daily Muhasabah journal", ar: "دفتر المحاسبة اليومي")
    static let featurePrayerQibla = LocalizedText(en: "Prayer times and Qibla finder", ar: "مواقيت الصلاة واتجاه القبلة")

    static let strictGentle = LocalizedText(en: "Gentle — just reminders and tracking", ar: "لطيف — فقط تذكيرات وتتبع")
    static let strictBalanced = LocalizedText(en: "Balanced — soft limits with token rewards", ar: "متوازن — حدود مرنة مع مكافآت")
    static let strictStrict = LocalizedText(en: "Strict — real app blocking, I need accountability", ar: "صارم — حجب حقيقي للتطبيقات، أحتاج محاسبة")
    static let strictMaximum = LocalizedText(en: "Maximum — lock me out until I complete my ibadah", ar: "أقصى — اقفلني حتى أكمل عبادتي")

    static let trees = LocalizedText(en: "Trees", ar: "أشجار")
    static let flowers = LocalizedText(en: "Flowers", ar: "أزهار")
    static let orbs = LocalizedText(en: "Orbs", ar: "أضواء")
    static let blooms = LocalizedText(en: "Blooms", ar: "ازدهار")
    static let view = LocalizedText(en: "View →", ar: "عرض ←")

    static let startStreakToday = LocalizedText(en: "Start your streak today", ar: "ابدأ سلسلتك اليوم")
    static let keepItGoing = LocalizedText(en: "Keep it going!", ar: "واصل!")

    static let salah = LocalizedText(en: "Salah", ar: "صلاة")
    static let quranLabel = LocalizedText(en: "Quran", ar: "القرآن")
    static let dhikrLabel = LocalizedText(en: "Dhikr", ar: "ذكر")

    static let subscription = LocalizedText(en: "Subscription", ar: "الاشتراك")
    static let replayOnboarding = LocalizedText(en: "Replay Onboarding", ar: "إعادة التعريف")
    static let languageChanged = LocalizedText(en: "Language changed. Please restart the app for full effect.", ar: "تم تغيير اللغة. يرجى إعادة تشغيل التطبيق.")
}
