//
//  CruiserWebView.h
//  CruiserWebViewController
//  https://github.com/dzenbot/CruiserWebViewController
//
//  Created by Ignacio Romero Zurbuchen on 11/21/14.
//  Improved by Yuriy Pitomets on 23/01/2015
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Copyright (c) 2015 Yuriy Pitomets. No rights reserved.
//  Licence: MIT-Licence
//

#import <WebKit/WebKit.h>

@protocol CruiserNavigationDelegate;

@interface CruiserWebView : WKWebView

@property (nonatomic, weak) id <CruiserNavigationDelegate> navDelegate;

@end


@protocol CruiserNavigationDelegate <WKNavigationDelegate>

- (void)webView:(CruiserWebView *)webView didUpdateProgress:(CGFloat)progress;

@end
