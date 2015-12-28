//
//  UIView+RetrieveAttributes.m
//  TestCalendar
//
//  Created by HungWeiTai on 2015/10/6.
//  Copyright © 2015年 IFIT LTD. All rights reserved.
//

#import "UIView+RetrieveAttributes.h"

#define RANDOM_COLOR (arc4random() % 256) / 255.0

@implementation UIView (RetrieveAttributes)

- (CGFloat)width {
    return CGRectGetWidth(self.frame);
}

- (void)setWidth:(CGFloat)width {
    CGRect frame = self.frame;
    frame.size.width = width;
    self.frame = frame;
}

- (CGFloat)height {
    return CGRectGetHeight(self.frame);
}

- (void)setHeight:(CGFloat)height {
    CGRect frame = self.frame;
    frame.size.height = height;
    self.frame = frame;
}

- (void)setSize:(CGSize)size {
    CGRect frame = self.frame;
    frame.size = size;
    self.frame = frame;
}

- (CGFloat)minX {
    return CGRectGetMinX(self.frame);
}

- (CGFloat)maxX {
    return CGRectGetMaxX(self.frame);
}

- (CGFloat)centerX {
    return CGRectGetMidX(self.bounds);
}

- (CGFloat)minY {
    return CGRectGetMinY(self.frame);
}

- (CGFloat)maxY {
    return CGRectGetMaxY(self.frame);
}

- (CGFloat)centerY {
    return CGRectGetMidY(self.bounds);
}

- (void)setX:(CGFloat)x {
    CGRect frame = self.frame;
    frame.origin.x = x;
    self.frame = frame;
}

- (void)setY:(CGFloat)y {
    CGRect frame = self.frame;
    frame.origin.y = y;
    self.frame = frame;
}

- (void)setOrigin:(CGPoint)point {
    CGRect frame = self.frame;
    frame.origin = point;
    self.frame = frame;
}

- (void)randomBackgroundColor {
    CGFloat red = RANDOM_COLOR;
    CGFloat green = RANDOM_COLOR;
    CGFloat blue = RANDOM_COLOR;
    self.backgroundColor = [UIColor colorWithRed:red green:green blue:blue alpha:1.0];
}

@end
