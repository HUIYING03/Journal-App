//
//  HeaderView.swift
//  Journal App
//
//  Created by Hui Ying on 04/06/2024.
// https://stackoverflow.com/questions/31964941/swift-how-to-make-custom-header-for-uitableview
//

import UIKit

class HeaderView: UIView {

    private var lableText: String
    private var lableSize: Int

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(frame: CGRect, lableText: String, lableSize: Int = 17) {
        self.lableText = lableText
        self.lableSize = lableSize
        super.init(frame: frame)
        setupView()
        titleLabel.text = lableText
        titleLabel.font = UIFont.boldSystemFont(ofSize: CGFloat(lableSize))
    }
    
    required init?(coder: NSCoder) {
        self.lableText = ""
        self.lableSize = 17
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        addSubview(titleLabel)
        
        // Layout constraints for titleLabel
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -8),
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 8)
        ])
    }
}
