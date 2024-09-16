//
//  AddTaskViewController.swift
//  Journal App
//
//  Created by Hui Ying on 13/05/2024.
//

import UIKit
import UserNotifications

class AddTaskViewController: UIViewController {

    lazy var appDelegate = {
        guard let appDelegate =  UIApplication.shared.delegate as?  AppDelegate else {
            fatalError("No AppDelegate")
        }
        return appDelegate
    }()
    
    weak var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var taskTitle: UITextField!
    @IBOutlet weak var details: UITextField!
    @IBOutlet weak var taskTag: UITextField!
    @IBOutlet weak var priority: UISegmentedControl!
    @IBOutlet weak var dueDate: UIDatePicker!
    @IBOutlet weak var reminderOn: UISwitch!
    
    @IBAction func saveTask(_ sender: Any) {
        guard let title = taskTitle.text else { return }
        
        // check title
        if title.isEmpty {
            Util.displayWithAction(on: self, title: "Failed to save", message: "Title must not be empty.", actionTitle: "OK")
            return
        }
        
        // if is on, 
        // check notification enabled
        if reminderOn.isOn {
            guard appDelegate.notificationsEnabled else {
                Util.displayWithAction(on: self, title: "Reminder is not set", message: "Go to setting to turn on notification", actionTitle: "OK")
                return
            }
        }

        // add task
        let _ = databaseController?.addTask(title: title, details: details.text, priority: priority.selectedSegmentIndex, tag: taskTag.text, due: dueDate.date, reminder: reminderOn.isOn, isComplete: false)

        if reminderOn.isOn && appDelegate.notificationsEnabled{
            let popOverController = TimePickViewController()
            popOverController.taskTitle = title
            popOverController.dueDate = dueDate.date
            popOverController.modalPresentationStyle = .pageSheet
            popOverController.sheetPresentationController?.detents = [.medium()]
            self.present(popOverController, animated: true)
        }
        navigationController?.popViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    
        // swipe down to dismiss keyboard
        let swipeDownGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        view.addGestureRecognizer(swipeDownGesture)
    }
    
    @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: view)
            if translation.y > 0 {
                taskTitle?.endEditing(true)
                details?.endEditing(true)
                taskTag?.endEditing(true)
                
            }
        }

}
