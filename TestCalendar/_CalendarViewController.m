//
//  ViewController.m
//  TestCalendar
//
//  Created by HungWeiTai on 2015/9/30.
//  Copyright © 2015年 IFIT LTD. All rights reserved.
//

#import "_CalendarViewController.h"

#define NUMBER_OF_MONTHS 5

CGFloat const kSectionInsetSides = 16.0;
CGFloat const kMinCellSpacing = 1.0;

NSString *const EmptyCellIdentifier = @"EmptyCell";
NSString *const DayCellIdentifier = @"DayCell";
NSString *const HeaderViewIdentifier = @"HeaderView";

@interface _CalendarViewController () <UICollectionViewDelegateFlowLayout>

@property (assign, nonatomic) NSInteger totalMonths;

@property (assign, nonatomic) NSInteger currentMonth;

@property (assign, nonatomic) NSInteger currentMonthIndex;

@property (assign, nonatomic) NSInteger currentDay;

@property (strong, nonatomic) NSMutableDictionary *monthInfo;

@property (assign, nonatomic, getter=canInsert) BOOL insert;

@end

@implementation _CalendarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _monthInfo = [@{} mutableCopy];
    _totalMonths = NUMBER_OF_MONTHS;
    _currentMonthIndex = [self middleInSection];
    
    NSDate *currentDate = [NSDate date];
    NSCalendar *currentCalendar = [NSCalendar currentCalendar];
    [currentCalendar getEra:NULL year:NULL month:&_currentMonth day:&_currentDay fromDate:currentDate];
    
    [self getMonthInfoForSection:self.currentMonthIndex];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    NSDictionary *monthInfo = self.monthInfo[[@(self.currentMonthIndex) stringValue]];
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:[monthInfo[@"CurrentDate"] integerValue] inSection:self.currentMonthIndex];
    [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredVertically animated:NO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)canInsert {
    return _insert;
}

- (NSInteger)middleInSection {
    return (NSInteger)(_totalMonths / 2);
}

- (NSDictionary *)getMonthInfoForSection:(NSInteger)section {
    @autoreleasepool {
        NSString *key = [@(section) stringValue];
        if (self.monthInfo[key]) {
            return self.monthInfo[key];
        }
        
        NSInteger monthOffset = section - self.currentMonthIndex;
        
        NSCalendar *currentCalendar = [NSCalendar currentCalendar];
        NSDate *firstDateOfMonth = [currentCalendar dateByAddingUnit:NSCalendarUnitMonth value:monthOffset toDate:[NSDate date] options:0];
        NSDateComponents *components = [currentCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:firstDateOfMonth];
        components.day = 1;
        firstDateOfMonth = [currentCalendar dateFromComponents:components];
        components = nil;
        
        NSInteger year = 0, month = 0, weekday = 0;
        [currentCalendar getEra:NULL year:&year month:&month day:NULL fromDate:firstDateOfMonth];
        [currentCalendar getEra:NULL yearForWeekOfYear:NULL weekOfYear:NULL weekday:&weekday fromDate:firstDateOfMonth];
        weekday -= 1;
        
        NSRange daysRange = [currentCalendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:firstDateOfMonth];
        NSInteger endIndex = weekday + daysRange.length;
        
        NSDictionary *monthInfo;
        if (monthOffset == 0) {
            NSInteger currentDateIndex = weekday + self.currentDay - 1;
            monthInfo = @{@"Year":       @(year),
                          @"Month":      @(month),
                          @"StartIndex": @(weekday),
                          @"EndIndex":   @(endIndex),
                          @"CurrentDate":@(currentDateIndex)};
        } else {
            monthInfo = @{@"Year":       @(year),
                          @"Month":      @(month),
                          @"StartIndex": @(weekday),
                          @"EndIndex":   @(endIndex)};
        }
        _monthInfo[key] = monthInfo;
        key = nil;
        
        return monthInfo;
    }
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return self.totalMonths;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSDictionary *monthInfo = [self getMonthInfoForSection:section];
    NSNumber *endIndex = monthInfo[@"EndIndex"];
    return [endIndex integerValue];
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    UICollectionReusableView *reusableView = [collectionView dequeueReusableSupplementaryViewOfKind:kind withReuseIdentifier:HeaderViewIdentifier forIndexPath:indexPath];
    if (kind == UICollectionElementKindSectionHeader) {
        NSDictionary *monthInfo = [self getMonthInfoForSection:indexPath.section];
        NSNumber *month = monthInfo[@"Month"];
        NSString *headerTitle;
        if ([month integerValue] == 1) {
            NSNumber *year = monthInfo[@"Year"];
            headerTitle = [NSString stringWithFormat:@"%@.%@ 月", year, month];
        } else {
            headerTitle = [NSString stringWithFormat:@"%@ 月", month];
        }
        
        UILabel *monthLabel = (UILabel *)[reusableView viewWithTag:100];
        monthLabel.text = headerTitle;
    }
    
    if (indexPath.section == 1 && self.canInsert) {
        __weak __typeof(self) weakSelf = self;
        [self.collectionView performBatchUpdates:^{
            weakSelf.totalMonths += 10;
            weakSelf.currentMonthIndex += 10;
            NSRange newsectionsRange = NSMakeRange(0, 10);
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:newsectionsRange];
            [weakSelf.collectionView insertSections:indexSet];
        } completion:^(BOOL finished) {
            [weakSelf setInsert:NO];
        }];
    }
    
    return reusableView;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *monthInfo = [self getMonthInfoForSection:indexPath.section];
    NSNumber *startIndex = monthInfo[@"StartIndex"];
    NSNumber *endIndex = monthInfo[@"EndIndex"];
    
    if (indexPath.item >= [startIndex integerValue] && indexPath.item < [endIndex integerValue]) {
        UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:DayCellIdentifier forIndexPath:indexPath];
        
        UILabel *dayLabel = (UILabel *)[cell viewWithTag:100];
        dayLabel.text = [NSString stringWithFormat:@"%@", @((indexPath.item - [startIndex integerValue]) + 1)];
        
        if (monthInfo[@"CurrentDate"] && ([monthInfo[@"CurrentDate"] integerValue] == indexPath.item)) {
            cell.backgroundColor = [UIColor colorWithRed:255.0/255.0 green:185.0/255.0 blue:185.0/255.0 alpha:1.0];
            [self setInsert:YES];
        } else {
            cell.backgroundColor = [UIColor whiteColor];
        }
        
        return cell;
    }
    
    return [collectionView dequeueReusableCellWithReuseIdentifier:EmptyCellIdentifier forIndexPath:indexPath];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat viewWidth = CGRectGetWidth(self.collectionView.frame);
    CGFloat cellWidth = (viewWidth - (kSectionInsetSides * 2) - (kMinCellSpacing * 6)) / 7;
    return (CGSize){cellWidth, cellWidth};
}

@end
