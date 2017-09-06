
/*
 UnRar Multi - Bach Unrar Tool.
 written by Jared Bruni
 */

//
//  AppController.h
//  UnrarMulti
//
//  Created by Jared Bruni on 10/12/15.
//  Copyright © 2015 Jared Bruni. All rights reserved.
//

#ifndef AppController_h
#define AppController_h
#import<Cocoa/Cocoa.h>

#include<sstream>

@interface AppController : NSObject {
 
    IBOutlet NSTextView *txt_view;
    IBOutlet NSButton *extract_button;
    IBOutlet NSComboBox *box;
    IBOutlet NSButton *paths;
    IBOutlet NSProgressIndicator *progress;
    NSMutableArray *files;
    
}
- (IBAction) removeFromList: (id) sender;
- (IBAction) addFiles: (id) sender;
- (IBAction) extract: (id) sender;
- (IBAction) clearList: (id) sender;
- (IBAction) addFile: (id) sender;
- (void) flushToLog: (std::ostringstream *)str;

@end



#endif /* AppController_h */
