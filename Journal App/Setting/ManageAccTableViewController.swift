//
//  ManageAccTableViewController.swift
//  Journal App
//
//  Created by Hui Ying on 30/05/2024.
//

import UIKit
import FirebaseAuth

class ManageAccTableViewController: UITableViewController {
    
    weak var databaseController: DatabaseProtocol?
        var authController = Auth.auth()
        var currentUser: User?

    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        currentUser = authController.currentUser
    }

    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        switch indexPath.row {
        case 0:
            content.text = "Change Password"
        case 1:
            content.text = "Log Out"
        default:
            break
        }
        cell.contentConfiguration = content
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            changePassword(self)
        }
        if indexPath.row == 1 {
            _ = databaseController?.logOut()
            // set hte rott view controller back to login vc after log out
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginNavController = storyboard.instantiateViewController(identifier: "LoginNavigationController")
            
            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(loginNavController)
        }
    }
    
    // use alert controller to prompt passwords
    func changePassword(_ sender: Any) {
        let alertControllerOld = UIAlertController(title: "Change Password", message: "Enter your current password.", preferredStyle: .alert)
        
        alertControllerOld.addTextField { (textField) in
            textField.placeholder = "Current Password"
            textField.isSecureTextEntry = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
            if let oldpextField = alertControllerOld.textFields?.first,
               let oldpass = oldpextField.text, let _ = self.currentUser {
                self.verifyCurrentPassword(oldpass) { success in
                    if success {
                        // Password verified, prompt for new password
                        let alertController = UIAlertController(title: "Enter Password", message: "Please enter your new password:", preferredStyle: .alert)
                        
                        alertController.addTextField { (textField) in
                            textField.placeholder = "Password"
                            textField.isSecureTextEntry = true
                        }
                        
                        alertController.addTextField { (textField) in
                            textField.placeholder = "Confirm Password"
                            textField.isSecureTextEntry = true
                        }
                        
                        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                        let okAction = UIAlertAction(title: "OK", style: .default) { (_) in
                            if let passwordTextField = alertController.textFields?.first, let cpasswordTextField = alertController.textFields?.last,
                               let password = passwordTextField.text,
                               let cpassword = cpasswordTextField.text {
                                if password != cpassword {
                                    // if not match, clear the fields
                                    Util.displayWithAction(on: self, title: "Error", message: "Password does not match", actionTitle: "OK")
                                    passwordTextField.text = ""
                                    cpasswordTextField.text = ""
                                } else {
                                    // if match, change password
                                    self.databaseController?.changePassword(currentPassword: oldpass, newPassword: cpassword) { error in
                                        if let error = error {
                                            // Handle error
                                            print("Error changing password: \(error.localizedDescription)")
                                        }
                                    }
                                    Util.displayWithAction(on: self, title: "Password", message: "Password updated successfully", actionTitle: "OK")
                                }
                            }
                        }
                        alertController.addAction(cancelAction)
                        alertController.addAction(okAction)
                        self.present(alertController, animated: true, completion: nil)
                    } else {
                        // Incorrect password, display error message
                        Util.displayWithAction(on: self, title: "Error", message: "Incorrect password", actionTitle: "Please try again")
                    }
                }
            }
        }
        
        alertControllerOld.addAction(cancelAction)
        alertControllerOld.addAction(okAction)
        present(alertControllerOld, animated: true, completion: nil)
        
    }
    
    // reauthenticate user
    func verifyCurrentPassword(_ password: String, completion: @escaping (Bool) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(false)
            return
        }
        // Reauthenticate user with current password
        let credential = EmailAuthProvider.credential(withEmail: user.email!, password: password)
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                // Reauthentication failed
                print("Error reauthenticating user:", error.localizedDescription)
                completion(false)
            } else {
                // Reauthentication succeeded
                completion(true)
            }
        }
    }

    // add email address as header
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let headerView = HeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50), lableText: currentUser?.email ?? "")
            return headerView
        }
        return nil
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 40
        }
        return 0
    }
}
