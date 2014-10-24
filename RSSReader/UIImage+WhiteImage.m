//
//  UIImage+WhiteImage.m
//  Source: https://gist.github.com/dhoerl/1229792
//
//  Created by David Hoerl on 9/14/11.
//  Modified by Mitchell Cooper.
//  Copyright (c) 2014 Mitchell Cooper.
//  Copyright (c) 2011 David Hoerl. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "UIImage+WhiteImage.h"

@implementation UIImage (WhiteImage)
 
- (UIImage *)whiteImage {
	CGRect r;
	r.origin.x = r.origin.y = 0;
	r.size     = self.size;
	
	UIGraphicsBeginImageContextWithOptions(r.size, NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
 
    // my fix to flip it certically.
    CGAffineTransform flip = CGAffineTransformMake(1, 0, 0, -1, 0, r.size.height);
    CGContextConcatCTM(context, flip);

	CGContextClipToMask(context, r, [self CGImage]);
	CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
	CGContextFillRect(context, r);
	UIImage *whiteImage = UIGraphicsGetImageFromCurrentImageContext();

	UIGraphicsEndImageContext();
	return whiteImage;
}
 
@end