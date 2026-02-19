import CoreText
import Foundation

enum FontCatalog {
    static func registerAll() {
        register("Crasng.ttf") // CrashNumberingGothic
        register("digital-7.ttf") // Digital-7MonoItalic
        register("Eras-Demi-ITC.ttf") // ErasITC-Demi
        register("SanvitoPro-LtDisp.otf") // SanvitoPro-LtDisp
    }

    private static func register(_ filename: String) {
        guard let url = Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "font") else {
            return
        }

        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
