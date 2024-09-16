//
//  SleepViewController.swift
//  Journal App
//
//  Created by Hui Ying on 20/05/2024.
//

import UIKit

class SleepViewController: UIViewController {
    
    var databaseController: DatabaseProtocol?
    var reminderTimeSet: Date?
    var reminderDone: Bool = false
    
    @IBOutlet weak var sleepTime: UIDatePicker!
    @IBOutlet weak var reminderOn: UISwitch!
    
    @IBAction func doneButton(_ sender: UIBarItem) {
        // set new reminder time
        databaseController?.setReminderTime(time: sleepTime.date)
        performSegue(withIdentifier: "sleepTimeSet", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        // get reminder from firebase
        // if reminder exists,
        // navigate to reminder view controller
        databaseController?.getReminderTime { (reminderTime) in
            if let reminderTime = reminderTime {
                self.sleepTime.date = reminderTime
                self.reminderDone = true
                self.performSegue(withIdentifier: "sleepTimeSet", sender: self)
            }
        }
        sleepTime.datePickerMode = .time
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // if reminder is not set before,
        // set it with the time picked
        if !reminderDone {
            databaseController?.setReminderTime(time: sleepTime.date)
        }
        if segue.identifier == "sleepTimeSet" {
            // Get the new view controller using segue.destination.
            // Pass the selected object to the new view controller.
            if let reminderViewController = segue.destination as? ReminderViewController {
                reminderViewController.reminderSet = reminderOn.isOn
                reminderViewController.remindTime = sleepTime.date
                
            }
        }
    }
    

}
