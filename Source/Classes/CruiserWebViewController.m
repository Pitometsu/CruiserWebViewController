//
//  CruiserWebViewController.m
//  CruiserWebViewController
//  https://github.com/dzenbot/CruiserWebViewController
//
//  Created by Ignacio Romero Zurbuchen on 10/25/13.
//  Improved by Yuriy Pitomets on 23/01/2015
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Copyright (c) 2015 Yuriy Pitomets. No rights reserved.
//  Licence: MIT-Licence
//

#import "CruiserPolyActivity.h"
#import "CruiserWebViewController.h"


#define CRUISER_IS_IPAD [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad
#define CRUISER_IS_LANDSCAPE \
([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeLeft ||\
 [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationLandscapeRight)


static char CruiserWebViewControllerKVOContext       = 0;
static const NSTimeInterval kAnimationDuration       = 0.25;
static NSString *const kPinsDictionaryKey            = @"cruiser_web_view_controller.pins_dictionary";
static NSString *const kGoogleServiceRequestPath     = @"https://www.google.com/search?q=";
static NSString *const kDuckDuckGoServiceRequestPath = @"https://duckduckgo.com/?q=";
static NSString *const kHostnameRegex                = @"((\\w)*|([0-9]*)|([-|_])*)+"
                                                        "([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+";


@interface CruiserWebViewController () <UIScrollViewDelegate>

@property (nonatomic, strong) UIBarButtonItem *backwardBarItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarItem;
@property (nonatomic, strong) UIBarButtonItem *pinBarItem;
@property (nonatomic, strong) UIBarButtonItem *downBarItem;
@property (nonatomic, strong) UIBarButtonItem *upBarItem;
@property (nonatomic, strong) UIBarButtonItem *actionBarItem;

@property (nonatomic, strong) UIButton *stateButton;
@property (nonatomic, strong) UIButton *webButton;

@property (nonatomic, assign) CruiserSearchService currentSearchService;

@property (nonatomic, strong) UIProgressView *progressView;

@property (nonatomic, strong) UILongPressGestureRecognizer *backwardLongPress;
@property (nonatomic, strong) UILongPressGestureRecognizer *forwardLongPress;

@property (nonatomic, strong) NSMutableDictionary *pins;
//@property (nonatomic, strong) NSMutableDictionary *pages;

@property (nonatomic, weak) UIToolbar *toolbar;
@property (nonatomic, weak) UINavigationBar *navigationBar;
@property (nonatomic, weak) UIView *navigationBarSuperView;

@end


@implementation CruiserWebViewController

- (instancetype)init
{
    self = [super init];

    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithURL:(NSURL *)URL
{
    NSParameterAssert(URL);

    self = [self init];

    if (self) {
        _URL = URL;
    }
    return self;
}

- (instancetype)initWithFileURL:(NSURL *)URL
{
    // TODO: check is url valid and file exist
    return [self initWithURL:URL];
}

- (void)awakeFromNib
{
    [self commonInit];
}

- (void)commonInit
{
    self.currentSearchService        = CruiserSearchServicePrimary;
    self.primarySearchService        = kGoogleServiceRequestPath;
    self.alternativeSearchService    = kDuckDuckGoServiceRequestPath;
    self.supportedWebNavigationTools = CruiserWebNavigationToolAll;
    self.supportedWebActions         = CruiserWebActionAll;
    self.showLoadingProgress         = YES;
    self.hideBarsWithGestures        = YES;
    self.allowHistory                = YES;
    self.pins                        = [NSMutableDictionary dictionaryWithCapacity:1];
}


#pragma mark - View life cycle

- (void)loadView
{
    [super loadView];

    self.view = self.webView;
//    self.automaticallyAdjustsScrollViewInsets = YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // IPNavBarSqueezableViewController
    self.triggeringScrollView = self.webView.scrollView;

    if (self.addressField) {
        self.titleFont = self.addressField.font;
    }
    __weak typeof(self) this = self;

    self.expandCompletion = ^{
        if (!this.addressField) {
            return;
        }
        this.addressField.backgroundColor = [this.addressField.backgroundColor
                                             colorWithAlphaComponent:1.f];
        this.addressField.borderStyle = UITextBorderStyleRoundedRect;
        this.addressField.rightViewMode = UITextFieldViewModeUnlessEditing;
        this.addressField.leftViewMode  = UITextFieldViewModeAlways;
        [this clearProgressViewAnimated:NO];        
    };
    self.downBarItem.enabled = NO;
    self.upBarItem.enabled   = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [UIView performWithoutAnimation:^{
        static dispatch_once_t willAppearConfig;
        dispatch_once(&willAppearConfig, ^{
            [self configureToolBars];
        });
    }];

    if (!self.webView.URL
        && !self.webView.loading
        && self.URL
        ) {
        [self loadURL:self.URL];
    }
}

// TODO: speed up UI, not use Did Appear method
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    static dispatch_once_t didAppearConfig;
    dispatch_once(&didAppearConfig, ^{
        [self configureBarItemsGestures];
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];

    [self clearProgressViewAnimated:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];

    [self.webView stopLoading];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // TODO: reduce memory usage
}

- (void)dealloc
{
    [self.navigationBar removeObserver:self
                            forKeyPath:@"hidden"
                               context:&CruiserWebViewControllerKVOContext];
    [self.navigationBar removeObserver:self
                            forKeyPath:@"center"
                               context:&CruiserWebViewControllerKVOContext];
    [self.navigationBar removeObserver:self
                            forKeyPath:@"alpha"
                               context:&CruiserWebViewControllerKVOContext];
}


#pragma mark - Public methods

- (void)loadPins
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSDictionary *loadedPins = [defaults dictionaryForKey:kPinsDictionaryKey];

    if (loadedPins) {
        self.pins = [loadedPins mutableCopy];
    }
}

- (void)storePins
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setValue:self.pins
                forKey:kPinsDictionaryKey];
    [defaults synchronize];
}

