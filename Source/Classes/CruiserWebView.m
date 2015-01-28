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

#import "CruiserWebView.h"


@implementation CruiserWebView

#pragma mark - Setters

- (void)setNavDelegate:(id<CruiserNavigationDelegate>)delegate
{
    if (!delegate || (self.navDelegate && ![self.navDelegate isEqual:delegate])) {
        [self removeObserver:self
                  forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }
    if (delegate) {
        [self addObserver:self
               forKeyPath:NSStringFromSelector(@selector(estimatedProgress))
                  options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                  context:NULL];
    }
    _navDelegate = delegate;

    [super setNavigationDelegate:delegate];
}


#pragma mark - Key Value Observer

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([object isEqual:self] && [keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))]) {
        if (self.navDelegate && [self.navDelegate respondsToSelector:@selector(webView:didUpdateProgress:)]) {
            [self.navDelegate webView:self
                    didUpdateProgress:self.estimatedProgress];
        }
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

@end
