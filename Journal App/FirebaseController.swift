//
//  FirebaseController.swift
//  Journal App
//
//  Created by Hui Ying on 23/04/2024.
//

import UIKit
import Firebase
import FirebaseFirestoreSwift
import FirebaseAuth
import FirebaseCore
import FirebaseStorage
import UserNotifications

class FirebaseController: NSObject, DatabaseProtocol {
    
    // storage
    var coreDataController: CoreDataController
    var database: Firestore
    var userRef: CollectionReference?
    var entryRef: CollectionReference?
    var dateRef: DocumentReference?
    var taskRef: CollectionReference?
    var scheduleRef: CollectionReference?
    let storage: Storage?
    
    var listeners = MulticastDelegate<DatabaseListener>()
    
    // auth
    var authController: Auth
    var currentUser: FirebaseAuth.User?

    var journalText: String?
    var journalImages: [JournalImageModel] = []
    var currentDate: Date
    var taskList: [TaskTodo]
    var scheduleList: [Schedule]
    
    lazy var appDelegate = {
        guard let appDelegate =  UIApplication.shared.delegate as?  AppDelegate else {
            fatalError("No AppDelegate")
        }
        return appDelegate
    }()
    
    override init(){
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        storage = Storage.storage()
        currentDate = Date()
        currentUser = authController.currentUser
        taskList = [TaskTodo]()
        scheduleList = [Schedule]()
        self.coreDataController = CoreDataController()
        
        super.init()
        if authController.currentUser != nil {
            self.userRef = database.collection("users")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentDate)
        self.datePicked(dateString: dateString)
        self.fetchTasksForDate(dateString: dateString)
        fetchAllTask()
    }
    
    // MARK: Listeners
    
