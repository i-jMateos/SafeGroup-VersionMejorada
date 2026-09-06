//
//  UserProfileViewController.swift
//  SafeGroup
//
//  Created by Jordi Mateos Manchado on 13/11/2020.
//  Copyright © 2020 Jordi Mateos Manchado. All rights reserved.
//

import UIKit
import FirebaseAuth

class UserProfileViewController: UIViewController {

    @IBOutlet weak var nameLabel: UITextField!
    
    @IBOutlet weak var lastnameLabel: UITextField!
    
    @IBOutlet weak var imageProfileLabel: UIImageView!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var roleLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageProfileLabel.layer.cornerRadius = self.imageProfileLabel.frame.width/4.0
        
        let currentUser = User.currentUser
        
        nameLabel.text = currentUser?.firstname
        lastnameLabel.text = currentUser?.lastname
        emailTextField.text = currentUser?.email
        roleLabel.text = "Rol: \(currentUser?.role?.rawValue.uppercased() ?? "")" 
        
        applyTheme(role: currentUser?.role)
    }
    
    private func applyTheme(role: Role?) {
        view.backgroundColor = Constants.Theme.background
        
        [nameLabel, lastnameLabel, emailTextField].forEach {
            $0?.applyFieldStyle()
            $0?.isEnabled = false
        }
        
        let roleColor: UIColor = (role == .guia) ? Constants.Theme.primary : Constants.Theme.accent
        roleLabel?.textColor = roleColor
        roleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        
        imageProfileLabel.tintColor = roleColor
        imageProfileLabel.backgroundColor = Constants.Theme.cardBackground
        imageProfileLabel.layer.cornerRadius = imageProfileLabel.frame.width / 2
        imageProfileLabel.layer.masksToBounds = true
        imageProfileLabel.contentMode = .center
        
        // Titulos y textos sueltos de la pantalla (los que no son campos ni el rol).
        styleLooseLabels(in: view, roleColor: roleColor)
        styleButtons(in: view)
    }
    
    private func styleLooseLabels(in view: UIView, roleColor: UIColor) {
        for subview in view.subviews {
            if let label = subview as? UILabel, label !== roleLabel {
                label.textColor = Constants.Theme.textPrimary
            }
            styleLooseLabels(in: subview, roleColor: roleColor)
        }
    }
    
    private func styleButtons(in view: UIView) {
        for subview in view.subviews {
            if let button = subview as? UIButton {
                button.backgroundColor = Constants.Theme.cardBackground
                button.setTitleColor(Constants.Theme.textPrimary, for: .normal)
                button.layer.cornerRadius = 16
                button.layer.masksToBounds = true
            }
            styleButtons(in: subview)
        }
    }
    
    @IBAction func signoutPressed(_ sender: Any) {
        do {
            try Auth.auth().signOut()
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let window = appDelegate.window
            let mainController = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController()
            window?.rootViewController = mainController
            window?.makeKeyAndVisible()
        } catch {
            print("Error al intentar cerrar sesion")
        }
        
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
