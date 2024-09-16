//
//  TextCollectionViewCell.swift
//  Journal App
//
//  Created by Hui Ying on 01/05/2024.
//

import UIKit

protocol TextCollectionViewCellDelegate: AnyObject {
    func textCellDidEndEditing(_ cell: TextCollectionViewCell, text: String?)
}

class TextCollectionViewCell: UICollectionViewCell, UITextViewDelegate {
    
    @IBOutlet weak var journalText: UITextView!
    
    weak var delegate: TextCollectionViewCellDelegate?
    
    public var placeholder = "1. Press anywhere to enter text :)" + "\n\n2. Tap on the camera button to upload images" + "\n\n3. Press done to save the text and images\n\n" +
    "4. Tap on the images uploaded to view in a larger size!!"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        journalText.delegate = self
        journalText.isEditable = true
    }
    
    
    func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        // Save the text when the user finishes editing
        textView.resignFirstResponder() // Dismiss the keyboard
        delegate?.textCellDidEndEditing(self, text: textView.text)
        return true
    }
    
    // When user start editing the text view
    // if the text in the text view is the placeholder text
    // clear the text view
    // https://stackoverflow.com/questions/1328638/placeholder-in-uitextview/1704469#1704469
    func textViewDidBeginEditing(_ textView: UITextView){
        if (textView.text == placeholder && textView.textColor == .placeholderText){
            textView.text = ""
        }
        textView.becomeFirstResponder()
    }
}

