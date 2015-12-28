//
//  CalendarViewController.m
//  TestCalendar
//
//  Created by HungWeiTai on 2015/10/6.
//  Copyright © 2015年 IFIT LTD. All rights reserved.
//

#import "CalendarViewController.h"

#import "UIView+RetrieveAttributes.h"
#import "CircleView.h"

#define COMPONENTS_UNIT_FULL (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay)

#define INTEGER_NOT_SET -1
#define FLOAT_NOT_SET -1.0
#define INSETS_NOT_SET (UIEdgeInsets){-1.0, -1.0, -1.0, -1.0}

typedef struct {
    CGFloat topBound;
    CGFloat bottomBound;
} ContentBounds;

typedef NS_ENUM(NSUInteger, MoveDirection) {
    MoveDirectionUp,
    MoveDirectionDown
};

CGFloat const kContentInsetTop = 8.0;
CGFloat const kContentInsetBottom = 8.0;
CGFloat const kContentInsetLeft = 16.0;
CGFloat const kContentInsetRight = 16.0;

CGFloat const kItemSpacing = 1.0;
CGFloat const kLineSpacing = 1.0;

NSInteger const kAppendMonthsNumber = 6;

CGFloat const kMonthHeaderHeight = 56.5;

NSInteger const kDaysOfWeek = 7;
NSInteger const kAverageWeeksPerMonth = 5;

NSString *const kSectionIdentifier = @"Section";
NSString *const kItemIdentifier = @"Item";

@interface CalendarViewController () <UIScrollViewDelegate, CalendarItemViewDelegate, CircleViewDelegate>

@property (strong, nonatomic) NSCalendar *calendar;

@property (copy, nonatomic) NSDateComponents *todayDateComponents;

@property (strong, nonatomic) NSDateFormatter *defaultFormatter;

@property (weak, nonatomic) UIScrollView *scrollView;

@property (assign, nonatomic) ContentBounds contentBounds;

@property (assign, nonatomic) CGFloat itemWidth;

@property (strong, nonatomic) NSMutableArray<UIView *> *visibleViews;

@property (strong, nonatomic) NSMutableDictionary *reusePool;

@property (strong, nonatomic) NSMutableArray<NSDate *> *calendarQueue;

@property (assign, nonatomic) CGPoint originalContentOffset;

@property (assign, nonatomic) CGPoint adjustedContentOffset;

@property (weak, nonatomic) CalendarItemView *selectedItem;

@property (copy, nonatomic) NSDateComponents *selectedDateComponents;

//User Options

@property (assign, nonatomic) NSInteger bufferedMonths;

@property (assign, nonatomic) CGFloat itemSpacing;

@property (assign, nonatomic) CGFloat lineSpacing;

@property (assign, nonatomic) UIEdgeInsets monthInsets;

@end

@implementation CalendarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self commonSettings];
}

- (void)commonSettings {
    [self initProperties];
    [self addScrollView];
    [self addCircleView];
    [self initializeCalendarQueueWithDate:[self dateOfCurrentMonth]];
    [self configureContentBounds];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    NSLog(@"%@ dealloc...", NSStringFromClass([self class]));
}

#pragma mark - Init

- (void)initProperties {
    _calendar = [NSCalendar currentCalendar];
    
    _visibleViews = [@[] mutableCopy];
    _reusePool = [@{} mutableCopy];
    _calendarQueue = [@[] mutableCopy];
    _todayDateComponents = [self fullComponentsForDate:[NSDate date]];
    
    _bufferedMonths = INTEGER_NOT_SET;
    _itemSpacing = FLOAT_NOT_SET;
    _lineSpacing = FLOAT_NOT_SET;
    _monthInsets = INSETS_NOT_SET;
    
    [self registerReusbaleItem:[UIView class] ForIdentifier:kSectionIdentifier];
    [self registerReusbaleItem:[UIView class] ForIdentifier:kItemIdentifier];
}

- (void)initializeCalendarQueueWithDate:(NSDate *)date {
    [self createMonthAtCenter:date];
    [self appendMonthsAtBeginningWithNumbers:self.bufferedMonths];
    [self appendMonthsAtEndWithNumbers:self.bufferedMonths];
}

