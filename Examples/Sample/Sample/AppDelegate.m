//
//  AppDelegate.m
//  Sample
//
//  Created by Ignacio on 3/27/14.
//  Improved by Yuriy Pitomets on 23/01/2015
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Copyright (c) 2015 Yuriy Pitomets. No rights reserved.
//

#import "AppDelegate.h"
#import "CruiserWebViewController.h"

#define DEBUG_LOCAL 0

@implementation AppDelegate

- (BOOL)            application:(UIApplication *)application
  didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

#if DEBUG_LOCAL
    NSString *path = [[NSBundle mainBundle] pathForResource:@"NSHipster.com" ofType:@"html"];

    ViewController *controller = [[ViewController alloc] initWithFileURL:[NSURL fileURLWithPath:path]];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    self.window.rootViewController = navController;
#else
    CruiserWebViewController *controller = [[CruiserWebViewController alloc] initWithURL:[NSURL URLWithString:@"http://appcruiser.com/welcome"]];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    UITextField *addressField = [[UITextField alloc] initWithFrame:CGRectMake(10, 11, 355, 25)];
    addressField.delegate                  = controller;
    addressField.borderStyle               = UITextBorderStyleRoundedRect;
    addressField.textAlignment             = NSTextAlignmentCenter;
    addressField.returnKeyType             = UIReturnKeyGo;
    addressField.keyboardType              = UIKeyboardTypeURL;
    addressField.clearButtonMode           = UITextFieldViewModeWhileEditing;
    addressField.rightViewMode             = UITextFieldViewModeUnlessEditing;
    addressField.adjustsFontSizeToFitWidth = YES;
    addressField.minimumFontSize           = 6.f;
    [navController.navigationBar addSubview:addressField];
    controller.addressField = addressField;
    self.window.rootViewController = navController;
#endif

    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