    func addListener(listener: DatabaseListener) {
        listeners.addDelegate(listener)
        if listener.listenerType == .date {
            listener.onDateChange(change: .update, date: currentDate, text: self.journalText ?? "", image: self.journalImages)
        }
        if listener.listenerType == .task {
            listener.onTaskChange(change: .update, tasks: taskList)
        }
        if listener.listenerType == .schedule {
            listener.onScheduleChange(change: .update, schedule: self.scheduleList, date: self.currentDate)
        }
    }
    
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
    }

    // MARK: Save the text entry
    
    func saveText(dateString: String, text: String) {
        do {
            // Use the date string as the document ID
            let documentRef = entryRef?.document(dateString)
            // Set the data for the document
            documentRef?.setData([
                "text": text
            ]) { error in
                if let error = error {
                    print("Error setting document data: \(error)")
                } else {
                    print("Document \(dateString) successfully saved")
                    self.journalText = text
                    self.listeners.invoke { listener in
                        if listener.listenerType == ListenerType.date {
                            listener.onDateChange(change: .add, date: self.currentDate, text: self.journalText ?? "", image: self.journalImages)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Fetch data for date selected
    
    func datePicked(dateString: String){
        self.entryRef = userRef?.document(currentUser!.uid).collection("entries")
        entryRef?.document(dateString).getDocument { document, error in
            
            // Check if the document exists
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.currentDate = dateFormatter.date(from: dateString)!
            self.journalImages = []
            if let document = document, document.exists {
                // If exists, retrieve and display the data
                let journalData = document.data()
                let journalText = journalData?["text"] as? String ?? ""
                self.journalText = journalText
            } else {
                self.saveText(dateString: dateString, text: "")
            }
            // fetch the images
            self.fetchJournalImage()
            self.listeners.invoke { listener in
                if listener.listenerType == ListenerType.date {
                    listener.onDateChange(change: .add, date: self.currentDate, text: self.journalText ?? "", image: self.journalImages)
                }
            }
        }
    }
    
    // MARK: Image storage

    func saveJournalImage(currentDate: Date?, indexPathItem: Int, image: UIImage?){
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentDate!)
        let imageId = UUID().uuidString
        let userID = currentUser!.uid
        
        if let image = image {
            // initialise a image model with the image and data
            self.journalImages.append(JournalImageModel(id: imageId, image: image, date: Date()))
            // invoke listener to update view
            self.listeners.invoke { listener in
                if listener.listenerType == ListenerType.date {
                    listener.onDateChange(change: .add, date: self.currentDate, text: self.journalText ?? "", image: self.journalImages)
                }
            }
        }
        
        // create the path
        let uploadRef = storage?.reference().child("journalImages").child("\(userID)").child("\(dateString)").child("\(imageId).jpg")
        guard let imageData = image?.jpegData(compressionQuality: 0.8) else { return }
        let uploadMetaData = StorageMetadata.init()
        uploadMetaData.contentType = "image/jpeg"
        
        // save the image into Storage
        uploadRef?.putData(imageData, metadata: uploadMetaData){
            (downloadMetadata, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            let imageURL = downloadMetadata?.path ?? ""
            // store the information in Core Data
            self.coreDataController.saveJournalImage(id: imageId, date: currentDate ?? Date(), imageURL: imageURL, userID: userID)
        }
    }
    
    func fetchJournalImage(){
        // use the combination of date, user uid to fetch the list of images
        let imageMetadata = coreDataController.fetchJournalImages(for: self.currentDate, userID: currentUser!.uid)
        self.journalImages.removeAll()
        
        Task {
            do {
                // for each images
                for image in imageMetadata {
                    let imageURL = image.imageURL
                    guard let imageURL = imageURL else {
                        continue
                    }
                    // fetch image from Firebase Storage using the imageURL
                    let imageRef = self.storage?.reference().child(imageURL)
                    imageRef?.getData(maxSize: 10 * 1024 * 1024) { data, error in
                        if let data = data {
                            if let uiimage = UIImage(data: data), let id = image.id, let date = image.date {
                                // append fetched image to journalImages array
                                let imageModel = JournalImageModel(id: id, image: uiimage, date: image.date!)
                                self.journalImages.append(imageModel)
                                // notify listeners
                                self.listeners.invoke { listener in
                                    if listener.listenerType == ListenerType.date {
                                        listener.onDateChange(change: .add, date: self.currentDate, text: self.journalText ?? "", image: self.journalImages)
                                    }
                                }
                            } else {
                                print("Error: Could not create UIImage from data")
                            }
                        } else {
                            print("Error downloading image: \(error?.localizedDescription ?? "Unknown error")")
                        }
                    }
                }}}
    }
    
    func deleteJournalImage(imageModel: JournalImageModel){
        guard let currentUser = currentUser else { return }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: self.currentDate)
        // get the reference path
        let deleteRef = storage?.reference().child("journalImages").child("\(currentUser.uid)").child("\(dateString)").child("\(imageModel.id).jpg")
        // delete the image
        deleteRef?.delete { error in
            if let error = error {
                print("Error deleting image: \(error.localizedDescription)")
            } else {
                // if no error,
                // remove the image from the journal image list
                self.journalImages.removeAll { $0.id == imageModel.id }
                print("Image deleted successfully!")
            }
        }
        // delete the model from core data
        coreDataController.deleteJournalImage(by: imageModel.id)
    }
    
    // get all the imagemodel (for image page view)
    func getImage() -> [JournalImageModel] {
        return journalImages
    }

    // MARK: Set sleep reminder
    
    func setReminderTime(time: Date?){
        // override the existing data
        self.userRef?.document(currentUser!.uid).setData(["time": time ?? Date()])
        guard let time = time else {
            return
        }
        // remove pending notification for sleep reminder
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [AppDelegate.SLEEP_IDENTIFIER])
        // reschedule
        scheduleDailyNotification(time: time)
    }

    // AddTaskController - similar
    func scheduleDailyNotification(time: Date) {
        
        guard appDelegate.notificationsEnabled else {
            print("Notification not enabled")
            return
        }
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Sleep Reminder"
        content.body = "It's time to sleep"
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        // Use the hour and minute components to create a new DateComponents object
        var notificationComponents = DateComponents()
        notificationComponents.hour = components.hour
        notificationComponents.minute = components.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: notificationComponents, repeats: true)
        let request = UNNotificationRequest(identifier: AppDelegate.SLEEP_IDENTIFIER, content: content, trigger: trigger)
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled successfully")
            }
        }
    }
    
    // get reminder time
    func getReminderTime(completion: @escaping (Date?) -> Void) {
        guard let currentUser = Auth.auth().currentUser else {
            completion(nil)
            return
        }
        
        // check if time data exist
        self.userRef?.document(currentUser.uid).getDocument { (document, error) in
            if let document = document, document.exists {
                if let timestamp = document.data()?["time"] as? Timestamp {
                    let retTime = timestamp.dateValue()
                    // if exists, return the time data stored
                    completion(retTime)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    // MARK: To do list tasks
    
    func fetchAllTask(){
        self.taskRef = userRef?.document(currentUser!.uid).collection("tasks")
        // order the document lists by "order"
        taskRef?.order(by: "order").getDocuments {(querySnapshot, error) in
            
            if let error = error {
                print("Error fetching documents: \(error)")
                return
            }
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            // for each document, create one instance of TaskTodo with details
            for document in documents {
                let data = document.data()
                let newTask = TaskTodo()
                newTask.id = document.documentID
                newTask.title = data["title"] as? String
                newTask.details = data["details"] as? String
                newTask.priority = data["priority"] as? Int
                newTask.tag = data["tag"] as? String
                newTask.dueDate = data["dueDate"] as? Date
                newTask.reminder = data["reminder"] as? Bool ?? false
                newTask.isComplete = data["isComplete"] as? Bool ?? false
                // append it into task list
                self.taskList.append(newTask)
            }
        }
    }
    
    func addTask(title: String, details: String?, priority: Int, tag: String?, due: Date?, reminder: Bool, isComplete: Bool) -> TaskTodo {
        // create the task based on information passed in
        let newTask = TaskTodo()
        newTask.title = title
        newTask.details = details
        newTask.priority = priority
        newTask.tag = tag
        newTask.dueDate = due
        newTask.reminder = reminder
        newTask.isComplete = isComplete
        newTask.order = taskList.count
        do {
            // add the document into the collection
            if let newTaskRef = try self.taskRef?.addDocument(from: newTask) {
                // append into task list
                self.taskList.append(newTask)
                newTask.id = newTaskRef.documentID
            }
        } catch {
            print("Failed")
        }
        // notify listener
        listeners.invoke { listener in
            if listener.listenerType == ListenerType.task {
                listener.onTaskChange(change: .update, tasks: taskList)
            }
        }
        return newTask
    }
    
    func deleteTask(task: TaskTodo) {
        if let taskID = task.id {
            // delete from firestore
            taskRef?.document(taskID).delete()
        }
        // delete from task list
        taskList.removeAll {$0 == task}
        
        // delete scheduled notification
        let dueDate = task.dueDate
        let title = task.title
        if dueDate != nil && title != nil{
            let matchId = task.title!+task.dueDate!.description
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [matchId])
        }
        
        listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.task {
                listener.onTaskChange(change: .remove, tasks: taskList)
            }
        }
    }
    
    func updateTaskOrder(task: [TaskTodo]){
        // update order information based on the index
        for (index, mytask) in task.enumerated(){
            mytask.order = index
        }
        // for each task in the list
        for currentTask in task{
            guard let taskID = currentTask.id else {
                return
            }
            do {
                // update the new order in firestore
                taskRef?.document(taskID).updateData(["order": currentTask.order!])
            }
        }
        // update task list
        taskList = task
    }
    
    func updateTask(task: TaskTodo) {
        let updateRef = userRef?.document(currentUser!.uid).collection("tasks").document(task.id!)
        // update the is complete information in firestore
        updateRef?.updateData([
            "isComplete": !task.isComplete
        ]) { error in
            if let error = error {
                print("Error updating task: \(error.localizedDescription)")
            } else {
                // update task list
                if let index = self.taskList.firstIndex(where: { $0.id == task.id }) {
                    self.taskList[index].isComplete.toggle()
                }
            }
        }
    }

    // called when done response received
    func markAsDone(notification: String?) {
        // for each task in task list
        for task in taskList {
            // filter task with reminder on
            if task.reminder {
                guard let dueDate = task.dueDate, let title = task.title else {
                    continue
                }
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "d MMMM"
                let formattedDate = dateFormatter.string(from: dueDate )
                let matchId = title+formattedDate.description
                // check if id match with notifiation identifier
                if matchId == notification {
                    // toggle the bool using update task
                    if !task.isComplete{
                        updateTask(task: task)
                        listeners.invoke { listener in
                            if listener.listenerType == ListenerType.task {
                                listener.onTaskChange(change: .update, tasks: taskList)
                            }
                        }
                    }
                }
            }
        }
    }

    
    // MARK: For schedule
    
    func saveScheduleToDate(date: Date, mySchedule: Schedule) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)

        let scheduleRef = userRef?.document(currentUser!.uid).collection("schedule")
        let dateDocumentRef = scheduleRef?.document(dateString)
        // add new document to the collection reference
        let taskRef = dateDocumentRef?.collection("tasks").document()
        let taskData: [String: Any] = [
            "title": mySchedule.title ?? "",
            "time": mySchedule.scheduledTime ?? Date()
        ]

        taskRef?.setData(taskData) { error in
            if let error = error {
                print("Error setting task data: \(error)")
            } else {
                print("Task added to schedule")
            }
        }
        // add it into schedule listx
        self.scheduleList.append(mySchedule)
        self.listeners.invoke { listener in
            if listener.listenerType == ListenerType.schedule {
                listener.onScheduleChange(change: .add, schedule: scheduleList, date: date)
            }
        }
    }
    
    func deleteScheduleFromDate(date: Date, schedule: Schedule) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let scheduleRef = userRef?.document(currentUser!.uid).collection("schedule")
        let dateDocumentRef = scheduleRef?.document(dateString)
        let taskRef = dateDocumentRef?.collection("tasks")

        // get documents that match the title and time
        let query = taskRef?
            .whereField("title", isEqualTo: schedule.title ?? "")
            .whereField("time", isEqualTo: schedule.scheduledTime ?? Date())

        query?.getDocuments { querySnapshot, error in
            if let error = error {
                print("Error querying tasks: \(error)")
                return
            }

            guard let documents = querySnapshot?.documents else {
                print("No matching documents found")
                return
            }

            // delete document that matched the date and title
            for document in documents {
                document.reference.delete { error in
                    if let error = error {
                        print("Error deleting task: \(error)")
                    } else {
                        print("Task deleted successfully")

                        // Remove the schedule from the local list
                        if let index = self.scheduleList.firstIndex(where: {
                            $0.title == schedule.title && $0.scheduledTime == schedule.scheduledTime
                        }) {
                            self.scheduleList.remove(at: index)
                            self.listeners.invoke { listener in
                                if listener.listenerType == ListenerType.schedule {
                                    listener.onScheduleChange(change: .remove, schedule: self.scheduleList, date: date)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func fetchTasksForDate(dateString: String) {

        let scheduleRef = userRef?.document(currentUser!.uid).collection("schedule").document(dateString).collection("tasks")
        
        // get all document with current date string
        scheduleRef?.getDocuments { (querySnapshot, error) in
            if error != nil {
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                return
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            self.currentDate = dateFormatter.date(from: dateString)!
            self.scheduleList = []

            // for each documenet
            for document in documents {
                let data = document.data()
                let title = data["title"] as? String ?? ""
                let timestamp = data["time"] as? Timestamp ?? Timestamp()
                let time = timestamp.dateValue()
                // create schedule instance with field information
                let schedule = Schedule()
                schedule.title = title
                schedule.scheduledTime = time
                // append in local list
                self.scheduleList.append(schedule)
            }
            self.listeners.invoke { listener in
                if listener.listenerType == ListenerType.schedule {
                    listener.onScheduleChange(change: .add, schedule: self.scheduleList, date: self.currentDate )
                }
            }
        }
    }
    
   
    
    // MARK: User authentication

    func signUp(email:String, password: String)-> Task<Bool, Error>{
        return Task {
            do {
                let authResult = try await authController.createUser(withEmail: email, password: password)
                currentUser = authResult.user
                self.userRef = database.collection("users")
                loadAfterLogin()
                return true
                // user logged in
            }
            catch {
                print("User creation failed with error \(error.localizedDescription)")
                return false
            }
        }
    }
    
    
    func logIn(email: String, password: String)-> Task<Bool, Error>{
       return Task {
           do {
               let authResult = try await authController.signIn(withEmail: email, password: password)
               currentUser = authResult.user
               self.userRef = database.collection("users")
               loadAfterLogin()
               return true
           }
           catch {
               print(error.localizedDescription)
               return false
           }
           
       }
   }
    
    // reload all information after log in
    func loadAfterLogin(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        self.datePicked(dateString: dateString)
        self.fetchTasksForDate(dateString: dateString)
        fetchAllTask()
    }

    
    func logOut() -> Bool {
        if Auth.auth().currentUser != nil {
            do {
                try Auth.auth().signOut()
                currentUser = nil
                print("Successfully logged out")
                return true
            } catch let error {
                print("Error signing out: \(error.localizedDescription)")
                return false
            }
        }
        currentUser = nil
        return false
    }
    
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (Error?) -> Void) {
        guard let user = currentUser else {
            // User is not signed in
            return
        }
        // Reauthenticate user with current password
        let credential = EmailAuthProvider.credential(withEmail: user.email!, password: currentPassword)
            user.reauthenticate(with: credential) { authResult, error in
                if let error = error {
                    // Reauthentication failed
                    print("Error reauthenticating user:", error.localizedDescription)
                    return
                }
                user.updatePassword(to: newPassword) { error in
                    if let error = error {
                        print("Error updating password:", error.localizedDescription)
                        return
                    }
                    // Password updated successfully
                    print("Password updated successfully")
                }
            }
    }

    

}
