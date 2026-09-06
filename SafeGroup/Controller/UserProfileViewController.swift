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

        let currentUser = User.currentUser
        let role = currentUser?.role

        // La pantalla nueva se construye entera por codigo (cabecera grande,
        // tarjeta de "tour actual" y menu de opciones), asi que ocultamos los
        // elementos antiguos del Storyboard en vez de intentar reaprovecharlos.
        hideOriginalElements()

        buildProfileScreen(
            firstname: currentUser?.firstname ?? "",
            lastname: currentUser?.lastname ?? "",
            email: currentUser?.email ?? "",
            role: role
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Ocultar elementos originales del Storyboard

    private func hideOriginalElements() {
        nameLabel?.superview?.isHidden = true   // stack con nombre/apellido/email/rol
        imageProfileLabel?.isHidden = true
        hideLooseTitleLabel(in: view)
        navigationItem.rightBarButtonItem = nil
    }

    private func hideLooseTitleLabel(in view: UIView) {
        for subview in view.subviews {
            if let label = subview as? UILabel, label.text == "Perfil de usuario" {
                label.isHidden = true
            }
            hideLooseTitleLabel(in: subview)
        }
    }

    // MARK: - Construccion de la pantalla nueva

    private func buildProfileScreen(firstname: String, lastname: String, email: String, role: Role?) {
        let roleColor: UIColor = (role == .guia) ? Constants.Theme.primary : Constants.Theme.accent
        let roleText = (role == .guia) ? "Guía" : "Participante"

        view.backgroundColor = Constants.Theme.background

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 20
        content.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(content)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 8),
            content.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            content.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            content.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        let headerView = makeHeaderRow(subtitle: "Tu cuenta y gestión como \(roleText.lowercased())")
        let avatarView = makeAvatarSection(firstname: firstname, lastname: lastname, email: email, roleColor: roleColor, roleText: roleText)
        let tourCard = makeTourCard(roleColor: roleColor)
        let menuSection = makeMenuSection(roleText: roleText)

        content.addArrangedSubview(headerView)
        content.addArrangedSubview(avatarView)
        content.addArrangedSubview(tourCard)
        content.addArrangedSubview(menuSection)

        content.setCustomSpacing(28, after: headerView)
        content.setCustomSpacing(28, after: avatarView)
    }

    // MARK: - Cabecera ("Perfil" + subtitulo + boton "...")

    private func makeHeaderRow(subtitle: String) -> UIView {
        let container = UIView()

        let titleLabel = UILabel()
        titleLabel.text = "Perfil"
        titleLabel.font = .systemFont(ofSize: 34, weight: .bold)
        titleLabel.textColor = Constants.Theme.textPrimary
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 15)
        subtitleLabel.textColor = Constants.Theme.textSecondary
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let moreButton = UIButton(type: .system)
        moreButton.backgroundColor = Constants.Theme.cardBackground
        moreButton.tintColor = Constants.Theme.textPrimary
        moreButton.layer.cornerRadius = 22
        moreButton.layer.masksToBounds = false
        moreButton.layer.shadowColor = UIColor.black.cgColor
        moreButton.layer.shadowOpacity = 0.08
        moreButton.layer.shadowRadius = 6
        moreButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        moreButton.translatesAutoresizingMaskIntoConstraints = false
        if let icon = symbolImage("ellipsis") {
            moreButton.setImage(icon, for: .normal)
        } else {
            moreButton.setTitle("•••", for: .normal)
        }
        moreButton.addTarget(self, action: #selector(moreButtonTapped), for: .touchUpInside)

        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(moreButton)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: moreButton.leadingAnchor, constant: -12),
            subtitleLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            moreButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            moreButton.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            moreButton.widthAnchor.constraint(equalToConstant: 44),
            moreButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        return container
    }

    @objc private func moreButtonTapped() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Cerrar sesión", style: .destructive, handler: { [weak self] _ in
            guard let self = self else { return }
            self.signoutPressed(self)
        }))
        sheet.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        present(sheet, animated: true)
    }

    // MARK: - Avatar + nombre + rol

    private func makeAvatarSection(firstname: String, lastname: String, email: String, roleColor: UIColor, roleText: String) -> UIView {
        let container = UIView()

        let avatar = UIView()
        avatar.backgroundColor = roleColor.withAlphaComponent(0.15)
        avatar.layer.cornerRadius = 50
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: symbolImage("person.fill"))
        icon.tintColor = roleColor
        icon.contentMode = .scaleAspectFit
        icon.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(icon)

        let nameLbl = UILabel()
        nameLbl.text = "\(firstname) \(lastname)".trimmingCharacters(in: .whitespaces)
        nameLbl.font = .systemFont(ofSize: 22, weight: .bold)
        nameLbl.textColor = Constants.Theme.textPrimary
        nameLbl.textAlignment = .center
        nameLbl.translatesAutoresizingMaskIntoConstraints = false

        let emailLbl = UILabel()
        emailLbl.text = email
        emailLbl.font = .systemFont(ofSize: 15)
        emailLbl.textColor = Constants.Theme.textSecondary
        emailLbl.textAlignment = .center
        emailLbl.translatesAutoresizingMaskIntoConstraints = false

        let pill = UILabel()
        pill.text = roleText.uppercased()
        pill.font = .systemFont(ofSize: 13, weight: .bold)
        pill.textColor = roleColor
        pill.textAlignment = .center
        pill.backgroundColor = roleColor.withAlphaComponent(0.15)
        pill.layer.cornerRadius = 12
        pill.layer.masksToBounds = true
        pill.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(avatar)
        container.addSubview(nameLbl)
        container.addSubview(emailLbl)
        container.addSubview(pill)

        NSLayoutConstraint.activate([
            avatar.topAnchor.constraint(equalTo: container.topAnchor),
            avatar.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 100),
            avatar.heightAnchor.constraint(equalToConstant: 100),

            icon.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 44),
            icon.heightAnchor.constraint(equalToConstant: 44),

            nameLbl.topAnchor.constraint(equalTo: avatar.bottomAnchor, constant: 14),
            nameLbl.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            nameLbl.leadingAnchor.constraint(greaterThanOrEqualTo: container.leadingAnchor),
            nameLbl.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor),

            emailLbl.topAnchor.constraint(equalTo: nameLbl.bottomAnchor, constant: 4),
            emailLbl.centerXAnchor.constraint(equalTo: container.centerXAnchor),

            pill.topAnchor.constraint(equalTo: emailLbl.bottomAnchor, constant: 10),
            pill.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            pill.heightAnchor.constraint(equalToConstant: 26),
            pill.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
            pill.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        return container
    }

    // MARK: - Tarjeta "Tour actual"

    private func makeTourCard(roleColor: UIColor) -> UIView {
        let card = UIView()
        card.backgroundColor = Constants.Theme.cardBackground
        card.layer.cornerRadius = Constants.Theme.cornerRadius
        card.layer.masksToBounds = false
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.08
        card.layer.shadowRadius = 10
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.translatesAutoresizingMaskIntoConstraints = false

        let headerLabel = UILabel()
        headerLabel.text = "Tour actual"
        headerLabel.font = .systemFont(ofSize: 18, weight: .bold)
        headerLabel.textColor = Constants.Theme.textPrimary
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: symbolImage("chevron.right"))
        chevron.tintColor = Constants.Theme.textSecondary
        chevron.translatesAutoresizingMaskIntoConstraints = false

        // Nota: son datos de ejemplo. Todavia no existe en la app un "tour
        // activo" real asociado al usuario (numero de conectados, alertas, etc).
        let thumbnail = UIView()
        thumbnail.backgroundColor = roleColor.withAlphaComponent(0.18)
        thumbnail.layer.cornerRadius = 12
        thumbnail.layer.masksToBounds = true
        thumbnail.translatesAutoresizingMaskIntoConstraints = false

        let thumbnailIcon = UIImageView(image: symbolImage("photo"))
        thumbnailIcon.tintColor = roleColor
        thumbnailIcon.contentMode = .scaleAspectFit
        thumbnailIcon.translatesAutoresizingMaskIntoConstraints = false
        thumbnail.addSubview(thumbnailIcon)

        let tourTitle = UILabel()
        tourTitle.text = "Cambrils · Playa"
        tourTitle.font = .systemFont(ofSize: 17, weight: .bold)
        tourTitle.textColor = Constants.Theme.textPrimary
        tourTitle.translatesAutoresizingMaskIntoConstraints = false

        let statusPill = UILabel()
        statusPill.text = "  ●  En curso  "
        statusPill.font = .systemFont(ofSize: 12, weight: .bold)
        statusPill.textColor = Constants.Theme.primary
        statusPill.backgroundColor = Constants.Theme.primary.withAlphaComponent(0.15)
        statusPill.layer.cornerRadius = 10
        statusPill.layer.masksToBounds = true
        statusPill.translatesAutoresizingMaskIntoConstraints = false

        let participantsLabel = UILabel()
        participantsLabel.text = "18 participantes"
        participantsLabel.font = .systemFont(ofSize: 13)
        participantsLabel.textColor = Constants.Theme.textSecondary
        participantsLabel.translatesAutoresizingMaskIntoConstraints = false

        let divider = makeDivider()

        let connectedStat = makeStatItem(icon: "person.2.fill", text: "17 conectados")
        let alertStat = makeStatItem(icon: "exclamationmark.triangle.fill", text: "1 alerta")
        let statsRow = UIStackView(arrangedSubviews: [connectedStat, alertStat])
        statsRow.axis = .horizontal
        statsRow.distribution = .fillEqually
        statsRow.translatesAutoresizingMaskIntoConstraints = false

        [headerLabel, chevron, thumbnail, tourTitle, statusPill, participantsLabel, divider, statsRow].forEach { card.addSubview($0) }

        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 18),
            headerLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),

            chevron.centerYAnchor.constraint(equalTo: headerLabel.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),

            thumbnail.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 14),
            thumbnail.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            thumbnail.widthAnchor.constraint(equalToConstant: 72),
            thumbnail.heightAnchor.constraint(equalToConstant: 72),

            thumbnailIcon.centerXAnchor.constraint(equalTo: thumbnail.centerXAnchor),
            thumbnailIcon.centerYAnchor.constraint(equalTo: thumbnail.centerYAnchor),
            thumbnailIcon.widthAnchor.constraint(equalToConstant: 28),
            thumbnailIcon.heightAnchor.constraint(equalToConstant: 28),

            tourTitle.topAnchor.constraint(equalTo: thumbnail.topAnchor, constant: 2),
            tourTitle.leadingAnchor.constraint(equalTo: thumbnail.trailingAnchor, constant: 14),
            tourTitle.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),

            statusPill.topAnchor.constraint(equalTo: tourTitle.bottomAnchor, constant: 6),
            statusPill.leadingAnchor.constraint(equalTo: thumbnail.trailingAnchor, constant: 14),
            statusPill.heightAnchor.constraint(equalToConstant: 22),

            participantsLabel.topAnchor.constraint(equalTo: statusPill.bottomAnchor, constant: 6),
            participantsLabel.leadingAnchor.constraint(equalTo: thumbnail.trailingAnchor, constant: 14),

            divider.topAnchor.constraint(equalTo: thumbnail.bottomAnchor, constant: 18),
            divider.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            divider.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            divider.heightAnchor.constraint(equalToConstant: 1),

            statsRow.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14),
            statsRow.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 18),
            statsRow.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -18),
            statsRow.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -18)
        ])

        return card
    }

    private func makeStatItem(icon: String, text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.heightAnchor.constraint(equalToConstant: 20).isActive = true

        let iconView = UIImageView(image: symbolImage(icon))
        iconView.tintColor = Constants.Theme.textPrimary
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = Constants.Theme.textPrimary
        label.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconView)
        container.addSubview(label)

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor)
        ])

        return container
    }

    private func makeDivider() -> UIView {
        let divider = UIView()
        divider.backgroundColor = Constants.Theme.textSecondary.withAlphaComponent(0.15)
        divider.translatesAutoresizingMaskIntoConstraints = false
        return divider
    }

    // MARK: - Menu de opciones

    private func makeMenuSection(roleText: String) -> UIView {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        stack.addArrangedSubview(makeMenuRow(icon: "person.fill", title: "Mi cuenta", subtitle: "Datos personales y seguridad"))
        stack.addArrangedSubview(makeMenuRow(icon: "person.text.rectangle.fill", title: "Identificación de \(roleText.lowercased())", subtitle: "Tu rol y credenciales"))
        stack.addArrangedSubview(makeMenuRow(icon: "gearshape.fill", title: "Preferencias", subtitle: "Idioma, notificaciones y más"))
        stack.addArrangedSubview(makeMenuRow(icon: "questionmark.circle.fill", title: "Ayuda", subtitle: "Soporte y preguntas frecuentes"))

        return stack
    }

    private func makeMenuRow(icon: String, title: String, subtitle: String) -> UIView {
        let row = UIButton(type: .system)
        row.backgroundColor = Constants.Theme.cardBackground
        row.layer.cornerRadius = Constants.Theme.cornerRadius
        row.layer.masksToBounds = false
        row.layer.shadowColor = UIColor.black.cgColor
        row.layer.shadowOpacity = 0.06
        row.layer.shadowRadius = 6
        row.layer.shadowOffset = CGSize(width: 0, height: 2)
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(equalToConstant: 68).isActive = true
        row.addTarget(self, action: #selector(menuRowTapped), for: .touchUpInside)

        let iconBadge = UIView()
        iconBadge.backgroundColor = Constants.Theme.background
        iconBadge.layer.cornerRadius = 10
        iconBadge.isUserInteractionEnabled = false
        iconBadge.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView(image: symbolImage(icon))
        iconView.tintColor = Constants.Theme.textPrimary
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = Constants.Theme.textPrimary
        titleLabel.isUserInteractionEnabled = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = Constants.Theme.textSecondary
        subtitleLabel.isUserInteractionEnabled = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        let chevron = UIImageView(image: symbolImage("chevron.right"))
        chevron.tintColor = Constants.Theme.textSecondary
        chevron.isUserInteractionEnabled = false
        chevron.translatesAutoresizingMaskIntoConstraints = false

        iconBadge.addSubview(iconView)
        row.addSubview(iconBadge)
        row.addSubview(titleLabel)
        row.addSubview(subtitleLabel)
        row.addSubview(chevron)

        NSLayoutConstraint.activate([
            iconBadge.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            iconBadge.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            iconBadge.widthAnchor.constraint(equalToConstant: 40),
            iconBadge.heightAnchor.constraint(equalToConstant: 40),

            iconView.centerXAnchor.constraint(equalTo: iconBadge.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBadge.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconBadge.trailingAnchor, constant: 14),
            titleLabel.topAnchor.constraint(equalTo: row.topAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

            subtitleLabel.leadingAnchor.constraint(equalTo: iconBadge.trailingAnchor, constant: 14),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: chevron.leadingAnchor, constant: -8),

            chevron.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            chevron.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            chevron.widthAnchor.constraint(equalToConstant: 14),
            chevron.heightAnchor.constraint(equalToConstant: 14)
        ])

        return row
    }

    @objc private func menuRowTapped() {
        let alert = UIAlertController(title: "Próximamente", message: "Esta sección todavía está en construcción.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Vale", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Utilidad iconos (SF Symbols solo desde iOS 13)

    private func symbolImage(_ name: String) -> UIImage? {
        if #available(iOS 13.0, *) {
            return UIImage(systemName: name)
        }
        return nil
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