#pragma mark - Getter methods

- (CruiserWebView *)webView
{
    if (!_webView) {
        CruiserWebView *webView = [[CruiserWebView alloc] initWithFrame:self.view.bounds
                                                          configuration:[WKWebViewConfiguration new]];
        webView.backgroundColor = [UIColor whiteColor];
        webView.allowsBackForwardNavigationGestures = YES;
        webView.UIDelegate = self;
        webView.navDelegate = self;
        webView.scrollView.delegate = self;

        _webView = webView;
    }
    return _webView;
}

- (UIProgressView *)progressView
{
    if (!_progressView) {
        CGFloat lineHeight = 2.f;
        CGRect frame = CGRectMake(0.f,
                                  CGRectGetHeight(self.navigationBar.bounds) - lineHeight,
                                  CGRectGetWidth(self.navigationBar.bounds),
                                  lineHeight);
        UIProgressView *progressView = [[UIProgressView alloc] initWithFrame:frame];
        progressView.trackTintColor = [UIColor clearColor];
        progressView.alpha = 0.f;

        [self.navigationBar addSubview:progressView];

        _progressView = progressView;
    }
    return _progressView;
}

- (UIBarButtonItem *)backwardBarItem
{
    if (!_backwardBarItem) {
        _backwardBarItem = [[UIBarButtonItem alloc] initWithImage:[self backwardButtonImage]
                                              landscapeImagePhone:nil
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(goBackward:)];
        _backwardBarItem.accessibilityLabel = NSLocalizedStringFromTable(@"Backward",
                                                                         @"CruiserWebViewController",
                                                                         @"Accessibility label button title");
        _backwardBarItem.enabled = NO;
    }
    return _backwardBarItem;
}

- (UIBarButtonItem *)forwardBarItem
{
    if (!_forwardBarItem) {
        _forwardBarItem = [[UIBarButtonItem alloc] initWithImage:[self forwardButtonImage]
                                             landscapeImagePhone:nil
                                                           style:UIBarButtonItemStylePlain
                                                          target:self
                                                          action:@selector(goForward:)];
        _forwardBarItem.accessibilityLabel = NSLocalizedStringFromTable(@"Forward",
                                                                        @"CruiserWebViewController",
                                                                        @"Accessibility label button title");
        _forwardBarItem.enabled = NO;
    }
    return _forwardBarItem;
}

- (UIBarButtonItem *)pinBarItem
{
    if (!_pinBarItem) {
        _pinBarItem = [[UIBarButtonItem alloc] initWithImage:[self pinButtonImage]
                                         landscapeImagePhone:nil
                                                       style:UIBarButtonItemStylePlain
                                                      target:self
                                                      action:@selector(pinHere:)];
        _pinBarItem.accessibilityLabel = NSLocalizedStringFromTable(@"Pin",
                                                                    @"CruiserWebViewController",
                                                                    @"Accessibility label button title");
        _pinBarItem.enabled = NO;
    }
    return _pinBarItem;
}

- (UIBarButtonItem *)downBarItem
{
    if (!_downBarItem) {
        _downBarItem = [[UIBarButtonItem alloc] initWithImage:[self downButtonImage]
                                          landscapeImagePhone:nil
                                                        style:UIBarButtonItemStylePlain
                                                       target:self
                                                       action:@selector(scrollDown:)];
        _downBarItem.accessibilityLabel = NSLocalizedStringFromTable(@"Down",
                                                                     @"CruiserWebViewController",
                                                                     @"Accessibility label button title");
        _downBarItem.enabled = NO;
    }
    return _downBarItem;
}

