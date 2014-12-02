//
//  UIImageAdditions.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 12/1/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

extension UIImage {
    
    var pngRepresentation: NSData? {
        return UIImagePNGRepresentation(self)
    }
    
    var withoutWhiteBackground: UIImage {
        
        // convert to uncompressed jpg to remove any alpha channels
        // this is a necessary first step when processing images that already have transparency
        let image = UIImage(data: UIImageJPEGRepresentation(self, 1))!
            
        let rawImageRef = image.CGImage
        // RGB color range to mask (make transparent)  R-Low, R-High, G-Low, G-High, B-Low, B-High
        let colorMasking: [CGFloat] = [222, 255, 222, 255, 222, 255]
        
        UIGraphicsBeginImageContext(image.size);
        let maskedImageRef = CGImageCreateWithMaskingColors(rawImageRef, colorMasking);
        
        // iPhone translation
        CGContextTranslateCTM(UIGraphicsGetCurrentContext(), 0.0, image.size.height);
        CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, -1.0);
        
        CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, image.size.width, image.size.height), maskedImageRef);
        let result = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return result;
    }
    
}