//
//  AppDelegate.m
//  Passwords
//
//  Created by Radif's Mac Sharafullin on 12/19/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"
#import "NSData+CommonCrypto.h"

@interface AppDelegate ()
-(NSString *)filePath;
-(NSString *)passwordDirectory;
-(NSString *)decodedStringWithKey:(NSString *)key error:(NSError **)error;
-(void)encodeString:(NSString *)string withKey:(NSString *)key;
-(void)saveWithPassword;
-(void)loadWithPassword;
-(NSString *)timestampID;  
-(void)fadeOut;
-(void)setChanged:(BOOL)changed;
-(void)loadFileWithKey:(NSString *)key;
-(void)backupCurrentFile;
@end
@implementation AppDelegate{
    IBOutlet NSTextView *_textView; 
    BOOL _changed;
    __strong NSString *_originalString;
    __strong NSString *_passwordString;
}

@synthesize window = _window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [self setChanged:FALSE];
    _originalString=@"";
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self filePath]]) 
        [self loadWithPassword];
    else
        [self loadFileWithKey:@""];
    
    
}
-(void)encodeString:(NSString *)string withKey:(NSString *)key{
    NSString *filePath=[self filePath];
    NSData *stringData=[string dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error=nil;
    NSData *encodedData=[stringData AES256EncryptedDataUsingKey:key error:&error];
    
    //prepare the backup of the file if exists
    [self backupCurrentFile];
    
    
    
    [encodedData writeToFile:filePath atomically:TRUE];
}

-(NSString *)decodedStringWithKey:(NSString *)key error:(NSError **)error{
    NSString *filePath=[self filePath];
    NSData *encodedData=[NSData dataWithContentsOfFile:filePath];
    
    NSString *decodedString=@"File \"~/.personal_passwords/.passwords\" was not found, please start the new document by replacing this text";
    if (encodedData) {
        NSError *err=nil;
        decodedString=[[NSString alloc] initWithData:[encodedData decryptedAES256DataUsingKey:key error:&err] encoding:NSUTF8StringEncoding];
        *error=err;
        
    }
    return decodedString;
}
-(NSString *)passwordDirectory{
    NSString * dir =[@"~/.personal_passwords" stringByResolvingSymlinksInPath];
    BOOL isDirectory=FALSE;

    BOOL found=FALSE;
    if ([[NSFileManager defaultManager] fileExistsAtPath:dir isDirectory:&isDirectory]) 
        if (isDirectory) 
            found=TRUE;
        
    if (!found)
        [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:TRUE attributes:nil error:nil];
    return dir;
    
}
-(NSString *)filePath{
    return [[self passwordDirectory] stringByAppendingPathComponent:@".passwords"];
}
-(NSString *)timestampID{
	NSDateFormatter *dateFormatter=[[NSDateFormatter alloc]init];
	[dateFormatter setDateFormat:@"MM-dd-yyyy_hh.mm.ss_a"];
	return [dateFormatter stringFromDate:[NSDate date]];
}
#pragma mark Window stuff
-(IBAction)closeWindow:(id)sender{

    [self saveWithPassword];
}

- (BOOL)windowShouldClose:(id)sender{
    [self saveWithPassword];
	return NO;
}
-(void)loadWithPassword{
    NSSecureTextField *accessory = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0,0,200,25)];
	[accessory insertText:[[NSAttributedString alloc] init]];
	[accessory setEditable:YES];
	[accessory setDrawsBackground:YES];
    
    
	NSAlert *alert = [[NSAlert alloc] init];
    
	[alert setAccessoryView:accessory];
	[alert setMessageText:@"Enter the master password"];
	[alert addButtonWithTitle:@"Done"];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:@"load_case"];
}

-(void)saveWithPassword{
    if (_changed) {
        NSSecureTextField *accessory = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0,0,200,25)];
        [accessory insertText:[[NSAttributedString alloc] init]];
        [accessory setEditable:YES];
        [accessory setDrawsBackground:YES];
        [accessory setStringValue:_passwordString];
    
    
	NSAlert *alert = [[NSAlert alloc] init];
    
	[alert setAccessoryView:accessory];
	[alert setMessageText:@"The passwords content has been changed"];
	[alert addButtonWithTitle:@"Save"];
	[alert addButtonWithTitle:@"Don't Save"];
	[alert beginSheetModalForWindow:[self window]
					  modalDelegate:self
					 didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
						contextInfo:@"save_case"];
    }else{
        [self fadeOut];
    
    }

}

