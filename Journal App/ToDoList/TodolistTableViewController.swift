//
//  TodolistTableViewController.swift
//  Journal App
//
//  Created by Hui Ying on 13/05/2024.
//

import UIKit

class TodolistTableViewController: UITableViewController, DatabaseListener {
    
    
    weak var databaseController: DatabaseProtocol?
    var listenerType = ListenerType.task
    var currentTask: [TaskTodo] = []
    var detailViewController : UIViewController?
    weak var delegate: PassTaskDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // for task details
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        tableView.addGestureRecognizer(longPress)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // Database Listener delegate method
    
    func onDateChange(change: DatabaseChange, date: Date, text: String, image: [JournalImageModel]) {
        
    }
    
    func onTaskChange(change: DatabaseChange, tasks: [TaskTodo]) {
        currentTask = tasks
        tableView.reloadData()
    }
    
    func onScheduleChange(change: DatabaseChange, schedule: [Schedule], date: Date) {
        
    }
    
    // Present detail view controller sheet when long press on a task
    @objc private func handleLongPress(sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchPoint = sender.location(in: tableView)
            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                // show detail modal
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                detailViewController = storyboard.instantiateViewController(withIdentifier: "detailViewController")
                delegate = detailViewController as? PassTaskDelegate
                if currentTask.count > 0 {
                    delegate?.displayTask(currentTask[indexPath.item])
                } else {
                    let demoTask = TaskTodo()
                    demoTask.title = "Tap on plus button to add new to do task"
                    demoTask.details = "Turn on notification to receive reminder..."
                    demoTask.tag = "Long press to view details :)"
                    delegate?.displayTask(demoTask)
                }
                detailViewController?.modalPresentationStyle = .pageSheet
                if let sheet = detailViewController?.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.largestUndimmedDetentIdentifier = .medium
                    sheet.prefersEdgeAttachedInCompactHeight = true
                    sheet.prefersGrabberVisible = true
                }
                present(detailViewController!, animated: true, completion: nil)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return currentTask.count == 0 ? 1 : currentTask.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "taskCell", for: indexPath)
        
        var content = cell.defaultContentConfiguration()
        if currentTask.count > 0 {
            let task = currentTask[indexPath.row]
            content.text = task.title
            if task.tag!.isEmpty {
                content.secondaryText = ""
            } else {
                content.secondaryText = "#" + task.tag!
            }
            if task.isComplete {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            cell.contentConfiguration = content
        } else {
            // default cell
            content.text = "Tap on plus button to add new to do task"
            content.secondaryText = "#Long press to view details :)"
            cell.accessoryType = .checkmark
        }
        cell.contentConfiguration = content
        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
     */

    @IBAction func editMode(_ sender: UIBarButtonItem) {
        self.tableView.isEditing.toggle()
        sender.title = (self.tableView.isEditing) ? "Done" : "Edit"
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if currentTask.count > 0 {
            if editingStyle == .delete {
                // Delete task from class list variable
                let task = currentTask.remove(at: indexPath.item)
                // delete task and update order
                databaseController?.deleteTask(task: task)
                databaseController?.updateTaskOrder(task: currentTask)
                tableView.reloadData()
            }
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        // select to mark as done
        if currentTask.count > 0 {
            let task = currentTask[indexPath.row]
            if task.isComplete {
                cell?.accessoryType = .none
            }
            else {
                cell?.accessoryType = .checkmark
            }
            // update task attribute
            let _ = databaseController?.updateTask(task: task)
        }
    }
        
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        // update the class list
        if currentTask.count > 0{
            let selected = currentTask.remove(at: fromIndexPath.item)
            currentTask.insert(selected, at: to.item)
            // update the order in firestore
            databaseController?.updateTaskOrder(task: currentTask)
            tableView.reloadData()
        }
    }
}

protocol PassTaskDelegate: AnyObject {
    func displayTask(_ task: TaskTodo)
}
