//
//  TokenField.swift
//
//  Created by Ken Franklin on 3/19/21.
//

import UIKit

let tokenFieldDefaultVerticalInset: CGFloat      = 7.0
let tokenFieldDefaultHorizontalInset: CGFloat    = 15.0
let tokenFieldDefaultToLabelPadding: CGFloat     = 5.0
let tokenFieldDefaultTokenPadding: CGFloat       = 2.0
let tokenFieldDefaultMinInputWidth: CGFloat      = 80.0
let tokenFieldDefaultMaxHeight: CGFloat          = 150.0
let heightForToken: CGFloat = 30.0

protocol TokenFieldDelegate {
    func tokenField(tokenField: TokenField, didEnterText text: String?)
    func tokenField(tokenField: TokenField, didDeleteToken atIndex: UInt32)
    func tokenField(tokenField: TokenField, didChangeText text: String?)
    func tokenField(tokenField: TokenField, didChangeChangeContentHeight height: CGFloat)
    func tokenFieldDidBeginEditing(tokenField: TokenField)
}

protocol TokenFieldDataSource {
    func tokenField(tokenField: TokenField, titleForTokenAt index: UInt32) -> String
    func numberOfTokensInTokenField(tokenField: TokenField) -> UInt32
    func tokenFieldCollapsedText(tokenField: TokenField) -> String
    func tokenField(tokenField: TokenField, colorSchemeForTokenAt index: UInt32) -> UIColor
}

class TokenField: UIView, BackspaceTextFieldDelegate  {
    var scrollView: UIScrollView?
    var tokens = [Token]()
    var originalHeight: CGFloat = 0.0
    var tapGestureRecognizer: UITapGestureRecognizer!
    var invisibleTextField: BackspaceTextField?
    var inputTextField: BackspaceTextField = {
        let tf = BackspaceTextField()
        tf.keyboardType = inputTextFieldKeyboardType
        tf.textColor = inputTextFieldTextColor
        tf.font = UIFont(name: "HelveticaNeue", size: 15.5)
        tf.autocorrectionType = autocorrectionType
        tf.autocapitalizationType = autocapitalizationType
        tf.tintColor = colorScheme
        tf.delegate = self
        tf.backspaceDelegate = self
        tf.placeholder = placeholderText
        tf.accessibilityLabel = inputTextFieldAccessibilityLabel ?? "To"
        tf.inputAccessoryView = inputTextFieldAccessoryView
        tf.addTarget:self action:@selector(inputTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];

    }
    var colorScheme: UIColor = .systemBlue
    var collapsedLabel: UILabel
    var delegate: TokenFieldDelegate?
    var dataSource: TokenFieldDataSource?

    var maxHeight: CGFloat
    var verticalInset: CGFloat
    var horizontalInset: CGFloat
    var minInputWidth: CGFloat
    var tokenPadding: CGFloat

    var inputTextFieldKeyboardType: UIKeyboardType
    var inputTextFieldKeyboardAppearance: UIKeyboardAppearance
    var autocorrectionType: UITextAutocorrectionType
    var autocapitalizationType: UITextAutocapitalizationType
    var inputTextFieldAccessoryView: UIView?
    var toLabelTextColor: UIColor = .black
    var toLabelText: String?
    lazy var toLabel: UILabel = {
        let l = UILabel()
        l.textColor = toLabelTextColor
        l.font = UIFont(name: "HelveticaNeue", size: 15.5)
        l.frame = CGRect(x: 0, y: 0, width: 0, height: heightForToken)
        l.text = toLabelText
        l.sizeToFit()
    }()

    var inputTextFieldTextColor: UIColor
    var delimiters: [String]?
    var placeholderText: String?
    var inputTextFieldAccessibilityLabel: String?

    func getLabel() -> UILabel {
        toLabel.text = toLabelText
        return toLabel
    }

