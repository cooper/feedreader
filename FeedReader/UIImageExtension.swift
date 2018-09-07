//
//  UIImageAdditions.swift
//  RSSReader
//
//  Created by Mitchell Cooper on 12/1/14.
//  Copyright (c) 2014 Mitchell Cooper. All rights reserved.
//

import UIKit

extension UIImage {
    
    // returns NSData for PNG storage
    var pngRepresentation: Data? {
        return UIImagePNGRepresentation(self)
    }
    
    // returns a version with any white background removed
    var withoutWhiteBackground: UIImage {

        // convert to uncompressed jpg to remove any alpha channels
        // this is a necessary first step when processing images that already have transparency
        let image = UIImage(data: UIImageJPEGRepresentation(self, 1)!)!
            
        let rawImageRef = image.cgImage
        // RGB color range to mask (make transparent)  R-Low, R-High, G-Low, G-High, B-Low, B-High
        let colorMasking: [CGFloat] = [222, 255, 222, 255, 222, 255]
        
        UIGraphicsBeginImageContext(image.size)
        let maskedImageRef = rawImageRef?.copy(maskingColorComponents: colorMasking)
        UIGraphicsGetCurrentContext()?.setAllowsAntialiasing(true)
        UIGraphicsGetCurrentContext()?.setShouldAntialias(true)
        CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh)

        // iPhone translation
        UIGraphicsGetCurrentContext()?.translateBy(x: 0.0, y: image.size.height)
        UIGraphicsGetCurrentContext()?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsGetCurrentContext()?.draw(maskedImageRef!, in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result!
    }
    
}
