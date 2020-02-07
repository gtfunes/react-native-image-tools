
#import "RNImageTools.h"
#import "React/RCTLog.h"
#import "React/RCTConvert.h"

CGFloat layerImageScaleFactor = 1;

@implementation RNImageTools

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(transform:(NSString *)imageURLString
                  translateX:(CGFloat)translateX
                  translateY:(CGFloat)translateY
                  rotate:(CGFloat)rotate
                  scale:(CGFloat)scale
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = [self getUIImageFromURLString:imageURLString];
    UIImage *resultImage = [self transformImage:image translateX:translateX translateY:translateY rotate:rotate scaleX:scale scaleY:scale];
    
    NSString *imagePath = [self saveImage:resultImage withPostfix:@"transformed"];
    
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:resultImage.size.width],
              @"height": [NSNumber numberWithFloat:resultImage.size.height]
              });
}

RCT_EXPORT_METHOD(crop:(NSString *)imageURLString
                  x:(CGFloat)x
                  y:(CGFloat)y
                  width:(CGFloat)width
                  height:(CGFloat)height
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSURL *imageURL = [RCTConvert NSURL:imageURLString];
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:imageURL];
    UIImage *image = [self fixImageOrientation:[[UIImage alloc] initWithData:imageData]];
    UIImage *croppedImage = [self cropImage:image toRect:CGRectMake(x, y, width, height)];
    
    NSString *imagePath = [self saveImage:croppedImage withPostfix:@"cropped"];
    
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:croppedImage.size.width],
              @"height": [NSNumber numberWithFloat:croppedImage.size.height]
              });
}

RCT_EXPORT_METHOD(mask:(NSString *)imageURLString
                  maskImageURLString:(NSString *)maskImageURLString
                  options:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = [self getUIImageFromURLString:imageURLString];
    UIImage *maskImage = [self getUIImageFromURLString:maskImageURLString];
    BOOL trimTransparency = [RCTConvert BOOL:options[@"trimTransparency"]];
    
    CGRect cropRect = [self calcRect:maskImage.size forContainedSize:image.size];
    UIImage *croppedImage = [self cropImage:image toRect:cropRect];

    UIImage *maskedImage = [self maskImage:croppedImage withMask:maskImage];
    UIImageView *maskedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, maskedImage.size.width, maskedImage.size.height)];
    maskedImageView.image = maskedImage;
    UIImage *maskedImageFromLayer = [self imageFromLayer:maskedImageView.layer];
    
    UIImage *resultImage = trimTransparency ? [self trimTransparentPixels:maskedImageFromLayer requiringFullOpacity:NO] : maskedImageFromLayer;
    NSString *imagePath = [self saveImage:resultImage withPostfix:@"masked"];
    
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:resultImage.size.width],
              @"height": [NSNumber numberWithFloat:resultImage.size.height]
              });
}

RCT_EXPORT_METHOD(resize:(NSString *)imageURLString
                  toWidth:(CGFloat)width
                  toHeight:(CGFloat)height
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = [self getUIImageFromURLString:imageURLString];
    
    image = [self resizeImage:image toWidth:width toHeight:height];
    
    NSString *imagePath = [self saveImage:image withPostfix:@"resized"];
    
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:image.size.width],
              @"height": [NSNumber numberWithFloat:image.size.height]
              });
}

RCT_EXPORT_METHOD(cornerRadius:(NSString *)imageURLString
                  toWidth:(CGFloat)width
                  toHeight:(CGFloat)height
                  radius: (CGFloat)radius
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = [self getUIImageFromURLString:imageURLString];

    image = [self resizeImage:image toWidth:width toHeight:height];

    UIImage *newImage =  [self drawCornerRadiusForImage:image withRadius:radius andBorderColor:nil];

    NSString *imagePath = [self saveImage:newImage withPostfix:@"cornerRadius"];

    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:image.size.width],
              @"height": [NSNumber numberWithFloat:image.size.height]
              });
}

