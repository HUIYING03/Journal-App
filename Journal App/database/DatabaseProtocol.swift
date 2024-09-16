//
//  DatabaseProtocol.swift
//  Journal App
//
//  Created by Hui Ying on 23/04/2024.
//

import Foundation
import UIKit

enum DatabaseChange {
    case add
    case update
    case remove
}

enum ListenerType {
    case date
    case task
    case schedule
}

protocol DatabaseListener: AnyObject{
    var listenerType: ListenerType {get set}
    func onDateChange(change: DatabaseChange, date: Date, text: String, image: [JournalImageModel])
    func onTaskChange(change: DatabaseChange, tasks: [TaskTodo])
    func onScheduleChange(change: DatabaseChange, schedule: [Schedule], date: Date)
}

protocol DatabaseProtocol: AnyObject {
    
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)
    
    // For text and image storage
    func saveText(dateString: String, text: String)
    func datePicked(dateString: String)
    func saveJournalImage(currentDate: Date?, indexPathItem: Int, image: UIImage?)
    func deleteJournalImage(imageModel: JournalImageModel)
    func getImage() -> [JournalImageModel]
    
    // to do list
    func addTask(title: String, details: String?, priority: Int, tag: String?, due: Date?, reminder: Bool, isComplete: Bool) -> TaskTodo
    func deleteTask(task: TaskTodo)
    func updateTask(task: TaskTodo)
    func updateTaskOrder(task: [TaskTodo])
    func fetchAllTask()
    func markAsDone(notification: String?)
    
    // sleep reminder
    func setReminderTime(time: Date?)
    func getReminderTime(completion: @escaping (Date?) -> Void)
    func scheduleDailyNotification(time: Date)
    
    // schedule
    func saveScheduleToDate(date: Date, mySchedule: Schedule)
    func fetchTasksForDate(dateString: String)
    func deleteScheduleFromDate(date: Date, schedule: Schedule)

    // User authentication
    func logIn(email: String, password: String) -> Task<Bool, Error>
    func signUp(email: String, password: String) -> Task<Bool, Error>
    func logOut() -> Bool
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (Error?) -> Void)
}
