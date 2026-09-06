//
//  RegisterViewController.swift
//  SafeGroup
//
//  Created by Jordi Mateos Manchado on 16/11/2020.
//  Copyright © 2020 Jordi Mateos Manchado. All rights reserved.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore

class RegisterViewController: UIViewController {

    @IBOutlet weak var infoLabel: UILabel!
    
    @IBOutlet weak var roleSegmentedControl: UISegmentedControl!
    @IBOutlet weak var createCountTextField: UILabel!
    @IBOutlet weak var lastnameTextField: UITextField!
    @IBOutlet weak var firstnameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    let db = Firestore.firestore()
    var usersReference: DocumentReference? = nil
    
    private var selectedRole: Role?
    private var roleOverlayView: UIView?
    private var lastSuggestedEmail: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        usersReference = db.collection("users").document()
        
        self.hideKeyboardWhenTappedAround()
        applyTheme()
        setupEmailSuggestion()
        showRoleSelector()
    }
    
    private func applyTheme() {
        view.backgroundColor = Constants.Theme.background
        
        [firstnameTextField, lastnameTextField, emailTextField, passwordTextField].forEach {
            $0?.applyFieldStyle()
        }
        
        registerButton.applyPrimaryStyle()
        infoLabel?.textColor = Constants.Theme.textSecondary
        
        // El rol ahora se elige antes, con las tarjetas de showRoleSelector().
        roleSegmentedControl.isHidden = true
    }
    
    // MARK: - Sugerencia automatica de email a partir del nombre
    
    private func setupEmailSuggestion() {
        firstnameTextField.addTarget(self, action: #selector(nameFieldsChanged), for: .editingChanged)
        lastnameTextField.addTarget(self, action: #selector(nameFieldsChanged), for: .editingChanged)
    }
    
    @objc private func nameFieldsChanged() {
        let firstName = firstnameTextField.text ?? ""
        let lastName = lastnameTextField.text ?? ""
        let suggestion = suggestedEmail(firstName: firstName, lastName: lastName)
        
        guard !suggestion.isEmpty else { return }
        
        // Solo autocompletamos si el campo esta vacio o si sigue igual a la
        // ultima sugerencia (para no pisar un email que el usuario haya escrito a mano).
        if emailTextField.text?.isEmpty ?? true || emailTextField.text == lastSuggestedEmail {
            emailTextField.text = suggestion
            lastSuggestedEmail = suggestion
        }
    }
    
    private func suggestedEmail(firstName: String, lastName: String) -> String {
        let combined = (firstName + lastName)
            .folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
        guard !combined.isEmpty else { return "" }
        return "\(combined)@gmail.com"
    }
    
    // MARK: - Selector de rol (primer paso, antes del formulario)
    
    private func showRoleSelector() {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = Constants.Theme.background
        overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let questionLabel = UILabel()
        questionLabel.text = "¿Qué rol quieres para empezar esta aventura?"
        questionLabel.font = .systemFont(ofSize: 22, weight: .bold)
        questionLabel.textColor = Constants.Theme.textPrimary
        questionLabel.textAlignment = .center
        questionLabel.numberOfLines = 0
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let guiaCard = makeRoleCard(title: "Guía", subtitle: "Organiza y dirige eventos", systemImageName: "star.fill", role: .guia)
        let participanteCard = makeRoleCard(title: "Participante", subtitle: "Únete y disfruta de eventos", systemImageName: "person.fill", role: .participante)
        
        let stack = UIStackView(arrangedSubviews: [guiaCard, participanteCard])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        overlay.addSubview(questionLabel)
        overlay.addSubview(stack)
        
        NSLayoutConstraint.activate([
            questionLabel.topAnchor.constraint(equalTo: overlay.safeAreaLayoutGuide.topAnchor, constant: 70),
            questionLabel.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 30),
            questionLabel.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -30),
            
            stack.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: overlay.leadingAnchor, constant: 30),
            stack.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -30)
        ])
        
        view.addSubview(overlay)
        roleOverlayView = overlay
    }
    
    private func makeRoleCard(title: String, subtitle: String, systemImageName: String, role: Role) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = Constants.Theme.cardBackground
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = false
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.10
        button.layer.shadowRadius = 12
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.heightAnchor.constraint(equalToConstant: 110).isActive = true
        
        let icon = UIImageView()
        if #available(iOS 13.0, *) {
            icon.image = UIImage(systemName: systemImageName)
        } else {
            // iOS 12 no tiene SF Symbols: dejamos el circulo de color como icono simple.
            icon.backgroundColor = Constants.Theme.primary
            icon.layer.cornerRadius = 20
        }
        icon.tintColor = Constants.Theme.primary
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.isUserInteractionEnabled = false
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 19, weight: .bold)
        titleLabel.textColor = Constants.Theme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.isUserInteractionEnabled = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 14)
        subtitleLabel.textColor = Constants.Theme.textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.isUserInteractionEnabled = false
        
        button.addSubview(icon)
        button.addSubview(titleLabel)
        button.addSubview(subtitleLabel)
        
        NSLayoutConstraint.activate([
            icon.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 24),
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 40),
            icon.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 18),
            titleLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 28),
            titleLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -16)
        ])
        
        button.tag = (role == .guia) ? 0 : 1
        button.addTarget(self, action: #selector(roleCardTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    @objc private func roleCardTapped(_ sender: UIButton) {
        let role: Role = sender.tag == 0 ? .guia : .participante
        selectedRole = role
        roleSegmentedControl.selectedSegmentIndex = (role == .guia) ? 0 : 1
        
        applyRoleStyle(role)
        
        UIView.animate(withDuration: 0.3, animations: {
            self.roleOverlayView?.alpha = 0
        }, completion: { _ in
            self.roleOverlayView?.removeFromSuperview()
            self.roleOverlayView = nil
        })
    }
    
    private func applyRoleStyle(_ role: Role) {
        switch role {
        case .guia:
            registerButton.backgroundColor = Constants.Theme.primary
            infoLabel?.text = "Modo Guía: crea y dirige tus propios eventos."
        case .participante:
            registerButton.backgroundColor = Constants.Theme.accent
            infoLabel?.text = "Modo Participante: únete a eventos cerca de ti."
        }
    }
    
    func register(email: String, password: String, firstName: String, lastName: String, role: Role) {
        Auth.auth().createUser(withEmail: email, password: password) { (authResult, error) in
            if let error = error {
                print(error)
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "No se pudo crear la cuenta", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            } else {
                guard let id = authResult?.user.uid else { return }
                
                let user = User(id: id, email: email, firtname: firstName, lastname: lastName, role: role)
                guard let userEncoded = user.dictionary else { return }
                
                self.usersReference?.setData(userEncoded, completion: { (err) in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Document added with ID: \(self.usersReference!.documentID)")
                        
                        // Almacenar usuario actual de UserDefaults para luego.
                        User.setCurrent(user, writeToUserDefaults: true)
                        
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        let window = appDelegate.window
                        let mainController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()
                        window?.rootViewController = mainController
                        window?.makeKeyAndVisible()
                    }
                })
            }
        }
    }

    
    @IBAction func registerButton(_ sender: Any) {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let firstName = self.firstnameTextField.text else { return }
        guard let lastName = self.lastnameTextField.text else { return }
        
        var role: Role!
        let index = roleSegmentedControl.selectedSegmentIndex
        if index == 0 {
            role = .guia
        } else {
            role = .participante
        }
        
        register(email: email, password: password, firstName: firstName, lastName: lastName, role: role)
    }
    
    @IBAction func doneButtonAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
