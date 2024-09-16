//
//  CoreDataController.swift
//  Journal App
//
//  Created by Hui Ying on 02/06/2024.
//

import UIKit
import CoreData

class CoreDataController: NSObject {
    
    var persistentContainer: NSPersistentContainer
    
    override init(){
        persistentContainer = NSPersistentContainer(name: "Journal-DataModel")
        persistentContainer.loadPersistentStores() {(description, error) in
            if  let error = error
            {
                fatalError("Failed to load Core Data Stack with error: \(error)")
            }
        }
        super.init()
    }
    
    func cleanup(){
        if persistentContainer.viewContext.hasChanges {
            do {
                try persistentContainer.viewContext.save()
            } catch {
                fatalError("Failed to save changes to Core Data with error: \(error)")
            }
        }
    }
    
    func saveJournalImage(id: String, date: Date, imageURL: String, userID: String) {
        let journalImage = MyJournalImage(context: persistentContainer.viewContext)
        journalImage.id = id
        journalImage.date = date
        journalImage.imageURL = imageURL
        journalImage.userID = userID
        cleanup()
    }
    
    func fetchJournalImages(for date: Date, userID: String) -> [MyJournalImage] {
        // creat efetch request date and user id as predicate
        let fetchRequest: NSFetchRequest<MyJournalImage> = MyJournalImage.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "date == %@ AND userID == %@", date as NSDate, userID)
        do {
            // return the result of fetch
            return try persistentContainer.viewContext.fetch(fetchRequest)
        } catch {
            print("Failed to fetch image metadata: \(error.localizedDescription)")
            return []
        }
    }
    
    func deleteJournalImage(by id: String) {
        // create fetch frequest with imageid
        let fetchRequest: NSFetchRequest<MyJournalImage> = MyJournalImage.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)
        
        do {
            if let journalImage = try persistentContainer.viewContext.fetch(fetchRequest).first {
                // delete the image
                persistentContainer.viewContext.delete(journalImage)
                cleanup()
            }
        } catch {
            print("Failed to delete image metadata: \(error.localizedDescription)")
        }
    }
}