RCT_EXPORT_METHOD(borderRadius:(NSString *)imageURLString
                  toWidth:(CGFloat)width
                  toHeight:(CGFloat)height
                  radius: (CGFloat)radius
                  borderColor: (NSString *)borderColor
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = [self getUIImageFromURLString:imageURLString];
    image = [self resizeImage:image toWidth:width toHeight:height];

    UIImage *newImage =  [self drawCornerRadiusForImage:image withRadius:radius andBorderColor:borderColor];

    NSString *imagePath = [self saveImage:newImage withPostfix:@"borderRadius"];

    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:image.size.width],
              @"height": [NSNumber numberWithFloat:image.size.height]
              });
}

RCT_EXPORT_METHOD(borderRadiusWithPadding:(NSString *)imageURLString
                  toWidth:(CGFloat)width
                  toHeight:(CGFloat)height
                  radius: (CGFloat)radius
                  borderColor: (NSString *)borderColor
                  padding:(CGFloat) padding
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = [self getUIImageFromURLString:imageURLString];
    CGSize size = CGSizeMake(width, height);
    //draw image first
    UIImage *newImage =  [self drawCornerRadiusForImage:image withRadius:image.size.width/2 withPadding: padding * image.size.width / 26 andBorderColor:borderColor];
    UIImage *resizedImage = [self imageWithImage:newImage scaledToSize:size scale:1];
    NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *imagePath = [self saveImage:resizedImage withImageName:[NSString stringWithFormat:@"%@",fileName]];
    UIImage *resizedImage2x = [self imageWithImage:newImage scaledToSize:size scale:2];
    [self saveImage:resizedImage2x withImageName:[NSString stringWithFormat:@"%@@2x",fileName]];
    UIImage *resizedImage3x = [self imageWithImage:newImage scaledToSize:size scale:3];
    [self saveImage:resizedImage3x withImageName:[NSString stringWithFormat:@"%@@3x",fileName]];
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:resizedImage.size.width],
              @"height": [NSNumber numberWithFloat:resizedImage.size.height]
              });
}

RCT_EXPORT_METHOD(borderCircle:(NSString *)imageURLString
                  toSize:(CGFloat)imageSize
                  borderWidth: (CGFloat)borderWidth
                  borderColor: (NSString *)borderColor
                  padding:(CGFloat) padding
                  backgroundColor: (NSString *)backgroundColor
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = [self getUIImageFromURLString:imageURLString];
    CGSize size = CGSizeMake(imageSize, imageSize);
    //draw image first
    UIImage *newImage = [self cropCircleForImage:image withSize:imageSize withPadding:padding borderWith:borderWidth borderColor:borderColor andBackgroundColor:backgroundColor];
    
    UIImage *resizedImage = [self imageWithImage:newImage scaledToSize:size scale:1];
    NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *imagePath = [self saveImage:resizedImage withImageName:[NSString stringWithFormat:@"%@",fileName]];
    UIImage *resizedImage2x = [self imageWithImage:newImage scaledToSize:size scale:2];
    [self saveImage:resizedImage2x withImageName:[NSString stringWithFormat:@"%@@2x",fileName]];
    UIImage *resizedImage3x = [self imageWithImage:newImage scaledToSize:size scale:3];
    [self saveImage:resizedImage3x withImageName:[NSString stringWithFormat:@"%@@3x",fileName]];
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:resizedImage.size.width],
              @"height": [NSNumber numberWithFloat:resizedImage.size.height]
              });
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize scale:(CGFloat)scale {
    if (!image) {
        return nil;
    }
    CGRect rect = CGRectMake(0, 0, newSize.width, newSize.height);
    UIGraphicsBeginImageContextWithOptions(newSize, false, scale);
    [image drawInRect:rect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

RCT_EXPORT_METHOD(merge:(NSArray *)imageURLStrings
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSInteger count = [imageURLStrings count];
    NSMutableArray *images = [[NSMutableArray alloc] initWithCapacity:count];
    for (NSInteger i = 0; i < count; i++) {
        UIImage *image = [self getUIImageFromURLString:imageURLStrings[i]];
        [images addObject:image];
    }
    
    NSArray *imagesImmutable = [[NSArray alloc] initWithArray:images];
    
    UIImage *mergedImage = [self mergeImages:imagesImmutable];
    
    NSString *imagePath = [self saveImage:mergedImage withPostfix:@"merged"];

    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:mergedImage.size.width],
              @"height": [NSNumber numberWithFloat:mergedImage.size.height]
              });
}

