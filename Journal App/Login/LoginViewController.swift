//
//  LoginViewController.swift
//  Journal App
//
//  Created by Hui Ying on 23/04/2024.
//

import UIKit
import FirebaseAuth


class LoginViewController: UIViewController {
    
    weak var databaseController: DatabaseProtocol?
    var authHandle: AuthStateDidChangeListenerHandle?
    var logged = false
    
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBAction func login(_ sender: Any) {
        // if the email and password entered are valid
        if validation(){
            Task {
                do {
                    // try to log in
                    logged = (try await databaseController?.logIn(email: email.text!, password: password.text!).value) ?? false
                    if logged {
                        Util.displayWithAction(on: self, title: "Welcome", message: "Successfully logged in", actionTitle: "OK")
                    }
                    if !logged{
                        Util.displayWithAction(on: self, title: "Failed", message: "To login", actionTitle: "OK")
                        return
                    }
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let mainTabBarController = storyboard.instantiateViewController(identifier: "MainTabBarController")
                        // Get the SceneDelegate object from view controller
                        // then call the change root view controller function to change to main tab bar
                        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
                } catch {
                    Util.displayWithAction(on: self, title: "Failed", message:
                                            "To login", actionTitle: "OK")
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        // add gesture to dismiss keyboard
        let swipeDownGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        view.addGestureRecognizer(swipeDownGesture)  
    }
    
    
    // Swipe down to dismiss the keyboard
    @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if translation.y > 0 {
            email?.endEditing(true)
            password.endEditing(true)
        }
    }
    
    // MARK: Email / password check
    
    // check if the email entered is valid
    func isValidEmail(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    // Check if the email and password enter is valid
    // return true if valid else false
    func validation() -> Bool {
        if !email.hasText{
            Util.displayWithAction(on: self, title: "Error", message: "Enter your email address", actionTitle: nil)
        }
        else if !password.hasText{
            Util.displayWithAction(on: self, title: "Error", message: "Enter your password", actionTitle: nil)
        }
        else if !isValidEmail(email: email.text!){
            Util.displayWithAction(on: self, title: "Error", message: "Invalid email", actionTitle: nil)
        }
        else {
            return true
        }
        return false
    }
}
