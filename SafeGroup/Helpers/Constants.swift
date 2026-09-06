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
        // Paleta "fintech premium" en claro (tipo Trade Republic: fondo vainilla,
        // tarjetas casi blancas con sombra suave, verde vivo como color de accion).
        static let primary = UIColor(red: 0.00, green: 0.62, blue: 0.42, alpha: 1.0)        // Verde (CTA principal)
        static let primaryDark = UIColor(red: 0.00, green: 0.45, blue: 0.30, alpha: 1.0)
        static let accent = UIColor(red: 0.80, green: 0.56, blue: 0.02, alpha: 1.0)         // Dorado oscuro (rol Participante)
        static let background = UIColor(red: 0.97, green: 0.94, blue: 0.87, alpha: 1.0)    // Vainilla
        static let cardBackground = UIColor(red: 1.00, green: 0.99, blue: 0.97, alpha: 1.0) // Blanco calido (tarjetas elevadas)
        static let fieldBackground = UIColor(red: 1.00, green: 0.99, blue: 0.97, alpha: 1.0)
        static let textPrimary = UIColor(red: 0.09, green: 0.09, blue: 0.11, alpha: 1.0)
        static let textSecondary = UIColor(red: 0.45, green: 0.45, blue: 0.50, alpha: 1.0)
        static let cornerRadius: CGFloat = 14
    }

}