- (void)addScrollView {
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    _scrollView = scrollView;
    
    scrollView.contentSize = (CGSize){scrollView.width, [self properContentHeight]};
    scrollView.delegate = self;
    scrollView.scrollsToTop = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    [scrollView setContentOffset:[self centerOffset]];
    [self.view addSubview:scrollView];
}

- (void)addCircleView {
    CircleView *circleView = [CircleView circleView];
    circleView.delegate = self;
    
    CGFloat x = self.view.width - circleView.width - 20.0;
    CGFloat y = self.view.height - circleView.height - 20.0;
    [circleView setPosition:(CGPoint){x, y}];
    [self.view insertSubview:circleView aboveSubview:self.scrollView];
}

#pragma mark - Getter and Setter

- (NSInteger)bufferedMonths {
    if (_bufferedMonths == INTEGER_NOT_SET) {
        if ([self.delegate respondsToSelector:@selector(numberOfBufferedMonthsForPastAndFuture)]) {
            _bufferedMonths = [self.delegate numberOfBufferedMonthsForPastAndFuture];
            if (_bufferedMonths <= 1) {
                _bufferedMonths = kAppendMonthsNumber;
            }
        } else {
            _bufferedMonths = kAppendMonthsNumber;
        }
    }
    return _bufferedMonths;
}

- (CGFloat)itemSpacing {
    if (_itemSpacing == FLOAT_NOT_SET) {
        if ([self.delegate respondsToSelector:@selector(spacingBetweenItems)]) {
            _itemSpacing = [self.delegate spacingBetweenItems];
            if (_itemSpacing < 0) {
                _itemSpacing = kItemSpacing;
            }
        } else {
            _itemSpacing = kItemSpacing;
        }
    }
    return _itemSpacing;
}

- (CGFloat)lineSpacing {
    if (_lineSpacing == FLOAT_NOT_SET) {
        if ([self.delegate respondsToSelector:@selector(spacingBetweenLines)]) {
            _lineSpacing = [self.delegate spacingBetweenLines];
            if (_lineSpacing < 0) {
                _lineSpacing = kLineSpacing;
            }
        } else {
            _lineSpacing = kLineSpacing;
        }
    }
    return _lineSpacing;
}

- (UIEdgeInsets)monthInsets {
    if (UIEdgeInsetsEqualToEdgeInsets(_monthInsets, (UIEdgeInsets){-1.0, -1.0, -1.0, -1.0})) {
        if ([self.delegate respondsToSelector:@selector(insetsForEachMonth)]) {
            _monthInsets = [self.delegate insetsForEachMonth];
            _monthInsets.top = (_monthInsets.top < 0)? kContentInsetTop: _monthInsets.top;
            _monthInsets.left = (_monthInsets.left < 0)? kContentInsetLeft: _monthInsets.left;
            _monthInsets.bottom = (_monthInsets.bottom < 0)? kContentInsetBottom: _monthInsets.bottom;
            _monthInsets.right = (_monthInsets.right < 0)? kContentInsetRight: _monthInsets.right;
        } else {
            _monthInsets = (UIEdgeInsets){kContentInsetTop, kContentInsetLeft, kContentInsetBottom, kContentInsetRight};
        }
    }
    return _monthInsets;
}

- (NSDateFormatter *)defaultFormatter {
    if (!_defaultFormatter) {
        _defaultFormatter = [[NSDateFormatter alloc] init];
        [_defaultFormatter setTimeZone:[NSTimeZone localTimeZone]];
        [_defaultFormatter setDateFormat:@"yyyy.MM"];
    }
    return _defaultFormatter;
}

#pragma mark - Calculate Attributes

- (CGFloat)singleItemWidth {
    _itemWidth = (self.scrollView.width - [self horizontalSpacing]) / kDaysOfWeek;
    return _itemWidth;
}

- (CGFloat)averageMonthHeight {
    return ([self singleItemWidth] * kAverageWeeksPerMonth) + kMonthHeaderHeight + [self verticalSpacing];
}

