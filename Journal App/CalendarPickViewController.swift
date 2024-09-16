//
//  CalendarPickViewController.swift
//  Journal App
//
//  Created by Hui Ying on 22/04/2024.
//

import UIKit

class CalendarPickViewController: UIViewController {
    
    // function variable
    // allow other view controller set function as attribute for this
    // calendar pick view controller
    public var datePickForController : ((String) -> Void)?

    @IBAction func datePicked(_ sender: Any) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: datePicker.date)
        // call the function attribute
        datePickForController?(dateString)
        dismiss(animated: true)
    }
    
    @IBOutlet weak var datePicker: UIDatePicker!
    
    init(){
        super.init(nibName: "CalendarPickViewController", bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datePicker.maximumDate = Date()
    }
}
