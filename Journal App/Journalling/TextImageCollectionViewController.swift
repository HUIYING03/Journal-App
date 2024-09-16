//
//  TextImageCollectionViewController.swift
//  Journal App
//
//  Created by Hui Ying on 01/05/2024.
//

import UIKit
import SpriteKit

private let reuseIdentifier = "Cell"

class TextImageCollectionViewController: UICollectionViewController,UIImagePickerControllerDelegate, UINavigationControllerDelegate, DatabaseListener, UITextViewDelegate, ImageCollectionViewCellDelegate{
    
    var listenerType: ListenerType = .date
    
    let SECTION_TEXT = 0
    let SECTION_IMAGE = 1

    let CELL_TEXT = "textCell"
    let CELL_IMAGE = "imageCell"
    
    var images : [JournalImageModel] = []
    var currentDate: Date?
    var texts: String?
    
    
    weak var databaseController: DatabaseProtocol?
    var textViewHolder : TextCollectionViewCell?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        // set the layout of collection view
        collectionView.setCollectionViewLayout(collectionLayout(), animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        databaseController?.addListener(listener: self)
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        databaseController?.removeListener(listener: self)
    }
    
    // MARK: Database listener delegate methods
    
    func onScheduleChange(change: DatabaseChange, schedule: [Schedule], date: Date) {
        
    }

    func onTaskChange(change: DatabaseChange, tasks: [TaskTodo]) {
        
    }
    