- (CGFloat)horizontalSpacing {
    return (self.monthInsets.left + self.monthInsets.right) + (self.itemSpacing * (kDaysOfWeek - 1));
}

- (CGFloat)verticalSpacing {
    return (self.monthInsets.top + self.monthInsets.bottom) + (self.lineSpacing * (kAverageWeeksPerMonth - 1)) + self.lineSpacing;
}

- (CGFloat)properContentHeight {
    return [self totalMonths] * [self averageMonthHeight];
}

- (CGPoint)centerOffset {
    CGFloat totalBarHeight = [self totalBarHeight];
    CGFloat centerOffsetY = (self.scrollView.contentSize.height - (self.scrollView.height - totalBarHeight)) / 2;
    return (CGPoint){0.0, centerOffsetY};
}

- (CGFloat)totalBarHeight {
    CGFloat statusBarHeight = CGRectGetHeight([[UIApplication sharedApplication] statusBarFrame]);
    CGFloat navigationBarHeight = self.navigationController.navigationBar.height;
    CGFloat tabBarHeight = self.tabBarController.tabBar.height;
    return statusBarHeight + navigationBarHeight + tabBarHeight;
}

- (CGFloat)monthHeightByIndex:(NSInteger)index {
    NSDate *date = self.calendarQueue[index];
    return [self monthHeightByDate:date];
}

- (CGFloat)monthHeightByDate:(NSDate *)date {
    NSInteger acrossWeeks = [self totalWeeksAcrossMonthByDate:date];
    CGFloat itemHeight = self.itemWidth;
    return ((itemHeight + self.lineSpacing) * acrossWeeks) + kMonthHeaderHeight + self.lineSpacing + self.monthInsets.top + self.monthInsets.bottom;
}

#pragma mark - Calculate Calendar

- (NSInteger)totalMonths {
    return (self.bufferedMonths * 2) + 1;
}

- (NSInteger)timeIntervalFromComponent:(NSDateComponents *)components {
    return (NSInteger)floor([[self.calendar dateFromComponents:components] timeIntervalSince1970]);
}

- (NSDateComponents *)fullComponentsForDate:(NSDate *)date {
    return [self.calendar components:COMPONENTS_UNIT_FULL fromDate:date];
}

- (NSDate *)dateOfCurrentMonth {
    NSDateComponents *components = [self fullComponentsForDate:[NSDate date]];
    components.day = 1;
    return [self.calendar dateFromComponents:components];
}

- (NSDate *)dateFromComponents:(NSDateComponents *)components withOffset:(NSInteger)offset unit:(NSCalendarUnit)unit {
    switch (unit) {
        case NSCalendarUnitDay:
            components.day += offset;
            return [self.calendar dateFromComponents:components];
        case NSCalendarUnitMonth:
            components.month += offset;
            return [self.calendar dateFromComponents:components];
        case NSCalendarUnitYear:
            components.year += offset;
            return [self.calendar dateFromComponents:components];
        default:
            return [self.calendar dateFromComponents:components];
    }
}

- (NSInteger)firstWeekDayOfDate:(NSDate *)date {
    return [self.calendar component:NSCalendarUnitWeekday fromDate:date];
}

- (NSInteger)lastDayOfMonthByDate:(NSDate *)date {
    NSDateComponents *components = [self fullComponentsForDate:date];
    components.month += 1;
    components.day = 0;
    return [self.calendar component:NSCalendarUnitDay fromDate:[self.calendar dateFromComponents:components]];
}

- (NSInteger)totalDaysInMonth:(NSDate *)date {
    NSInteger emptyDays = [self firstWeekDayOfDate:date] - 1;
    NSInteger lastDay = [self lastDayOfMonthByDate:date];
    return emptyDays + lastDay;
}

- (NSInteger)totalWeeksAcrossMonthByDate:(NSDate *)date {
    return (NSInteger)ceil([self totalDaysInMonth:date] / 7.0) ;
}

