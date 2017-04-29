//
//  WhereFromExtractor.h
//  DownloadSorterSwift
//
//  Created by Wolfgang Lutz on 24.04.15.
//  Copyright (c) 2015 Wolfgang Lutz. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AttributeExtractor : NSObject
+ (NSArray*) getWhereFromForPath:(NSString*) path;
@end
