//
//  GBRetractableTabBar.m
//  GBRetractableTabBar
//
//  Created by Luka Mirosevic on 17/05/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBRetractableTabBar.h"
#import "GBRetractableTabBarViewProtocol.h"

#import "GBToolbox.h"

static NSUInteger const kGBRetractableTabBarUndefinedIndex = NSUIntegerMax;

@interface GBRetractableTabBar () {
    UIView                                      *_barBackgroundView;
    UIImage                                     *_barBackgroundImage;
    CGFloat                                     _barHeight;
}

@property (strong, nonatomic) UIView            *contentView;
@property (strong, nonatomic) UIView            *barView;

@property (strong, nonatomic) NSMutableArray    *myControlViews;
@property (strong, nonatomic) NSMutableArray    *myViewControllers;
@property (strong, nonatomic) UIViewController  *activeViewController;
@property (assign, nonatomic) NSUInteger        activeIndex;

@end

@implementation GBRetractableTabBar

#pragma mark - Private API: Lazy

_lazy(NSMutableArray, myControlViews, _myControlViews)
_lazy(NSMutableArray, myViewControllers, _myViewControllers)

//Create the contentview lazily
-(UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.barHeight)];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_contentView];
        [self.view sendSubviewToBack:_contentView];
        _contentView.backgroundColor = [UIColor grayColor];//foo testing
    }
    
    return _contentView;
}

//Create the barview lazily also
-(UIView *)barView {
    if (!_barView) {
        _barView = [[UIView alloc] initWithFrame:self.view.bounds];//just sets it to the entire view size for now
        [self _configureBar];//this won't infinite loop due to self.barView access because we've already assigned it so the above if won't match and it will return the freshly initialised one
        [self.view addSubview:_barView];
        [self.view bringSubviewToFront:_barView];
        _barView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.5];//foo testing
    }
    
    return _barView;
}

#pragma mark - Public API: Init

-(id)initWithTabBarHeight:(CGFloat)tabBarHeight {
    if (self = [super init]) {
        self.barHeight = tabBarHeight;
        
        [self basicInitRoutine];
    }
    
    return self;
}

-(id)init {
    if (self = [super init]) {
        [self basicInitRoutine];
    }
    
    return self;
}

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    @throw [NSException exceptionWithName:GBUnexpectedMessageException reason:@"GBRetractableTabBar: unsupported init method, use initWithTabBarHeight: or init:" userInfo:nil];
}

-(id)initWithCoder:(NSCoder *)aDecoder {
    @throw [NSException exceptionWithName:GBUnexpectedMessageException reason:@"GBRetractableTabBar: unsupported init method, use initWithTabBarHeight: or init:" userInfo:nil];
}

#pragma mark - Private API: Init

-(void)basicInitRoutine {
    self.activeIndex = kGBRetractableTabBarUndefinedIndex;
}

#pragma mark - Public API: Control Views

-(void)addControlView:(UIView<GBRetractableTabBarView> *)view {
    [self insertControlView:view atIndex:self.myControlViews.count];
}

-(void)insertControlView:(UIView<GBRetractableTabBarView> *)view atIndex:(NSUInteger)index {
    //first make sure the array has that length
    [self.myControlViews padToIndex:index];
    
    //add the view into the array
    self.myControlViews[index] = view;
    
    //configure this control view a little first
    [self _configureControlViewProperties:view];
    
    //arrange the control views inside the tab bar
    [self _arrangeControlViews];
}

-(void)removeControlViewAtIndex:(NSUInteger)index {
    //NSMutableArray can handle this properly
    [self.myControlViews removeObjectAtIndex:index];
    
    [self _arrangeControlViews];
}

-(void)removeAllControlViews {
    self.myControlViews = nil;
    
    [self _arrangeControlViews];
}

#pragma mark - Private API: Control Views

-(void)_configureControlViewProperties:(UIView<GBRetractableTabBarView> *)controlView {
    //make sure he's not resizable
    controlView.autoresizingMask = UIViewAutoresizingNone;
    
    //make sure he's not active when he's being added
    controlView.isActive = NO;
}

-(void)_arrangeControlViews {
    //make sure they all have equal spacing
}

#pragma mark - Public API: View Controllers

//Sets the view controller, releases the old one if there was one (and removes his view from the tab bar controller if he was active), if this is the active index, he immediately shows him
-(void)setViewController:(UIViewController *)viewController forIndex:(NSUInteger)index {
    //make sure the array has enough space
    [self.myViewControllers padToIndex:index];
    
    //insert the viewcontroller
    self.myViewControllers[index] = viewController;
    
    //sort out the drawing, vc lifecycle, etc.
    [self _sortOutViewControllers];
}

-(NSArray *)viewControllers {
    return [self.myViewControllers filter:^BOOL(id object) {
        return (object != [NSNull null]);
    }];
}

#pragma mark - Private API: View Controllers

-(void)_sortOutViewControllers {
    //active index and myViewControllers are the sources of truth, activeViewController is just so we can detect when he's been swapped out
    
    //check the active index, if it matches the currently shown vc, all good
}

#pragma mark - Public API: Tab bar height

-(void)setBarHeight:(CGFloat)tabBarHeight {
    _barHeight = tabBarHeight;
    
    //configure the tab bar to the new height
    [self _configureBar];
    
    //also reconfigure the bar bgview in case the old autoresizing didnt catch if we were 0 frame
    [self _configureBarBackgroundView];
}

-(CGFloat)barHeight {
    return _barHeight;
}

#pragma mark - Private API: Tab bar height

-(void)_configureBar {
    if (self.barView) {
        //set it's width to the full view width, leave height as is, pin to bottom
        self.barView.frame = CGRectMake(0, self.view.bounds.size.height-self.barHeight, self.view.bounds.size.width, self.barHeight);
        
        //make sure it stretches to the width and keeps it's height and is pinned to the bottom
        self.barView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        
        //make sure it doesnt clip views
        self.barView.clipsToBounds = NO;
    }
}

#pragma mark - Public API: Background

-(void)setBarBackgroundView:(UIView *)barBackgroundView {
    //remove old bgview
    [_barBackgroundView removeFromSuperview];
    
    //assign the new one
    _barBackgroundView = barBackgroundView;
    
    //make sure the tab bar is configured
    [self _configureBar];//foo not so sure
    
    //configure the new one
    [self _configureBarBackgroundView];
    
    //draw the new one
    [self.view addSubview:barBackgroundView];
}

-(UIView *)barBackgroundView {
    return _barBackgroundView;
}

-(void)setBarBackgroundImage:(UIImage *)barBackgroundImage {
    if (barBackgroundImage) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:barBackgroundImage];
        
        [self setBarBackgroundView:imageView];
        
        _barBackgroundImage = barBackgroundImage;
    }
}

-(UIImage *)barBackgroundImage {
    return _barBackgroundImage;
}

#pragma mark - Private API: Background

-(void)_configureBarBackgroundView {
    if (self.barBackgroundView) {
        //set it's width
        self.barBackgroundView.frame = CGRectMake(0, self.barBackgroundView.frame.size.height, self.barView.bounds.size.width, self.barHeight);
        
        //make sure it stretches to the width and keeps it's height and is pinned to the bottom
        self.barBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    }
}

#pragma mark - Public API: Retracting

//Shows or hides the tab bar, and shrinks or stretches the contentView respectively
-(void)show:(BOOL)shouldShow animated:(BOOL)shouldAnimate {
    
}


@end