- (BOOL)isMonthExistInQueue:(NSDateComponents *)dateComponents targetIndex:(NSUInteger *)targetIndex {
    for (NSDate *date in self.calendarQueue) {
        NSDateComponents *componentsInQueue = [self fullComponentsForDate:date];
        if ([componentsInQueue isEqual:dateComponents]) {
            if (targetIndex != NULL) {
                NSUInteger index = [self.calendarQueue indexOfObject:date];
                *targetIndex = index;
                targetIndex = NULL;
            }
            return YES;
        }
    }
    return NO;
}

#pragma mark - Actions

- (void)didSelectItem:(CalendarItemView *)item {
    if (self.selectedItem != item) {
        [self.selectedItem setSelected:NO];
        [item setSelected:YES];
        
        self.selectedItem = item;
        self.selectedDateComponents = [self fullComponentsForDate:[NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)item.tag]];
        
        if ([self.delegate respondsToSelector:@selector(calendarViewController:didSelectDate:)]) {
            [self.delegate calendarViewController:self didSelectDate:[self.calendar dateFromComponents:self.selectedDateComponents]];
        }
    }
}

- (void)jumpToDate:(NSDateComponents *)dateComponents {
    dateComponents.day = 1;
    NSUInteger targetIndex;
    
    if ([self isMonthExistInQueue:dateComponents targetIndex:&targetIndex]) {
        [self moveToMonthAtIndex:targetIndex];
    } else {
        [self clearContentView];
        [self initializeCalendarQueueWithDate:[self.calendar dateFromComponents:dateComponents]];
    }
}

- (void)moveToMonthAtIndex:(NSUInteger)index {
    UIView *view = self.visibleViews[index];
    CGPoint point = view.frame.origin;
    point.y -= (self.scrollView.height - [self totalBarHeight] - view.height) / 2;
    [self.scrollView setContentOffset:point animated:YES];
}

#pragma mark - Reuse Pool

- (NSString *)classKeyForIdentifier:(NSString *)identifier {
    return [NSString stringWithFormat:@"%@Class", identifier];
}

- (void)registerReusbaleItem:(Class)class ForIdentifier:(NSString *)identifier {
    NSString *classKey = [self classKeyForIdentifier:identifier];
    _reusePool[classKey] = NSStringFromClass(class);
    _reusePool[identifier] = [@[] mutableCopy];
}

- (UIView *)dequeueReusableItemForIdentifier:(NSString *)identifier {
    NSMutableArray *itemsPool = self.reusePool[identifier];
    
    if (itemsPool.count) {
        return [self retrieveItemFromPool:itemsPool];
    } else {
        return [self createItemForIdentifier:identifier];
    }
}

- (void)enqueueReusalbeItem:(UIView *)item forIdentifier:(NSString *)identifier {
    NSMutableArray *itemsPool = self.reusePool[identifier];
    [itemsPool addObject:item];
}

- (UIView *)retrieveItemFromPool:(NSMutableArray *)pool {
    UIView *item = [pool firstObject];
    [pool removeObject:item];
    pool = nil;
    return item;
}

- (UIView *)createItemForIdentifier:(NSString *)identifier {
    NSString *classString = self.reusePool[[self classKeyForIdentifier:identifier]];
    Class itemClass = NSClassFromString(classString);
    
    if ([identifier isEqualToString:kSectionIdentifier]) {
        return [[itemClass alloc] initWithFrame:(CGRect){{0.0, 0.0}, {self.scrollView.width, 1}}];
    }
    if ([identifier isEqualToString:kItemIdentifier]) {
        return [CalendarItemView itemViewWithSize:(CGSize){self.itemWidth, self.itemWidth} delegate:self];
    }
    return [[itemClass alloc] init];
}

#pragma mark - Configure View Frame and Content

- (void)configureContentBounds {
    UIView *topBoundView = self.visibleViews[1];
    CGFloat topBound = topBoundView.maxY;
    
    UIView *bottomBoundView = self.visibleViews[(_visibleViews.count - 2)];
    CGFloat bottomBound = bottomBoundView.minY;
    
    _contentBounds = (ContentBounds){topBound, bottomBound};
}

