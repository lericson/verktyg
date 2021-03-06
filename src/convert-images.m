/**
 * convert-images.m: an image conversion utility
 *
 * Compile:
 *
 *   clang -isysroot /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.8.sdk \
 *         -framework Foundation -framework AppKit -framework QuartzCore \
 *         -x objective-c \
 *         -o convert-images \
 *         convert-images.m
 * 
 * Usage:
 *
 *   cat <<JSON >spec.json
 *   {"conversions": [{"input": "img.tiff",
 *                     "output": "img.jpg",
 *                     "move": "complete/img.tiff",
 *                     "type": "public.jpeg",
 *                     "compression": 0.8,
 *                     "longestSide": 2048}]}
 *   JSON
 *   convert-images <spec.json
 *
 * License:
 *
 *   Copyright (c) 2013, sendapatch.se
 *   All rights reserved.
 * 
 *   Redistribution and use in source and binary forms, with or without
 *   modification, are permitted provided that the following conditions are met:
 * 
 *    - Redistributions of source code must retain the above copyright notice, this
 *      list of conditions and the following disclaimer.
 * 
 *    - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * 
 *    - Neither the name of the author nor the names of the contributors may
 *      be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 * 
 *   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *   ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 *   WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 *   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
 *   ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 *   (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 *   LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 *   ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 *   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <Cocoa/Cocoa.h>
#include <QuartzCore/QuartzCore.h>

BOOL convert(NSDictionary *);

int main(void) {
    @autoreleasepool {
        NSError *error = nil;
        NSDictionary *opts = [NSJSONSerialization JSONObjectWithData:[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile] options:0 error:&error];

        if (error != nil) {
            NSLog(@"error during JSON deserialization: %@", error);
            return 1;
        }

        NSArray *conversions = [opts objectForKey:@"conversions"];
        NSInteger i = 1;
        for (NSDictionary *conversion in conversions) {
            NSLog(@"Conversion %lu of %lu", i++, [conversions count]);
            @autoreleasepool {
                if (!convert(conversion)) {
                    return 127;
                }
            }
        }

        return 0;
    }
}

BOOL convert(NSDictionary *conversion) {
    NSString *inputFile = [conversion objectForKey:@"input"];
    NSString *outputFile = [conversion objectForKey:@"output"];
    NSNumber *longestSide = [conversion objectForKey:@"longestSide"];
    NSNumber *scaleFactor = nil;
    NSURL    *url = [NSURL fileURLWithPath:inputFile isDirectory:NO];

    CGImageSourceRef imgSrc = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
    if (imgSrc == NULL) {
        NSLog(@" * Load failed: %@", inputFile);
        return NO;
    }

    CIImage *im = [[CIImage imageWithCGImage:CGImageSourceCreateImageAtIndex(imgSrc, 0, NULL)] retain];
    if (im == nil) {
        NSLog(@" * Load failed: %@", inputFile);
        return NO;
    }

    NSDictionary *imgProps = [NSDictionary dictionary];
    imgProps = (NSDictionary *)CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, NULL);

    NSLog(@" * Loaded %@", inputFile);
    CFRelease(imgSrc);

    if (longestSide != nil) {
        scaleFactor = [NSNumber numberWithFloat:MIN([longestSide floatValue] / (float)([im extent].size.width),
                                                    [longestSide floatValue] / (float)([im extent].size.height))];
    }

    if (scaleFactor && ([scaleFactor floatValue] < 1.0f)) {
        CIFilter *scaleTransformFilter = [[CIFilter filterWithName:@"CILanczosScaleTransform"] retain];
        [scaleTransformFilter setDefaults];
        [scaleTransformFilter setValue:scaleFactor forKey:@"inputScale"];
        [scaleTransformFilter setValue:im forKey:@"inputImage"];
        im = [[scaleTransformFilter valueForKey:@"outputImage"] retain];
        NSLog(@" * Image size scaled %u%%", (unsigned int)([scaleFactor floatValue] * 100.0f));
    }

    NSString *uti = [conversion objectForKey:@"type"];
    NSLog(@" * Converting to %@", uti);
    CGImageDestinationRef idst = CGImageDestinationCreateWithURL((CFURLRef)[NSURL fileURLWithPath:outputFile], (CFStringRef)uti, 1, NULL);
    if (idst == NULL) {
        return 0;
    }

    NSBitmapImageRep *bitmap = [[[NSBitmapImageRep alloc] initWithCIImage:im] autorelease];
    CGImageDestinationAddImage(idst, [bitmap CGImage], (CFDictionaryRef)imgProps);

    NSLog(@" * Writing %@", outputFile);
    bool ok = CGImageDestinationFinalize(idst);
    CFRelease(idst);

    NSString *move = [conversion objectForKey:@"move"];
    if (move != nil) {
        NSFileManager *fm = [[[NSFileManager alloc] init] autorelease];
        NSError *error = nil;
        [fm moveItemAtPath:inputFile toPath:move error:&error];
        if (error != nil) {
            NSLog(@" * Move item error: %@", error);
            return NO;
        }
        NSLog(@" * Moved original to %@", move);
    }

    return (BOOL)ok;
}
