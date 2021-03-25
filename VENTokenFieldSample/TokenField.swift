//
//  TokenField.swift
//
//  Created by Ken Franklin on 3/19/21.
//

import UIKit

let tokenFieldDefaultVerticalInset: CGFloat = 7.0
let tokenFieldDefaultHorizontalInset: CGFloat = 15.0
let tokenFieldDefaultToLabelPadding: CGFloat = 5.0
let tokenFieldDefaultTokenPadding: CGFloat = 7.0
let tokenFieldDefaultMinInputWidth: CGFloat = 80.0
let tokenFieldDefaultMaxHeight: CGFloat = 150.0
let heightForToken: CGFloat = 30.0

@objc
public protocol TokenFieldDelegate {
    func tokenField(tokenField: TokenField, didEnterText text: String?)
    func tokenField(tokenField: TokenField, didDeleteToken atIndex: UInt32)
    func tokenField(tokenField: TokenField, didChangeText text: String?)
    func tokenField(tokenField: TokenField, didChangeChangeContentHeight height: CGFloat)
    func tokenFieldDidBeginEditing(tokenField: TokenField)
}

public extension TokenFieldDelegate {
    func tokenField(tokenField: TokenField, didEnterText text: String?) {}
    func tokenField(tokenField: TokenField, didDeleteToken atIndex: UInt32) {}
    func tokenField(tokenField: TokenField, didChangeText text: String?) {}
    func tokenField(tokenField: TokenField, didChangeChangeContentHeight height: CGFloat) {}
    func tokenFieldDidBeginEditing(tokenField: TokenField) {}
}

@objc
public protocol TokenFieldDataSource {
    func tokenField(tokenField: TokenField, titleForTokenAt index: UInt32) -> String
    func numberOfTokensInTokenField(tokenField: TokenField) -> UInt32
    func tokenFieldCollapsedText(tokenField: TokenField) -> String
    func tokenField(tokenField: TokenField, colorSchemeForTokenAt index: UInt32) -> UIColor
}

public extension TokenFieldDataSource {
    func tokenField(tokenField: TokenField, titleForTokenAt index: UInt32) -> String { return "" }
    func numberOfTokensInTokenField(tokenField: TokenField) -> UInt32 { return 0 }
    func tokenFieldCollapsedText(tokenField: TokenField) -> String { return "" }
    func tokenField(tokenField: TokenField, colorSchemeForTokenAt index: UInt32) -> UIColor { return .black }
}