- (void)moveToScrollViewCenter:(UIView *)sectionView {
    CGFloat y = (self.scrollView.contentSize.height - sectionView.height) / 2;
    [sectionView setOrigin:(CGPoint){0.0, y}];
}

- (void)moveVisibleViewsWithCompletionHandler:(void (^)(MoveDirection direction))completionHandler {
    CGFloat moveOffset = _adjustedContentOffset.y - _originalContentOffset.y;
    [_visibleViews enumerateObjectsUsingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
            CGRect frame = view.frame;
            frame.origin.y += moveOffset;
            view.frame = frame;
    }];
    completionHandler((moveOffset >= 0)? MoveDirectionDown: MoveDirectionUp);
}

- (void)configureSectionView:(UIView *)view withDate:(NSDate *)date {
    UIView *headerView = [self headerViewInView:view];
    UILabel *dateLabel = (UILabel *)[headerView viewWithTag:101];
    dateLabel.text = [self.defaultFormatter stringFromDate:date];
    
    [self configureItemsInView:view date:date];
}

- (UIView *)headerViewInView:(UIView *)view {
    UIView *headerView = [view viewWithTag:100];
    if (!headerView) {
        CGFloat headerViewWidth = view.width - (self.monthInsets.left + self.monthInsets.right);
        headerView = [[UIView alloc] initWithFrame:(CGRect){{self.monthInsets.left, self.monthInsets.top}, {headerViewWidth, kMonthHeaderHeight}}];
        headerView.tag = 100;
        headerView.backgroundColor = [UIColor whiteColor];
        [view addSubview:headerView];
        
        [self headerLabelInHeaderView:headerView];
        [self addWeekdayLabelInHeaderView:headerView];
    }
    return headerView;
}

- (UILabel *)headerLabelInHeaderView:(UIView *)headerView {
    UILabel *headerLabel = (UILabel *)[headerView viewWithTag:101];
    if (!headerLabel) {
        headerLabel = [[UILabel alloc] initWithFrame:(CGRect){{0.0, 0.0}, {headerView.width, (headerView.height - 18.5)}}];
        headerLabel.tag = 101;
        headerLabel.font = [UIFont boldSystemFontOfSize:20.0];
        headerLabel.textAlignment = NSTextAlignmentCenter;
        headerLabel.textColor = [UIColor darkGrayColor];
        headerLabel.backgroundColor = [UIColor whiteColor];
        [headerView addSubview:headerLabel];
    }
    return headerLabel;
}

- (void)addWeekdayLabelInHeaderView:(UIView *)headerView {
    @autoreleasepool {
        for (NSInteger index = 0; index < kDaysOfWeek; index++) {
            UILabel *weekdayLabel = [[UILabel alloc] init];
            weekdayLabel.text = [self weekdayStringBtIndex:index];
            weekdayLabel.textColor = [UIColor darkGrayColor];
            weekdayLabel.font = [UIFont systemFontOfSize:12.0];
            [weekdayLabel sizeToFit];
            
            CGFloat centerX = (self.itemWidth / 2) + (index * (self.itemWidth + self.itemSpacing));
            CGFloat centerY = kMonthHeaderHeight - (CGRectGetHeight(weekdayLabel.bounds) / 2);
            weekdayLabel.center = (CGPoint){centerX, centerY};
            
            [headerView addSubview:weekdayLabel];
        }
    }
}

- (NSString *)weekdayStringBtIndex:(NSInteger)index {
    return self.calendar.veryShortWeekdaySymbols[index];
}

- (void)configureItemsInView:(UIView *)view date:(NSDate *)date {
    NSInteger firstWeekDay = [self firstWeekDayOfDate:date];
    NSInteger totalDays = [self totalDaysInMonth:date];
    NSInteger startIndex = firstWeekDay - 1;
    NSDateComponents *components = [self fullComponentsForDate:date];
    
    for (NSInteger idx = 0; idx < totalDays; idx++) {
        if (idx >= startIndex) {
            CalendarItemView *item = [self itemForDateComponents:components];
            [item setOrigin:[self positionForItemAtIndex:idx]];
            [view addSubview:item];
            components.day++;
        }
    }
    components = nil;
}

