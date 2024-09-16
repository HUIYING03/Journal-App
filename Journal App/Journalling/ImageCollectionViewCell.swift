//
//  ImageCollectionViewCell.swift
//  Journal App
//
//  Created by Hui Ying on 01/05/2024.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell{
    
    weak var delegate: ImageCollectionViewCellDelegate?
    var indexPath: IndexPath?

    @IBOutlet weak var journalImage: UIImageView!
    @IBOutlet weak var deleteButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        journalImage.contentMode = .scaleAspectFill
        journalImage.clipsToBounds = true
        // set the button
        deleteButton.backgroundColor = UIColor.opaqueSeparator.withAlphaComponent(0.5)
        deleteButton.tintColor = .systemGray
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)}
    
    // if delete button tapped, call the did tap delete button in
    // the collection view controller to delete the image
    @IBAction func deleteButtonTapped(_ sender: Any) {
            guard let indexPath = indexPath else { return }
            delegate?.didTapDeleteButton(at: indexPath)
        }
}

protocol ImageCollectionViewCellDelegate: AnyObject {
    func didTapDeleteButton(at indexPath: IndexPath)
}
