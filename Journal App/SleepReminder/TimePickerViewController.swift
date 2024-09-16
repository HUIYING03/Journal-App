//
//  TimePickerViewController.swift
//  Journal App
//
//  Created by Hui Wong on 20/5/2024.
//

import UIKit

class TimePickerViewController: UIViewController {

    var delegate: ChangeTimeDelegate?
    
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var reminderSwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        timePicker.datePickerMode = .time
        // add toolbar
        let toolbarHeight: CGFloat = 44
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: toolbarHeight))
        toolbar.autoresizingMask = [.flexibleWidth]
        view.addSubview(toolbar)
       
        // Add toolbar items
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelButtonTapped))
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneButtonTapped))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
       
        toolbar.items = [cancelButton, flexibleSpace, doneButton]
    }
    
    // dismiss the sheet
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    // update the view controller
    @objc func doneButtonTapped() {
        delegate?.timeChanged(timePicker.date)
        delegate?.reminderToggle(reminderSwitch.isOn)
        dismiss(animated: true, completion: nil)
    }
}

protocol ChangeTimeDelegate: AnyObject{
    func timeChanged(_ time: Date);
    func reminderToggle(_ isOn: Bool);
}
