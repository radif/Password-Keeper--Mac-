//
//  AppDelegate.h
//  Passwords
//
//  Created by Radif's Mac Sharafullin on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTextViewDelegate>

@property (assign) IBOutlet NSWindow *window;
-(IBAction)importFile:(id)sender;
-(IBAction)exportFile:(id)sender;
-(IBAction)closeWindow:(id)sender;
-(IBAction)saveFile:(id)sender;
@end
