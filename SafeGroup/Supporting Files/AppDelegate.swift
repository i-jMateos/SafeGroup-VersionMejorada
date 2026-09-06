//
//  AppDelegate.swift
//  SafeGroup
//
//  Created by Jordi Mateos Manchado on 11/11/2020.
//  Copyright © 2020 Jordi Mateos Manchado. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        FirebaseApp.configure()
        
        // Tema visual global de la app (estilo oscuro premium)
        UINavigationBar.appearance().tintColor = Constants.Theme.primary
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: Constants.Theme.textPrimary]
        UINavigationBar.appearance().barTintColor = Constants.Theme.background
        UINavigationBar.appearance().isTranslucent = false
        
        UITabBar.appearance().tintColor = Constants.Theme.primary
        UITabBar.appearance().unselectedItemTintColor = Constants.Theme.textSecondary
        UITabBar.appearance().barTintColor = Constants.Theme.background
        UITabBar.appearance().isTranslucent = false
        
        if let _ = Auth.auth().currentUser {
            if let userData = UserDefaults.standard.object(forKey: Constants.UserDefaults.currentUser) as? Data, let user = try? JSONDecoder().decode(User.self, from: userData) {
                User.setCurrent(user)
            }
            
            let mainController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
            window?.rootViewController = mainController
            window?.makeKeyAndVisible()
        } else {
            let mainController = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController()
            window?.rootViewController = mainController
            window?.makeKeyAndVisible()
        }
        
        return true
    }

}


// MARK: - Pestaña extra de emergencia, solo visible para el rol Guia

class GuideAlertViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = Constants.Theme.background
        title = "Alertas"
        
        if #available(iOS 13.0, *) {
            tabBarItem = UITabBarItem(title: "Alertas", image: UIImage(systemName: "exclamationmark.triangle.fill"), selectedImage: nil)
        } else {
            tabBarItem = UITabBarItem(title: "Alertas", image: nil, selectedImage: nil)
        }
        
        let infoLabel = UILabel()
        infoLabel.text = "Panel de Guía"
        infoLabel.font = .systemFont(ofSize: 22, weight: .bold)
        infoLabel.textColor = Constants.Theme.textPrimary
        infoLabel.textAlignment = .center
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let button = UIButton(type: .system)
        button.setTitle("Enviar alerta de emergencia", for: .normal)
        button.applyPrimaryStyle()
        button.backgroundColor = UIColor.systemRed
        button.layer.shadowColor = UIColor.systemRed.cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(sendAlertTapped), for: .touchUpInside)
        
        view.addSubview(infoLabel)
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            infoLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            infoLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 20),
            button.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 30),
            button.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -30)
        ])
        
        // Forzamos el calculo del layout ahora mismo: al añadir estas vistas por
        // codigo dentro de una pestaña de UITabBarController, a veces no se pintan
        // hasta el siguiente toque en pantalla si no se fuerza aqui.
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }
    
    @objc private func sendAlertTapped() {
        guard let firUser = Auth.auth().currentUser else { return }
        
        let db = Firestore.firestore()
        let ref = db.collection("emergency_alerts").document()
        let data: [String: Any] = [
            "id": ref.documentID,
            "message": "Alerta de emergencia enviada por el guia",
            "userEmail": firUser.email ?? "",
            "timestamp": Timestamp(date: Date())
        ]
        
        ref.setData(data) { error in
            DispatchQueue.main.async {
                let title = error == nil ? "Alerta enviada" : "No se pudo enviar"
                let message = error?.localizedDescription ?? "Se ha registrado la emergencia."
                let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - Tab Bar Controller con estilo distinto segun el rol del usuario

class MainTabBarController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyRoleStyle()
    }
    
    private func applyRoleStyle() {
        tabBar.unselectedItemTintColor = Constants.Theme.textSecondary
        tabBar.barTintColor = Constants.Theme.background
        tabBar.isTranslucent = false
        
        guard let role = User.currentUser?.role else { return }
        
        switch role {
        case .guia:
            // Estilo "pro": verde vivo, y una pestaña extra de alertas de emergencia.
            tabBar.tintColor = Constants.Theme.primary
            
            let alertViewController = GuideAlertViewController()
            if var controllers = self.viewControllers, !(controllers.contains(where: { $0 is GuideAlertViewController })) {
                controllers.append(alertViewController)
                self.viewControllers = controllers
            }
        case .participante:
            // Estilo mas calido, sin pestaña extra.
            tabBar.tintColor = Constants.Theme.accent
        }
    }
}