RCT_EXPORT_METHOD(delete:(NSString *)imageURLString
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    [self deleteImageAtPath:imageURLString];
    resolve(nil);
}

RCT_EXPORT_METHOD(createMaskFromShape:(NSDictionary*)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    CGFloat width = [RCTConvert CGFloat:options[@"width"]];
    CGFloat height = [RCTConvert CGFloat:options[@"height"]];
    NSArray *points = [RCTConvert NSArray:options[@"points"]];
    BOOL inverted = [RCTConvert BOOL:options[@"inverted"]];
    
    NSMutableArray *pointsWithCGPoints = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < [points count]; i++) {
        CGPoint convertedCGPoint = [RCTConvert CGPoint:[points objectAtIndex:i]];
        [pointsWithCGPoints addObject:[NSValue valueWithCGPoint:convertedCGPoint]];
    }
    
    UIImage *image = [self createMaskImageFromShape:pointsWithCGPoints withWidth:width height:height invert:inverted];
    
    NSString *imagePath = [self saveImage:image withPostfix:@"shape"];
    
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:image.size.width],
              @"height": [NSNumber numberWithFloat:image.size.height]
              });
}

- (UIImage *)drawCornerRadiusForImage:(UIImage *) image withRadius: (CGFloat) radius andBorderColor: (nullable NSString *) borderColor {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.layer.cornerRadius = radius;
    if (borderColor != nil) {
        imageView.layer.borderWidth = 1;
        imageView.layer.borderColor = [[self colorWithHexString:borderColor] CGColor];
    }
    imageView.clipsToBounds = true;
    UIGraphicsBeginImageContext(imageView.bounds.size);
    if (UIGraphicsGetCurrentContext() != nil) {
        [imageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *newImage =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (UIImage *)drawCornerRadiusForImage:(UIImage *) image withRadius: (CGFloat) radius withPadding: (CGFloat)padding andBorderColor: (nullable NSString *) borderColor {
    CGFloat size = radius * 2;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(padding, padding, size - padding * 2, size - padding * 2)];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.cornerRadius = radius - padding ;
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, size, size)];
    [view addSubview:imageView];
    view.layer.cornerRadius = radius;
    if (borderColor != nil) {
        view.layer.borderWidth = size * 1.5 / 26;
        view.layer.borderColor = [[self colorWithHexString:borderColor] CGColor];
    }
    view.clipsToBounds = true;
    imageView.clipsToBounds = true;
    UIGraphicsBeginImageContext(view.bounds.size);

    if (UIGraphicsGetCurrentContext() != nil) {
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *newImage =  UIGraphicsGetImageFromCurrentImageContext();
//    NSData *imageData = UIImageJPEGRepresentation(newImage, 1);
    UIGraphicsEndImageContext();
//    return [UIImage imageWithData:imageData];
    return newImage;
}
- (UIImage *)cropCircleForImage:(UIImage *) image withSize: (CGFloat) size withPadding: (CGFloat)padding borderWith: (CGFloat)borderWidth borderColor: (nullable NSString *) borderColor andBackgroundColor: (nullable NSString *)backgroundColor {
    CGFloat radius = size / 2.0f;
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(padding, padding, size - padding * 2, size - padding * 2)];
    imageView.image = image;
    imageView.contentMode = UIViewContentModeScaleAspectFill;
    imageView.layer.cornerRadius = radius - padding ;
    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0, 0, size, size)];
    [view addSubview:imageView];
    view.layer.cornerRadius = radius;
    if (borderColor != nil) {
        view.layer.borderWidth = borderWidth;
        view.layer.borderColor = [[self colorWithHexString:borderColor] CGColor];
    }
    view.clipsToBounds = true;
    imageView.clipsToBounds = true;
    imageView.backgroundColor = [UIColor clearColor];
    [view setBackgroundColor: [self colorWithHexString:backgroundColor]];
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0);
    if (UIGraphicsGetCurrentContext() != nil) {
        [[UIColor clearColor] set];
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    }
    UIImage *newImage =  UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}
