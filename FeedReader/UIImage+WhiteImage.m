//
//  UIImage+WhiteImage.m
//  Source: https://gist.github.com/dhoerl/1229792
//
//  Created by David Hoerl on 9/14/11.
//  Modified by Mitchell Cooper.
//
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
    
    // normal rect
    CGRect rs;
    rs.origin.x = rs.origin.y = 0;
    rs.size     = self.size;
    
//    // bigger rect
//	CGRect rb;
//	rb.origin.x = rb.origin.y = 0;
//	rb.size     = CGSizeMake(self.size.width + 500, self.size.height + 500);
    CGRect rb = rs;
    
	UIGraphicsBeginImageContextWithOptions(rb.size, NO, 0);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetShouldAntialias(context, true);
    
    // flip it vertically
    CGAffineTransform flip = CGAffineTransformMake(1, 0, 0, -1, 0, rb.size.height);
    CGContextConcatCTM(context, flip);
    
    // fill the white image
	CGContextClipToMask(context, rb, [self CGImage]);
	CGContextSetFillColorWithColor(context, [[UIColor whiteColor] CGColor]);
	CGContextFillRect(context, rb);
    
	UIImage *whiteImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
//
//    // scale down
//    UIGraphicsBeginImageContextWithOptions(rs.size, NO, 0);
//    context = UIGraphicsGetCurrentContext();
//    CGContextTranslateCTM(context, 0.0, rs.size.height);
//    CGContextScaleCTM(context, 1.0, -1.0);
//    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, rs.size.width, rs.size.height), whiteImage.CGImage);
//    whiteImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    [[UIBezierPath bezierPathWithRoundedRect:rs
//                                cornerRadius:10.0] addClip];
//    
	return whiteImage;
}
 
@end