- (UIBarButtonItem *)upBarItem
{
    if (!_upBarItem) {
        _upBarItem = [[UIBarButtonItem alloc] initWithImage:[self upButtonImage]
                                        landscapeImagePhone:nil
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(scrollUp:)];
        _upBarItem.accessibilityLabel = NSLocalizedStringFromTable(@"Up",
                                                                   @"CruiserWebViewController",
                                                                   @"Accessibility label button title");
        _upBarItem.enabled = NO;
    }
    return _upBarItem;
}

- (UIBarButtonItem *)actionBarItem
{
    if (!_actionBarItem) {
        _actionBarItem = [[UIBarButtonItem alloc] initWithImage:[self actionButtonImage]
                                            landscapeImagePhone:nil
                                                          style:UIBarButtonItemStylePlain
                                                         target:self
                                                         action:@selector(presentActivityController:)];
        _actionBarItem.enabled = NO;
    }
    return _actionBarItem;
}

- (NSArray *)navigationToolItems
{
    NSMutableArray *items = [NSMutableArray new];

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                   target:nil
                                                                                   action:NULL];
    if ((self.supportedWebNavigationTools & CruiserWebNavigationToolBackward) > 0 || self.supportsAllNavigationTools) {
        [items addObject:self.backwardBarItem];
    }
    if ((self.supportedWebNavigationTools & CruiserWebNavigationToolForward) > 0 || self.supportsAllNavigationTools) {
        if (!CRUISER_IS_IPAD) [items addObject:flexibleSpace];
        [items addObject:self.forwardBarItem];
    }
    if ((self.supportedWebNavigationTools & CruiserWebNavigationToolPin) > 0 || self.supportsAllNavigationTools) {
        if (!CRUISER_IS_IPAD) [items addObject:flexibleSpace];
        [items addObject:self.pinBarItem];
    }
    if ((self.supportedWebNavigationTools & CruiserWebNavigationToolDown) > 0 || self.supportsAllNavigationTools) {
        if (!CRUISER_IS_IPAD) [items addObject:flexibleSpace];
        [items addObject:self.downBarItem];
    }
    if ((self.supportedWebNavigationTools & CruiserWebNavigationToolUp) > 0 || self.supportsAllNavigationTools) {
        if (!CRUISER_IS_IPAD) [items addObject:flexibleSpace];
        [items addObject:self.upBarItem];
    }
    if (self.supportedWebActions > 0) {
        if (!CRUISER_IS_IPAD) [items addObject:flexibleSpace];
        [items addObject:self.actionBarItem];
    }
    return items;
}

- (BOOL)supportsAllNavigationTools
{
    return _supportedWebNavigationTools == CruiserWebNavigationToolAll;
}

- (UIButton *)stateButton
{
    if (!_stateButton) {
        UIImage *stateImage = [self reloadButtonImage];
        _stateButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _stateButton.frame = CGRectMake(0.f,
                                        0.f,
                                        stateImage.size.width,
                                        stateImage.size.height);
        [_stateButton setImage:stateImage
                      forState:UIControlStateNormal];
        [self updateStateButton];
    }
    return _stateButton;
}

- (UIButton *)webButton
{
    if (!_webButton) {
        UIImage *webImage = [self primarySearchButtonImage];
        _webButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _webButton.frame = CGRectMake(0.f,
                                      0.f,
                                      webImage.size.width,
                                      webImage.size.height);
        [_webButton setImage:webImage
                    forState:UIControlStateNormal];
        [_webButton addTarget:self
                       action:@selector(switchSearchService:)
             forControlEvents:UIControlEventTouchDown];
    }
    return _webButton;
}

- (UIImage *)backwardButtonImage
{
    if (!_backwardButtonImage) {
        _backwardButtonImage = [UIImage imageNamed:@"cruiser_icn_toolbar_backward"];
    }
    return _backwardButtonImage;
}

- (UIImage *)forwardButtonImage
{
    if (!_forwardButtonImage) {
        _forwardButtonImage = [UIImage imageNamed:@"cruiser_icn_toolbar_forward"];
    }
    return _forwardButtonImage;
}

- (UIImage *)pinButtonImage
{
    if (!_pinButtonImage) {
        _pinButtonImage = [UIImage imageNamed:@"cruiser_icn_toolbar_pin"];
    }
    return _pinButtonImage;
}

- (UIImage *)downButtonImage
{
    if (!_downButtonImage) {
        _downButtonImage = [UIImage imageNamed:@"cruiser_icn_toolbar_down"];
    }
    return _downButtonImage;
}

- (UIImage *)upButtonImage
{
    if (!_upButtonImage) {
        _upButtonImage = [UIImage imageNamed:@"cruiser_icn_toolbar_up"];
    }
    return _upButtonImage;
}

