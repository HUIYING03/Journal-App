//
//  TimePickViewController.swift
//  Journal App
//
//  Created by Hui Ying on 21/05/2024.
//

import UIKit

class TimePickViewController: UIViewController {

    lazy var appDelegate = {
        guard let appDelegate =  UIApplication.shared.delegate as?  AppDelegate else {
            fatalError("No AppDelegate")
        }
        return appDelegate
    }()

    public var taskTitle: String?
    public var dueDate: Date?
    
    
    @IBOutlet weak var reminderSelected: UIDatePicker!
    
    @IBAction func doneButton(_ sender: Any) {
        // create notification request
        let content = UNMutableNotificationContent()
        content.title = taskTitle ?? "Journal"        
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d MMMM"
        let formattedDate = dateFormatter.string(from: dueDate ?? Date())
        content.body = "You have task due " + formattedDate
        
        content.categoryIdentifier = AppDelegate.CATEGORY_IDENTIFIER
        let identifier = (taskTitle ?? "Journal")+formattedDate.description
        let userInfo = ["identifier": identifier]
        content.userInfo = userInfo
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderSelected.date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        // schedule the request
        UNUserNotificationCenter.current().add(request)
        dismiss(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    init(){
        super.init(nibName: "TimePickViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
