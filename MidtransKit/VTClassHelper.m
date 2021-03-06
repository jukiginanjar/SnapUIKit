//
//  VTClassHelper.m
//  MidtransKit
//
//  Created by Nanang Rafsanjani on 2/23/16.
//  Copyright © 2016 Veritrans. All rights reserved.
//

#import "VTClassHelper.h"
#import <MidtransCoreKit/MidtransCoreKit.h>

@implementation NSMutableAttributedString (Helper)

- (void)replaceCharacterString:(NSString *)characterString withIcon:(UIImage *)icon {
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    attachment.image = icon;
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    
    NSString *string = self.string.copy;
    NSRange foundRange = [string rangeOfString:characterString];
    
    while (foundRange.location != NSNotFound) {
        [self replaceCharactersInRange:foundRange withAttributedString:attachmentString];
        
        NSRange rangeToSearch;
        rangeToSearch.location = foundRange.location + foundRange.length;
        rangeToSearch.length = string.length - rangeToSearch.location;
        foundRange = [string rangeOfString:characterString options:0 range:rangeToSearch];
    }
}

@end

@implementation NSNumber (formatter)

- (NSString *)formattedCurrencyNumber {
    NSNumberFormatter *nf = [NSNumberFormatter indonesianCurrencyFormatter];
    return [@"Rp " stringByAppendingString:[nf stringFromNumber:self]];
}

@end

@implementation VTClassHelper

+ (NSBundle*)kitBundle {
    static dispatch_once_t onceToken;
    static NSBundle *kitBundle = nil;
    dispatch_once(&onceToken, ^{
        kitBundle = [NSBundle bundleWithPath:@"MidtransKit.bundle"];
        
        if (kitBundle == nil) {
            // This might be the same as the previous check if not using a dynamic framework
            NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"MidtransKit" ofType:@"bundle"];
            kitBundle = [NSBundle bundleWithPath:path];
        }
        
        if (kitBundle == nil) {
            // This will be the same as mainBundle if not using a dynamic framework
            kitBundle = [NSBundle bundleForClass:[self class]];
        }
        
        if (kitBundle == nil) {
            kitBundle = [NSBundle mainBundle];
        }
    });
    return kitBundle;
}

+ (NSArray <VTInstruction *> *)instructionsFromFilePath:(NSString *)filePath {
    NSArray *guideList = [NSArray arrayWithContentsOfFile:filePath];
    NSMutableArray *instructions = [NSMutableArray new];
    for (NSDictionary *guideData in guideList) {
        VTInstruction *instruction = [VTInstruction modelObjectWithDictionary:guideData];
        [instructions addObject:instruction];
    }
    return instructions;
}

+ (NSArray <VTGroupedInstruction*>*)groupedInstructionsFromFilePath:(NSString *)filePath {
    NSArray *guideList = [NSArray arrayWithContentsOfFile:filePath];
    NSMutableArray *groupedInstructions = [NSMutableArray new];
    for (NSDictionary *groupedInstructionData in guideList) {
        VTGroupedInstruction *groupedIns = [VTGroupedInstruction modelObjectWithDictionary:groupedInstructionData];
        [groupedInstructions addObject:groupedIns];
    }
    return groupedInstructions;
}

+ (BOOL)hasKindOfController:(UIViewController *)controller onControllers:(NSArray<UIViewController*>*)controllers {
    for (UIViewController *c in controllers) {
        if ([c isKindOfClass:controller.class]) {
            return YES;
        }
    }
    return NO;
}

+ (UIViewController *)rootViewController {
    UIViewController *topRootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (topRootViewController.presentedViewController){
        if(![topRootViewController.presentedViewController isKindOfClass:[UIAlertController class]]){
            topRootViewController = topRootViewController.presentedViewController;
        }
        else{
            break;
        }
    }
    if(!topRootViewController || [topRootViewController isKindOfClass:[UINavigationController class]] || [topRootViewController isKindOfClass:[UITabBarController class]]){
        
        if (!topRootViewController) {
            topRootViewController = [[[[UIApplication sharedApplication]delegate]window]rootViewController];
        }
        
        if ([topRootViewController isKindOfClass:[UINavigationController class]]){
            UINavigationController* navController = (UINavigationController*)topRootViewController;
            return navController.topViewController;
        }
        else if ([topRootViewController isKindOfClass:[UITabBarController class]]){
            
            UITabBarController* tabController = (UITabBarController*)topRootViewController;
            
            if ([tabController.selectedViewController isKindOfClass:[UINavigationController class]]){
                UINavigationController* navController = (UINavigationController*)tabController.selectedViewController;
                return navController.topViewController;
            }
            else{
                return tabController.selectedViewController;
            }
        }
        else{
            return topRootViewController;
        }
    }
    return topRootViewController;
}

@end

@implementation NSString (utilities)

- (BOOL)isNumeric {
    NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange r = [self rangeOfCharacterFromSet: nonNumbers];
    return r.location == NSNotFound;
}

- (NSString *)formattedCreditCardNumber {
    NSString *cardNumber = self;
    NSString *result = @"";
    
    while (cardNumber.length > 0) {
        NSString *subString = [cardNumber substringToIndex:MIN(cardNumber.length, 4)];
        result = [result stringByAppendingString:subString];
        if (subString.length == 4) {
            result = [result stringByAppendingString:@" "];
        }
        cardNumber = [cardNumber substringFromIndex:MIN(cardNumber.length, 4)];
    }
    return result;
}

- (CGSize)sizeWithFont:(UIFont *)font constraint:(CGSize)constraint {
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGRect rect = [self boundingRectWithSize:constraint
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attributes
                                     context:nil];
    return CGSizeMake(ceilf(rect.size.width), ceilf(rect.size.height));
}

@end

@implementation UILabel (utilities)

- (void)setRoundedCorners:(BOOL)rounded {
    if (rounded) {
        self.layer.cornerRadius = CGRectGetHeight(self.bounds)/2.0;
    } else {
        self.layer.cornerRadius = 0;
    }
}

@end

@implementation UIViewController (Utils)

- (void)addSubViewController:(UIViewController *)viewController toView:(UIView*)contentView {
    
    [self addChildViewController:viewController];
    [viewController didMoveToParentViewController:self];
    
    viewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [contentView addSubview:viewController.view];
    
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[content]|" options:0 metrics:0 views:@{@"content":viewController.view}]];
    [contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[content]|" options:0 metrics:0 views:@{@"content":viewController.view}]];
}

- (void)removeSubViewController:(UIViewController *)viewController {
    [viewController.view removeFromSuperview];
    [viewController removeFromParentViewController];
    [viewController didMoveToParentViewController:nil];
}

@end

@implementation NSArray (Item)

- (NSString *)formattedPriceAmount {
    double priceAmount = 0;
    for (MidtransItemDetail *item in self) {
        priceAmount += (item.price.doubleValue * item.quantity.integerValue);
    }
    return @(priceAmount).formattedCurrencyNumber;
}

@end


