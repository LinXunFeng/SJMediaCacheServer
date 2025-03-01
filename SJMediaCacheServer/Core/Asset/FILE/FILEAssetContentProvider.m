//
//  FILEAssetContentProvider.m
//  SJMediaCacheServer
//
//  Created by BlueDancer on 2020/11/24.
//

#import "FILEAssetContentProvider.h" 
#import "NSFileManager+MCS.h"
#import "MCSAssetContent.h"

#define FILE_PREFIX_CONTENT @"file"
 
@implementation FILEAssetContentProvider {
    NSString *_directory;
}

+ (instancetype)contentProviderWithDirectory:(NSString *)directory {
    FILEAssetContentProvider *mgr = FILEAssetContentProvider.alloc.init;
    mgr->_directory = directory;
    return mgr;
}

- (nullable NSArray<id<MCSAssetContent>> *)contents {
    NSMutableArray<id<MCSAssetContent>> *m = nil;
    for ( NSString *filename in [NSFileManager.defaultManager contentsOfDirectoryAtPath:_directory error:NULL] ) {
        if ( ![filename hasPrefix:FILE_PREFIX_CONTENT] ) continue;
        if ( m == nil ) m = NSMutableArray.array;
        NSString *filePath = [self _contentFilePathForFilename:filename];
        NSUInteger offset = [self _offsetForFilename:filename];
        NSUInteger length = (NSUInteger)[NSFileManager.defaultManager mcs_fileSizeAtPath:filePath];
        id<MCSAssetContent>content = [MCSAssetContent.alloc initWithFilePath:filePath position:offset length:length];
        [m addObject:content];
    }
    return m.copy;
}

- (nullable id<MCSAssetContent>)createContentAtOffset:(NSUInteger)offset pathExtension:(nullable NSString *)pathExtension error:(NSError **)errorPtr {
    NSError *error = nil;
    if ( ![NSFileManager.defaultManager fileExistsAtPath:_directory] ) {
        [NSFileManager.defaultManager createDirectoryAtPath:_directory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    if ( error == nil ) {
        NSUInteger number = 0;
        do {
            NSString *filename = [self _filenameWithOffset:offset number:number pathExtension:pathExtension];
            NSString *filePath = [self _contentFilePathForFilename:filename];
            if ( ![NSFileManager.defaultManager fileExistsAtPath:filePath] ) {
                [NSFileManager.defaultManager createFileAtPath:filePath contents:nil attributes:nil];
                return [MCSAssetContent.alloc initWithFilePath:filePath position:offset];
            }
            number += 1;
        } while (true);
    }
    else {
        if ( errorPtr != NULL ) *errorPtr = error;
    }
    return nil;
}

- (nullable NSString *)contentFilePath:(MCSAssetContent *)content {
    return content.filePath;
}

- (void)removeContent:(MCSAssetContent *)content {
    [NSFileManager.defaultManager removeItemAtPath:content.filePath error:NULL];
}

- (void)removeContents:(NSArray<id<MCSAssetContent>> *)contents {
    [contents enumerateObjectsUsingBlock:^(id<MCSAssetContent>  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeContent:obj];
    }];
}

- (void)clear {
    [NSFileManager.defaultManager removeItemAtPath:_directory error:NULL];
}

#pragma mark - 前缀_偏移量_序号.扩展名

- (nullable NSString *)_contentFilePathForFilename:(NSString *)filename {
    return filename.length != 0 ? [_directory stringByAppendingPathComponent:filename] : nil;
}

- (NSString *)_filenameWithOffset:(NSUInteger)offset number:(NSInteger)number pathExtension:(nullable NSString *)pathExtension {
    // _FILE_NAME(__prefix__, __offset__, __number__, __extension__)
    NSString *filename = [NSString stringWithFormat:@"%@_%ld_%lu", FILE_PREFIX_CONTENT, (unsigned long)offset, (long)number];
    if ( pathExtension.length != 0 ) filename = [filename stringByAppendingPathExtension:pathExtension];
    return filename;
}

- (NSUInteger)_offsetForFilename:(NSString *)filename {
    return (NSUInteger)[[filename componentsSeparatedByString:@"_"][1] longLongValue];
}
@end
