//
//  SettingsTableViewController.swift
//  Journal App
//
//  Created by Hui Ying on 30/05/2024.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    lazy var appDelegate = {
        guard let appDelegate =  UIApplication.shared.delegate as?  AppDelegate else {
            fatalError("No AppDelegate")
        }
        return appDelegate
    }()
    
    weak var databaseController: DatabaseProtocol?
    
    let SECTION_PRIVACY = 0
    let SECTION_GENERAL = 1
    let SECTION_ACKNOWLEDGEMENT = 2
    
    var loggedOut = false
    var notification = false

    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case SECTION_PRIVACY:
            return 1
        case SECTION_GENERAL:
            return 1
        case SECTION_ACKNOWLEDGEMENT:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        switch indexPath.section {
        case SECTION_PRIVACY:
            content.text = "Privacy Settings"
        case SECTION_GENERAL:
            content.text = "Notifications"
            let notificationSwitch = UISwitch()
            Task {
                // get the authorization status
                let notificationCenter = UNUserNotificationCenter.current()
                let notiSetting = await notificationCenter.notificationSettings()
                notification = notiSetting.authorizationStatus == .authorized
            }
            // on if both the notification enabled and notication authorised == true
            notificationSwitch.isOn = UserDefaults.standard.bool(forKey: "notificationsEnabled") && notification
            notificationSwitch.addTarget(self, action: #selector(notificationSwitchChanged(_:)), for: .valueChanged)
            cell.accessoryView = notificationSwitch
        case SECTION_ACKNOWLEDGEMENT:
            content.text = "About"
        default:
            break
        }
        if indexPath.section == SECTION_GENERAL {
            cell.accessoryType = .none
        } else {
            cell.accessoryType = .disclosureIndicator
        }
        cell.contentConfiguration = content
        return cell
    }
    
    @objc func notificationSwitchChanged(_ sender: UISwitch) {
        // if authorized
        if notification {
            let isEnabled = sender.isOn
            // set user default
            UserDefaults.standard.set(isEnabled, forKey: "notificationsEnabled")
            // update app delegate
            appDelegate.notificationsEnabled = sender.isOn
            if isEnabled {
                // reschedule the nofication saved in the user default
                rescheduleSavedNotifications()
            } else {
                // save the notification in user default
                saveScheduledNotifications()
            }
        } else {
            Util.displayWithAction(on: self, title: "Notification", message: "Enable notification in your settings and restart the app to receive notification", actionTitle: "OK")
            sender.isOn = !sender.isOn
        }
    }
    
    // remove all pending notification and save it in user default
    func saveScheduledNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            var notifications = [NotificationDetails]()
            for request in requests {
                // for each request, create notifcation and add back list
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let triggerDate = trigger.nextTriggerDate() {
                    let details = NotificationDetails(
                        identifier: request.identifier,
                        title: request.content.title,
                        body: request.content.body,
                        date: triggerDate
                    )
                    notifications.append(details)
                }
            }
            // encode the list and store in userdefault
            if let data = try? JSONEncoder().encode(notifications) {
                UserDefaults.standard.set(data, forKey: "savedNotifications")
            }
            // Cancel all scheduled notifications
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
    
    // reschedule the saved notification stored in the user default
    func rescheduleSavedNotifications() {
        if let data = UserDefaults.standard.data(forKey: "savedNotifications"),
           // decode the saved notification
           let notifications = try? JSONDecoder().decode([NotificationDetails].self, from: data) {
            // for each, create the notification
            for notification in notifications {
                let content = UNMutableNotificationContent()
                content.title = notification.title
                content.body = notification.body
                
                let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: notification.date)
                let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
                
                let request = UNNotificationRequest(identifier: notification.identifier, content: content, trigger: trigger)
                // and schedule it
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
            // Clear saved notifications from UserDefaults
            UserDefaults.standard.removeObject(forKey: "savedNotifications")
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case SECTION_PRIVACY:
            return "Privacy"
        case SECTION_GENERAL:
            return "General"
        case SECTION_ACKNOWLEDGEMENT:
            return "About"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // instantiate view controller based on the section selected
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var viewController: UIViewController?

        switch indexPath.section {
        case SECTION_PRIVACY:
            viewController = storyboard.instantiateViewController(withIdentifier: "ManageAccountTableViewController")
        case SECTION_ACKNOWLEDGEMENT:
            viewController = storyboard.instantiateViewController(withIdentifier: "AboutViewController")
        default:
            break
        }
        // push it to the navigation stack
        if let viewController = viewController {
            navigationController?.pushViewController(viewController, animated: true)
        }
    }

    /*
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
}

struct NotificationDetails: Codable {
    let identifier: String
    let title: String
    let body: String
    let date: Date
}
