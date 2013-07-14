//
//  GBRetractableTabBar.m
//  GBRetractableTabBar
//
//  Created by Luka Mirosevic on 17/05/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBRetractableTabBar.h"

#import "GBToolbox.h"

static GBRetractableTabBarContentResizingMode const kDefaultResizingMode =                          GBRetractableTabBarContentResizingModeAutomaticallyAdjustHeight;
static BOOL const kDefaultShouldPopToRootOnNavigationControllerWhenTappingActiveControlView =       YES;


@interface UIViewController ()

@property (weak, nonatomic, readwrite) GBRetractableTabBar                                          *retractableTabBar;

@property (strong, nonatomic) NSNumber                                                              *retractableTabBarResizingModeNumber;
@property (assign, nonatomic) GBRetractableTabBarContentResizingMode                                retractableTabBarResizingMode;

@end

@implementation UIViewController (GBRetractableTabBar)

_associatedObject(weak, nonatomic, GBRetractableTabBar *, retractableTabBar, setRetractableTabBar)

_associatedObject(strong, nonatomic, NSNumber *, retractableTabBarResizingModeNumber, setRetractableTabBarResizingModeNumber)

-(GBRetractableTabBarContentResizingMode)retractableTabBarResizingMode {
    NSNumber *resizingModeNumber = self.retractableTabBarResizingModeNumber;
    if (resizingModeNumber) {
        return (GBRetractableTabBarContentResizingMode)resizingModeNumber.intValue;
    }
    else {
        return kDefaultResizingMode;
    }
}

-(void)setRetractableTabBarResizingMode:(GBRetractableTabBarContentResizingMode)retractableTabBarResizingMode {
    self.retractableTabBarResizingModeNumber = @(retractableTabBarResizingMode);
}

@end


NSUInteger const kGBRetractableTabBarUndefinedIndex =                                               NSUIntegerMax;

static CGFloat const kGBRetractableBarAnimationDuration =                                           0.3;
static GBRetractableTabBarLayoutStyle const kGBRetractableTabBarDefaultLayoutStyle =                GBRetractableTabBarLayoutStyleSpread;

@interface GBRetractableTabBar () {
    UIView                                                                                          *_barBackgroundView;
    UIImage                                                                                         *_barBackgroundImage;
    CGFloat                                                                                         _barHeight;
    BOOL                                                                                            _isShowing;
}

@property (strong, nonatomic) UIView                                                                *contentView;
@property (strong, nonatomic) UIView                                                                *barView;
@property (strong, nonatomic) UIView                                                                *controlViewsContainer;

@property (strong, nonatomic) NSMutableArray                                                        *myControlViews;
@property (strong, nonatomic) NSMutableArray                                                        *myViewControllers;
@property (strong, nonatomic, readwrite) UIViewController                                           *activeViewController;
@property (assign, nonatomic) NSUInteger                                                            myActiveIndex;

@property (strong, nonatomic) UITapGestureRecognizer                                                *tapGestureRecognizer;

@end

@implementation GBRetractableTabBar

#pragma mark - Private API: Lazy

_lazy(NSMutableArray, myControlViews, _myControlViews)
_lazy(NSMutableArray, myViewControllers, _myViewControllers)

//Create the gesturerecognizer lazily
-(UITapGestureRecognizer *)tapGestureRecognizer {
    if (!_tapGestureRecognizer) {
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
        _tapGestureRecognizer.numberOfTapsRequired = 1;
        _tapGestureRecognizer.numberOfTouchesRequired = 1;
    }
    
    return _tapGestureRecognizer;
}

//Create the contentview lazily
-(UIView *)contentView {
    if (!_contentView) {
        _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - self.barHeight)];
        _contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.view addSubview:_contentView];
        [self.view sendSubviewToBack:_contentView];
    }
    
    return _contentView;
}

//Create the barview lazily
-(UIView *)barView {
    if (!_barView) {
        _barView = [[UIView alloc] initWithFrame:self.view.bounds];//just sets it to the entire view size for now
        [self _configureBar];//this won't infinite loop due to self.barView access because we've already assigned it so the above if won't match and it will return the freshly initialised one
        
        //strecth the container to fill the bar
        self.controlViewsContainer.frame = _barView.bounds;
        
        //add the container to the bar
        [_barView addSubview:self.controlViewsContainer];
        
        //add the gestureRecognizer
        [_barView addGestureRecognizer:self.tapGestureRecognizer];
        
        [self.view addSubview:_barView];
        [self.view bringSubviewToFront:_barView];
    }
    
    return _barView;
}

