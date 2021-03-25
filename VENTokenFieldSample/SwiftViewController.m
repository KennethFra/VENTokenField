//
//  ViewController.m
//  TokenFieldSample
//
//  Created by Ayaka Nonaka on 6/20/14.
//  Copyright (c) 2014 Venmo. All rights reserved.
//

#import "SwiftViewController.h"
#import "VENTokenFieldSample-Swift.h"
#import "VENTokenField.h"

@interface SwiftViewController () <TokenFieldDelegate, TokenFieldDataSource>
@property (weak, nonatomic) IBOutlet TokenField *tokenField;
@property (weak, nonatomic) IBOutlet VENTokenField *venTokenField;
@property (strong, nonatomic) NSMutableArray *names;
@end

@implementation SwiftViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.names = [NSMutableArray array];
    self.tokenField.delegate = self;
    self.tokenField.dataSource = self;
    self.tokenField.placeholderText = NSLocalizedString(@"Enter names here", nil);
    self.tokenField.colorScheme = [UIColor colorWithRed:61/255.0f green:149/255.0f blue:206/255.0f alpha:1.0f];
    self.tokenField.delimiters = @[@","];
    [self.tokenField becomeFirstResponder];
    
    self.venTokenField.delegate = self;
    self.venTokenField.dataSource =  self;
    self.venTokenField.placeholderText = NSLocalizedString(@"Enter names here", nil);
    self.venTokenField.toLabelText = NSLocalizedString(@"Post to:", nil);
    [self.venTokenField setColorScheme:[UIColor colorWithRed:61/255.0f green:149/255.0f blue:206/255.0f alpha:1.0f]];
    self.venTokenField.delimiters = @[@","];
    [self.venTokenField becomeFirstResponder];

}

- (IBAction)didTapResignFirstResponderButton:(id)sender
{
    [self.tokenField resignFirstResponder];
    [self.venTokenField resignFirstResponder];
}


#pragma mark - TokenFieldDelegate

- (void)tokenField:(TokenField *)tokenField didEnterText:(NSString *)text
{
    [self.names addObject:text];
    [tokenField reloadData];
}

- (void)tokenField:(TokenField *)tokenField didDeleteTokenAtIndex:(NSUInteger)index
{
    [self.names removeObjectAtIndex:index];
    [tokenField reloadData];
}


#pragma mark - TokenFieldDataSource

- (NSString *)tokenField:(TokenField *)tokenField titleForTokenAtIndex:(NSUInteger)index
{
    return self.names[index];
}

- (NSUInteger)numberOfTokensInTokenField:(TokenField *)tokenField
{
    return [self.names count];
}

- (NSString *)tokenFieldCollapsedText:(TokenField *)tokenField
{
    return [NSString stringWithFormat:@"%tu people", [self.names count]];
}

- (void)tokenFieldDidBeginEditingWithTokenField:(TokenField * _Nonnull)tokenField {
    
}

- (void)tokenFieldWithTokenField:(TokenField * _Nonnull)tokenField didChangeChangeContentHeight:(CGFloat)height {
    
}

- (void)tokenFieldWithTokenField:(TokenField * _Nonnull)tokenField didChangeText:(NSString * _Nullable)text {
    
}

- (void)tokenFieldWithTokenField:(TokenField * _Nonnull)tokenField didDeleteToken:(uint32_t)atIndex {
    [self.names removeObjectAtIndex:atIndex];
    [tokenField reloadData];
}

- (void)tokenFieldWithTokenField:(TokenField * _Nonnull)tokenField didEnterText:(NSString * _Nullable)text {
    [self.names addObject:text];
    [tokenField reloadData];
}

- (uint32_t)numberOfTokensInTokenFieldWithTokenField:(TokenField * _Nonnull)tokenField {
    return [self.names count];
}

- (NSString * _Nonnull)tokenFieldCollapsedTextWithTokenField:(TokenField * _Nonnull)tokenField {
    return [NSString stringWithFormat:@"%tu people", [self.names count]];
}

- (UIColor * _Nonnull)tokenFieldWithTokenField:(TokenField * _Nonnull)tokenField colorSchemeForTokenAt:(uint32_t)index {
    return UIColor.blueColor;
}

- (NSString * _Nonnull)tokenFieldWithTokenField:(TokenField * _Nonnull)tokenField titleForTokenAt:(uint32_t)index {
    return self.names[index];
}
@end
