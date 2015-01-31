//
//  CruiserWebViewController.h
//  CruiserWebViewController
//  https://github.com/dzenbot/CruiserWebViewController
//
//  Created by Ignacio Romero Zurbuchen on 10/25/13.
//  Improved by Yuriy Pitomets on 23/01/2015
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Copyright (c) 2015 Yuriy Pitomets. No rights reserved.
//  Licence: MIT-Licence
//

#import "CruiserWebView.h"
#import "IPNavBarSqueezableViewController.h"
#import <UIKit/UIKit.h>


/**
 Types of supported search services.
 */
typedef NS_ENUM(NSUInteger, CruiserSearchService) {
    CruiserSearchServicePrimary,    // Google.com by default
    CruiserSearchServiceAlternative // DuckDuckGo.com by default
};

/**
 Types of supported navigation tools.
 */
typedef NS_OPTIONS(NSUInteger, CruiserWebNavigationTools) {
    CruiserWebNavigationToolAll      = -1,
    CruiserWebNavigationToolNone     = 0,
    CruiserWebNavigationToolBackward = 1 << 0,
    CruiserWebNavigationToolForward  = 1 << 1,
    CruiserWebNavigationToolPin      = 1 << 2,
    CruiserWebNavigationToolDown     = 1 << 3,
    CruiserWebNavigationToolUp       = 1 << 4
};

/**
 Types of supported actions (i.e. Share & Copy link, Add to Reading List, Open in Safari/Chrome/Opera/Dolphin).
 */
typedef NS_OPTIONS(NSUInteger, CruiserSupportedWebActions) {
    CruiserWebActionAll                = -1,
    CruiserWebActionNone               = 0,
    CruiserSupportedWebActionshareLink = 1 << 0,
    CruiserWebActionCopyLink           = 1 << 1,
    CruiserWebActionReadLater          = 1 << 2,
    CruiserWebActionOpenSafari         = 1 << 3,
    CruiserWebActionOpenChrome         = 1 << 4,
    CruiserWebActionOpenOperaMini      = 1 << 5,
    CruiserWebActionOpenDolphin        = 1 << 6
};

/**
 A very simple web browser with useful navigation and tooling features.
 */
@interface CruiserWebViewController : IPNavBarSqueezableViewController <CruiserNavigationDelegate,
                                                                        WKUIDelegate,
                                                                        UITableViewDataSource,
                                                                        UITableViewDelegate,
                                                                        UITextFieldDelegate>

/** The web view that the controller manages. */
@property (nonatomic, strong) CruiserWebView *webView;
/** The URL identifying the location of the content to load. */
@property (nonatomic, readwrite) NSURL *URL;
/** The supported navigation tool bar items. Default is All. */
@property (nonatomic, readwrite) CruiserWebNavigationTools supportedWebNavigationTools;
/** The supported actions like sharing and copy link, add to reading list, open in Safari, etc. Default is All. */
@property (nonatomic, readwrite) CruiserSupportedWebActions supportedWebActions;
/** Yes if a progress bar indicates the . Default is YES. */
@property (nonatomic) BOOL showLoadingProgress;
/** YES if long pressing the backward and forward buttons the navigation history is displayed. Default is YES. */
@property (nonatomic) BOOL allowHistory;
/** YES if both, the navigation and tool bars should hide when panning vertically. Default is YES. */
@property (nonatomic) BOOL hideBarsWithGestures;

///------------------------------------------------
/// @name Initialization
///------------------------------------------------

/**
 Initializes and returns a newly created webview controller with an initial HTTP URL to be requested as soon as the view appears.

 @param URL The HTTP URL to be requested.
 @returns The initialized webview controller.
 */
- (instancetype)initWithURL:(NSURL *)URL;

/**
 Initializes and returns a newly created webview controller for local HTML navigation.

 @param URL The file URL of the main html.
 @returns The initialized webview controller.
 */
- (instancetype)initWithFileURL:(NSURL *)URL;

/**
 Starts loading a new request. Useful to programatically update the web content.

 @param URL The HTTP or file URL to be requested.
 */
- (void)loadURL:(NSURL *)URL NS_REQUIRES_SUPER;


///------------------------------------------------
/// @name UI outlets
///------------------------------------------------

@property (nonatomic, weak) IBOutlet UITextField *addressField;


///------------------------------------------------
/// @name Appearance customisation
///------------------------------------------------

// The back button displayed on the tool bar (requieres CruiserWebNavigationToolBackward)
@property (nonatomic, strong) UIImage *backwardButtonImage;
// The forward button displayed on the tool bar (requieres CruiserWebNavigationToolForward)
@property (nonatomic, strong) UIImage *forwardButtonImage;
// The pin button displayed on the tool bar (requieres CruiserWebNavigationToolPin)
@property (nonatomic, strong) UIImage *pinButtonImage;
// The down button displayed on the tool bar (requieres CruiserWebNavigationToolDown)
@property (nonatomic, strong) UIImage *downButtonImage;
// The up button displayed on the tool bar (requieres CruiserWebNavigationToolUp)
@property (nonatomic, strong) UIImage *upButtonImage;
// The action button displayed on the navigation bar (requieres at least 1 CruiserSupportedWebActions value)
@property (nonatomic, strong) UIImage *actionButtonImage;

// The stop button displayed in addressField
@property (nonatomic, strong) UIImage *stopButtonImage;
// The reload button displayed in addressField
@property (nonatomic, strong) UIImage *reloadButtonImage;
// The button for first search service displayed in addressField
@property (nonatomic, strong) UIImage *primarySearchButtonImage;
// The button for second search service displayed in addressField
@property (nonatomic, strong) UIImage *alternativeSearchButtonImage;


///------------------------------------------------
/// @name Search services
///------------------------------------------------

// String for request to primary search service
@property (nonatomic, copy) NSString *primarySearchService;
// String for request to alternative search service
@property (nonatomic, copy) NSString *alternativeSearchService;

///------------------------------------------------
/// @name Navigation logic
///------------------------------------------------

// Load saved locations for web pages from user defaults
- (void)loadPins;
// Store all saved locations for web pages to user defaults
- (void)storePins;


///------------------------------------------------
/// @name Delegate Methods Requiring Super
///------------------------------------------------

// CruiserNavigationDelegate
- (void)webView:(CruiserWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation NS_REQUIRES_SUPER;
- (void)webView:(CruiserWebView *)webView didCommitNavigation:(WKNavigation *)navigation NS_REQUIRES_SUPER;
- (void)webView:(CruiserWebView *)webView didUpdateProgress:(CGFloat)progress NS_REQUIRES_SUPER;
- (void)webView:(CruiserWebView *)webView didFinishNavigation:(WKNavigation *)navigation NS_REQUIRES_SUPER;
- (void)webView:(CruiserWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error NS_REQUIRES_SUPER;

// WKUIDelegate
- (CruiserWebView *)webView:(CruiserWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures NS_REQUIRES_SUPER;

// UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView NS_REQUIRES_SUPER;
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section NS_REQUIRES_SUPER;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;

// UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;

@end
