//
//  ImagePageViewController.swift
//  Journal App
//
//  Copyright (C) 2017 Apple Inc. All Rights Reserved.
//  See LICENSE.txt for this sample’s licensing information
//
//  Updated by Michael Wybrow 2024-05-07 for iOS 17 to fix page control bugs.
//
//  Abstract:
//  The primary view controller of this app for displaying the paginated scroll view.
//

import UIKit

class ImagePageViewController: UIViewController, UIScrollViewDelegate {

    weak var databaseController: DatabaseProtocol?
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var pageControl: UIPageControl!
    
    public var imageList = [UIImage?]()
    var pages = [UIView?]()
    var transitioning = false
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    
        /**
        Setup the initial scroll view content size and first pages only once.
        (Due to this function called each time views are added or removed).
        */
        _ = setupInitialPages
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        // get image models from database controller
        // extract into image list
        if let modelToImage = databaseController?.getImage() {
            // Map each model object to its corresponding UIImage
            let images: [UIImage] = modelToImage.map { model in
                return model.image
            }
            imageList = images
        }
        
        /**
        View controllers are created lazily, in the meantime, load the array with
        placeholders which will be replaced on demand.
        */
        pages = [UIView?](repeating: nil, count: imageList.count)
        
        pageControl.numberOfPages = imageList.count
        pageControl.currentPage = 0
        
        // add swipe gestuer to dismiss the page view controller
        let swipeDownGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        view.addGestureRecognizer(swipeDownGesture)
    }
    
    // swipe down to dismiss page view controller
    @objc func handleSwipe(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        if translation.y > 0 {
            dismiss(animated: true)
        }
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Initial Setup

    lazy var setupInitialPages: Void = {
        /**
        Setup our initial scroll view content size and first pages once.
        
        Layout the scroll view's content size after we have knowledge of the topLayoutGuide dimensions.
        Each page is the width and height of the scroll view's frame.
        
        Note: Set the scroll view's content size to take into account the top layout guide.
        */
        adjustScrollView()
        
        // Pages are created on demand, load the visible page and next page.
        loadPage(0)
        loadPage(1)
    }()
    // MARK: - Utilities
    
    fileprivate func removeAnyImages() {
        for page in pages where page != nil {
            page?.removeFromSuperview()
        }
    }
    
    /// Readjust the scroll view's content size in case the layout has changed.
    fileprivate func adjustScrollView() {
        scrollView.contentSize =
        CGSize(width: scrollView.frame.width * CGFloat(imageList.count),
                   height: scrollView.frame.height - view.safeAreaLayoutGuide.layoutFrame.minY)
    }
    
    // MARK: - Transitioning
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        
        /**
        Since we transitioned to a different screen size we need to reconfigure the scroll view content.
        Remove any the pages from our scrollview's content.
        */
        removeAnyImages()
        
        coordinator.animate(alongsideTransition: nil) { _ in
            // Adjust the scroll view's contentSize (larger or smaller) depending on the new transition size.
            self.adjustScrollView()

            // Clear out and reload the relevant pages.
            self.pages = [UIView?](repeating: nil, count: self.imageList.count)
            
            self.transitioning = true
            
            // Go to the appropriate page (but with no animation).
            self.gotoPage(page: self.pageControl.currentPage, animated: false)
            
            self.transitioning = false
        }
        
        super.viewWillTransition(to: size, with: coordinator)
    }
    
    // MARK: - Page Loading
    
    fileprivate func loadPage(_ page: Int) {
        guard page < imageList.count && page != -1 else { return }
        
        if pages[page] == nil {
            if let image = imageList[page] {
                // Load the image from our bundle.
                let newImageView = UIImageView(image: image)
                newImageView.contentMode = .scaleAspectFit
                newImageView.backgroundColor = .black
                
                /**
                Setup the canvas view to hold the image.
                Its frame will be the same as the scroll view's frame.
                */
                var frame = scrollView.frame
                // Offset the frame's X origin to its correct page offset.
                frame.origin.x = frame.width * CGFloat(page)
                // Set frame's y origin value to take into account the top layout guide.
                frame.origin.y = -self.view.safeAreaLayoutGuide.layoutFrame.minY
                frame.size.height += self.view.safeAreaLayoutGuide.layoutFrame.minY
                let canvasView = UIView(frame: frame)
                scrollView.addSubview(canvasView)
                
                // Setup the imageView's constraints to snap to all sides of its superview (canvasView).
                newImageView.translatesAutoresizingMaskIntoConstraints = false
                canvasView.addSubview(newImageView)
                
                NSLayoutConstraint.activate([
                    (newImageView.leadingAnchor.constraint(equalTo: canvasView.leadingAnchor)),
                    (newImageView.trailingAnchor.constraint(equalTo: canvasView.trailingAnchor)),
                    (newImageView.topAnchor.constraint(equalTo: canvasView.topAnchor)),
                    (newImageView.bottomAnchor.constraint(equalTo: canvasView.bottomAnchor))
                    ])
                
                pages[page] = canvasView
            }
        }
    }
    
    fileprivate func loadCurrentPages(page: Int) {
        // Load the visible page and the page on either side of it (to avoid flashes when the user starts scrolling).
        
        // Don't load if we are at the beginning or end of the list of pages.
        guard (page > 0 && page + 1 < imageList.count) || transitioning else { return }
        
        // Remove all of the images and start over.
        removeAnyImages()
        pages = [UIView?](repeating: nil, count: imageList.count)

        // Load the appropriate new pages for scrolling.
        loadPage(Int(page) - 1)
        loadPage(Int(page))
        loadPage(Int(page) + 1)
    }
    
    /// Updates the scroll view to display a particular page
    ///
    /// - Parameters:
    ///   - page: The index of the page to display
    ///   - animates: Whether the change should be animated
    fileprivate func gotoPage(page: Int, animated: Bool) {
        loadCurrentPages(page: page)
        
        // Update the scroll view scroll position to the appropriate page.
        var bounds = scrollView.bounds
        bounds.origin.x = bounds.width * CGFloat(page)
        bounds.origin.y = 0
        scrollView.scrollRectToVisible(bounds, animated: animated)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // Switch the indicator based on the page the scroll view ends on.
        let pageWidth = scrollView.frame.width
        let page = floor(scrollView.contentOffset.x / pageWidth)
        pageControl.currentPage = Int(page)
        
        
        loadCurrentPages(page: pageControl.currentPage)
    }
    
    // MARK: - Actions
    
    @IBAction func gotoPage(_ sender: UIPageControl) {
        // User tapped the page control at the bottom, so move to the newer page, with animation.
        gotoPage(page: sender.currentPage, animated: true)
    }

    @IBAction func dragLoadPage(_ sender: UIPageControl) {
        print(sender.currentPage)

        gotoPage(page: sender.currentPage, animated: false)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
