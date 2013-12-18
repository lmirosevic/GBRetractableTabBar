//
//  GBRetractableTabBar.h
//  GBRetractableTabBar
//
//  Created by Luka Mirosevic on 17/05/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "GBRetractableTabBarControlViewProtocol.h"

extern NSUInteger const kGBRetractableTabBarUndefinedIndex;

typedef enum {
    GBRetractableTabBarLayoutStyleSpread,
    GBRetractableTabBarLayoutStyleBunched,
} GBRetractableTabBarLayoutStyle;

typedef enum {
    GBRetractableTabBarContentResizingModeAutomaticallyAdjustHeight,
    GBRetractableTabBarContentResizingModeFixedFullHeight,
} GBRetractableTabBarContentResizingMode;

@class GBRetractableTabBar;

@interface UIViewController (GBRetractableTabBar)

@property (weak, nonatomic, readonly) GBRetractableTabBar                   *retractableTabBar;
@property (weak, nonatomic, readonly) GBRetractableTabBar                   *containingRetractableTabBar;

@end

@protocol GBRetractableTabBarControlView;
@protocol GBRetractableTabBarDelegate;

@interface GBRetractableTabBar : UIViewController

@property (weak, nonatomic) id<GBRetractableTabBarDelegate>                 delegate;

@property (assign, nonatomic) CGFloat                                       barHeight;
@property (strong, nonatomic) UIView                                        *barBackgroundView;
@property (strong, nonatomic) UIImage                                       *barBackgroundImage;
@property (assign, nonatomic) GBRetractableTabBarLayoutStyle                style;
@property (assign, nonatomic) CGFloat                                       barOverflowDistance;
@property (assign, nonatomic) BOOL                                          shouldPopToRootOnNavigationControllerWhenTappingActiveControlView;

@property (assign, nonatomic) BOOL                                          isShowing;
@property (strong, nonatomic, readonly) UIViewController                    *activeViewController;
@property (assign, nonatomic) NSUInteger                                    activeIndex;
@property (assign, nonatomic, readonly) NSUInteger                          previousActiveIndex;

#pragma mark - Init

//Designated initialiser
-(id)initWithTabBarHeight:(CGFloat)tabBarHeight;

#pragma mark - External control

//Programatically set which viewController/controlView pair is active
-(void)setActiveIndex:(NSUInteger)index;

//Lets you go back to the previously selected tab
-(void)restorePreviousActiveIndex;

#pragma mark - Populating the tab bar

//Adds a viewcontroller and his control view. If this is the first pair, they're activated (i.e. viewcontroller's view is shown, controlView is sent the setActive:YES message)
-(void)addViewController:(UIViewController *)viewController withControlView:(UIView<GBRetractableTabBarControlView> *)controlView;

#pragma mark - Control Views
//Views added must all conform to the protocol but can be any subclass of UIView. Make sure they don't handle events in the responder chain, so that these may bubble on to the tab bar

//Places a view at a specific position. You can set arbitrary indexes at arbitrary orders and it will work itself out. It doesn't follow NSArray semantics where you can only add immediately to the end. This is so that you can add things out of order
-(void)setControlView:(UIView<GBRetractableTabBarControlView> *)view forIndex:(NSUInteger)index;

//Return them as an array
-(NSArray *)controlViews;

#pragma mark - View Controllers

//Sets the view controller, releases the old one if there was one (and removes his view from the tab bar controller if he was active), if this is the active index, he immediately shows him
-(void)setViewController:(UIViewController *)viewController forIndex:(NSUInteger)index;

//Returns the list of view controllers as an array
-(NSArray *)viewControllers;

#pragma mark - Tab bar height

//simple accessors, changing the height lays all the elements out properly
-(void)setBarHeight:(CGFloat)tabBarHeight;
-(CGFloat)barHeight;

#pragma mark - Background

//Stretches the view to fill the width, leaves the height as is and bottom aligns. View might stick out past the top of the tab bar, it doesn't clip... for shadows and cool designs.
-(void)setBarBackgroundView:(UIView *)barBackgroundView;
-(UIView *)barBackgroundView;

//Convenience setter for creating a backgroundView out of an image, stretches it to fill the width, and sets the height to the barHeight
-(void)setBarBackgroundImage:(UIImage *)barBackgroundImage;
//Returns the UIImage used to create the bg
-(UIImage *)barBackgroundImage;

#pragma mark - Retracting

//Shows or hides the tab bar, and shrinks or stretches the contentView respectively
-(void)show:(BOOL)shouldShowBar animated:(BOOL)shouldAnimate;

#pragma mark - View sizing behaviour

//Changes the resizing behaviour of the content view controller's view
-(void)setContentResizingMode:(GBRetractableTabBarContentResizingMode)contentResizingMode forViewController:(UIViewController *)viewController;

@end


@protocol GBRetractableTabBarDelegate <NSObject>
@optional

//Called when a control view is tapped
-(void)tabBar:(GBRetractableTabBar *)tabBar didTapOnControlViewWithIndex:(NSUInteger)index controlView:(UIView<GBRetractableTabBarControlView> *)controlView;

//Called when a control view is re-tapped (tapped when already active)
-(void)tabBar:(GBRetractableTabBar *)tabBar didReTapOnControlViewWithIndex:(NSUInteger)index controlView:(UIView<GBRetractableTabBarControlView> *)controlView;

//Called when a view controller is shown
-(void)tabBar:(GBRetractableTabBar *)tabBar didShowViewControllerWithIndex:(NSUInteger)index viewController:(UIViewController *)viewController;

//Called when a view controller is hidden
-(void)tabBar:(GBRetractableTabBar *)tabBar didHideViewControllerWithIndex:(NSUInteger)index viewController:(UIViewController *)viewController;

//Called when a view controller is replaced, essentially combines the above two for when you need to know them both within the same context
-(void)tabBar:(GBRetractableTabBar *)tabBar didReplaceViewControllerWithOldIndex:(NSUInteger)oldIndex oldViewController:(UIViewController *)oldViewController withViewControllerWithNewIndex:(NSUInteger)newIndex newViewController:(UIViewController *)newViewController;

//When you just want to know the new active index
-(void)tabBar:(GBRetractableTabBar *)tabBar didChangeActiveIndexFromOldIndex:(NSUInteger)oldIndex toNewIndex:(NSUInteger)newIndex;

//Lets you know when the tab bar was hidden/shown
-(void)tabBarDidHideTabBar:(GBRetractableTabBar *)tabBar animated:(BOOL)animated;
-(void)tabBarDidShowTabBar:(GBRetractableTabBar *)tabBar animated:(BOOL)animated;

//Lets the delegate decide whether it's OK to show the VC
-(BOOL)tabBar:(GBRetractableTabBar *)tabBar shouldShowViewController:(UIViewController *)viewController forControlView:(UIView<GBRetractableTabBarControlView> *)controlView withIndex:(NSUInteger)index;

@end

//adds some features for interacting with the UINavigationController
#import "GBRetractableTabBar+UINavigationController.h"


