//
//  ReminderViewController.swift
//  Journal App
//
//  Created by Hui Wong on 20/5/2024.
//

import UIKit
import UserNotifications

class ReminderViewController: UIViewController, ChangeTimeDelegate{
    
    @IBOutlet weak var changeButton: UIButton!
    
    var databaseController: DatabaseProtocol?
    var reminderSet: Bool = false
    var remindTime: Date?
    
    @IBOutlet weak var bedTime: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.hidesBackButton = true
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController

        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        bedTime.text = formatter.string(from: remindTime!)
        
        changeButton.tintColor = self.traitCollection.userInterfaceStyle == .dark ? .lightText : .darkText
    }
    
    @IBAction func changeTime(_ sender: Any) {
        // change time button is press
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let changeTimeVC = storyboard.instantiateViewController(withIdentifier: "changeTimeViewController") as! TimePickerViewController
        changeTimeVC.delegate = self
        changeTimeVC.modalPresentationStyle = .pageSheet
        if let sheet = changeTimeVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.prefersGrabberVisible = true
        }
        // add bar item to modal
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissModal))
        changeTimeVC.toolbarItems = [doneButton]
        changeTimeVC.hidesBottomBarWhenPushed = false
        
        // present the time picker view controller
        present(changeTimeVC, animated: true, completion: nil)
    }
    
    
    // MARK: Change time protocol delegate method
    
    func reminderToggle(_ isOn: Bool) {
        if !isOn{
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [AppDelegate.SLEEP_IDENTIFIER])
        }
    }
    
    func timeChanged(_ time: Date) {
        databaseController?.setReminderTime(time: time)
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        bedTime.text = formatter.string(from: time)
    }

    
    
    @objc private func dismissModal(){
        dismiss(animated: true)
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
