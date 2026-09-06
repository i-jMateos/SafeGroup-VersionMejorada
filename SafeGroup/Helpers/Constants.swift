//
//  Constants.swift
//  SafeGroup
//
//  Created by jmateos on 5/1/21.
//  Copyright © 2021 Jordi Mateos Manchado. All rights reserved.
//

import UIKit

struct Constants {
    struct UserDefaults {
        static let currentUser = "currentUser"
    }

    struct Theme {
        // Paleta "fintech premium" (tipo apps bancarias: fondo oscuro, tarjetas
        // elevadas con sombra, verde vivo como color de accion principal).
        static let primary = UIColor(red: 0.00, green: 0.85, blue: 0.55, alpha: 1.0)        // Verde vivo (CTA principal)
        static let primaryDark = UIColor(red: 0.00, green: 0.60, blue: 0.38, alpha: 1.0)
        static let accent = UIColor(red: 0.98, green: 0.75, blue: 0.14, alpha: 1.0)         // Dorado (rol Participante)
        static let background = UIColor(red: 0.05, green: 0.05, blue: 0.07, alpha: 1.0)    // Fondo casi negro
        static let cardBackground = UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
        static let fieldBackground = UIColor(red: 0.11, green: 0.11, blue: 0.13, alpha: 1.0)
        static let textPrimary = UIColor.white
        static let textSecondary = UIColor(red: 0.60, green: 0.60, blue: 0.64, alpha: 1.0)
        static let cornerRadius: CGFloat = 14
    }

}