-(UIView *)controlViewsContainer {
    //this just makes sure he exists, barView calls upon him when necessary
    if (!_controlViewsContainer) {
        _controlViewsContainer = [[UIView alloc] init];
        
        //make sure it stretches with the barView
        _controlViewsContainer.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        
        //make sure it doesnt clip views
        _controlViewsContainer.clipsToBounds = NO;
        
        
        _controlViewsContainer.backgroundColor = [UIColor clearColor];
    }
    
    return _controlViewsContainer;
}

#pragma mark - Custom accessors

-(NSUInteger)activeIndex {
    return self.myActiveIndex;
}

-(void)setMyActiveIndex:(NSUInteger)myActiveIndex {
    //if its changed
    if (_myActiveIndex != myActiveIndex) {
        //remember them
        NSUInteger oldIndex = _myActiveIndex;
        NSUInteger newIndex = myActiveIndex;
        
        //set the ivar so everyone else will know the correct state
        _myActiveIndex = myActiveIndex;
        
        //we'll need to remember this for later
        UIViewController *oldViewController = self.activeViewController;
        
        
        //fist handle the internal stuff
            //view controllers
            [self _sortOutViewControllers];
            
            //control views
            [self _activateCorrectControlView];
        
            //handle the geometry (some contentVCs might have different resizing settings
            [self _handleGeometryShowing:self.isShowing];
        
        
        //now tell our delegate what happenend
            //index
            if ([self.delegate respondsToSelector:@selector(tabBar:didChangeActiveIndexFromOldIndex:toNewIndex:)]) {
                [self.delegate tabBar:self didChangeActiveIndexFromOldIndex:oldIndex toNewIndex:newIndex];
            }
            
            //view controllers
            if ([self.delegate respondsToSelector:@selector(tabBar:didHideViewControllerWithIndex:viewController:)]) {
                [self.delegate tabBar:self didHideViewControllerWithIndex:oldIndex viewController:oldViewController];
            }
            if ([self.delegate respondsToSelector:@selector(tabBar:didShowViewControllerWithIndex:viewController:)]) {
                [self.delegate tabBar:self didShowViewControllerWithIndex:newIndex viewController:self.activeViewController];
            }
            
            //joint
            if ([self.delegate respondsToSelector:@selector(tabBar:didReplaceViewControllerWithOldIndex:oldViewController:withViewControllerWithNewIndex:newViewController:)]) {
                [self.delegate tabBar:self didReplaceViewControllerWithOldIndex:oldIndex oldViewController:oldViewController withViewControllerWithNewIndex:newIndex newViewController:self.activeViewController];
            }
    }
}

-(void)setStyle:(GBRetractableTabBarLayoutStyle)style {
    _style = style;
    
    [self _arrangeControlViews];
}

#pragma mark - Init

-(id)initWithTabBarHeight:(CGFloat)tabBarHeight {
    if (self = [super init]) {
        self.barHeight = tabBarHeight;
        self.myActiveIndex = kGBRetractableTabBarUndefinedIndex;
        _isShowing = YES;
        self.style = kGBRetractableTabBarDefaultLayoutStyle;
        self.shouldPopToRootOnNavigationControllerWhenTappingActiveControlView = kDefaultShouldPopToRootOnNavigationControllerWhenTappingActiveControlView;
    }
    
    return self;
}

-(id)init {
    return [self initWithTabBarHeight:50];
}

#pragma mark - External control

//Programatically set which viewController/controlView pair is active
-(void)setActiveIndex:(NSUInteger)index {
    self.myActiveIndex = index;
}

#pragma mark - Populating the tab bar

//Adds a viewcontroller and his control view. If this is the first pair, they're activated (i.e. viewcontroller's view is shown, controlView is sent the setActive:YES message)
-(void)addViewController:(UIViewController *)viewController withControlView:(UIView<GBRetractableTabBarControlView> *)controlView {
    if (viewController && controlView) {
        [self addViewController:viewController];
        [self addControlView:controlView];
    }
}

#pragma mark - Control Views

