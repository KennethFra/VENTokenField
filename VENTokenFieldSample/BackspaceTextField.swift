//
//  BackspaceTextField.swift
//  TokenField
//
//  Created by Ken Franklin on 3/19/21.
//

import UIKit

protocol BackspaceTextFieldDelegate : UITextFieldDelegate {
    func textFieldDidEnterBackspace(textField: BackspaceTextField)
}

class BackspaceTextField : UITextField {
    var backspaceDelegate:  BackspaceTextFieldDelegate?

    override public func deleteBackward() {
        defer {
            super.deleteBackward()
        }
        
        guard let text = text, text.isEmpty else { return }
        backspaceDelegate?.textFieldDidEnterBackspace(textField: self)
    }
}
