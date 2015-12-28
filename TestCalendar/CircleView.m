//
//  CircleView.m
//  TestCalendar
//
//  Created by HungWeiTai on 2015/10/14.
//  Copyright © 2015年 IFIT LTD. All rights reserved.
//

#import "CircleView.h"
#import "UIView+RetrieveAttributes.h"

#define DEFAULT_BG_COLOR [UIColor colorWithRed:220.0/255.0 green:90.0/255.0 blue:110.0/255.0 alpha:1.0]
#define DEFAULT_HIGHLIGHT_COLOR [UIColor colorWithRed:255.0/255.0 green:106.0/255.0 blue:131.0/255.0 alpha:1.0]

@implementation CircleView

+ (instancetype)circleView {
    CircleView *circleView = [[self alloc] initWithFrame:(CGRect){{0.0, 0.0}, {60.0, 60.0}}];
    [circleView addTapGesture];
    return circleView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.backgroundColor = [DEFAULT_BG_COLOR CGColor];
        self.layer.cornerRadius = CGRectGetHeight(self.bounds) / 2;
        self.layer.shadowOffset = (CGSize){3.0, 3.0};
        self.layer.shadowRadius = 3.0;
        self.layer.shadowOpacity = 0.75;
        
        UILabel *label = [[UILabel alloc] init];
        label.text = @"今";
        label.font = [UIFont boldSystemFontOfSize:40.0];
        label.textColor = [UIColor whiteColor];
        [label sizeToFit];
        
        [label setCenter:(CGPoint){self.centerX, self.centerY}];
        [self addSubview:label];
        _wordLabel = label;
    }
    return self;
}

- (void)setPosition:(CGPoint)position {
    CGRect frame = self.frame;
    frame.origin = position;
    self.frame = frame;
}

- (void)addTapGesture {
    UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self addGestureRecognizer:tapGesture];
}

- (void)tapped:(UIGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        self.layer.backgroundColor = [DEFAULT_BG_COLOR CGColor];
        if ([self.delegate respondsToSelector:@selector(didSelectCircleView:)]) {
            [self.delegate didSelectCircleView:self];
        }
    }
    if (gesture.state == UIGestureRecognizerStateCancelled) {
        self.layer.backgroundColor = [DEFAULT_BG_COLOR CGColor];
    }
    [self didTappedAnimation];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.layer.backgroundColor = [DEFAULT_HIGHLIGHT_COLOR CGColor];
}

- (void)didTappedAnimation {
    __weak __typeof(self) weakSelf = self;
    self.userInteractionEnabled = NO;
    [UIView animateKeyframesWithDuration:0.5 delay:0.1 options:UIViewKeyframeAnimationOptionCalculationModeLinear animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.3 animations:^{
            weakSelf.wordLabel.transform = CGAffineTransformMakeRotation(-M_PI_2);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.2 animations:^{
            weakSelf.wordLabel.transform = CGAffineTransformMakeRotation(-M_PI);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.2 animations:^{
            weakSelf.wordLabel.transform = CGAffineTransformMakeRotation(-M_PI_2 * 3);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.7 relativeDuration:0.3 animations:^{
            weakSelf.wordLabel.transform = CGAffineTransformMakeRotation(-M_PI * 2);
        }];
    } completion:^(BOOL finished) {
        if (finished) {
            weakSelf.userInteractionEnabled = YES;
        }
    }];
}

@end
