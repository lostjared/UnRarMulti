/*
 UnRar Multi - Bach Unrar Tool.
 written by Jared Bruni
 */

//
//  AppController.m
//  UnrarMulti
//
//  Created by Jared Bruni on 10/12/15.
//  Copyright © 2015 Jared Bruni. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AppController.h"

#include<iostream>
#include<string>
#include<vector>
#include<dirent.h>
#include<sys/types.h>
#include<sys/stat.h>
#include<sstream>
#include<cstdio>
#include<cstdlib>
#include<unistd.h>
#include<regex>

void extract_paths(NSInteger state, id s, std::string output_path, std::vector<std::string> &files);


void add_directory(std::string path, std::vector<std::string> &files) {
    DIR *dir = opendir(path.c_str());
    if(dir == NULL) {
        std::cerr << "Error could not open directory: " << path << "\n";
        return;
    }
    dirent *file_info;
    while( (file_info = readdir(dir)) != 0 ) {
        std::string f_info = file_info->d_name;
        if(f_info == "." || f_info == "..")  continue;
        std::string fullpath=path+"/"+f_info;
        struct stat s;
#ifdef WIN32
        stat(fullpath.c_str(), &s);
#else
        lstat(fullpath.c_str(), &s);
#endif
        if(S_ISDIR(s.st_mode)) {
            if(f_info.length()>0 && f_info[0] != '.')
                add_directory(path+"/"+f_info, files);
            
            continue;
        }
        if(f_info.length()>0 && f_info[0] != '.') {
            std::string ext;
            auto pos = f_info.rfind(".");
            if(pos != std::string::npos) {
                std::string ext = f_info.substr(pos, f_info.length()-pos);
                std::string filename = f_info.substr(0, pos);
                if(ext == ".rar") {
                    std::regex r(R"(^((?!\.part(?!0*1\.rar$)\d+\.rar$).)*\.(?:rar|r?0*1)$)");
                    if(std::regex_search(f_info, r) == true) {
                        std::cout << "added: " << fullpath << "\n";
                        files.push_back(fullpath);
                        continue;
                    }
                }
            }
        }
    }
    closedir(dir);
}

void extract_paths(NSInteger state, id s, std::string output_path, std::vector<std::string> &files) {
    
    std::ostringstream stream_out;
    
    NSBundle *bundle = [NSBundle mainBundle];
    
    NSString *value = [bundle pathForResource:@"unrar" ofType:nil];
    
    for(unsigned int i = 0; i < files.size(); ++i) {
        std::ostringstream stream;
        stream << "\"" << [value UTF8String] << "\" " << ((state == 1) ? "e" : "x") << " -o+ \"" << files[i] << "\" \"" << output_path << "\"";
        FILE *fptr = popen(stream.str().c_str(), "r");
        if(!fptr) {
            stream_out << "Error opening file: " << files[i] << "\n";
            [s flushToLog: &stream_out];
            continue;
        }
        
        char return_data[PATH_MAX];
        while(fgets(return_data, PATH_MAX, fptr) != NULL) {
            stream_out << return_data;
            [s flushToLog: &stream_out];
        }
        
        int status = pclose(fptr);
        if(status == 0) {
            stream_out << "Successfully extracted to output directory: " << output_path << "\n";
        } else {
            stream_out << "Extraction failed..\n";
        }
        [s flushToLog: &stream_out];
    }
}


std::vector<std::string> vfiles;

@implementation AppController

- (id) init {
    self  = [super init];
    files = [[NSMutableArray alloc] init];
    return self;
}


- (void) awakeFromNib {
    
    [extract_button setEnabled: NO];
    [box removeAllItems];
    
}


- (IBAction) addFiles: (id) sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setCanCreateDirectories:NO];
    if([panel runModal]) {
        
        [progress setHidden: NO];
        [progress startAnimation:self];
        
        dispatch_queue_t qt = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(qt, ^{
            NSString *str_x = [[[panel URLs] objectAtIndex: 0] path];
            add_directory([str_x UTF8String], vfiles);
            dispatch_sync(dispatch_get_main_queue(), ^{
                if(vfiles.size()>0) {
                    for(unsigned int i = 0; i < vfiles.size(); ++i) {
                        NSString *s = [NSString stringWithUTF8String: vfiles[i].c_str()];
                        [box addItemWithObjectValue: s];
                    }
                    [box reloadData];
                    [extract_button setEnabled: YES];
                    [progress setHidden: YES];
                    [progress stopAnimation:self];
                }
                
            });
           
        });
        if(!vfiles.empty()) {
            vfiles.erase(vfiles.begin(), vfiles.end());
        }
    }
}


- (IBAction) extract: (id) sender {
    
    std::vector<std::string> *efiles;

    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:NO];
    [panel setCanCreateDirectories:YES];
    
    if([panel runModal]) {
        [extract_button setEnabled: NO];
        efiles = new std::vector<std::string>();
        
        for(unsigned int i = 0; i < [box numberOfItems]; ++i) {
            std::string value = [[[box objectValues] objectAtIndex: i] UTF8String];
            std::cout << value << "\n";
            efiles->push_back(value);
        }
        
        [progress setHidden: NO];
        [progress startAnimation:self];
        
        dispatch_queue_t qt = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        dispatch_async(qt, ^{
            NSString *str_x = [[[panel URLs] objectAtIndex: 0] path];
            NSInteger state;
            
            if([paths state] == NSOnState)
                state = 1;
             else state = 0;
            
            extract_paths(state, self, [str_x UTF8String], *efiles);
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                delete efiles;
                std::cout << "Deleted vector\n";
                [extract_button setEnabled: YES];
                [progress stopAnimation:self];
                [progress setHidden: YES];
            });
        });
    
      
    
    }
    
}

- (IBAction) removeFromList: (id) sender {
    NSInteger cur_index = [box indexOfSelectedItem];
    if(cur_index != -1) {
        [box removeItemAtIndex: cur_index];
        
        if([box numberOfItems] > 0)
            [box selectItemAtIndex: 0];
        
        if([box numberOfItems] == 0) {
            [extract_button setEnabled: NO];
        }
        
        [box setStringValue: @""];
        [box reloadData];
    }
}

- (IBAction) addFile: (id) sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setCanCreateDirectories:NO];
    [panel setAllowsMultipleSelection: YES];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects: @"rar",nil]];
    if([panel runModal]) {
        for(NSInteger i = 0; i < [[panel URLs] count]; ++i) {
            NSString *text = [[[panel URLs] objectAtIndex: i] path];
            [box addItemWithObjectValue:text];
        }
        [box reloadData];
        [extract_button setEnabled: YES];
    }
}


- (IBAction) clearList: (id) sender {
    
    [box removeAllItems];
    [box setStringValue: @""];
    [box reloadData];
    [extract_button setEnabled: NO];
    
}

- (void) flushToLog:(std::ostringstream *)sout {
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        NSTextView *sv = txt_view;
        NSString *value = [[sv textStorage] string];
        NSString *newValue = [[NSString alloc] initWithFormat: @"%@%s", value, sout->str().c_str()];
        [sv setString: newValue];
        [sv scrollRangeToVisible:NSMakeRange([[sv string] length], 0)];
        sout->str("");
        
    });
    
}

@end

void flushToLog(std::ostringstream &sout) {
}

