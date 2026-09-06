 //
 //  UIViewController+.swift
 //  SafeGroup
 //
 //  Created by Jordi Mateos Manchado on 12/11/2020.
 //  Copyright © 2020 Jordi Mateos Manchado. All rights reserved.
 //
 
 import UIKit
 
 var vSpinner : UIView?
 
 extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func showLoading(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        let ai = UIActivityIndicatorView.init(style: .whiteLarge)
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeLoading() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
 }


// MARK: - Estilos reutilizables (tema visual de la app)

extension UIButton {
    func applyPrimaryStyle() {
        backgroundColor = Constants.Theme.primary
        setTitleColor(.black, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        layer.cornerRadius = Constants.Theme.cornerRadius
        layer.masksToBounds = false
        contentEdgeInsets = UIEdgeInsets(top: 14, left: 24, bottom: 14, right: 24)
        
        // Sombra "glow" del mismo color, look premium tipo apps bancarias.
        layer.shadowColor = Constants.Theme.primary.cgColor
        layer.shadowOpacity = 0.45
        layer.shadowRadius = 10
        layer.shadowOffset = CGSize(width: 0, height: 4)
    }
}

extension UITextField {
    func applyFieldStyle() {
        backgroundColor = Constants.Theme.fieldBackground
        textColor = Constants.Theme.textPrimary
        font = .systemFont(ofSize: 16)
        borderStyle = .none
        layer.cornerRadius = Constants.Theme.cornerRadius
        layer.masksToBounds = false
        
        // Sombra suave para dar sensacion de tarjeta "elevada" sobre el fondo oscuro.
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.35
        layer.shadowRadius = 8
        layer.shadowOffset = CGSize(width: 0, height: 4)

        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 44))
        leftView = padding
        leftViewMode = .always

        if let placeholder = placeholder {
            attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: Constants.Theme.textSecondary]
            )
        }
    }
}
