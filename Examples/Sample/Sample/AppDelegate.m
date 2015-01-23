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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
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
    self.window.rootViewController = navController;
#endif

    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    return YES;
}

@end
