//
//  DetailsViewController.swift
//  Journal App
//
//  Created by Hui Ying on 14/05/2024.
//

import UIKit

class DetailsViewController: UIViewController, PassTaskDelegate {

    weak var databaseController: DatabaseProtocol?
    var taskToDisplay: TaskTodo?
    var iniReminder: Bool?
    var iniDate: Date?

    @IBOutlet weak var taskReminder: UISwitch!
    @IBOutlet weak var taskDate: UIDatePicker!
    @IBOutlet weak var taskPrior: UISegmentedControl!
    @IBOutlet weak var taskTag: UILabel!
    @IBOutlet weak var taskTitle: UILabel!
    @IBOutlet weak var taskDetail: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        // set the view
        taskTitle.text = taskToDisplay?.title
        iniDate = taskToDisplay?.dueDate
        taskDate.date = (taskToDisplay?.dueDate) ?? Date()
        taskTag.text = taskToDisplay?.tag
        taskDetail.text = taskToDisplay?.details
        taskPrior.selectedSegmentIndex = (taskToDisplay?.priority) ?? 0
        iniReminder = taskReminder.isOn
        taskReminder.setOn(taskReminder.isOn, animated: true)
        taskPrior.isEnabled = false
    }
    
    // Pass Task protocol delegate method
    func displayTask(_ task: TaskTodo) {
        self.taskToDisplay = task
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
