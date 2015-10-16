//
//  Lokaligo.h
//  Lokaligo
//
//  Created by Mateusz Armatys on 15.10.2015.
//  Copyright © 2015 Lokaligo. All rights reserved.
//

#import <AppKit/AppKit.h>

@class Lokaligo;

static Lokaligo *sharedPlugin;

@interface Lokaligo : NSObject

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end