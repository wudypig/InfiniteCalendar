//
//  CalendarViewController.h
//  TestCalendar
//
//  Created by HungWeiTai on 2015/10/6.
//  Copyright © 2015年 IFIT LTD. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CalendarViewDelegate;

@interface CalendarViewController : UIViewController

@property (weak, nonatomic) id<CalendarViewDelegate> delegate;

- (void)jumpToDate:(NSDateComponents *)dateComponents;

@end

@protocol CalendarViewDelegate <NSObject>

@optional

//User Options for Attributes

- (NSInteger)numberOfBufferedMonthsForPastAndFuture;

- (CGFloat)spacingBetweenItems;

- (CGFloat)spacingBetweenLines;

- (UIEdgeInsets)insetsForEachMonth;

//User Options for Actions

- (void)calendarViewController:(CalendarViewController *)calendarViewController didSelectDate:(NSDate *)date;

@end

#pragma mark - CalendarItemView

@protocol CalendarItemViewDelegate;

@interface CalendarItemView : UIView

@property (weak, nonatomic) id<CalendarItemViewDelegate> delegate;

@property (assign, nonatomic) BOOL highlighted;

@property (assign, nonatomic) BOOL selected;

+ (instancetype)itemViewWithSize:(CGSize)size delegate:(id<CalendarItemViewDelegate>)delegate;

- (instancetype)initWithFrame:(CGRect)frame;

- (void)setDayLabelWithDay:(NSInteger)day;

- (void)setHighlighted:(BOOL)highlight;

- (BOOL)isHighlighted;

- (void)setSelected:(BOOL)selected;

- (BOOL)isSelected;

@end

@protocol CalendarItemViewDelegate <NSObject>

@required

- (void)didSelectedCalendarItemView:(CalendarItemView *)itemView;

@end