- (CalendarItemView *)itemForDateComponents:(NSDateComponents *)components {
    CalendarItemView *item = (CalendarItemView *)[self dequeueReusableItemForIdentifier:kItemIdentifier];
//    [item randomBackgroundColor];
    [item setUserInteractionEnabled:YES];
    [item setTag:[self timeIntervalFromComponent:components]];
    [item setDayLabelWithDay:components.day];
    [item setHighlighted:[components isEqual:self.todayDateComponents]];
    [self resumeSelection:[components isEqual:self.selectedDateComponents] forItemView:item];
    return item;
}

- (void)resumeSelection:(BOOL)isSelected forItemView:(CalendarItemView *)itemView {
    if (isSelected) {
        [itemView setSelected:YES];
        self.selectedItem = itemView;
    } else {
        [itemView setSelected:NO];
    }
}

- (CGPoint)positionForItemAtIndex:(NSInteger)index {
    CGFloat x = ((index % kDaysOfWeek) * (self.itemWidth + self.itemSpacing)) + self.monthInsets.left;
    CGFloat y = ((index / kDaysOfWeek) * (self.itemWidth + self.lineSpacing)) + self.monthInsets.top + kMonthHeaderHeight + self.lineSpacing;
    return (CGPoint){x, y};
}

#pragma mark - UIScrollViewDelegate

- (BOOL)scrollViewReachTopBound:(UIScrollView *)scrollView {
    return scrollView.contentOffset.y <= _contentBounds.topBound;
}

- (BOOL)scrollViewReachBottomBound:(UIScrollView *)scrollView {
    CGFloat scrollViewHeight = scrollView.height - [self totalBarHeight];
    return (scrollView.contentOffset.y + scrollViewHeight) >= _contentBounds.bottomBound;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self scrollViewReachTopBound:scrollView] || [self scrollViewReachBottomBound:scrollView]) {
        _originalContentOffset = scrollView.contentOffset;
        [scrollView setContentOffset:[self centerOffset]];
        _adjustedContentOffset = scrollView.contentOffset;
        
        __weak __typeof(self) weakSelf = self;
        [self moveVisibleViewsWithCompletionHandler:^(MoveDirection direction) {
            NSInteger numbersOfViewRemoved = [weakSelf removeViewsOverTheBoundsWithDirection:direction];
            [weakSelf appendObjectsWithNumber:numbersOfViewRemoved direction:direction];
        }];
    }
}

#pragma mark - Remove And Append Section Views

- (void)clearContentView {
    [self removeAllViews];
    [self.scrollView setContentOffset:[self centerOffset] animated:YES];
}

- (void)removeAllViews {
    for (UIView *view in self.visibleViews) {
        for (UIView *subview in view.subviews) {
            if (subview.tag != 100) {
                [subview removeFromSuperview];
                [self enqueueReusalbeItem:subview forIdentifier:kItemIdentifier];
            }
        }
        [view removeFromSuperview];
        [self enqueueReusalbeItem:view forIdentifier:kSectionIdentifier];
    }
    [self.visibleViews removeAllObjects];
    [self.calendarQueue removeAllObjects];
}

- (NSInteger)removeViewsOverTheBoundsWithDirection:(MoveDirection)direction {
    NSEnumerationOptions option = (direction == MoveDirectionUp)? 0: NSEnumerationReverse;
    NSMutableIndexSet *indexSet = [[NSIndexSet indexSet] mutableCopy];
    
    __weak __typeof(self) weakSelf = self;
    [self.visibleViews enumerateObjectsWithOptions:option usingBlock:^(UIView * _Nonnull view, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([weakSelf isSectionView:view needToBeRemovedWithDirection:direction]) {
            [view removeFromSuperview];
            [weakSelf enqueueReusalbeItem:view forIdentifier:kSectionIdentifier];
            [indexSet addIndex:idx];
            
            for (UIView *subview in view.subviews) {
                if (subview.tag != 100) {
                    [subview removeFromSuperview];
                    [weakSelf enqueueReusalbeItem:subview forIdentifier:kItemIdentifier];
                }
            }
        } else {
            *stop = YES;
        }
    }];
    
    [self.visibleViews removeObjectsAtIndexes:indexSet];
    [self.calendarQueue removeObjectsAtIndexes:indexSet];
    
    return indexSet.count;
}

