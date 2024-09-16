//
//  TaskTodo.swift
//  Journal App
//
//  Created by Hui Ying on 13/05/2024.
//

import UIKit
import FirebaseFirestoreSwift

class TaskTodo: NSObject, Codable {

    var id: String?
    var title: String?
    var details: String?
    var priority: Int?
    var tag: String?
    var dueDate: Date?
    var reminder: Bool = false
    var isComplete = false
    var order: Int?
    
}