- (UIImage *)actionButtonImage
{
    if (!_actionButtonImage) {
        _actionButtonImage = [UIImage imageNamed:@"cruiser_icn_toolbar_action"];
    }
    return _actionButtonImage;
}

- (UIImage *)reloadButtonImage
{
    if (!_reloadButtonImage) {
        _reloadButtonImage = [UIImage imageNamed:@"cruiser_icn_toolbar_reload"];
    }
    return _reloadButtonImage;
}

- (UIImage *)stopButtonImage
{
    if (!_stopButtonImage) {
        _stopButtonImage = [UIImage imageNamed:@"cruiser_icn_toolbar_stop"];
    }
    return _stopButtonImage;
}

- (UIImage *)primarySearchButtonImage
{
    if (!_primarySearchButtonImage) {
        _primarySearchButtonImage = [UIImage imageNamed:@"cruiser_icn_toolbar_web"];
    }
    return _primarySearchButtonImage;
}

- (UIImage *)alternativeSearchButtonImage
{
    if (!_alternativeSearchButtonImage) {
        _alternativeSearchButtonImage = [UIImage imageNamed:@"cruiser_icn_toolbar_face"];
    }
    return _alternativeSearchButtonImage;
}

- (NSArray *)applicationActivitiesForItem:(id)item
{
    NSMutableArray *activities = [[NSMutableArray alloc]
                                  initWithCapacity:5];
    if ([item isKindOfClass:[UIImage class]]) {
        return activities;
    }
    if ((_supportedWebActions & CruiserWebActionCopyLink) > 0 || self.supportsAllActions) {
        [activities addObject:[CruiserPolyActivity activityWithType:CruiserPolyActivityTypeLink]];
    }
    if ((_supportedWebActions & CruiserWebActionOpenSafari) > 0 || self.supportsAllActions) {
        [activities addObject:[CruiserPolyActivity activityWithType:CruiserPolyActivityTypeSafari]];
    }
    if ((_supportedWebActions & CruiserWebActionOpenChrome) > 0 || self.supportsAllActions) {
        [activities addObject:[CruiserPolyActivity activityWithType:CruiserPolyActivityTypeChrome]];
    }
    if ((_supportedWebActions & CruiserWebActionOpenOperaMini) > 0 || self.supportsAllActions) {
        [activities addObject:[CruiserPolyActivity activityWithType:CruiserPolyActivityTypeOpera]];
    }
    if ((_supportedWebActions & CruiserWebActionOpenDolphin) > 0 || self.supportsAllActions) {
        [activities addObject:[CruiserPolyActivity activityWithType:CruiserPolyActivityTypeDolphin]];
    }
    return activities;
}

- (NSArray *)excludedActivityTypesForItem:(id)item
{
    NSMutableArray *types = [[NSMutableArray alloc]
                             initWithCapacity:10];
    if (![item isKindOfClass:[UIImage class]]) {
        [types addObjectsFromArray:@[UIActivityTypeCopyToPasteboard,
                                     UIActivityTypeSaveToCameraRoll,
                                     UIActivityTypePostToFlickr,
                                     UIActivityTypePrint,
                                     UIActivityTypeAssignToContact]];
    }
    if (self.supportsAllActions) {
        return types;
    }
    if ((_supportedWebActions & CruiserSupportedWebActionshareLink) == 0) {
        [types addObjectsFromArray:@[UIActivityTypeMail, UIActivityTypeMessage,
                                     UIActivityTypePostToFacebook, UIActivityTypePostToTwitter,
                                     UIActivityTypePostToWeibo, UIActivityTypePostToTencentWeibo,
                                     UIActivityTypeAirDrop]];
    }
    if ((_supportedWebActions & CruiserWebActionReadLater) == 0
        && [item isKindOfClass:[UIImage class]]
        ) {
        [types addObject:UIActivityTypeAddToReadingList];
    }
    return types;
}

- (BOOL)supportsAllActions
{
    return _supportedWebActions == CruiserWebActionAll;
}


#pragma mark - Setter methods

- (void)setURL:(NSURL *)URL
{
    if ([self.URL isEqual:URL]) {
        return;
    }
    if (self.isViewLoaded) {
        [self loadURL:URL];
    }
    _URL = URL;
}

// Sets the request errors with an alert view.
- (void)setLoadingError:(NSError *)error
{
    switch (error.code) {
        case NSURLErrorUnknown:
        case NSURLErrorCancelled:   return;
    }
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil)
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil] show];
}

- (void)setAddressField:(UITextField *)addressField
{
    if (self.addressField == addressField) {
        return;
    }
    addressField.delegate = self;
    self->_addressField = addressField;
    self.titleFont = self.addressField.font;
}


#pragma mark - CruiserWebViewController methods

- (BOOL)validateHostname:(NSString *)query
{
    NSPredicate *urlTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@",
                            kHostnameRegex];
    return [urlTest evaluateWithObject:query];
}

