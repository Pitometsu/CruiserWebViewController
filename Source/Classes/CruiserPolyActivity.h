//
//  CruiserPolyActivity.h
//  CruiserWebViewController
//  https://github.com/dzenbot/CruiserWebViewController
//
//  Created by Ignacio Romero Zurbuchen on 3/28/14.
//  Improved by Yuriy Pitomets on 23/01/2015
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Copyright (c) 2015 Yuriy Pitomets. No rights reserved.
//  Licence: MIT-Licence
//

#import <UIKit/UIKit.h>

/**
 Types of activity kind, used for polymorphic creation.
 */
typedef NS_OPTIONS(NSUInteger, CruiserPolyActivityType) {
    CruiserPolyActivityTypeLink,
    CruiserPolyActivityTypeSafari,
    CruiserPolyActivityTypeChrome,
    CruiserPolyActivityTypeOpera,
    CruiserPolyActivityTypeDolphin
};

/**
 The CruiserPolyActivity class is an abstract subclass of UIActivity allowing to easily create polymorphic instances by assigning different activity types. Each type will render a different icon and title, and will perform different actions too.
 */
@interface CruiserPolyActivity : UIActivity

@property (nonatomic, readonly) CruiserPolyActivityType type;
@property (nonatomic, readonly) NSURL *URL;

/**
 Initializes and returns a newly created activity with a specific type.

 @param type The type of the activity to be created.
 @returns The initialized activity.
 */
- (instancetype)initWithActivityType:(CruiserPolyActivityType)type;

/**
 Allocates a new instance of the receiving class, sends it an init message, and returns the initialized object.
 This method implements the same logic than initWithActivityType: but is just shorter to call.

 @param type The type of the activity to be created.
 */
+ (instancetype)activityWithType:(CruiserPolyActivityType)type;

@end
