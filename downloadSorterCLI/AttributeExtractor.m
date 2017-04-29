//
//  WhereFromExtractor.m
//  DownloadSorterSwift
//
//  Created by Wolfgang Lutz on 24.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

#import "AttributeExtractor.h"

@implementation AttributeExtractor

+ (NSArray*) getWhereFromForPath:(NSString*) path{
    MDItemRef item = MDItemCreate( kCFAllocatorDefault, (CFStringRef)CFBridgingRetain(path) );
    
    CFArrayRef list = MDItemCopyAttributeNames( item );
    
    NSDictionary *resDict = (NSDictionary *)CFBridgingRelease(MDItemCopyAttributes( item, list ));
    CFRelease( list );
    CFRelease( item );
    
    return [resDict objectForKey:@"kMDItemWhereFroms"];
};

@end