- (NSURL *)URLFromString:(NSString *)query
{
    // try to use query as an URL
    NSURL *url = [NSURL URLWithString:query];

    if (url) {
        if (url.host && url.scheme) {
            return url;
        }
        if ([self validateHostname:query]) {
            url = [self URLFromString:
                   [NSString stringWithFormat:@"http://%@", query]];
            return url;
        }
    }
    // make search by query
    NSString *currentSearchServiceRequestPath = @"";

    switch (self.currentSearchService) {
        case CruiserSearchServicePrimary:
            currentSearchServiceRequestPath = [kGoogleServiceRequestPath copy];
            break;
        case CruiserSearchServiceAlternative:
            currentSearchServiceRequestPath = [kDuckDuckGoServiceRequestPath copy];
            break;
    }
    url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",
                                currentSearchServiceRequestPath,
                                [query stringByAddingPercentEscapesUsingEncoding:
                                 NSASCIIStringEncoding]]];
    return url;
}

- (void)loadURL:(NSURL *)URL
{
    if ([URL isFileURL]) {
        NSData *data = [[NSData alloc] initWithContentsOfURL:URL];
        NSString *HTMLString = [[NSString alloc] initWithData:data
                                                     encoding:NSStringEncodingConversionAllowLossy];
        [self.webView loadHTMLString:HTMLString
                             baseURL:nil];
    } else {
        NSURLRequest *request = [[NSURLRequest alloc] initWithURL:URL];
        [self.webView loadRequest:request];
    }
}

- (void)goBackward:(id)sender
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
}

- (void)goForward:(id)sender
{
    if ([self.webView canGoForward]) {
        [self.webView goForward];
    }
}

- (void)pinHere:(id)sender
{
    NSNumber *position = @(self.webView.scrollView.contentOffset.y);

    NSMutableArray *pagePins = self.pins[self.webView.URL.absoluteString];

    if (!pagePins) { // new page
        pagePins = [[NSMutableArray alloc] initWithCapacity:1];
        self.pins[self.webView.URL] = pagePins;
    }
    for (NSNumber *p in pagePins) {
        if ([p isEqualToNumber:position]) {
            return;
        }
    }
    [pagePins addObject:position];
    // sort pins for quick access
    [pagePins sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        NSNumber *num1 = (NSNumber *)obj1;
        NSNumber *num2 = (NSNumber *)obj2;

        if (![num1 isKindOfClass:[NSNumber class]]
            || ![num2 isKindOfClass:[NSNumber class]]
            ) {
            return NSOrderedSame;
        }
        return [num1 compare:num2];
    }];
}

// TODO: speed up scrollDown: and scrollUp: method's enumeration with bisection method
- (void)scrollDown:(id)sender
{
    NSNumber *position = @(self.webView.scrollView.contentOffset.y);

    NSMutableArray *pagePins = self.pins[self.webView.URL.absoluteString];

    if (pagePins) {
        for (NSNumber *p in pagePins) {
            if ([p compare:position] == NSOrderedDescending) {
                CGPoint pinOffset = CGPointMake(0.f,
                                                p.floatValue);
                [self.webView.scrollView setContentOffset:pinOffset
                                                 animated:YES];
                return;
            }
        }
    }
    CGPoint bottomOffset = CGPointMake(0.f,
                                       self.webView.scrollView.contentSize.height
                                       - self.webView.scrollView.bounds.size.height);
    [self.webView.scrollView setContentOffset:bottomOffset
                                     animated:YES];
}

- (void)scrollUp:(id)sender
{
    NSNumber *position = @(self.webView.scrollView.contentOffset.y);

    NSMutableArray *pagePins = self.pins[self.webView.URL.absoluteString];

    if (pagePins) {
        for (NSNumber *p in [pagePins reverseObjectEnumerator]) {
            if ([p compare:position] == NSOrderedAscending) {
                CGPoint pinOffset = CGPointMake(0.f,
                                                p.floatValue);
                [self.webView.scrollView setContentOffset:pinOffset
                                                 animated:YES];
                return;
            }
        }
    }
    CGPoint topOffset = CGPointMake(0.f,
                                    -self.webView.scrollView.contentInset.top);
    [self.webView.scrollView setContentOffset:topOffset
                                     animated:YES];
}

- (void)dismissHistoryController
{
    if (self.presentedViewController) {
        [self.presentedViewController dismissViewControllerAnimated:YES completion:^{

            // The bar button item's gestures are invalidated after using them, so we must re-assign them.
            [self configureBarItemsGestures];
        }];
    }
}

- (void)showBackwardHistory:(UIGestureRecognizer *)sender
{
    if (!self.allowHistory || self.webView.backForwardList.backList.count == 0 || sender.state != UIGestureRecognizerStateBegan) {
        return;
    }

    [self presentHistoryControllerForTool:CruiserWebNavigationToolBackward fromView:sender.view];
}