    func inputText() -> String? {
    }

//- (instancetype)initWithFrame:(CGRect)frame
//{
//    self = [super initWithFrame:frame];
//    if (self) {
//        [self setUpInit];
//    }
//    return self;
//}
//
//func awakeFromNib
//{
//    [self setUpInit];
//}
//
    func isFirstResponder() ->  Bool {
        return inputTextField?.isFirstResponder ?? false
    }

    override func becomeFirstResponder() -> Bool {
        layoutTokensAndInputWithFrameAdjustment(shouldAdjustFrame: true)
        inputTextFieldBecomeFirstResponder()
        return true
    }

    override func resignFirstResponder() -> Bool {
        super.resignFirstResponder()

        return inputTextField?.resignFirstResponder() ?? true
    }


    func setUpInit()
    {
        // Set up default values.
        autocorrectionType = .no;
        autocapitalizationType = .sentences
        maxHeight = tokenFieldDefaultMaxHeight
        verticalInset = tokenFieldDefaultVerticalInset
        horizontalInset = tokenFieldDefaultHorizontalInset
        tokenPadding = tokenFieldDefaultTokenPadding
        minInputWidth = tokenFieldDefaultMinInputWidth
        colorScheme = .blue
        toLabelTextColor = UIColor(displayP3Red: 112.0/255.0, green: 124.0/255.0, blue: 124.0/255.0, alpha: 1.0)
        inputTextFieldTextColor = UIColor(displayP3Red: 38.0/255.0, green: 39.0/255.0, blue: 41.0/255.0, alpha: 1.0)

        // Accessing bare value to avoid kicking off a premature layout run.
        toLabelText = "To"

        originalHeight = frame.height

        // Add invisible text field to handle backspace when we don't have a real first responder.
        layoutInvisibleTextField()

        layoutScrollView()
        reloadData()
    }

func collapse()
{
    layoutCollapsedLabel()
}

func reloadData()
{
    layoutTokensAndInputWithFrameAdjustment(shouldAdjustFrame: true)
}

func setPlaceholderText(placeholderText: String)
{
    self.placeholderText = placeholderText
    self.inputTextField?.placeholder = placeholderText
}


func setInputTextFieldAccessibilityLabel(inputTextFieldAccessibilityLabel: String) {
        self.inputTextFieldAccessibilityLabel = inputTextFieldAccessibilityLabel
        self.inputTextField?.accessibilityLabel = self.inputTextFieldAccessibilityLabel
}
//
func setInputTextFieldTextColor(inputTextFieldTextColor: UIColor) {
    self.inputTextFieldTextColor = inputTextFieldTextColor
    inputTextField.textColor = inputTextFieldTextColor
}

func setToLabelTextColor(toLabelTextColor: UIColor)
{
        self.toLabelTextColor = toLabelTextColor;
        self.toLabel.textColor = self.toLabelTextColor;
}

func setToLabelText(toLabelText: String)
{
    self.toLabelText = toLabelText;
    reloadData()
}

func setColorScheme(color: UIColor)
{
    colorScheme = color
    collapsedLabel.textColor = color
    inputTextField.tintColor = color
    tokens.forEach { $0.setColorScheme(colorScheme: color) }
}
//
func setInputTextFieldAccessoryView(inputTextFieldAccessoryView: UIView)
{
    self.inputTextFieldAccessoryView = inputTextFieldAccessoryView
    self.inputTextField.inputAccessoryView = self.inputTextFieldAccessoryView
}
//
func inputText() -> String
{
    return self.inputTextField.text ?? ""
}
//
//
//#pragma mark - View Layout
//
override func layoutSubviews()
{

    super.layoutSubviews()

    guard let scrollView = scrollView else { return }
    scrollView.contentSize = CGSize(width: frame.width - horizontalInset * 2,height: frame.height - self.verticalInset * 2);
    if isCollapsed() {
        layoutCollapsedLabel()
    } else {
        layoutTokensAndInputWithFrameAdjustment(shouldAdjustFrame: false)
    }
}
//
func layoutCollapsedLabel()
{
    collapsedLabel.removeFromSuperview()
    scrollView?.isHidden = true
    frame = CGRect(x: 0, y: 0, width: 0, height: originalHeight)

    var currentX: CGFloat = 0

    layoutToLabelInView(view: self, origin: CGPoint(x: horizontalInset, y: verticalInset), currentX: &currentX)

    layoutCollapsedLabelWithCurrentX(currentX: &currentX)

    tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(gestureRecognizer:)))
    addGestureRecognizer(tapGestureRecognizer)
}
//
func layoutTokensAndInputWithFrameAdjustment(shouldAdjustFrame: Bool)
{
    guard let scrollView = scrollView else { return }
    collapsedLabel.removeFromSuperview()
    let inputFieldShouldBecomeFirstResponder = inputTextField.isFirstResponder ?? false
    scrollView.subviews.forEach { $0.removeFromSuperview() }
    scrollView.isHidden = false
    removeGestureRecognizer(tapGestureRecognizer)

    tokens.removeAll()

    var currentX: CGFloat = 0
    var currentY: CGFloat = 0

    layoutToLabelInView(view: scrollView, origin: .zero, currentX: &currentX)
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
//
func isCollapsed() -> Bool {
    return collapsedLabel.superview != nil;
}
//
func layoutScrollView() {
    scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: frame.width, height: frame.height));
    scrollView?.scrollsToTop = false
    scrollView?.contentSize = CGSize(frame.width - horizontalInset * 2, CGRectGetHeight(self.frame) - self.verticalInset * 2);
    self.scrollView.contentInset = UIEdgeInsetsMake(self.verticalInset,
                                                    self.horizontalInset,
                                                    self.verticalInset,
                                                    self.horizontalInset);
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    [self addSubview:self.scrollView];
}
//
    func layoutInputTextFieldWithCurrentX(currentX: inout CGFloat, currentY: inout CGFloat, clearInput: Bool)
{
    guard let scrollView = scrollView else { return }

    var inputTextFieldWidth = scrollView.contentSize.width - currentX
    if inputTextFieldWidth < minInputWidth {
        inputTextFieldWidth = scrollView.contentSize.width
        currentY += heightForToken
        currentX = 0;
    }

    VENBackspaceTextField *inputTextField = self.inputTextField;
    if (clearInput) {
        inputTextField.text = @"";
    }
    inputTextField.frame = CGRectMake(*currentX, *currentY + 1, inputTextFieldWidth, [self heightForToken] - 1);
    inputTextField.tintColor = self.colorScheme;
    [self.scrollView addSubview:inputTextField];
}

    func layoutCollapsedLabelWithCurrentX(currentX: inout CGFloat)
{
        let l = UILabel(frame: CGRect(x: currentX, y: toLabel.frame.minY, width: frame.width - currentX - horizontalInset,  height: toLabel.frame.height))
        l.font = UIFont(name: "HelveticaNeue", size: 15.5)
        l.frame = CGRect(x: 0, y: 0, width: 0, height: heightForToken)
        l.text = collapsedText()

    label.text = [self collapsedText];
    label.textColor = self.colorScheme;
    label.minimumScaleFactor = 5./label.font.pointSize;
    label.adjustsFontSizeToFitWidth = YES;
    [self addSubview:label];
    self.collapsedLabel = label;
}
//
    func layoutToLabelInView(view: UIView,  origin: CGPoint, currentX: inout CGFloat)
{
    toLabel.removeFromSuperview()
    toLabel = UILabel()

    var newFrame = toLabel.frame
    newFrame.origin = origin

    toLabel.sizeToFit()
    newFrame.size.width = toLabel.frame.width

    self.toLabel.frame = newFrame;

    view.addSubview(toLabel)
    currentX += toLabel.isHidden ? toLabel.frame.minX : toLabel.frame.maxX + tokenFieldDefaultToLabelPadding
}
//
    func layoutTokensWith(currentX: inout CGFloat, currentY: inout CGFloat)
{
        for i in 0..<numberOfTokens {

        }

        for (NSUInteger i = 0; i < [self numberOfTokens]; i++) {
        NSString *title = [self titleForTokenAtIndex:i];
        VENToken *token = [[VENToken alloc] init];

        __weak VENToken *weakToken = token;
        __weak VENTokenField *weakSelf = self;
        token.didTapTokenBlock = ^{
            [weakSelf didTapToken:weakToken];
        };

        [token setTitleText:[NSString stringWithFormat:@"%@,", title]];
        token.colorScheme = [self colorSchemeForTokenAtIndex:i];

        [self.tokens addObject:token];

        if (*currentX + token.width <= self.scrollView.contentSize.width) { // token fits in current line
            token.frame = CGRectMake(*currentX, *currentY, token.width, token.height);
        } else {
            *currentY += token.height;
            *currentX = 0;
            CGFloat tokenWidth = token.width;
            if (tokenWidth > self.scrollView.contentSize.width) { // token is wider than max width
                tokenWidth = self.scrollView.contentSize.width;
            }
            token.frame = CGRectMake(*currentX, *currentY, tokenWidth, token.height);
        }
        *currentX += token.width + tokenPadding;
        [self.scrollView addSubview:token];
    }
}
//
//
//#pragma mark - Private
//
func layoutInvisibleTextField()
{
    invisibleTextField = BackspaceTextField()
    
    invisibleTextField?.autocorrectionType = autocorrectionType
    invisibleTextField?.autocapitalizationType = autocapitalizationType
    invisibleTextField?.backspaceDelegate = self

    addSubview(invisibleTextField!)
}
//
func inputTextFieldBecomeFirstResponder()
{
    guard inputTextField?.isFirstResponder ==  false else { return }

    inputTextField?.becomeFirstResponder()
    delegate?.tokenFieldDidBeginEditing(tokenField: self)
}

