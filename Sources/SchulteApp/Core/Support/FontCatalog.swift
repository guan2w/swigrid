import CoreText
import Foundation

enum FontCatalog {
    static func registerAll() {
        register("Crasng.ttf")
        register("digital-7.ttf")
        register("Eras-Demi-ITC.ttf")
        register("SanvitoPro-LtDisp.otf")
    }

    private static func register(_ filename: String) {
        guard let url = Bundle.module.url(forResource: filename, withExtension: nil, subdirectory: "font") else {
            return
        }

        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }
}