-(void)addControlView:(UIView<GBRetractableTabBarControlView> *)view {
    [self setControlView:view forIndex:self.myControlViews.count];
}

-(void)setControlView:(UIView<GBRetractableTabBarControlView> *)view forIndex:(NSUInteger)index {
    if (view) {
        //first make sure the array has that length
        [self.myControlViews padToIndex:index];
        
        //add the view into the array
        self.myControlViews[index] = view;
        
        //configure this control view a little first
        [self _configureControlViewProperties:view];
        
        //arrange the control views inside the tab bar
        [self _arrangeControlViews];
        
        //activate him?
        [self _happyActiveTrigger];
    }
}

-(NSArray *)controlViews {
    return [self.myControlViews filter:^BOOL(id object) {
        return (object != [NSNull null]);
    }];
}

#pragma mark - Private API: Control Views

-(void)_configureControlViewProperties:(UIView<GBRetractableTabBarControlView> *)controlView {
    //make sure he's not resizable
    controlView.autoresizingMask = UIViewAutoresizingNone;
    
    //make sure he's not active when he's being added
    controlView.isActive = NO;
}

-(void)_arrangeControlViews {
    //get dense array representation, not the sparse list
    NSArray *controlViews = self.controlViews;
    
    //first take all the existing ones off, this will release them if they're no longer in the myControlViews array, which is convenient as we won't need those any more anyways
    [self.controlViewsContainer removeAllSubviews];
    
    //only if there's anything to add
    if (controlViews.count > 0) {
        //now calculate the spacing, can be negative doesn't matter
        CGFloat totalWidth = 0;
        for (UIView *view in controlViews) {
            totalWidth += view.frame.size.width;
        }

        CGFloat leftMargin;
        CGFloat collapsibleHorizontalMargin;
        
        switch (self.style) {
            case GBRetractableTabBarLayoutStyleBunched: {
                leftMargin = (self.view.bounds.size.width - totalWidth ) / 2;
                collapsibleHorizontalMargin = 0;
            } break;
                
            case GBRetractableTabBarLayoutStyleSpread: {
                leftMargin = 0;
                collapsibleHorizontalMargin = (self.view.bounds.size.width - totalWidth) / (controlViews.count + 1);
            } break;
        }
        
        //set the frames and add them to the container
        CGFloat howFar = leftMargin;
        for (UIView *view in controlViews) {
            //make sure it behaves
            view.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
            
            //set the frames
            CGFloat xOrigin = howFar + collapsibleHorizontalMargin;
            CGFloat yOrigin = (self.barView.bounds.size.height - view.frame.size.height) / 2;
            view.frame = CGRectMake(xOrigin, yOrigin, view.frame.size.width, view.frame.size.height);
            howFar += collapsibleHorizontalMargin + view.frame.size.width;
            
            //add them to the container
            [self.controlViewsContainer addSubview:view];
        }
    }
}

-(void)_activateCorrectControlView {
    //prep
    UIView<GBRetractableTabBarControlView> *currentlyActiveView = (self.myActiveIndex != kGBRetractableTabBarUndefinedIndex) ? self.controlViews[self.myActiveIndex] : nil;
    
    //if the target is already active then we're done
    if (!currentlyActiveView.isActive) {
        //make sure any old dudes get deactivated first
        [self.myControlViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[UIView class]]) {
                UIView<GBRetractableTabBarControlView> *view = obj;
                
                //this is the new active one
                if (idx == self.myActiveIndex) {
                    view.isActive = YES;
                }
                //all the rest
                else {
                    //check if he's active...
                    if (view.isActive) {
                        //...if so, deactivate him
                        view.isActive = NO;
                    }
                }
            }
        }];
    }
}

#pragma mark - View Controllers

-(void)addViewController:(UIViewController *)viewController {
    [self setViewController:viewController forIndex:self.myViewControllers.count];
}

-(void)setViewController:(UIViewController *)viewController forIndex:(NSUInteger)index {
    if (viewController) {
        //make sure he knows who we are
        viewController.retractableTabBar = self;
        
        //if we're gonna replace someone, this is a good time to say goodbye
        if (self.viewControllers.count > index && self.viewControllers[index]) ((UIViewController *)self.viewControllers[index]).retractableTabBar = nil;
        
        //make sure the array has enough space
        [self.myViewControllers padToIndex:index];
        
        //insert the viewcontroller
        self.myViewControllers[index] = viewController;
        
        //sort out the drawing, vc lifecycle, etc.
        [self _sortOutViewControllers];
        
        //activate him?
        [self _happyActiveTrigger];
    }
}

