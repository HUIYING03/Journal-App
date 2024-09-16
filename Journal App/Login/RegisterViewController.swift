//
//  RegisterViewController.swift
//  Journal App
//
//  Created by Hui Ying on 23/04/2024.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    
    weak var databaseController: DatabaseProtocol?
    var signed = false
    
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var confirmPass: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBAction func signUpButton(_ sender: Any) {
        // check if the email, password and confirma password are valid
        if validation(){
            Task {
                do {
                    // try to sign up
                    signed = (try await databaseController?.signUp(email: email.text!, password: password.text!).value) ?? false
                    // if successfully signed up, set the
                    // main tab bar controller as root view controller
                    if signed {
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                            let mainTabBarController = storyboard.instantiateViewController(identifier: "MainTabBarController")
                            
                            (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        // add swipe down gesture to dismiss keyboard
        let swipeDownGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        view.addGestureRecognizer(swipeDownGesture)
        // Do any additional setup after loading the view.
    }
    
    // Swipe down to dismiss the keyboard
    @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if translation.y > 0 {
            email?.endEditing(true)
            confirmPass?.endEditing(true)
            password?.endEditing(true)

        }
    }
    
    // MARK: Check if email, password and confirm password are valid
    
    // check if email entered is valid
    func isValidEmail(email: String) -> Bool {
            let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
            let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
            return emailPred.evaluate(with: email)
        }
    
    // Check if email, password and confirm password are valid
    func validation() -> Bool {
            if !email.hasText{
                Util.displayWithAction(on: self, title: "Error", message: "Enter your email address", actionTitle: "OK")
            }
            else if !password.hasText{
                Util.displayWithAction(on: self, title: "Error", message: "Enter your password", actionTitle: "OK")
            }
            else if !confirmPass.hasText{
                Util.displayWithAction(on: self, title: "Error", message: "Enter your confirm password", actionTitle: "OK")
            }
            else if !isValidEmail(email: email.text!){
                Util.displayWithAction(on: self, title: "Error", message: "Invalid email", actionTitle: "OK")
            }
            else if password.text != confirmPass.text{
                Util.displayWithAction(on: self, title: "Error", message: "Passwords not match!", actionTitle: "OK")
                }
            else {
                return true
            }
            return false
        }
}
