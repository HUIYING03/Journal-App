//
//  ScheduleTableViewController.swift
//  Journal App
//
//  Created by Hui Ying on 04/06/2024.
//

import UIKit

class ScheduleTableViewController: UITableViewController, DatabaseListener {
    
    var listenerType: ListenerType = .schedule
    
    var schedule = [Schedule]()
    var currentDate: Date?
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        databaseController?.addListener(listener: self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        databaseController?.removeListener(listener: self)
    }
    
    // MARK: Database listener delegate method
    
    func onDateChange(change: DatabaseChange, date: Date, text: String, image: [JournalImageModel]) {
        
    }
    
    func onTaskChange(change: DatabaseChange, tasks: [TaskTodo]) {
        
    }
    
    func onScheduleChange(change: DatabaseChange, schedule: [Schedule], date: Date) {
        self.schedule = schedule
        currentDate = date
        tableView.reloadData()
    }

    // MARK: - Table view data source
    @IBAction func addSchedule(_ sender: Any) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let addScheduleViewController = storyboard.instantiateViewController(withIdentifier: "addScheduleViewController") as! AddScheduleViewController
        addScheduleViewController.theDate = currentDate
        addScheduleViewController.modalPresentationStyle = .pageSheet
        if let sheet = addScheduleViewController.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.largestUndimmedDetentIdentifier = .medium
            sheet.prefersEdgeAttachedInCompactHeight = true
        }
        present(addScheduleViewController, animated: true, completion: nil)
    }
        
    // present calendar pick view controller
    @IBAction func selectDate(_ sender: UIBarButtonItem) {
        
        if let presentedPopover = presentedViewController as? CalendarPickViewController {
            presentedPopover.dismiss(animated: false, completion: nil)
        }
        
        let popOverController = CalendarPickViewController()
        
        // set the fetch tasks for date function as date pick for view controller
        popOverController.datePickForController = { [weak self] dateString in
            self?.databaseController?.fetchTasksForDate(dateString: dateString)
        }
        popOverController.preferredContentSize = CGSize(width: 300, height: 300)
        popOverController.modalPresentationStyle = .pageSheet
        popOverController.sheetPresentationController?.detents = [.medium()]
        self.present(popOverController, animated: true)
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return schedule.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "scheduleCell", for: indexPath) as! ScheduleTableViewCell
        cell.scheduleTitle.text = schedule[indexPath.row].title
        cell.scheduledTime.date = schedule[indexPath.row].scheduledTime ?? Date()
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentDate ?? Date())
        if section == 0 {
            // set date string as header
            let headerView = HeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 50), lableText: dateString, lableSize: 20)
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            let theSchedule = schedule.remove(at: indexPath.row)
            databaseController?.deleteScheduleFromDate(date: currentDate ?? Date(), schedule: theSchedule)
            tableView.reloadData()
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