@objc
public class TokenField: UIView, BackspaceTextFieldDelegate {
    var scrollView: UIScrollView?
    var tokens = [Token]()
    var originalHeight: CGFloat = 0.0
    var tapGestureRecognizer: UITapGestureRecognizer!
    var invisibleTextField: BackspaceTextField?
    lazy var inputTextField: BackspaceTextField = {
        let tf = BackspaceTextField()
        tf.keyboardType = inputTextFieldKeyboardType
        tf.textColor = inputTextFieldTextColor
        tf.font = UIFont.boldSystemFont(ofSize: 15.5)
        tf.autocorrectionType = autocorrectionType
        tf.autocapitalizationType = autocapitalizationType
        tf.tintColor = colorScheme
        tf.delegate = self
        tf.backspaceDelegate = self
        tf.placeholder = placeholderText
        tf.accessibilityLabel = inputTextFieldAccessibilityLabel ?? "Register"
        tf.inputAccessoryView = inputTextFieldAccessoryView
        tf.addTarget(self, action: #selector(inputTextFieldDidChange(textField:)), for: .editingChanged)
        return tf
    }()

    @objc var colorScheme: UIColor = .systemBlue {
        didSet(newColor) {
            collapsedLabel.textColor = newColor
            inputTextField.tintColor = newColor
            tokens.forEach { $0.colorScheme = newColor }
        }
    }
    var collapsedLabel = UILabel()

    @objc var delegate: TokenFieldDelegate?
    @objc var dataSource: TokenFieldDataSource?

    var maxHeight: CGFloat = 0.0
    var verticalInset: CGFloat = 0.0
    var horizontalInset: CGFloat = 0.0
    var minInputWidth: CGFloat = 0.0
    var tokenPadding: CGFloat = tokenFieldDefaultTokenPadding
    var isCollapsed: Bool {
        collapsedLabel.superview != nil
    }
    
    var inputTextFieldKeyboardType: UIKeyboardType = .emailAddress {
        didSet {
            inputTextField.keyboardType = inputTextFieldKeyboardType
        }
    }
    var inputTextFieldKeyboardAppearance: UIKeyboardAppearance = .default {
        didSet {
            inputTextField.keyboardAppearance = inputTextFieldKeyboardAppearance
        }
    }
    var autocorrectionType: UITextAutocorrectionType = .no {
        didSet {
            inputTextField.autocorrectionType = autocorrectionType
            invisibleTextField?.autocorrectionType = autocorrectionType
        }
    }
    var autocapitalizationType: UITextAutocapitalizationType = .none {
        didSet {
            inputTextField.autocapitalizationType = autocapitalizationType
            invisibleTextField?.autocapitalizationType = autocapitalizationType
        }
    }
    
    var inputTextFieldAccessoryView: UIView? {
        didSet {
            inputTextField.inputAccessoryView = self.inputTextFieldAccessoryView
        }
    }
    
    var inputText: String? {
        inputTextField.text ?? ""
    }

    @objc var inputTextFieldTextColor: UIColor = .black {
        didSet {
            inputTextField.textColor = inputTextFieldTextColor
        }
    }
    
    @objc var delimiters = [String]()
    
    @objc var placeholderText: String? {
        didSet {
            inputTextField.placeholder = placeholderText
        }
    }
    
    @objc var inputTextFieldAccessibilityLabel: String? {
        didSet {
            inputTextField.accessibilityLabel = self.inputTextFieldAccessibilityLabel
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        setUpInit()
    }

    @available(*, unavailable)
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override public func awakeFromNib() {
        super.awakeFromNib()
        setUpInit()
    }

    func isFirstResponder() -> Bool {
        return inputTextField.isFirstResponder
    }

    @discardableResult
    override public func becomeFirstResponder() -> Bool {
        layoutTokensAndInputWithFrameAdjustment(shouldAdjustFrame: true)
        inputTextFieldBecomeFirstResponder()
        return true
    }

    override public func resignFirstResponder() -> Bool {
        super.resignFirstResponder()
        return inputTextField.resignFirstResponder()
    }

    func setUpInit() {
        autocorrectionType = .no
        autocapitalizationType = .sentences
        maxHeight = tokenFieldDefaultMaxHeight
        verticalInset = tokenFieldDefaultVerticalInset
        horizontalInset = tokenFieldDefaultHorizontalInset
        tokenPadding = tokenFieldDefaultTokenPadding
        minInputWidth = tokenFieldDefaultMinInputWidth
        colorScheme = .blue
        inputTextFieldTextColor = UIColor(displayP3Red: 38.0/255.0, green: 39.0/255.0, blue: 41.0/255.0, alpha: 1.0)

        originalHeight = frame.height
        layoutInvisibleTextField()

        layoutScrollView()
        reloadData()
    }

    @objc
    public func reloadData() {
        layoutTokensAndInputWithFrameAdjustment(shouldAdjustFrame: true)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        guard let scrollView = scrollView else { return }
        scrollView.contentSize = CGSize(width: frame.width - horizontalInset * 2, height: frame.height - verticalInset * 2)
        layoutTokensAndInputWithFrameAdjustment(shouldAdjustFrame: false)
    }

    func layoutTokensAndInputWithFrameAdjustment(shouldAdjustFrame: Bool) {
        guard let scrollView = scrollView else { return }
        collapsedLabel.removeFromSuperview()
        let inputFieldShouldBecomeFirstResponder = inputTextField.isFirstResponder
        scrollView.subviews.forEach { $0.removeFromSuperview() }
        scrollView.isHidden = false

        if let tapGestureRecognizer = tapGestureRecognizer {
            removeGestureRecognizer(tapGestureRecognizer)
        }

        tokens.removeAll()

        var currentX: CGFloat = 0
        var currentY: CGFloat = 0

        layoutTokensWith(currentX: &currentX, currentY: &currentY)

        layoutInputTextFieldWithCurrentX(currentX: &currentX, currentY: &currentY, clearInput: shouldAdjustFrame)

        if shouldAdjustFrame {
            adjustHeightForCurrentY(currentY: currentY)
        }

        scrollView.contentSize = CGSize(width: scrollView.contentSize.width, height: currentY + heightForToken)

        updateInputTextField()

        if inputFieldShouldBecomeFirstResponder {
            inputTextFieldBecomeFirstResponder()
        } else {
            focusInputTextField()
        }
    }

    func layoutScrollView() {
        scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height))
        scrollView?.scrollsToTop = false
        scrollView?.contentSize = CGSize(width: frame.width - horizontalInset * 2, height: frame.height - verticalInset * 2)
        scrollView?.contentInset = UIEdgeInsets(top: verticalInset,
                                                left: horizontalInset,
                                                bottom: verticalInset,
                                                right: horizontalInset)
        scrollView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        addSubview(scrollView!)
    }

