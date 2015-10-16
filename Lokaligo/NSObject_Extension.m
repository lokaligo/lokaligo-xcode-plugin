//
//  NSObject_Extension.m
//  Lokaligo
//
//  Created by Mateusz Armatys on 15.10.2015.
//  Copyright © 2015 Lokaligo. All rights reserved.
//


#import "NSObject_Extension.h"
#import "Lokaligo.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    if ([currentApplicationName isEqual:@"Xcode"]) {
        dispatch_once(&onceToken, ^{
            sharedPlugin = [[Lokaligo alloc] initWithBundle:plugin];
        });
    }
}
@end
