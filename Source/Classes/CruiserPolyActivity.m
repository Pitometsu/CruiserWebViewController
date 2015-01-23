//
//  CruiserPolyActivity.m
//  CruiserWebViewController
//  https://github.com/dzenbot/CruiserWebViewController
//
//  Created by Ignacio Romero Zurbuchen on 3/28/14.
//  Improved by Yuriy Pitomets on 23/01/2015
//  Copyright (c) 2014 DZN Labs. All rights reserved.
//  Copyright (c) 2015 Yuriy Pitomets. No rights reserved.
//  Licence: MIT-Licence
//

#import "CruiserPolyActivity.h"

@implementation CruiserPolyActivity

+ (instancetype)activityWithType:(CruiserPolyActivityType)type
{
    return [[CruiserPolyActivity alloc] initWithActivityType:type];
}

- (instancetype)initWithActivityType:(CruiserPolyActivityType)type
{
    self = [super init];
    if (self) {
        _type = type;
    }
    return self;
}


#pragma mark - Getter methods

+ (UIActivityCategory)activityCategory
{
    return UIActivityCategoryAction;
}

- (NSString *)activityType
{
    switch (self.type) {
        case CruiserPolyActivityTypeLink:           return @"com.appcruiser.CruiserWebViewController.activity.CopyLink";
        case CruiserPolyActivityTypeSafari:         return @"com.appcruiser.CruiserWebViewController.activity.OpenInSafari";
        case CruiserPolyActivityTypeChrome:         return @"com.appcruiser.CruiserWebViewController.activity.OpenInChrome";
        case CruiserPolyActivityTypeOpera:          return @"com.appcruiser.CruiserWebViewController.activity.OpenInOperaMini";
        case CruiserPolyActivityTypeDolphin:        return @"com.appcruiser.CruiserWebViewController.activity.OpenInDolphin";
    }
}

- (NSString *)activityTitle
{
    switch (self.type) {
        case CruiserPolyActivityTypeLink:           return NSLocalizedString(@"Copy Link", nil);
        case CruiserPolyActivityTypeSafari:         return NSLocalizedString(@"Open in Safari", nil);
        case CruiserPolyActivityTypeChrome:         return NSLocalizedString(@"Open in Chrome", nil);
        case CruiserPolyActivityTypeOpera:          return NSLocalizedString(@"Open in Opera", nil);
        case CruiserPolyActivityTypeDolphin:        return NSLocalizedString(@"Open in Dolphin", nil);
    }
}

- (UIImage *)activityImage
{
    switch (self.type) {
        case CruiserPolyActivityTypeLink:           return [UIImage imageNamed:@"cruiser_icn_activity_link"];
        case CruiserPolyActivityTypeSafari:         return [UIImage imageNamed:@"cruiser_icn_activity_safari"];
        case CruiserPolyActivityTypeChrome:         return [UIImage imageNamed:@"cruiser_icn_activity_chrome"];
        case CruiserPolyActivityTypeOpera:          return [UIImage imageNamed:@"cruiser_icn_activity_opera"];
        case CruiserPolyActivityTypeDolphin:        return [UIImage imageNamed:@"cruiser_icn_activity_dolphin"];
        default:                                return nil;
    }
}

- (NSURL *)chromeURLWithURL:(NSURL *)URL
{
    return [self customURLWithURL:URL andType:CruiserPolyActivityTypeChrome];
}

- (NSURL *)operaURLWithURL:(NSURL *)URL
{
    return [self customURLWithURL:URL andType:CruiserPolyActivityTypeOpera];
}

- (NSURL *)dolphinURLWithURL:(NSURL *)URL
{
    return [self customURLWithURL:URL andType:CruiserPolyActivityTypeDolphin];
}

- (NSURL *)customURLWithURL:(NSURL *)URL andType:(CruiserPolyActivityType)type
{
    // Replaces the URL Scheme with the type equivalent.
    NSString *scheme = nil;
    if ([URL.scheme isEqualToString:@"http"]) {
        if (type == CruiserPolyActivityTypeChrome) scheme = @"googlechrome";
        if (type == CruiserPolyActivityTypeOpera) scheme = @"ohttp";
        if (type == CruiserPolyActivityTypeDolphin) scheme = @"dolphin";
    }
    else if ([URL.scheme isEqualToString:@"https"]) {
        if (type == CruiserPolyActivityTypeChrome) scheme = @"googlechromes";
        if (type == CruiserPolyActivityTypeOpera) scheme = @"ohttps";
        if (type == CruiserPolyActivityTypeDolphin) scheme = @"dolphin";
    }

    // Proceeds only if a valid URI Scheme is available.
    if (scheme) {
        NSRange range = [[URL absoluteString] rangeOfString:@":"];
        NSString *urlNoScheme = [[URL absoluteString] substringFromIndex:range.location];
        return [NSURL URLWithString:[scheme stringByAppendingString:urlNoScheme]];
    }

    return nil;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	for (UIActivity *item in activityItems) {

		if ([item isKindOfClass:[NSString class]]) {

			NSURL *URL = [NSURL URLWithString:(NSString *)item];
            if (!URL) continue;

            if (self.type == CruiserPolyActivityTypeLink) {
                return URL ? YES : NO;
            }
            if (self.type == CruiserPolyActivityTypeSafari) {
                return [[UIApplication sharedApplication] canOpenURL:URL];
            }
            if (self.type == CruiserPolyActivityTypeChrome) {
                return [[UIApplication sharedApplication] canOpenURL:[self chromeURLWithURL:URL]];
            }
            if (self.type == CruiserPolyActivityTypeOpera) {
                return [[UIApplication sharedApplication] canOpenURL:[self operaURLWithURL:URL]];
            }
            if (self.type == CruiserPolyActivityTypeDolphin) {
                return [[UIApplication sharedApplication] canOpenURL:[self dolphinURLWithURL:URL]];
            }

            break;
		}
	}

	return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	for (id item in activityItems) {

		if ([item isKindOfClass:[NSString class]]) {
			_URL = [NSURL URLWithString:(NSString *)item];
            if (!self.URL) continue;
            else break;
		}
	}
}

- (void)performActivity
{
    BOOL completed = NO;

    if (!self.URL) {
        [self activityDidFinish:completed];
        return;
    }

    switch (self.type) {
        case CruiserPolyActivityTypeLink:
            [[UIPasteboard generalPasteboard] setURL:self.URL];
            completed = YES;
            break;
        case CruiserPolyActivityTypeSafari:
            completed = [[UIApplication sharedApplication] openURL:self.URL];
            break;
        case CruiserPolyActivityTypeChrome:
            completed = [[UIApplication sharedApplication] openURL:[self chromeURLWithURL:self.URL]];
            break;
        case CruiserPolyActivityTypeOpera:
            completed = [[UIApplication sharedApplication] openURL:[self operaURLWithURL:self.URL]];
            break;
        case CruiserPolyActivityTypeDolphin:
            completed = [[UIApplication sharedApplication] openURL:[self dolphinURLWithURL:self.URL]];
            break;
    }

	[self activityDidFinish:completed];
}

@end