//
    func adjustHeightForCurrentY(currentY: CGFloat)
{
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
            height = originalHeight;
        }
    }

    if oldHeight != height {
        frame = CGRect(x: frame.minX, y: frame.minY, width: frame.width, height: height)

        delegate?.tokenField(tokenField: self, didChangeChangeContentHeight: height)
    }
}
//
//
//func setAutocorrectionType:(UITextAutocorrectionType)autocorrectionType
//{
//    _autocorrectionType = autocorrectionType;
//    [self.inputTextField setAutocorrectionType:self.autocorrectionType];
//    [self.invisibleTextField setAutocorrectionType:self.autocorrectionType];
//}
//
//func setInputTextFieldKeyboardAppearance:(UIKeyboardAppearance)inputTextFieldKeyboardAppearance
//{
//    _inputTextFieldKeyboardAppearance = inputTextFieldKeyboardAppearance;
//    [self.inputTextField setKeyboardAppearance:self.inputTextFieldKeyboardAppearance];
//}
//
//func setInputTextFieldKeyboardType:(UIKeyboardType)inputTextFieldKeyboardType
//{
//    _inputTextFieldKeyboardType = inputTextFieldKeyboardType;
//    [self.inputTextField setKeyboardType:self.inputTextFieldKeyboardType];
//}
//
//func setAutocapitalizationType:(UITextAutocapitalizationType)autocapitalizationType
//{
//    _autocapitalizationType = autocapitalizationType;
//    [self.inputTextField setAutocapitalizationType:self.autocapitalizationType];
//    [self.invisibleTextField setAutocapitalizationType:self.autocapitalizationType];
//}
//
@objc func inputTextFieldDidChange(textField: UITextField)
{
    delegate?.tokenField(tokenField: self, didChangeText: textField.text)
}