    func layoutInputTextFieldWithCurrentX(currentX: inout CGFloat, currentY: inout CGFloat, clearInput: Bool) {
        guard let scrollView = scrollView else { return }

        var inputTextFieldWidth = scrollView.contentSize.width - currentX
        if inputTextFieldWidth < minInputWidth {
            inputTextFieldWidth = scrollView.contentSize.width
            currentY += heightForToken
            currentX = 0
        }

        if clearInput {
            inputTextField.text = ""
        }
        inputTextField.frame = CGRect(x: currentX, y: currentY + 1, width: inputTextFieldWidth, height: heightForToken - 1)
        inputTextField.tintColor = colorScheme
        scrollView.addSubview(inputTextField)
    }

    func layoutTokensWith(currentX: inout CGFloat, currentY: inout CGFloat) {
        guard let scrollView = scrollView else { return }

        for i in 0 ..< numberOfTokens() {
            let title = titleForTokenAt(index: i)
            let token = Token.instanceFromNib()
            token.didTapTokenBlock = { [weak self] token in
                self?.didTapToken(token: token)
            }

            token.setTitle(text: "\(title)")
            token.colorScheme = colorSchemeForTokenAt(index: i)

            tokens.append(token)

            if currentX + token.frame.width <= scrollView.contentSize.width {
                token.frame = CGRect(x: currentX, y: currentY, width: token.frame.width, height: token.frame.height)
            } else {
                currentY += token.frame.height
                currentX = 0
                var tokenWidth = token.frame.width
                if tokenWidth > scrollView.contentSize.width { // token is wider than max width
                    tokenWidth = scrollView.contentSize.width
                }
                token.frame = CGRect(x: currentX, y: currentY, width: tokenWidth, height: token.frame.height)
            }
            currentX += token.frame.width + tokenPadding
            scrollView.addSubview(token)
        }
    }

    func layoutInvisibleTextField() {
        invisibleTextField = BackspaceTextField()

        invisibleTextField?.autocorrectionType = autocorrectionType
        invisibleTextField?.autocapitalizationType = autocapitalizationType
        invisibleTextField?.backspaceDelegate = self

        addSubview(invisibleTextField!)
    }

    func inputTextFieldBecomeFirstResponder() {
        guard inputTextField.isFirstResponder == false else { return }

        inputTextField.becomeFirstResponder()
        delegate?.tokenFieldDidBeginEditing(tokenField: self)
    }

