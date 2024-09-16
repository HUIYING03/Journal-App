//
//  AddScheduleViewController.swift
//  Journal App
//
//  Created by Hui Ying on 04/06/2024.
//

import UIKit

class AddScheduleViewController: UIViewController {
    
    var theDate: Date?
    
    weak var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var taskDate: UIDatePicker!
    @IBOutlet weak var taskTitle: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        // Do any additional setup after loading the view.
    }
    
    @IBAction func doneButton(_ sender: Any) {
        let mySchedule = Schedule()
        mySchedule.title = taskTitle.text
        mySchedule.scheduledTime = taskDate.date
        
        if mySchedule.title != "" {
            // save the schedule to firebase
            databaseController?.saveScheduleToDate(date: theDate ?? Date(), mySchedule: mySchedule)
            dismiss(animated: true)
        } else {
            Util.displayWithAction(on: self, title: "Enter a title", message: "The title cannot be empty", actionTitle: "OK")
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