- (UIColor *) colorWithHexString: (NSString *) hexString {
    NSString *colorString = [[hexString stringByReplacingOccurrencesOfString: @"#" withString: @""] uppercaseString];
    CGFloat alpha, red, blue, green;
    switch ([colorString length]) {
        case 3: // #RGB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 1];
            green = [self colorComponentFrom: colorString start: 1 length: 1];
            blue  = [self colorComponentFrom: colorString start: 2 length: 1];
            break;
        case 4: // #ARGB
            alpha = [self colorComponentFrom: colorString start: 0 length: 1];
            red   = [self colorComponentFrom: colorString start: 1 length: 1];
            green = [self colorComponentFrom: colorString start: 2 length: 1];
            blue  = [self colorComponentFrom: colorString start: 3 length: 1];
            break;
        case 6: // #RRGGBB
            alpha = 1.0f;
            red   = [self colorComponentFrom: colorString start: 0 length: 2];
            green = [self colorComponentFrom: colorString start: 2 length: 2];
            blue  = [self colorComponentFrom: colorString start: 4 length: 2];
            break;
        case 8: // #AARRGGBB
            alpha = [self colorComponentFrom: colorString start: 0 length: 2];
            red   = [self colorComponentFrom: colorString start: 2 length: 2];
            green = [self colorComponentFrom: colorString start: 4 length: 2];
            blue  = [self colorComponentFrom: colorString start: 6 length: 2];
            break;
        default:
            [NSException raise:@"Invalid color value" format: @"Color value %@ is invalid.  It should be a hex value of the form #RBG, #ARGB, #RRGGBB, or #AARRGGBB", hexString];
            break;
    }
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

- (CGFloat) colorComponentFrom: (NSString *) string start: (NSUInteger) start length: (NSUInteger) length {
    NSString *substring = [string substringWithRange: NSMakeRange(start, length)];
    NSString *fullHex = length == 2 ? substring : [NSString stringWithFormat: @"%@%@", substring, substring];
    unsigned hexComponent;
    [[NSScanner scannerWithString: fullHex] scanHexInt: &hexComponent];
    return hexComponent / 255.0;
}

- (UIImage*) getUIImageFromURLString:(NSString *)imageURLString {
    NSURL *imageURL = [RCTConvert NSURL:imageURLString];
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:imageURL];
    UIImage *image = [self fixImageOrientation:[[UIImage alloc] initWithData:imageData]];
    return image;
}

- (UIImage*) maskImage:(UIImage *) image withMask:(UIImage *) mask
{
    CGImageRef imageReference = image.CGImage;
    CGImageRef maskReference = mask.CGImage;
    
    CGImageRef imageMask = CGImageMaskCreate(CGImageGetWidth(maskReference),
                                             CGImageGetHeight(maskReference),
                                             CGImageGetBitsPerComponent(maskReference),
                                             CGImageGetBitsPerPixel(maskReference),
                                             CGImageGetBytesPerRow(maskReference),
                                             CGImageGetDataProvider(maskReference),
                                             NULL, // Decode is null
                                             YES // Should interpolate
                                             );
    
    CGImageRef maskedReference = CGImageCreateWithMask(imageReference, imageMask);
    CGImageRelease(imageMask);
    
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedReference];
    CGImageRelease(maskedReference);
    
    return maskedImage;
}
- (NSString *)saveImage:(UIImage *)image withImageName: (NSString *)fileName {
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@.png", [self getPathForDirectory:NSDocumentDirectory], fileName];

    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:fullPath atomically:YES];
    return fullPath;
}