- (void)showForwardHistory:(UIGestureRecognizer *)sender
{
    if (!self.allowHistory
        || self.webView.backForwardList.forwardList.count == 0
        || sender.state != UIGestureRecognizerStateBegan
        ) {
        return;
    }
    [self presentHistoryControllerForTool:CruiserWebNavigationToolForward fromView:sender.view];
}

- (void)presentHistoryControllerForTool:(CruiserWebNavigationTools)tool fromView:(UIView *)view
{
    UITableViewController *controller = [UITableViewController new];
    controller.title = NSLocalizedStringFromTable(@"History", @"CruiserWebViewController", nil);
    controller.tableView.delegate = self;
    controller.tableView.dataSource = self;
    controller.tableView.tag = tool;
    controller.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                 target:self
                                                                                                 action:@selector(dismissHistoryController)];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    UIView *bar = CRUISER_IS_IPAD ? self.navigationBar : self.toolbar;

    if (CRUISER_IS_IPAD) {
        UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:navigationController];
        [popover presentPopoverFromRect:view.frame
                                 inView:bar
               permittedArrowDirections:UIPopoverArrowDirectionAny
                               animated:YES];
    } else {
        [self presentViewController:navigationController
                           animated:YES
                         completion:NULL];
    }
}

- (void)configureToolBars
{
    if (CRUISER_IS_IPAD) {
        self.navigationItem.rightBarButtonItems = [[[self navigationToolItems] reverseObjectEnumerator] allObjects];
    } else {
        [self setToolbarItems:[self navigationToolItems]];
    }
    self.toolbar = self.navigationController.toolbar;

    self.navigationBar = self.navigationController.navigationBar;
    self.navigationBarSuperView = self.navigationBar.superview;

    self.navigationController.hidesBarsWhenVerticallyCompact = self.hideBarsWithGestures;
    self.navigationController.hidesBarsOnSwipe               = NO; // because not good for navigation
    self.navigationController.hidesBottomBarWhenPushed       = NO; // because not good for navigation
    self.navigationController.hidesBarsWhenKeyboardAppears   = NO; // because of address field

    if (self.hideBarsWithGestures) {
        [self.navigationBar addObserver:self
                             forKeyPath:@"hidden"
                                options:NSKeyValueObservingOptionNew
                                context:&CruiserWebViewControllerKVOContext];
        [self.navigationBar addObserver:self
                             forKeyPath:@"center"
                                options:NSKeyValueObservingOptionNew
                                context:&CruiserWebViewControllerKVOContext];
        [self.navigationBar addObserver:self
                             forKeyPath:@"alpha"
                                options:NSKeyValueObservingOptionNew
                                context:&CruiserWebViewControllerKVOContext];
    }
    if (!CRUISER_IS_IPAD
        && self.navigationController.toolbarHidden
        && self.toolbarItems.count > 0
        ) {
        self.navigationController.toolbarHidden = NO;
    }
    if (self.addressField) {
        self.addressField.rightView = self.stateButton;
        self.addressField.leftView = self.webButton;
    }
}

// Light hack for adding custom gesture recognizers to UIBarButtonItems
- (void)configureBarItemsGestures
{
    UIView *backwardButton= [self.backwardBarItem valueForKey:@"view"];
    if (backwardButton.gestureRecognizers.count == 0) {
        if (!_backwardLongPress) {
            _backwardLongPress = [[UILongPressGestureRecognizer
                                   alloc] initWithTarget:self
                                                  action:@selector(showBackwardHistory:)];
        }
        [backwardButton addGestureRecognizer:self.backwardLongPress];
    }

    UIView *forwardBarButton= [self.forwardBarItem valueForKey:@"view"];
    if (forwardBarButton.gestureRecognizers.count == 0) {
        if (!_forwardLongPress) {
            _forwardLongPress = [[UILongPressGestureRecognizer
                                  alloc] initWithTarget:self
                                                 action:@selector(showForwardHistory:)];
        }
        [forwardBarButton addGestureRecognizer:self.forwardLongPress];
    }
}

- (void)updateToolbarItems
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:self.webView.loading];

    self.backwardBarItem.enabled = [self.webView canGoBack];
    self.forwardBarItem.enabled = [self.webView canGoForward];
    
    [self updatePinBarItems];

    self.actionBarItem.enabled = !self.webView.isLoading;

    [self updateStateButton];
    [self updateDownUpItems];
}

- (void)updatePinBarItems
{
    self.pinBarItem.enabled  = YES;
    self.downBarItem.enabled = YES;
    self.upBarItem.enabled   = YES;
}

