//
//  Token.swift
//  VENTokenField
//
//  Created by Ken Franklin on 3/19/21.
//

import UIKit

class Token : UIView {
    var highlighted: Bool = false
    var didTapTokenBlock: (() -> Void)? = nil
    var colorScheme: UIColor = .systemTeal

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var backgroundView: UIView!

    class func instanceFromNib() -> Token {
        return UINib(nibName: "Token", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! Token
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }

    func setup() {
        backgroundView.layer.cornerRadius = 5
        let tapGestureRecognizer = UITapGestureRecognizer.init(target: self, action: #selector(didTapToken))
        addGestureRecognizer(tapGestureRecognizer)

        colorScheme = .systemBlue
        titleLabel.textColor = colorScheme
    }

    func setTitle(text: String) {
        titleLabel.text = text;
        titleLabel.textColor = self.colorScheme;
        titleLabel.sizeToFit()
        frame = CGRect(x: frame.minX, y: frame.minY, width: titleLabel.frame.maxX + 3, height: frame.height)
        titleLabel.sizeToFit()
    }

    func setHighlighted(highlighted: Bool) {
        // TODO USE didSet
        self.highlighted = highlighted
        titleLabel.textColor = highlighted ? .white : colorScheme
        backgroundView.backgroundColor = highlighted ? colorScheme : .clear
    }

    func setColorScheme(colorScheme: UIColor) {
        // TODO USE didSet
        self.colorScheme = colorScheme
        titleLabel.textColor = colorScheme
        setHighlighted(highlighted: highlighted)
    }

    @objc func didTapToken(tapGestureRecognizer: UITapGestureRecognizer) {
        didTapTokenBlock?()
    }
}