-(void)fadeOut{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:1.0];
    [[[self window] animator] setAlphaValue:0.0];
    [[NSApplication sharedApplication] performSelector:@selector(terminate:) withObject:nil afterDelay:[[NSAnimationContext currentContext] duration]];
    [NSAnimationContext endGrouping];
}
#pragma mark Alert stuff
- (void) alertDidEnd:(NSAlert *)a returnCode:(NSInteger)rc contextInfo:(NSString *)ci {
	NSString* context=ci;
	if ([context isEqualToString:@"save_case"]) {
		switch(rc) {
			case NSAlertSecondButtonReturn:
				// "First" pressed
                [self fadeOut];
				break;
			case NSAlertFirstButtonReturn:
				// save here

			[self encodeString:[_textView string] withKey:[(NSSecureTextField *)[a accessoryView] stringValue]];
				
				[self fadeOut];
				break;
				// ...
		}
	}else if([context isEqualToString:@"save_case_no_exit"]){
        switch(rc) {
			case NSAlertSecondButtonReturn:
				// "First" pressed
				break;
			case NSAlertFirstButtonReturn:
				// save here
                
                [self encodeString:[_textView string] withKey:[(NSSecureTextField *)[a accessoryView] stringValue]];
				[self setChanged:FALSE];
				break;

        }
    }else if ([context isEqualToString:@"load_case"]) {
        [self loadFileWithKey:[(NSSecureTextField *)[a accessoryView] stringValue]];
    }
}
-(void)loadFileWithKey:(NSString *)key{
    NSError *error=nil;
    _passwordString=key;
    _originalString=[self decodedStringWithKey:_passwordString error:&error];
    if (error) {
        [self fadeOut];
        return;
    }else{
        [_textView setString:_originalString];
        [self setChanged:FALSE];
        [_textView setSelectedRange:NSMakeRange(0, 0)];
    }
}
-(void)textDidChange:(NSNotification *)notification{
        [self setChanged:(![[_textView string] isEqualToString:_originalString])];
}
-(void)backupCurrentFile{
    NSString * filePath=[self filePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        //backup
        NSString * backupFileName=[NSString stringWithFormat:@".%@_bak", [self timestampID]];
        [[NSFileManager defaultManager] moveItemAtPath:filePath toPath:[[filePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:backupFileName]
                                                 error:nil];
}
}
-(void)setChanged:(BOOL)changed{
    [_window setTitle:changed? @"Passwords*": @"Passwords"];
    _changed=changed;
}
#pragma mark Import/export
-(IBAction)importFile:(id)sender{
    if (_changed) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"You have modified the Passwords file since you opened it\nPlease, save your password file first"];
        [alert addButtonWithTitle:@"OK"];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:@""];
        
        return;
    }
    NSOpenPanel *openPanel=[NSOpenPanel openPanel];
    
    [openPanel setTitle:@"Import Passwords from File"];
	[openPanel setPrompt:@"Import"];
	[openPanel setMessage:@"Locate Your Password Export"];
	[openPanel setCanCreateDirectories:FALSE];
	[openPanel setNameFieldLabel:@"Import:"];
	[openPanel setExtensionHidden:FALSE ];
	[openPanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result){
        
		if(result == NSOKButton){
			//Save
			//NSString * tvarDirectory = [tvarNSSavePanelObj directory];
            [self backupCurrentFile];
			NSURL * fURL = [openPanel URL];
            [[NSFileManager defaultManager] copyItemAtURL:fURL toURL:[NSURL fileURLWithPath:[self filePath]] error:nil];
            
            [self performSelector:@selector(loadWithPassword) withObject:nil afterDelay:.1];
            
		} else if(result == NSCancelButton) {
			//cancel
			return;
		}   
		
	}];
    
}
-(IBAction)exportFile:(id)sender{
    NSString *filePath=[self filePath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"The Password file is not setup yet, please save your passwords first"];
        [alert addButtonWithTitle:@"OK"];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:@""];
        
        
        return;
    }
    
    if (_changed) {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:@"You have modified the Passwords file since you opened it\nPlease, save your password file first"];
        [alert addButtonWithTitle:@"OK"];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:nil
                         didEndSelector:nil
                            contextInfo:@""];
        
        return;
    }
    
    NSSavePanel *savePanel	= [NSSavePanel savePanel];
	[savePanel setTitle:@"Export Passwords As..."];
	[savePanel setPrompt:@"Export"];
	[savePanel setMessage:@"Name Your Password Export"];
	[savePanel setCanCreateDirectories:YES];
	[savePanel setNameFieldLabel:@"Export As:"];
	[savePanel setExtensionHidden:FALSE ];
	[savePanel beginSheetModalForWindow:_window completionHandler:^(NSInteger result){
        
		if(result == NSOKButton){
			//Save
			//NSString * tvarDirectory = [tvarNSSavePanelObj directory];
			NSURL * fURL = [savePanel URL];
            [[NSFileManager defaultManager] copyItemAtURL:[NSURL fileURLWithPath:filePath] toURL:fURL error:nil];
						
		} else if(result == NSCancelButton) {
			//cancel
			return;
		}   
		
	}];
    
	

}
-(IBAction)saveFile:(id)sender{
    if (_changed) {
        NSSecureTextField *accessory = [[NSSecureTextField alloc] initWithFrame:NSMakeRect(0,0,200,25)];
        [accessory insertText:[[NSAttributedString alloc] init]];
        [accessory setEditable:YES];
        [accessory setDrawsBackground:YES];
        [accessory setStringValue:_passwordString];
        
        
        NSAlert *alert = [[NSAlert alloc] init];
        
        [alert setAccessoryView:accessory];
        [alert setMessageText:@"The passwords content has been changed"];
        [alert addButtonWithTitle:@"Save"];
        [alert addButtonWithTitle:@"Don't Save"];
        [alert beginSheetModalForWindow:[self window]
                          modalDelegate:self
                         didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                            contextInfo:@"save_case_no_exit"];
    }
}
@end
