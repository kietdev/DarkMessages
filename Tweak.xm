//
//  DarkMessages
//  Dark theme for Messages app.
//  iOS 10
//
//  @sticktron
//

#import "Headers.h"


static CKUIThemeDark *darkTheme;
static BOOL isEnabled;

static void loadSettings() {
	NSDictionary *settings = nil;
	
	CFPreferencesAppSynchronize(CFSTR("com.sticktron.darkmessages"));
	CFArrayRef keyList = CFPreferencesCopyKeyList(CFSTR("com.sticktron.darkmessages"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
	if (keyList) {
		settings = (NSDictionary *)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, CFSTR("com.sticktron.darkmessages"), kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
		CFRelease(keyList);
	}
	
	isEnabled = (settings && settings[@"Enabled"]) ? [settings[@"Enabled"] boolValue] : YES;
}

static void settingsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	// restart the Messages app
	HBLogInfo(@"DarkMessages >> Terminating MobileSMS...");
	[[UIApplication sharedApplication] terminateWithSuccess];
}


// Hooks -----------------------------------------------------------------------

%group Phone

%hook CKUIBehaviorPhone
- (id)theme {
	return darkTheme;
}
%end

%end

//------------------------------------------------------------------------------

%group Pad

%hook CKUIBehaviorPad
- (id)theme {
	return darkTheme;
}
%end

%end

//------------------------------------------------------------------------------

%group Common

// fix navbar: style
%hook CKAvatarNavigationBar
- (void)_setBarStyle:(int)style {
	%orig(1);
}
%end

// fix navbar: contact names
%hook CKAvatarContactNameCollectionReusableView
- (void)setStyle:(int)style {
	%orig(3);
}
%end

// fix navbar: group names
%hook CKAvatarTitleCollectionReusableView
- (void)setStyle:(int)style {
	%orig(3);
}
%end

// fix navbar: new message label
%hook CKNavigationBarCanvasView
- (void)setTitleView:(id)titleView {
	if (titleView && [titleView respondsToSelector:@selector(setTextColor:)]) {
		[(UILabel *)titleView setTextColor:UIColor.whiteColor];
	}
	%orig(titleView);
}
%end

// fix group details: contact names
%hook CKDetailsContactsTableViewCell
- (UILabel *)nameLabel {
	UILabel *nl = %orig;
	nl.textColor = UIColor.whiteColor;
	return nl;
}
%end

%end

//------------------------------------------------------------------------------

%ctor {
	@autoreleasepool {
		HBLogDebug("@Tweak loading...");
		
		loadSettings();
		
		if (isEnabled) {
			darkTheme = [[%c(CKUIThemeDark) alloc] init];
			
			// init hooks
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				%init(Pad);
			} else {
				%init(Phone);
			}
			%init(Common);
		}
		
		// listen for notifications from settings
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
			NULL,
			(CFNotificationCallback)settingsChanged,
			CFSTR("com.sticktron.darkmessages.settingschanged"),
			NULL,
			CFNotificationSuspensionBehaviorDeliverImmediately);
	}
}