- (void)updateStateButton
{
    [self.stateButton removeTarget:nil
                            action:NULL
                  forControlEvents:UIControlEventAllEvents];
    [self.stateButton addTarget:self.webView
                         action:self.webView.isLoading ? @selector(stopLoading) : @selector(reload)
               forControlEvents:UIControlEventTouchUpInside];
    [self.stateButton setImage:self.webView.isLoading ? self.stopButtonImage : self.reloadButtonImage
                      forState:UIControlStateNormal];
    self.stateButton.accessibilityLabel = NSLocalizedStringFromTable(self.webView.isLoading ? @"Stop"
                                                                     : @"Reload",
                                                                     @"CruiserWebViewController",
                                                                     @"Accessibility label button title");
    self.stateButton.enabled = YES;
}

- (void)switchSearchService:(id)sender
{
    switch (self.currentSearchService) {
        case CruiserSearchServicePrimary: {
            [self.webButton setImage:[self alternativeSearchButtonImage]
                            forState:UIControlStateNormal];
            self.currentSearchService = CruiserSearchServiceAlternative;
        }
            break;
        case CruiserSearchServiceAlternative: {
            [self.webButton setImage:[self primarySearchButtonImage]
                            forState:UIControlStateNormal];
            self.currentSearchService = CruiserSearchServicePrimary;
        }
            break;
    }
}

- (void)presentActivityController:(id)sender
{
    if (!self.webView.URL.absoluteString) {
        return;
    }

    [self presentActivityControllerWithItem:self.webView.URL.absoluteString
                                   andTitle:self.webView.title
                                     sender:sender];
}

- (void)presentActivityControllerWithItem:(id)item
                                 andTitle:(NSString *)title
                                   sender:(id)sender
{
    if (!item) {
        return;
    }
    UIActivityViewController *controller =
    [[UIActivityViewController alloc] initWithActivityItems:@[title, item]
                                      applicationActivities:[self applicationActivitiesForItem:item]];
    controller.excludedActivityTypes = [self excludedActivityTypesForItem:item];

    if (title) {
        [controller setValue:title forKey:@"subject"];
    }
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        controller.popoverPresentationController.barButtonItem = sender;
    }
    [self presentViewController:controller
                       animated:YES
                     completion:NULL];
}

- (void)clearProgressViewAnimated:(BOOL)animated
{
    if (!_progressView) {
        return;
    }
    [UIView animateWithDuration:animated ? kAnimationDuration : 0.0
                     animations:^{
                         self.progressView.alpha = 0;
                     } completion:^(BOOL finished) {
                         [self destroyProgressViewIfNeeded];
                     }];
}

- (void)destroyProgressViewIfNeeded
{
    if (_progressView) {
        [_progressView removeFromSuperview];
        _progressView = nil;
    }
}

- (void)updateDownUpItems
{
    self.downBarItem.enabled = self.webView.scrollView.contentOffset.y + self.webView.scrollView.frame.size.height
                             < self.webView.scrollView.contentSize.height;
    self.upBarItem.enabled   = self.webView.scrollView.contentOffset.y > 0.f;
}


#pragma mark - CruiserNavigationDelegate methods

- (void)                webView:(CruiserWebView *)webView
  didStartProvisionalNavigation:(WKNavigation *)navigation
{
    [self updateStateButton];

    if (self.addressField) {
        self.addressField.text = self.webView.URL.absoluteString;
    }
    self.title = self.webView.URL.absoluteString;
}

- (void)      webView:(CruiserWebView *)webView
  didCommitNavigation:(WKNavigation *)navigation
{
    UIApplication.sharedApplication.networkActivityIndicatorVisible = self.webView.loading;
}

- (void)    webView:(CruiserWebView *)webView
  didUpdateProgress:(CGFloat)progress
{
    if (!self.showLoadingProgress) {
        [self destroyProgressViewIfNeeded];
        return;
    }
    if (self.progressView.alpha == 0.f && progress > 0) {

        self.progressView.progress = 0.f;

        [UIView animateWithDuration:0.2 animations:^{
            self.progressView.alpha = 1.f;
        }];
    }
    else if (self.progressView.alpha == 1.f && progress == 1.f)
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.progressView.alpha = 0.f;
        } completion:^(BOOL finished) {
            self.progressView.progress = 0.f;
        }];
    }
    [self.progressView setProgress:progress
                          animated:YES];
}

- (void)      webView:(CruiserWebView *)webView
  didFinishNavigation:(WKNavigation *)navigation
{
    [self updateToolbarItems];

    if (self.addressField) {
        self.addressField.text = self.webView.title;
    }
    self.title = self.webView.title;
}

- (void)    webView:(CruiserWebView *)webView
  didFailNavigation:(WKNavigation *)navigation
          withError:(NSError *)error
{
    [self updateToolbarItems];
    [self setLoadingError:error];

    if (self.addressField) {
        self.addressField.text = @"";
    } else {
        self.title = @"";
    }
}


