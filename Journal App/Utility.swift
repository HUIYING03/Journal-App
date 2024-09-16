//
//  Utility.swift
//  Journal App
//
//  Created by Hui Ying on 05/06/2024.
//

import Foundation
import UIKit

class Util {
    
    // allow reuse and customisation for alert controller display
    static func displayWithAction(on viewController: UIViewController, title: String, message: String, actionTitle: String?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        if actionTitle != nil{
            let okAction = UIAlertAction(title: actionTitle, style: .default, handler: nil)
            alertController.addAction(okAction)
        }
        viewController.present(alertController, animated: true, completion: nil)
    }
}