@objc func handleSingleTap(gestureRecognizer: UITapGestureRecognizer)
{
    let _ = becomeFirstResponder()
}
//
    func didTapToken(token: Token)
{
    for aToken in tokens {
        if aToken == token {
            aToken.highlighted = !aToken.highlighted
        } else {
            aToken.highlighted = false
        }
    }

    setCursorVisibility()
}
//
func unhighlightAllTokens()
{
    for token in self.tokens {
        token.highlighted = false
    }

    setCursorVisibility()
}

func setCursorVisibility()
{
    let highlightedTokens = tokens.filter { token in
        token.highlighted
    }

    if highlightedTokens.isEmpty {
        inputTextFieldBecomeFirstResponder()
    } else {
        invisibleTextField?.becomeFirstResponder()
    }
}
//
func updateInputTextField()
{
    inputTextField?.placeholder = tokens.count > 0 ? nil : placeholderText
}
//
func focusInputTextField()
{
    guard let scrollView = scrollView, let inputTextField = inputTextField else { return }

    let contentOffset = scrollView.contentOffset

    let targetY = inputTextField.frame.minY + heightForToken - frame.height;
    if targetY > contentOffset.y {
        scrollView.setContentOffset(CGPoint(x: contentOffset.x, y: targetY), animated: false)
    }
}
//

    func colorSchemeForTokenAt(index: UInt32) -> UIColor {
        return dataSource?.tokenField(tokenField: self, colorSchemeForTokenAt: index) ?? colorScheme
    }