#pragma mark - WKUIDelegate methods

- (CruiserWebView *)     webView:(CruiserWebView *)webView
  createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration
             forNavigationAction:(WKNavigationAction *)navigationAction
                  windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
    [self updateDownUpItems];
}
/*
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate
{
    if (decelerate) {
        return;
    }
    if (self.toolbar.hidden || self.navigationBar.hidden) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BarsShouldUnhide"
                                                            object:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (self.toolbar.hidden || self.navigationBar.hidden) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BarsShouldUnhide"
                                                            object:self];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (self.hideBarsWithGestures) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"BarsShouldHide"
                                                            object:self];
    }
}
*/

#pragma mark - IPNavBarSqueezableViewController

- (void)processBars
{
    [self squeezeAddressField];

    [super processBars];
}

- (void)squeezeBars
{
    [self squeezeAddressField];

    [super squeezeBars];
}

- (void)squeezeAddressField
{
    if (!self.addressField) {
        return;
    }
    self.addressField.text = self.webView.title;
    self.addressField.borderStyle = UITextBorderStyleNone;
    self.addressField.backgroundColor = [self.addressField.backgroundColor
                                         colorWithAlphaComponent:0.f];
    [self.addressField resignFirstResponder];

    self.addressField.rightViewMode = UITextFieldViewModeNever;
    self.addressField.leftViewMode  = UITextFieldViewModeNever;
    [self destroyProgressViewIfNeeded];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView
  numberOfRowsInSection:(NSInteger)section
{
    if (tableView.tag == CruiserWebNavigationToolBackward) {
        return self.webView.backForwardList.backList.count;
    }
    if (tableView.tag == CruiserWebNavigationToolForward) {
        return self.webView.backForwardList.forwardList.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
    }
    WKBackForwardListItem *item = nil;

    if (tableView.tag == CruiserWebNavigationToolBackward) {
        item = self.webView.backForwardList.backList[indexPath.row];
    }
    if (tableView.tag == CruiserWebNavigationToolForward) {
        item = self.webView.backForwardList.forwardList[indexPath.row];
    }
    cell.textLabel.text = item.title;
    cell.detailTextLabel.text = [item.URL absoluteString];

    return cell;
}

- (CGFloat)     tableView:(UITableView *)tableView
  heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.f;
}


#pragma mark - UITableViewDelegate Methods

- (void)        tableView:(UITableView *)tableView
  didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    WKBackForwardListItem *item = nil;

    if (tableView.tag == CruiserWebNavigationToolBackward) {
        item = self.webView.backForwardList.backList[indexPath.row];
    }
    if (tableView.tag == CruiserWebNavigationToolForward) {
        item = self.webView.backForwardList.forwardList[indexPath.row];
    }
    [self.webView goToBackForwardListItem:item];
    [self dismissHistoryController];
}


#pragma mark - Key Value Observer

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (context != &CruiserWebViewControllerKVOContext) {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
        return;
    }
    if (![object isEqual:self.navigationBar]) {
        return;
    }
    // Skips for landscape orientation, since there is no status bar visible on iPhone landscape
    if (CRUISER_IS_LANDSCAPE) {
        return;
    }
    id newValue = change[NSKeyValueChangeNewKey];
    
    if ([keyPath isEqualToString:@"hidden"]
        && [newValue boolValue]
        && self.navigationBar.center.y >= -2.f
        ) {
        self.navigationBar.hidden = NO;
        
        if (!self.navigationBar.superview) {
            [self.navigationBarSuperView addSubview:self.navigationBar];
        }
    }
    if ([keyPath isEqualToString:@"center"]) {
        CGPoint center = [newValue CGPointValue];
        
        if (center.y < -2.f) {
            center.y = -2.f;
            self.navigationBar.center = center;
            
            [UIView beginAnimations:@"CruiserNavigationBarAnimation" context:nil];
            
            for (UIView *subview in self.navigationBar.subviews) {
                if (subview != self.navigationBar.subviews[0]) {
                    subview.alpha = 0.f;
                }
            }
            [UIView commitAnimations];
        }
    }
}


#pragma mark - View Auto-Rotation

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotate
{
    return NO;
}


#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (textField != self.addressField) {
        return;
    }
    textField.textAlignment = NSTextAlignmentLeft;
    textField.text = self.webView.URL.absoluteString;
    self.title = self.addressField.text;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField != self.addressField) {
        return;
    }
    textField.textAlignment = NSTextAlignmentCenter;
    textField.text = self.webView.title;
    self.title = self.addressField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField != self.addressField) {
        return YES;
    }
    [self loadURL:[self URLFromString:textField.text]];
    [textField resignFirstResponder];
    return NO;
}

@end
