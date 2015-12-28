//
//  CircleView.h
//  TestCalendar
//
//  Created by HungWeiTai on 2015/10/14.
//  Copyright © 2015年 IFIT LTD. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CircleViewDelegate;

@interface CircleView : UIView

@property (weak, nonatomic) id<CircleViewDelegate> delegate;

@property (weak, nonatomic) UILabel *wordLabel;

+ (instancetype)circleView;

- (void)setPosition:(CGPoint)position;

@end

@protocol CircleViewDelegate <NSObject>

- (void)didSelectCircleView:(CircleView *)circleView;

@end