    func adjustHeightForCurrentY(currentY: CGFloat) {
        let oldHeight = frame.height
        var height: CGFloat = 0
        if currentY + heightForToken > frame.height { // needs to grow
            if currentY + heightForToken <= frame.height {
                height = currentY + heightForToken + verticalInset * 2
            } else {
                height = frame.height
            }
        } else { // needs to shrink
            if currentY + heightForToken > originalHeight {
                height = currentY + heightForToken + verticalInset * 2
            } else {
                height = originalHeight
            }
        }

        if oldHeight != height {
            frame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: height)

            delegate?.tokenField(tokenField: self, didChangeChangeContentHeight: height)
        }
    }

    @objc func inputTextFieldDidChange(textField: UITextField) {
        delegate?.tokenField(tokenField: self, didChangeText: textField.text)
    }

    @objc func handleSingleTap(gestureRecognizer: UITapGestureRecognizer) {
        _ = becomeFirstResponder()
    }

    func didTapToken(token: Token) {
        for aToken in tokens {
            if aToken == token {
                aToken.highlighted = !aToken.highlighted
            } else {
                aToken.highlighted = false
            }
        }

        setCursorVisibility()
    }

    func unhighlightAllTokens() {
        for token in tokens {
            token.highlighted = false
        }

        setCursorVisibility()
    }

    func setCursorVisibility() {
        let highlightedTokens = tokens.filter { token in
            token.highlighted
        }

        if highlightedTokens.isEmpty {
            inputTextFieldBecomeFirstResponder()
        } else {
            invisibleTextField?.becomeFirstResponder()
        }
    }

    func updateInputTextField() {
        inputTextField.placeholder = tokens.count > 0 ? nil : placeholderText
    }

    func focusInputTextField() {
        guard let scrollView = scrollView else { return }

        let contentOffset = scrollView.contentOffset

        let targetY = inputTextField.frame.minY + heightForToken - frame.height
        if targetY > contentOffset.y {
            scrollView.setContentOffset(CGPoint(x: contentOffset.x, y: targetY), animated: false)
        }
    }

    func colorSchemeForTokenAt(index: UInt32) -> UIColor {
        return dataSource?.tokenField(tokenField: self, colorSchemeForTokenAt: index) ?? colorScheme
    }

    func titleForTokenAt(index: UInt32) -> String {
        dataSource?.tokenField(tokenField: self, titleForTokenAt: index) ?? ""
    }

    func numberOfTokens() -> UInt32 {
        return dataSource?.numberOfTokensInTokenField(tokenField: self) ?? 0
    }

    func collapsedText() -> String {
        return dataSource?.tokenFieldCollapsedText(tokenField: self) ?? ""
    }

    // #pragma mark - UITextFieldDelegate
    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return ((delegate?.tokenField(tokenField: self, didEnterText: textField.text)) != nil)
    }

    public func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField == inputTextField {
            unhighlightAllTokens()
        }
    }

    public func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        unhighlightAllTokens()
        guard let s = textField.text else { return true }

        let newString = s.replacingCharacters(in: Range(range, in: s)!, with: string)

        for delimiter in delimiters where newString.hasSuffix(delimiter) {
            let enteredString = newString.dropLast(delimiter.count)
            if enteredString.count > 0 {
                delegate?.tokenField(tokenField: self, didEnterText: String(enteredString))
                return false
            }
        }

        return true
    }

    func textFieldDidEnterBackspace(textField: BackspaceTextField) {
        guard let delegate = delegate, numberOfTokens() > 0 else { return }

        var didDeleteToken = false

        for token in tokens {
            if token.highlighted, let index = tokens.firstIndex(of: token) {
                delegate.tokenField(tokenField: self, didDeleteToken: UInt32(index))
                didDeleteToken = true
                break
            }
        }

        if !didDeleteToken {
            if let lastToken = tokens.last {
                lastToken.highlighted = true
            }
        }
        setCursorVisibility()
    }
}