- (NSString *)saveImage:(UIImage *)image withPostfix:(NSString *)postfix {
    NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@_%@.jpg", [self getPathForDirectory:NSDocumentDirectory], fileName, postfix];
    NSData *imageData = UIImageJPEGRepresentation(image, 0.6);
    [imageData writeToFile:fullPath atomically:YES];
    return fullPath;
}

- (void)deleteImageAtPath:(NSString *)path {
    NSError *error;
    NSString *directoryPath = [path stringByDeletingLastPathComponent];
    NSString *extension = [path pathExtension];
    NSString *fileName = [[path lastPathComponent] stringByDeletingPathExtension];
    NSString *fileName2x = [NSString stringWithFormat:@"%@/%@@2x.%@", directoryPath, fileName, extension];
    NSString *fileName3x = [NSString stringWithFormat:@"%@/%@@3x.%@", directoryPath, fileName, extension];
    NSArray * paths = @[path, fileName2x, fileName3x];
    for (int i = 0; i < paths.count; i++) {
        if ([[NSFileManager defaultManager] isDeletableFileAtPath:paths[i]]) {
            BOOL success = [[NSFileManager defaultManager] removeItemAtPath:paths[i] error:&error];
            if (!success) {
                NSLog(@"Error removing file at path: %@", error.localizedDescription);
            }
        }
    }
}


- (NSString *)getPathForDirectory:(int)directory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    return [paths firstObject];
}

- (UIImage *)imageFromLayer:(CALayer *)layer
{
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, NO, layerImageScaleFactor);
    
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return outputImage;
}

-(UIImage *) fixImageOrientation:(UIImage *) image {
    
    if (image.imageOrientation == UIImageOrientationUp) {
        return image;
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            
        default: break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            // CORRECTION: Need to assign to transform here
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            // CORRECTION: Need to assign to transform here
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        default: break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(nil, image.size.width, image.size.height, CGImageGetBitsPerComponent(image.CGImage), 0, CGImageGetColorSpace(image.CGImage), kCGImageAlphaPremultipliedLast);
    
    CGContextConcatCTM(ctx, transform);
    
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.height, image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
            break;
    }
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage*) transformImage:(UIImage *) image
                 translateX:(CGFloat)x
                 translateY:(CGFloat)y
                     rotate:(CGFloat)degree
                     scaleX:(CGFloat)sx
                     scaleY:(CGFloat)sy
{
    CGContextRef ctx = CGBitmapContextCreate(nil, image.size.width, image.size.height, CGImageGetBitsPerComponent(image.CGImage), 0, CGImageGetColorSpace(image.CGImage), kCGImageAlphaPremultipliedLast);
    
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, image.size.width, image.size.height));
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // Translate
    transform = CGAffineTransformTranslate(transform, x, -y);
    
    // Rotate
    transform = CGAffineTransformTranslate(transform, image.size.width / 2, image.size.height / 2);
    transform = CGAffineTransformRotate(transform, -M_PI / 180 * degree);
    transform = CGAffineTransformTranslate(transform, -image.size.width / 2, -image.size.height / 2);
    
    // Scale
    transform = CGAffineTransformTranslate(transform, -image.size.width * (sx - 1) / 2, -image.size.height * (sy - 1) / 2);
    transform = CGAffineTransformScale(transform, sx, sy);
    
    CGContextConcatCTM(ctx, transform);
    CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage*) cropImage:(UIImage *) image toRect:(CGRect) rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return cropped;
}