    // If date changed, reload collection view with updated data
    func onDateChange(change: DatabaseChange, date: Date, text: String, image: [JournalImageModel]) {
        currentDate = date
        images = image.sorted{$0.date < $1.date}
        texts = text
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentDate ?? Date())
        self.navigationItem.title = dateString
        collectionView.reloadData()
    }
    
    // Swipe down to dismiss the keyboard
    @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if translation.y > 0 {
            textViewHolder?.endEditing(true)
        }
    }

    // MARK: Set collection layout

    func collectionLayout() -> UICollectionViewLayout {
           // Create item size for the first section (vertical scrolling)
        let itemSizeSection1 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                     heightDimension: .fractionalHeight(1.0))
        let itemSection1 = NSCollectionLayoutItem(layoutSize: itemSizeSection1)
        let groupSizeSection1 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                      heightDimension: .fractionalHeight(0.6))
        let groupSection1 = NSCollectionLayoutGroup.horizontal(
            layoutSize: groupSizeSection1,
            repeatingSubitem: itemSection1,
            count: 1)
        // Create a section for the first section
        let section1 = NSCollectionLayoutSection(group: groupSection1)

        // Create item size for the second section (horizontal scrolling)
        let itemSizeSection2 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .fractionalHeight(1.0))
        let itemSection2 = NSCollectionLayoutItem(layoutSize: itemSizeSection2)

        let groupSizeSection2 = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.8), heightDimension: .fractionalHeight(0.2))
        
        let groupSection2 = NSCollectionLayoutGroup.horizontal(layoutSize: groupSizeSection2, subitems: [itemSection2])
        groupSection2.interItemSpacing = .fixed(10)
        // Create a section for the second section
        let section2 = NSCollectionLayoutSection(group: groupSection2)
        section2.orthogonalScrollingBehavior = .continuous
        section2.interGroupSpacing = 10

        // Create a layout with both sections
        let layout = UICollectionViewCompositionalLayout { (sectionIndex, _) -> NSCollectionLayoutSection? in
           switch sectionIndex {
           case 0:
               return section1
           case 1:
               return section2
           default:
               return nil
           }
        }
        return layout
       }
    
    // MARK: Image attachment
    
    @IBAction func addPhotoAction(_ sender: Any) {
        textViewHolder?.journalText.resignFirstResponder()
        
        let controller = UIImagePickerController()
        controller.allowsEditing = false
        controller.delegate = self
        
        // present sheet for image source selection
        let actionSheet = UIAlertController(title: nil, message: "Select Option:", preferredStyle: .actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { action in
            controller.sourceType = .camera
            self.present(controller, animated: true, completion: nil)
        }
        let libraryAction = UIAlertAction(title: "Photo Library", style: .default) { action in self.present(controller, animated: true, completion: nil)
        }
        controller.sourceType = .photoLibrary
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actionSheet.addAction(cameraAction)
        }
        actionSheet.addAction(libraryAction)
        actionSheet.addAction(cancelAction)
        self.present(actionSheet, animated: true, completion: nil)
    }

    // if picked an image, save it and dismiss the image picker
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            databaseController?.saveJournalImage(currentDate: currentDate!, indexPathItem: images.count-1, image: pickedImage)
            collectionView.reloadData()
            dismiss(animated: true, completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    // delete image using the small cross button
    func didTapDeleteButton(at indexPath: IndexPath) {
        let imageModel = images.remove(at: indexPath.item)
        databaseController?.deleteJournalImage(imageModel: imageModel)
        collectionView.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        switch section {
        case SECTION_TEXT: return 1
        case SECTION_IMAGE: return images.count
        default: return 0
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == SECTION_TEXT {
            let textCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_TEXT, for: indexPath) as! TextCollectionViewCell
            textCell.delegate = self
            textCell.journalText.text = self.texts ?? ""
            // placeholder text
            if textCell.journalText.text == "" {
                textCell.journalText.text = textCell.placeholder
                textCell.journalText.textColor = .placeholderText
            }
            else {
                // set text colour
                if self.traitCollection.userInterfaceStyle == .dark {
                    textCell.journalText.textColor = .lightText
                } else {
                    textCell.journalText.textColor = .darkText
                }
            }
            // add gestuer to dismiss keyboard
            let swipeDownGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
            textCell.addGestureRecognizer(swipeDownGesture)
            self.textViewHolder = textCell
            return textCell
        } else {
            let imageCell = collectionView.dequeueReusableCell(withReuseIdentifier: CELL_IMAGE, for: indexPath) as! ImageCollectionViewCell
            imageCell.delegate = self
            imageCell.indexPath = indexPath
            imageCell.journalImage.image = images[indexPath.item].image
            return imageCell
        }
    }
    
    // MARK: Present calendar picker
    
    // present date picker
    @IBAction func selectDate(_ sender: UIBarButtonItem) {
        textViewHolder?.journalText.resignFirstResponder()
        
        if let presentedPopover = presentedViewController as? CalendarPickViewController {
            presentedPopover.dismiss(animated: false, completion: nil)
        }
        
        let popOverController = CalendarPickViewController()
        // set date pick for controller function = date picked function
        // to call in view did load method of Calendar Pick View Controller
        popOverController.datePickForController = { [weak self] dateString in
            self?.databaseController?.datePicked(dateString: dateString)
        }
        popOverController.modalPresentationStyle = .pageSheet
        popOverController.sheetPresentationController?.detents = [.medium()]
        
        self.present(popOverController, animated: true)
    }

    // MARK: UICollectionViewDelegate

    // if select the image, show page view of the images
    // reference: FIT3178-W10 Apple Sample Project - Paginated Scroll View
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == SECTION_IMAGE {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let imagePageViewController = storyboard.instantiateViewController(withIdentifier: "ImagePageViewController")
            present(imagePageViewController, animated: true)
        }
    }
    
}

extension TextImageCollectionViewController: TextCollectionViewCellDelegate {
    
    // text cell end editing
    func textCellDidEndEditing(_ cell: TextCollectionViewCell, text: String?) {
        // if text exists
        if let text = text {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let date = dateFormatter.string(from: currentDate ?? Date())
            // save the text
            databaseController?.saveText(dateString: date, text: text)
        }
        // if text is empty
        if (text == ""){
            // set placeholder text
            cell.journalText.text = cell.placeholder
            cell.journalText.textColor = .lightGray
        }
        cell.resignFirstResponder()
        
    }
    
}