- (BOOL)isSectionView:(UIView *)view needToBeRemovedWithDirection:(MoveDirection)direction {
    if (direction == MoveDirectionUp && view.minY < 0.0) {
        return YES;
    }
    if (direction == MoveDirectionDown && view.maxY > self.scrollView.contentSize.height) {
        return YES;
    }
    return NO;
}

#pragma mark - Append Objects

- (void)appendObjectsWithNumber:(NSInteger)numbersOfViewRemoved direction:(MoveDirection)direction {
    if (direction == MoveDirectionUp) {
        [self appendMonthsAtEndWithNumbers:numbersOfViewRemoved];
    } else {
        [self appendMonthsAtBeginningWithNumbers:numbersOfViewRemoved];
    }
}

- (void)createMonthAtCenter:(NSDate *)date {
    @autoreleasepool {
//        NSDate *newDate = [self dateOfCurrentMonth];
        CGFloat monthHeight = [self monthHeightByDate:date];
        UIView *newView = [self sectionViewWithHeight:monthHeight y:0.0];
        [self moveToScrollViewCenter:newView];
        [self configureSectionView:newView withDate:date];
        
        [self.scrollView addSubview:newView];
        [self.visibleViews addObject:newView];
        [self.calendarQueue addObject:date];
    }
}

- (void)appendMonthsAtBeginningWithNumbers:(NSInteger)numbers {
    @autoreleasepool {
        for (NSInteger i = 0; i < numbers; i++) {
            NSDate *date = [self.calendarQueue firstObject];
            UIView *firstView = [self.visibleViews firstObject];
            
            NSDate *newDate = [self dateFromComponents:[self fullComponentsForDate:date] withOffset:(-1) unit:NSCalendarUnitMonth];
            CGFloat monthHeight = [self monthHeightByDate:newDate];
            UIView *newView = [self sectionViewWithHeight:monthHeight y:(firstView.minY - monthHeight)];
            [self configureSectionView:newView withDate:newDate];
            
            [self.scrollView addSubview:newView];
            [self.visibleViews insertObject:newView atIndex:0];
            [self.calendarQueue insertObject:newDate atIndex:0];
        }
    }
}

- (void)appendMonthsAtEndWithNumbers:(NSInteger)numbers {
    @autoreleasepool {
        for (NSInteger i = 0; i < numbers; i++) {
            NSDate *date = [self.calendarQueue lastObject];
            UIView *lastView = [self.visibleViews lastObject];
            
            NSDate *newDate = [self dateFromComponents:[self fullComponentsForDate:date] withOffset:1 unit:NSCalendarUnitMonth];
            UIView *newView = [self sectionViewWithHeight:[self monthHeightByDate:newDate] y:lastView.maxY];
            [self configureSectionView:newView withDate:newDate];
            
            [self.scrollView addSubview:newView];
            [self.visibleViews addObject:newView];
            [self.calendarQueue addObject:newDate];
        }
    }
}

- (UIView *)sectionViewWithHeight:(CGFloat)height y:(CGFloat)y {
    UIView *newView = [self dequeueReusableItemForIdentifier:kSectionIdentifier];
//    [newView randomBackgroundColor];
    [newView setSize:(CGSize){self.scrollView.width, height}];
    [newView setY:y];
    return newView;
}

#pragma mark - CalendarItemViewDelegate

- (void)didSelectedCalendarItemView:(CalendarItemView *)itemView {
    [self didSelectItem:itemView];
}

#pragma mark - CircleViewDelegate