- (UIImage*) resizeImage:(UIImage *)image toWidth:(CGFloat)width toHeight:(CGFloat)height
{
    CGContextRef ctx = CGBitmapContextCreate(nil, width, height, CGImageGetBitsPerComponent(image.CGImage), 0, CGImageGetColorSpace(image.CGImage), kCGImageAlphaPremultipliedLast);
    
    CGRect cropRect = [self calcRect:image.size forContainedSize:CGSizeMake(width, height)];;
    CGContextDrawImage(ctx, cropRect, image.CGImage);

    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage*) mergeImages:(NSArray *)images
{
    UIImage *firstImage = [images objectAtIndex:0];
    CGFloat width = firstImage.size.width;
    CGFloat height = firstImage.size.height;
    
    CGContextRef ctx = CGBitmapContextCreate(nil, width, height, CGImageGetBitsPerComponent(firstImage.CGImage), 0, CGImageGetColorSpace(firstImage.CGImage), kCGImageAlphaPremultipliedLast);
    
    for (UIImage *image in images) {
        CGContextDrawImage(ctx, CGRectMake(0, 0, width, height), image.CGImage);
    }
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage*) createMaskImageFromShape:(NSArray*)points withWidth:(CGFloat)width height:(CGFloat)height invert:(BOOL)inverted
{
    CGContextRef ctx = CGBitmapContextCreate(nil, width, height, 8, 0, CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedLast);
    
    NSInteger count = [points count];
    CGPoint cPoints[count];
    
    for (int i = 0; i < count; i++) {
        cPoints[i] = [[points objectAtIndex:i] CGPointValue];
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    // Flip top to right
    transform = CGAffineTransformTranslate(transform, 0, height);
    transform = CGAffineTransformScale(transform, 1, -1);
    
    CGContextConcatCTM(ctx, transform);
    
    CGColorRef rectCGColor = inverted ? [UIColor whiteColor].CGColor : [UIColor blackColor].CGColor;
    CGColorRef shapeCGColor = inverted ? [UIColor blackColor].CGColor : [UIColor whiteColor].CGColor;
    
    CGContextSetFillColorWithColor(ctx, rectCGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, width, height));
    
    CGContextSetFillColorWithColor(ctx, shapeCGColor);
    CGContextAddLines(ctx, cPoints, count);
    CGContextFillPath(ctx);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage *) trimTransparentPixels:(UIImage *)image requiringFullOpacity:(BOOL)fullyOpaque
{
    if (image.size.height < 2 || image.size.width < 2) {
        
        return image;
        
    }
    
    CGRect rect = CGRectMake(0, 0, image.size.width * image.scale, image.size.height * image.scale);
    UIEdgeInsets crop = [self transparencyInsets:image requiringFullOpacity:fullyOpaque];
    
    UIImage *img = image;
    
    if (crop.top == 0 && crop.bottom == 0 && crop.left == 0 && crop.right == 0) {
        
        // No cropping needed
        
    } else {
        
        // Calculate new crop bounds
        rect.origin.x += crop.left;
        rect.origin.y += crop.top;
        rect.size.width -= crop.left + crop.right;
        rect.size.height -= crop.top + crop.bottom;
        
        // Crop it
        CGImageRef newImage = CGImageCreateWithImageInRect([image CGImage], rect);
        
        // Convert back to UIImage
        img = [UIImage imageWithCGImage:newImage scale:image.scale orientation:image.imageOrientation];
        
        CGImageRelease(newImage);
    }
    
    return img;
}

