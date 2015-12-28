//
//  UIView+RetrieveAttributes.h
//  TestCalendar
//
//  Created by HungWeiTai on 2015/10/6.
//  Copyright © 2015年 IFIT LTD. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (RetrieveAttributes)

- (CGFloat)width;
- (void)setWidth:(CGFloat)width;

- (CGFloat)height;
- (void)setHeight:(CGFloat)height;

- (void)setSize:(CGSize)size;

- (CGFloat)minX;

- (CGFloat)maxX;

- (CGFloat)centerX;

- (CGFloat)minY;

- (CGFloat)maxY;

- (CGFloat)centerY;

- (void)setX:(CGFloat)x;

- (void)setY:(CGFloat)y;

- (void)setOrigin:(CGPoint)point;

- (void)randomBackgroundColor;

@end
