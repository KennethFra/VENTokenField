//
//  Token.swift
//  VENTokenField
//
//  Created by Ken Franklin on 3/19/21.
//

import UIKit

typealias TapTokenHandler = ((Token) -> Void)

class Token : UIView {
    let backgroundGray = UIColor(displayP3Red: 233.0/255.0, green: 233.0/255.0, blue: 233.0/255.0, alpha: 1.0)

    var highlighted: Bool = false {
        didSet(newValue) {
            updateTinting()
        }
    }
    var didTapTokenBlock: TapTokenHandler? = nil
    var colorScheme: UIColor = .systemTeal {
        didSet {
            updateTinting()
        }
    }

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

    func updateTinting() {
        titleLabel.textColor = highlighted ? .white : colorScheme
        backgroundView.backgroundColor = highlighted ? colorScheme : backgroundGray
    }
    
    @objc func didTapToken(tapGestureRecognizer: UITapGestureRecognizer) {
        didTapTokenBlock?(self)
    }
}