- (UIEdgeInsets)transparencyInsets:(UIImage*)image requiringFullOpacity:(BOOL)fullyOpaque
{
    // Draw our image on that context
    NSInteger width  = (NSInteger)CGImageGetWidth([image CGImage]);
    NSInteger height = (NSInteger)CGImageGetHeight([image CGImage]);
    NSInteger bytesPerRow = width * (NSInteger)sizeof(uint8_t);
    
    // Allocate array to hold alpha channel
    uint8_t * bitmapData = calloc((size_t)(width * height), sizeof(uint8_t));
    
    // Create alpha-only bitmap context
    CGContextRef contextRef = CGBitmapContextCreate(bitmapData, (NSUInteger)width, (NSUInteger)height, 8, (NSUInteger)bytesPerRow, NULL, kCGImageAlphaOnly);
    
    CGImageRef cgImage = image.CGImage;
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(contextRef, rect, cgImage);
    
    // Sum all non-transparent pixels in every row and every column
    uint16_t * rowSum = calloc((size_t)height, sizeof(uint16_t));
    uint16_t * colSum = calloc((size_t)width,  sizeof(uint16_t));
    
    // Enumerate through all pixels
    for (NSInteger row = 0; row < height; row++) {
        
        for (NSInteger col = 0; col < width; col++) {
            
            if (fullyOpaque) {
                
                // Found non-transparent pixel
                if (bitmapData[row*bytesPerRow + col] == UINT8_MAX) {
                    
                    rowSum[row]++;
                    colSum[col]++;
                    
                }
                
            } else {
                
                // Found non-transparent pixel
                if (bitmapData[row*bytesPerRow + col]) {
                    
                    rowSum[row]++;
                    colSum[col]++;
                    
                }
                
            }
            
        }
        
    }
    
    // Initialize crop insets and enumerate cols/rows arrays until we find non-empty columns or row
    UIEdgeInsets crop = UIEdgeInsetsZero;
    
    // Top
    for (NSInteger i = 0; i < height; i++) {
        
        if (rowSum[i] > 0) {
            
            crop.top = i;
            break;
            
        }
        
    }
    
    // Bottom
    for (NSInteger i = height - 1; i >= 0; i--) {
        
        if (rowSum[i] > 0) {
            crop.bottom = MAX(0, height - i - 1);
            break;
        }
        
    }
    
    // Left
    for (NSInteger i = 0; i < width; i++) {
        
        if (colSum[i] > 0) {
            crop.left = i;
            break;
        }
        
    }
    
    // Right
    for (NSInteger i = width - 1; i >= 0; i--) {
        
        if (colSum[i] > 0) {
            
            crop.right = MAX(0, width - i - 1);
            break;
            
        }
    }
    
    free(bitmapData);
    free(colSum);
    free(rowSum);
    
    CGContextRelease(contextRef);
    
    return crop;
}

- (UIImage *) removeTransparencyFromImage:(UIImage *)image {
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(image.CGImage);
    if (alpha == kCGImageAlphaPremultipliedLast || alpha == kCGImageAlphaPremultipliedFirst ||
        alpha == kCGImageAlphaLast || alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaOnly)
    {
        // create the context with information from the original image
        CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                           image.size.width,
                                                           image.size.height,
                                                           CGImageGetBitsPerComponent(image.CGImage),
                                                           CGImageGetBytesPerRow(image.CGImage),
                                                           CGImageGetColorSpace(image.CGImage),
                                                           CGImageGetBitmapInfo(image.CGImage)
                                                           );
        
        // draw white rect as background
        CGContextSetFillColorWithColor(bitmapContext, [UIColor whiteColor].CGColor);
        CGContextFillRect(bitmapContext, CGRectMake(0, 0, image.size.width, image.size.height));
        
        // draw the image
        CGContextDrawImage(bitmapContext, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
        CGImageRef resultNoTransparency = CGBitmapContextCreateImage(bitmapContext);
        
        // get the image back
        image = [UIImage imageWithCGImage:resultNoTransparency];
        
        // do not forget to release..
        CGImageRelease(resultNoTransparency);
        CGContextRelease(bitmapContext);

    }
    return image;
}

- (CGRect) calcRect:(CGSize)srcSize forContainedSize:(CGSize)dstSize {
    
    CGFloat width = 0.0;
    CGFloat height = 0.0;
    CGFloat x = 0.0;
    CGFloat y = 0.0;
    
    if (dstSize.width > dstSize.height) {
        width = srcSize.width * dstSize.height / srcSize.height;
        height = dstSize.height;
        x = (dstSize.width - width) / 2;
        y = 0;
    } else {
        width = dstSize.width;
        height = srcSize.height * dstSize.width / srcSize.width;
        x = 0;
        y = (dstSize.height - height) / 2;
    }

    return CGRectMake(x, y, width, height);
}

@end
