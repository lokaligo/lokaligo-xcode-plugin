//
//  Lokaligo.m
//  Lokaligo
//
//  Created by Mateusz Armatys on 15.10.2015.
//  Copyright © 2015 Lokaligo. All rights reserved.
//

#import "Lokaligo.h"

static NSString * const LokaligoAPIKey = @"com.lokaligo.api_key";

@interface Lokaligo() <NSAlertDelegate>

@property (nonatomic, strong, readwrite) NSBundle *bundle;
@end

@implementation Lokaligo

+ (instancetype)sharedPlugin
{
  return sharedPlugin;
}

- (id)initWithBundle:(NSBundle *)plugin
{
  if (self = [super init]) {
    // reference to plugin's bundle, for resource access
    self.bundle = plugin;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didApplicationFinishLaunchingNotification:)
                                                 name:NSApplicationDidFinishLaunchingNotification
                                               object:nil];
  }
  return self;
}

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
  //removeObserver
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
    
  // Create menu items, initialize UI, etc.
  // Sample Menu Item:
  NSMenuItem *menuItem = [[NSApp mainMenu] itemWithTitle:@"Edit"];
  if (!menuItem) {
    menuItem = [[NSApp mainMenu] addItemWithTitle:@"Lokaligo" action:nil keyEquivalent:@""];
  }
  
  if (menuItem) {
    [[menuItem submenu] addItem:[NSMenuItem separatorItem]];
    NSMenuItem *actionMenuItem = [[NSMenuItem alloc] initWithTitle:@"Lokaligo import/export" action:@selector(doMenuAction) keyEquivalent:@""];
    //[actionMenuItem setKeyEquivalentModifierMask:NSAlphaShiftKeyMask | NSControlKeyMask];
    [actionMenuItem setTarget:self];
    [[menuItem submenu] addItem:actionMenuItem];
  }
}

- (void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Lokaligo

// Sample Action, for menu item:
- (void)doMenuAction
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *userDefaultsKey = [self getKeyForUserDefaults];
  if (!userDefaultsKey || userDefaultsKey.length == 0) {
    return;
  }
  
  NSString *apiKey = [defaults stringForKey:userDefaultsKey];
  
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:@"Enter your Lokaligo API key:"];
  [alert addButtonWithTitle:@"Run"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert setInformativeText:[self getCurrentProjectPath]];
  
  NSTextField *view = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 320, 30)];
  view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  if (apiKey) {
    [view setStringValue:apiKey];
  }
  
  [alert setAccessoryView:view];
  NSModalResponse modalResponse = [alert runModal];
  if (modalResponse == NSAlertFirstButtonReturn) {
    apiKey = [view stringValue];
    if (apiKey && apiKey.length > 0) {
      [defaults setObject:apiKey forKey:userDefaultsKey];
      [self runLokaligoWithApiKey:apiKey];
    }
  }
}

- (NSString*)getKeyForUserDefaults
{
  NSString* projectPath = [self getCurrentProjectPath];
  if (!projectPath) {
    return nil;
  }
  return [NSString stringWithFormat:@"%@-%@", LokaligoAPIKey, projectPath];
}

- (NSString*)getCurrentProjectPath
{
  NSArray *workspaceWindowControllers = [NSClassFromString(@"IDEWorkspaceWindowController") valueForKey:@"workspaceWindowControllers"];
  
  id workSpace;
  
  for (id controller in workspaceWindowControllers) {
    if ([[controller valueForKey:@"window"] isEqual:[NSApp keyWindow]]) {
      workSpace = [controller valueForKey:@"_workspace"];
    }
  }
  
  NSString *filePath = [[workSpace valueForKey:@"representingFilePath"] valueForKey:@"_pathString"];
  if (filePath) {
    return [filePath stringByDeletingLastPathComponent];
  }
  return nil;
}

- (NSString*)readAllFromPipe:(NSPipe*)pipe
{
  NSData* data = [pipe.fileHandleForReading readDataToEndOfFile];
  return [NSString stringWithUTF8String:data.bytes];
}

- (void)runLokaligoWithApiKey:(NSString*)apiKey
{
  NSBundle *myBundle = [NSBundle bundleWithIdentifier: @"com.lokaligo.Lokaligo"];
  NSString *scriptPath = [myBundle pathForResource:@"lokaligo_ios" ofType:@"sh"];
  NSTask *task = [[NSTask alloc] init];
  task.standardOutput = [NSPipe pipe];
  task.standardError = [NSPipe pipe];
  task.launchPath = @"/bin/sh";
  task.arguments = @[scriptPath];
  NSMutableDictionary* env = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo  processInfo] environment]];
  [env setObject:[self getCurrentProjectPath] forKey:@"SRCROOT"];
  [env setObject:apiKey forKey:@"LOKALIGO_API_KEY"];
//#if DEBUG
//  [env setObject:@"1" forKey:@"LOKALIGO_DEV"];
//#endif
  task.environment = env;
  
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setMessageText:@"Running Lokaligo import/export..."];
  [alert addButtonWithTitle:@"Cancel"];
  NSProgressIndicator* progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 320, 10)];
  progressIndicator.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
  progressIndicator.indeterminate = YES;
  [alert setAccessoryView:progressIndicator];
  
  [task setTerminationHandler:^(NSTask * _Nonnull task) {
    [NSApp endSheet:[alert window]];
    
    if (task.terminationStatus != 0) {
      NSString *output = [self readAllFromPipe:task.standardOutput];
      NSString *error = [self readAllFromPipe:task.standardError];
      NSString *msg = [NSString stringWithFormat:@"Could not run Lokaligo: code: %d\n%@\n%@", task.terminationStatus, error, output];
      NSAlert *alert = [[NSAlert alloc] init];
      [alert setMessageText:msg];
      [alert addButtonWithTitle:@"OK"];
      [alert runModal];
    }
  }];
  
  [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSModalResponse returnCode) {
    if (returnCode == NSAlertFirstButtonReturn) { // Cancel clicked
      if (task.isRunning) {
        [task interrupt];
      }
    }
  }];
  
  @try {
    [task launch];
  }
  @catch (NSException *exception) {
    NSString *msg = [NSString stringWithFormat:@"Could not run Lokaligo: %@", exception];
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:msg];
    [alert addButtonWithTitle:@"OK"];
    [alert runModal];
  }
}

@end