- (void)didSelectCircleView:(CircleView *)circleView {
    NSLog(@"Jump back to date: %ld/%ld/%ld", self.todayDateComponents.year, self.todayDateComponents.month, self.todayDateComponents.day);
    [self jumpToDate:[self.todayDateComponents copy]];
}

@end


#pragma mark -
#pragma mark - CalendarItemView

@interface CalendarItemView ()

@property (weak, nonatomic) UILabel *dayLabel;

@property (weak, nonatomic) CALayer *circleLayer;

@end

@implementation CalendarItemView

+ (instancetype)itemViewWithSize:(CGSize)size delegate:(id<CalendarItemViewDelegate>)delegate {
    CalendarItemView *itemView = [[self alloc] initWithFrame:(CGRect){{0.0}, size}];
    itemView.delegate = delegate;
    return itemView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        _dayLabel = [self creatDayLabel];
        _circleLayer = [self createCircleLayer];
        [self addGestures];
    }
    return self;
}

- (UILabel *)creatDayLabel {
    UILabel *dayLabel = [[UILabel alloc] init];
    dayLabel.center = (CGPoint){self.centerX, self.centerY};
    dayLabel.textColor = [UIColor darkGrayColor];
    dayLabel.font = [UIFont boldSystemFontOfSize:20.0];
    [self addSubview:dayLabel];
    return dayLabel;
}

- (CALayer *)createCircleLayer {
    CALayer *layer = [CALayer layer];
    layer.masksToBounds = NO;
    [self.layer insertSublayer:layer below:_dayLabel.layer];
    return layer;
}

- (void)addGestures {
    [self addTapGesture];
}

- (void)addTapGesture {
    UIGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [self addGestureRecognizer:tapGesture];
}

#pragma mark - Getter and Setter

- (void)setDayLabelWithDay:(NSInteger)day {
    self.dayLabel.text = [NSString stringWithFormat:@"%ld", (long)day];
    [self.dayLabel sizeToFit];
    self.dayLabel.center = (CGPoint){self.centerX, self.centerY};
    
    CGFloat circleLayerRedius = (MAX(_dayLabel.width, _dayLabel.height) + MAX(self.width, self.height)) / 2;
    _circleLayer.frame = (CGRect){{0.0, 0.0}, {circleLayerRedius, circleLayerRedius}};
    _circleLayer.position = _dayLabel.center;
    _circleLayer.cornerRadius = CGRectGetHeight(_circleLayer.frame) / 2;
}

- (void)setHighlighted:(BOOL)highlighted {
    _highlighted = highlighted;
    [self updateFocusedStatus:highlighted];
}

- (BOOL)isHighlighted {
    return _highlighted;
}

- (void)setSelected:(BOOL)selected {
    _selected = selected;
    [self updateFocusedStatus:selected];
}

- (BOOL)isSelected {
    return _selected;
}

#pragma mark - Actions

- (void)tapped:(UIGestureRecognizer *)gesture {
    if ([self.delegate respondsToSelector:@selector(didSelectedCalendarItemView:)]) {
        [self.delegate didSelectedCalendarItemView:self];
    }
}

#pragma mark - Modify Properties State

- (void)updateFocusedStatus:(BOOL)focused {
    if (focused) {
        [self setFocused];
    } else {
        [self setNormal];
    }
}

- (void)setFocused {
    self.circleLayer.backgroundColor = [self backgroundColorByCurrentStatus];
    self.circleLayer.hidden = NO;
    self.dayLabel.textColor = [UIColor whiteColor];
}

- (void)setNormal {
    if (_highlighted || _selected) {
        [self setFocused];
    } else {
        self.circleLayer.hidden = YES;
        self.dayLabel.textColor = [UIColor darkGrayColor];
    }
}

- (CGColorRef)backgroundColorByCurrentStatus {
    if (_highlighted && !_selected) {
        return [[UIColor redColor] CGColor];
    } else if (!_highlighted && _selected) {
        return [[UIColor blackColor] CGColor];
    } else if (_highlighted && _selected) {
        return [[UIColor blackColor] CGColor];
    } else {
        return [[UIColor whiteColor] CGColor];
    }
}

@end