//
//#pragma mark - Data Source
//

    func titleForTokenAt(index : UInt32) -> String {
        dataSource?.tokenField(tokenField: self, titleForTokenAt: index) ?? ""
    }

func numberOfTokens() -> UInt32 {
    return dataSource?.numberOfTokensInTokenField(tokenField: self) ?? 0
}

func collapsedText() -> String {
    return dataSource?.tokenFieldCollapsedText(tokenField: self) ?? ""
}
//#pragma mark - UITextFieldDelegate
//
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return delegate?.tokenField(tokenField: self, didEnterText: textField.text)

        return false
    }


//- (BOOL)textFieldShouldReturn:(UITextField *)textField
//{
//    if ([self.delegate respondsToSelector:@selector(tokenField:didEnterText:)]) {
//        if ([textField.text length]) {
//            [self.delegate tokenField:self didEnterText:textField.text];
//        }
//    }
//
//    return NO;
//}
//
func textFieldDidBeginEditing(textField: UITextField)
{
    if textField == self.inputTextField {
        unhighlightAllTokens()
    }
}
//




func textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self unhighlightAllTokens];
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    for (NSString *delimiter in self.delimiters) {
        if (newString.length > delimiter.length &&
            [[newString substringFromIndex:newString.length - delimiter.length] isEqualToString:delimiter]) {
            NSString *enteredString = [newString substringToIndex:newString.length - delimiter.length];
            if ([self.delegate respondsToSelector:@selector(tokenField:didEnterText:)]) {
                if (enteredString.length) {
                    [self.delegate tokenField:self didEnterText:enteredString];
                    return NO;
                }
            }
        }
    }
    return YES;
}
//
//
//#pragma mark - VENBackspaceTextFieldDelegate
//
func textFieldDidEnterBackspace(textField: BackspaceTextField)
{
    guard let delegate = delegate, numberOfTokens() > 0 else { return }

    var didDeleteToken = false

    for  token in self.tokens {
        if token.highlighted, let index = tokens.firstIndex(of: token) {
            delegate.tokenField(tokenField: self, didDeleteToken: UInt32(index))
            didDeleteToken = true;
            break;
        }
    }

    if !didDeleteToken {
        if let lastToken = tokens.last {
            lastToken.highlighted = true;
        }
    }
    setCursorVisibility()
}
//
//@end