-(NSArray *)viewControllers {
    return [self.myViewControllers filter:^BOOL(id object) {
        return (object != [NSNull null]);
    }];
}

#pragma mark - Private API: View Controllers

-(void)_sortOutViewControllers {
    //N.B. active index and myViewControllers are the sources of truth, activeViewController is just so we can detect when he's been swapped out
    UIViewController *newActiveViewController = (self.myActiveIndex != kGBRetractableTabBarUndefinedIndex) ? self.myViewControllers[self.myActiveIndex] : nil;
    
    //check if we have a change
    if (newActiveViewController != self.activeViewController) {
        //hide the old one
        [self hideViewController:self.activeViewController];
        
        //show the new one
        [self showViewController:newActiveViewController];
        
        //remember who is active
        self.activeViewController = newActiveViewController;
    }
}

-(void)hideViewController:(UIViewController *)viewController {
    if (viewController) {
        [viewController.view removeFromSuperview];
    }
}

-(void)showViewController:(UIViewController *)viewController {
    if (viewController) {
        viewController.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        viewController.view.frame = self.contentView.bounds;
        [self.contentView addSubview:viewController.view];
    }
}

#pragma mark - Tab bar height

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

#pragma mark - Background

-(void)setBarBackgroundView:(UIView *)barBackgroundView {
    //remove old bgview
    [_barBackgroundView removeFromSuperview];
    
    //assign the new one
    _barBackgroundView = barBackgroundView;
    
    //make sure the tab bar is configured
    [self _configureBar];
    
    //configure the new one
    [self _configureBarBackgroundView];
    
    //remove any potential images (the caller will add him afterwards if necessary)
    _barBackgroundImage = nil;
    
    //draw the new one
    [self.barView addSubview:barBackgroundView];
    
    //send it to the back
    [self.barView sendSubviewToBack:self.barBackgroundView];
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
        //set it's frame
        self.barBackgroundView.frame = CGRectMake(0, self.barHeight - self.barBackgroundView.frame.size.height, self.barView.bounds.size.width, self.barBackgroundView.frame.size.height);
        
        //make sure it stretches to the width and keeps it's height and is pinned to the bottom
        self.barBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    }
}

#pragma mark - Private API: Retracting

-(void)_handleGeometryShowing:(BOOL)shouldShowBar {
    CGRect contentViewTargetFrame;
    CGRect barViewTargetFrame;
    
    CGRect barShownTargetFrame = CGRectMake(0,
                                            self.view.bounds.size.height - self.barHeight,
                                            self.view.bounds.size.width,
                                            self.barHeight);
    
    CGRect barHiddenTargetFrame = CGRectMake(0,
                                             self.view.bounds.size.height + self.barOverflowDistance,
                                             self.view.bounds.size.width,
                                             self.barHeight);
    
    CGRect contentViewFullHeightTargetFrame = CGRectMake(0,
                                                         0,
                                                         self.view.bounds.size.width,
                                                         self.view.bounds.size.height + self.barOverflowDistance);
    
    CGRect contentViewMinusBarHeightTargetFrame = CGRectMake(0,
                                                             0,
                                                             self.view.bounds.size.width,
                                                             self.view.bounds.size.height - self.barHeight);
    
    //sort out bar sizing
    if (shouldShowBar) {
        //barview goes up
        barViewTargetFrame = barShownTargetFrame;
    }
    else {
        //barview goes down
        barViewTargetFrame = barHiddenTargetFrame;
    }
    
    //sort out content view sizing
    if (shouldShowBar) {
        switch (self.activeViewController.retractableTabBarResizingMode) {
                //shrink the height
            case GBRetractableTabBarContentResizingModeAutomaticallyAdjustHeight: {
                contentViewTargetFrame = contentViewMinusBarHeightTargetFrame;
            } break;
                
                //keep full size height
            case GBRetractableTabBarContentResizingModeFixedFullHeight: {
                contentViewTargetFrame = contentViewFullHeightTargetFrame;
            } break;
        }
    }
    else {
        //contentview goes down
        contentViewTargetFrame = contentViewFullHeightTargetFrame;
    }
    
    //do the actual property changes
    self.contentView.frame = contentViewTargetFrame;
    self.barView.frame = barViewTargetFrame;
}

