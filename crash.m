+ (NSData *)generateGIFWithImage:(UIImage *)image andStickers:(NSArray *)stickers small:(BOOL)small withShareType:(NSUInteger)shareType {
    
    NSMutableArray *stickerImages = [@[] mutableCopy];

    NSUInteger gifCount = [YXCommon generateGifCountWithStickers:stickers];
    
    for (NSUInteger i = 0; i < gifCount; i++) {
        NSMutableArray *stickerImgs = [@[] mutableCopy];
        for (NSUInteger j = 0; j < stickers.count; j++) {
            StickerItem *stickerItem = [stickers objectAtIndex:j];
            if (stickerItem.images.count > 0) {
                NSString *imageURL = [YXCommon imageURLInStickerItem:stickerItem.images withIndex:i]; //[stickerItem.images objectAtIndex:j];
                
                if ([[StickersManager defaultStickersManager].stickerImageManager cachedImageExistsForURL:[NSURL URLWithString:imageURL]]) {
                    NSString *cacheKey = [[StickersManager defaultStickersManager].stickerImageManager cacheKeyForURL:[NSURL URLWithString:imageURL]];
                    UIImage *cacheImage = [[StickersManager defaultStickersManager].stickerImageManager.imageCache imageFromDiskCacheForKey:cacheKey];
                    
                    if (small) {
                        UIGraphicsBeginImageContextWithOptions(CGSizeMake(SCREEN_WIDTH, SCREEN_WIDTH), NO, 1);
                    }else {
                        UIGraphicsBeginImageContextWithOptions(CGSizeMake(SCREEN_WIDTH * 2, SCREEN_WIDTH * 2), NO, 2);
                    }
                    CGContextRef ctx = UIGraphicsGetCurrentContext();
                    
                    CGPoint center = CGPointZero;
                    CGPoint point = CGPointZero;
                    if (small) {
                        center = CGPointMake(SCREEN_WIDTH * stickerItem.x , SCREEN_WIDTH * stickerItem.y);
                        point = CGPointMake(center.x - 52.5 , center.y - 52.5);
                    }else {
                        center = CGPointMake(SCREEN_WIDTH * stickerItem.x * 2.0, SCREEN_WIDTH * stickerItem.y * 2.0);
                        point = CGPointMake(center.x - 105 , center.y - 105);
                    }
                    
                    CGContextTranslateCTM(ctx, center.x, center.y);
                    CGContextConcatCTM(ctx, CGAffineTransformMake(stickerItem.scale, stickerItem.rotation, -stickerItem.rotation, stickerItem.scale, 0, 0));
                    CGContextTranslateCTM(ctx, -center.x, -center.y);
                    
                    if (small) {
                        [cacheImage drawInRect:CGRectMake(point.x , point.y, 105, 105)];
                    }else {
                        [cacheImage drawInRect:CGRectMake(point.x , point.y, 210, 210)];
                    }
                    
                    UIImage *stickerImage = UIGraphicsGetImageFromCurrentImageContext();
                    UIGraphicsEndImageContext();
                    
                    [stickerImgs addObject:stickerImage];
                }
            }
        }
        if (stickerImgs.count > 0) {
            [stickerImages addObject:[stickerImgs copy]];
        }
    }
    
    NSMutableArray *images = [@[] mutableCopy];
    for (NSArray *stickerImgs in stickerImages) {
        UIImage *drawImg = nil;
        if (small) {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(SCREEN_WIDTH, SCREEN_WIDTH), NO, 1);
            [image drawInRect:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_WIDTH)];
        }else {
            UIGraphicsBeginImageContextWithOptions(CGSizeMake(SCREEN_WIDTH * 2, SCREEN_WIDTH * 2), NO, 2);
            [image drawInRect:CGRectMake(0, 0, SCREEN_WIDTH * 2, SCREEN_WIDTH * 2)];
        }
        for (UIImage *img in stickerImgs) {
            [img drawInRect:CGRectMake(0, 0, img.size.width, img.size.height)];
        }
        drawImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [images addObject:drawImg];
    }

    NSURL *gifTempURL = [NSURL fileURLWithPath: [NSTemporaryDirectory() stringByAppendingPathComponent:@"gif-temp.gif"]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtURL:gifTempURL error:nil];
    
    if (images.count == 0) {
        [UIImageJPEGRepresentation(image, 1.0) writeToURL:gifTempURL atomically:YES];
        return [[NSData alloc] initWithContentsOfURL:gifTempURL];
    }

    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((CFURLRef)gifTempURL, kUTTypeGIF, images.count, NULL);
    
    NSDictionary *frameProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:@(0.15) forKey:(NSString *)kCGImagePropertyGIFDelayTime] forKey:(NSString *)kCGImagePropertyGIFDictionary];
    NSDictionary *gifProperties = [NSDictionary dictionaryWithObject:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0] forKey:(NSString *)kCGImagePropertyGIFLoopCount] forKey:(NSString *)kCGImagePropertyGIFDictionary];

    for (UIImage *image in images) {
        CGImageDestinationAddImage(destination, image.CGImage, (CFDictionaryRef)frameProperties);
    }
    
    CGImageDestinationSetProperties(destination, (CFDictionaryRef)gifProperties);
    CGImageDestinationFinalize(destination);
    CFRelease(destination);

    return [[NSData alloc] initWithContentsOfURL:gifTempURL];
}