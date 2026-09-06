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

// MARK: - Pantallas de detalle del menu de Perfil (Mi cuenta / Identificacion / Preferencias / Ayuda)

enum ProfileMenuKind {
    case myAccount
    case identification
    case preferences
    case help
}

class ProfileMenuDetailViewController: UIViewController {

    var kind: ProfileMenuKind = .myAccount
    var roleColor: UIColor = Constants.Theme.primary
    var roleText: String = ""
    var firstname: String = ""
    var lastname: String = ""
    var email: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Constants.Theme.background
        title = screenTitle()
        buildContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // La pestaña de Perfil oculta la barra de navegacion; aqui la
        // volvemos a mostrar para poder volver atras.
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func screenTitle() -> String {
        switch kind {
        case .myAccount: return "Mi cuenta"
        case .identification: return "Identificación"
        case .preferences: return "Preferencias"
        case .help: return "Ayuda"
        }
    }

    private func buildContent() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 16
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.topAnchor),
            content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        switch kind {
        case .myAccount:
            content.addArrangedSubview(makeInfoField(label: "Nombre", value: firstname))
            content.addArrangedSubview(makeInfoField(label: "Apellido", value: lastname))
            content.addArrangedSubview(makeInfoField(label: "Email", value: email))

            let changePasswordButton = UIButton(type: .system)
            changePasswordButton.setTitle("Cambiar contraseña", for: .normal)
            changePasswordButton.applyPrimaryStyle()
            changePasswordButton.backgroundColor = roleColor
            changePasswordButton.addTarget(self, action: #selector(changePasswordTapped), for: .touchUpInside)
            content.addArrangedSubview(changePasswordButton)

        case .identification:
            content.addArrangedSubview(makeInfoField(label: "Rol", value: roleText))
            content.addArrangedSubview(makeInfoField(label: "Identificador de usuario", value: Auth.auth().currentUser?.uid ?? "-"))
            if let creationDate = Auth.auth().currentUser?.metadata.creationDate {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                content.addArrangedSubview(makeInfoField(label: "Miembro desde", value: formatter.string(from: creationDate)))
            }

        case .preferences:
            content.addArrangedSubview(makeSwitchRow(
                title: "Avisos dentro de la app",
                subtitle: "Muestra las alertas mientras la app está abierta",
                isOn: UserDefaults.standard.object(forKey: "pref_inapp_alerts_enabled") == nil ? true : UserDefaults.standard.bool(forKey: "pref_inapp_alerts_enabled")
            ))
            content.addArrangedSubview(makeInfoField(label: "Idioma", value: "Español"))

        case .help:
            let faqs: [(String, String)] = [
                ("¿Cómo envío una alerta de emergencia?", "Si eres guía, ve a la pestaña Alertas y pulsa el botón rojo."),
                ("¿Cómo cambio mi contraseña?", "Ve a Perfil > Mi cuenta > Cambiar contraseña."),
                ("¿Necesito conexión a internet?", "Sí, la app necesita conexión para sincronizar eventos y alertas.")
            ]
            for (question, answer) in faqs {
                content.addArrangedSubview(makeFAQItem(question: question, answer: answer))
            }

            let contactButton = UIButton(type: .system)
            contactButton.setTitle("Contactar con soporte", for: .normal)
            contactButton.applyPrimaryStyle()
            contactButton.backgroundColor = roleColor
            contactButton.addTarget(self, action: #selector(contactSupportTapped), for: .touchUpInside)
            content.addArrangedSubview(contactButton)
        }
    }

    // MARK: - Helpers de construccion visual

    private func makeInfoField(label: String, value: String) -> UIView {
        let card = UIView()
        card.backgroundColor = Constants.Theme.cardBackground
        card.layer.cornerRadius = Constants.Theme.cornerRadius
        card.translatesAutoresizingMaskIntoConstraints = false

        let labelLbl = UILabel()
        labelLbl.text = label
        labelLbl.font = .systemFont(ofSize: 12, weight: .medium)
        labelLbl.textColor = Constants.Theme.textSecondary
        labelLbl.translatesAutoresizingMaskIntoConstraints = false

        let valueLbl = UILabel()
        valueLbl.text = value.isEmpty ? "-" : value
        valueLbl.font = .systemFont(ofSize: 16, weight: .semibold)
        valueLbl.textColor = Constants.Theme.textPrimary
        valueLbl.numberOfLines = 0
        valueLbl.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(labelLbl)
        card.addSubview(valueLbl)

        NSLayoutConstraint.activate([
            labelLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            labelLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            labelLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            valueLbl.topAnchor.constraint(equalTo: labelLbl.bottomAnchor, constant: 4),
            valueLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            valueLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            valueLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }

    private func makeSwitchRow(title: String, subtitle: String, isOn: Bool) -> UIView {
        let card = UIView()
        card.backgroundColor = Constants.Theme.cardBackground
        card.layer.cornerRadius = Constants.Theme.cornerRadius
        card.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = Constants.Theme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = Constants.Theme.textSecondary
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let toggle = UISwitch()
        toggle.isOn = isOn
        toggle.onTintColor = roleColor
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(switchToggled(_:)), for: .valueChanged)

        card.addSubview(titleLabel)
        card.addSubview(subtitleLabel)
        card.addSubview(toggle)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -12),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: toggle.leadingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),

            toggle.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            toggle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16)
        ])

        return card
    }

    private func makeFAQItem(question: String, answer: String) -> UIView {
        let card = UIView()
        card.backgroundColor = Constants.Theme.cardBackground
        card.layer.cornerRadius = Constants.Theme.cornerRadius
        card.translatesAutoresizingMaskIntoConstraints = false

        let questionLbl = UILabel()
        questionLbl.text = question
        questionLbl.font = .systemFont(ofSize: 15, weight: .bold)
        questionLbl.textColor = Constants.Theme.textPrimary
        questionLbl.numberOfLines = 0
        questionLbl.translatesAutoresizingMaskIntoConstraints = false

        let answerLbl = UILabel()
        answerLbl.text = answer
        answerLbl.font = .systemFont(ofSize: 14)
        answerLbl.textColor = Constants.Theme.textSecondary
        answerLbl.numberOfLines = 0
        answerLbl.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(questionLbl)
        card.addSubview(answerLbl)

        NSLayoutConstraint.activate([
            questionLbl.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            questionLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            questionLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            answerLbl.topAnchor.constraint(equalTo: questionLbl.bottomAnchor, constant: 6),
            answerLbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            answerLbl.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            answerLbl.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14)
        ])

        return card
    }

    // MARK: - Acciones

    @objc private func changePasswordTapped() {
        let alert = UIAlertController(title: "Cambiar contraseña", message: "Introduce tu nueva contraseña (mínimo 6 caracteres).", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Nueva contraseña"
        }
        alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alert.addAction(UIAlertAction(title: "Guardar", style: .default, handler: { [weak self, weak alert] _ in
            guard let newPassword = alert?.textFields?.first?.text, newPassword.count >= 6 else {
                self?.showSimpleAlert(title: "Contraseña muy corta", message: "Debe tener al menos 6 caracteres.")
                return
            }
            Auth.auth().currentUser?.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.showSimpleAlert(title: "No se pudo cambiar", message: error.localizedDescription)
                    } else {
                        self?.showSimpleAlert(title: "Listo", message: "Tu contraseña se ha actualizado.")
                    }
                }
            }
        }))
        present(alert, animated: true)
    }

    @objc private func contactSupportTapped() {
        let supportEmail = "jordimateosman@gmail.com"
        if let url = URL(string: "mailto:\(supportEmail)?subject=Soporte%20SafeGroup"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            showSimpleAlert(title: "Contacto", message: "Escríbenos a \(supportEmail)")
        }
    }

    @objc private func switchToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "pref_inapp_alerts_enabled")
    }

    private func showSimpleAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