#pragma mark - Retracting

-(void)setIsShowing:(BOOL)isShowing {
    [self show:isShowing animated:NO];
}

-(BOOL)isShowing {
    return _isShowing;
}

-(void)show:(BOOL)shouldShowBar animated:(BOOL)shouldAnimate {
    //if it changed
    if (shouldShowBar != _isShowing) {
        //property changes
        VoidBlock animations = ^{
            [self _handleGeometryShowing:shouldShowBar];
        };
        
        //once they've been changed, call this
        VoidBlock completion = ^{
            _isShowing = shouldShowBar;
            
            //tell our delegate
            if (shouldShowBar) {
                if ([self.delegate respondsToSelector:@selector(tabBarDidShowTabBar:animated:)]) {
                    [self.delegate tabBarDidShowTabBar:self animated:shouldAnimate];
                }
            }
            else {
                if ([self.delegate respondsToSelector:@selector(tabBarDidHideTabBar:animated:)]) {
                    [self.delegate tabBarDidHideTabBar:self animated:shouldAnimate];
                }
            }
        };
        
        
        //do the actual changes
        if (shouldAnimate) {
            [UIView animateWithDuration:kGBRetractableBarAnimationDuration animations:^{
                animations();
            } completion:^(BOOL finished) {
                completion();
            }];
        }
        else {
            animations();
            completion();
        }
    }
}

#pragma mark - View sizing behaviour

-(void)setContentResizingMode:(GBRetractableTabBarContentResizingMode)contentResizingMode forViewController:(UIViewController *)viewController {
    if (!viewController) @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"viewController must not be nil" userInfo:nil];
    
    //set the resizing mode for that VC
    viewController.retractableTabBarResizingMode = contentResizingMode;
    
    //this relays out the contentview, without animating, so the settings is applied immediately
    [self _handleGeometryShowing:self.isShowing];
}

#pragma mark - Tap gesture recognizer

-(void)tapped:(UITapGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        //ensure we're shown, don't ever want to get in the situation where you switch to a view controller which doesn't have a facility of hiding/showing the tab bar, and the bar being hidden
        [self show:YES animated:YES];
        
        //find location of tap
        CGPoint target = [gestureRecognizer locationInView:self.barView];
        
        //find which view that was in
        [self.controlViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIView *view = obj;
            
            if (CGRectContainsPoint(view.frame, target)) {
                //first tap
                if (self.myActiveIndex != idx) {
                    [self _didTapOnInActiveControlViewWithIndex:idx];
                }
                //reactive tap
                else {
                    [self _didTapOnAlreadyActiveControlViewWithIndex:idx];
                }
                
                //dont look further
                *stop = YES;
            }
        }];
    }
}

#pragma mark - Private: Tapping

-(void)_didTapOnInActiveControlViewWithIndex:(NSUInteger)index {
    //set active
    self.myActiveIndex = index;
}

-(void)_didTapOnAlreadyActiveControlViewWithIndex:(NSUInteger)index {
    //pop to root if desired
    if (self.shouldPopToRootOnNavigationControllerWhenTappingActiveControlView) {
        if ([self.activeViewController respondsToSelector:@selector(popToRootViewControllerAnimated:)]) {
            [((UINavigationController *)self.activeViewController) popToRootViewControllerAnimated:YES];
        }
    }
}

#pragma mark - Happy active trigger

//This is called when a controlView or viewController is added. If the active index is undefined, he activated the first index for which he gets both a controlview and a contentview
-(void)_happyActiveTrigger {
    if (self.myActiveIndex == kGBRetractableTabBarUndefinedIndex) {
        //enumerate the controlviews, and find the first corresponding contentview
        for (NSUInteger i=0; i<self.myControlViews.count; i++) {
            //if we don't have a corresponding vc, then we're done
            if (i >= self.myViewControllers.count) break;
            
            UIView *controlView = self.myControlViews[i];
            UIViewController *viewController = self.myViewControllers[i];
            
            if ([controlView isKindOfClass:[UIView class]] && [viewController isKindOfClass:[UIViewController class]]) {
                self.myActiveIndex = i;
                break;
            }
            
        }
    }
}

@end
