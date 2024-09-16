//
//  MyJournalImage+CoreDataProperties.swift
//  Journal App
//
//  Created by Hui Ying on 02/06/2024.
//
//

import Foundation
import CoreData


extension MyJournalImage {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MyJournalImage> {
        return NSFetchRequest<MyJournalImage>(entityName: "MyJournalImage")
    }

    @NSManaged public var id: String?
    @NSManaged public var date: Date?
    @NSManaged public var userID: String?
    @NSManaged public var imageURL: String?

}

extension MyJournalImage : Identifiable {

}
