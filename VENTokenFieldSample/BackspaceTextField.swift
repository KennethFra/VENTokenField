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

    func keyboardInputShouldDelete(textField: UITextField) -> Bool {
        guard let text = text, text.isEmpty else { return true }
        backspaceDelegate?.textFieldDidEnterBackspace(textField: self)
        return true
    }
}
