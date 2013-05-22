//
//  GBRetractableTabBar.h
//  GBRetractableTabBar
//
//  Created by Luka Mirosevic on 17/05/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol GBRetractableTabBarView;
@protocol GBRetractableTabBarDelegate;

@interface GBRetractableTabBar : UIViewController

@property (assign, nonatomic) CGFloat   barHeight;
@property (strong, nonatomic) UIView    *barBackgroundView;
@property (strong, nonatomic) UIImage   *barBackgroundImage;

#pragma mark - Init

//Designated initialiser
-(id)initWithTabBarHeight:(CGFloat)tabBarHeight;

#pragma mark - Control Views
//Views added must all conform to the protocol but can be any subclass of UIView. Make sure they don't handle events in the responder chain, so that these may bubble down to the tab bar

//Add a view to the end. The view is centered vertically and spaced evenly horizontally with all the other views
-(void)addControlView:(UIView<GBRetractableTabBarView> *)view;

//Places a view at a specific position. You can set arbitrary indexes at arbitrary orders and it will work itself out. It doesn't follow NSArray semantics where you can only add to the end.
-(void)insertControlView:(UIView<GBRetractableTabBarView> *)view atIndex:(NSUInteger)index;

//Removes a view, if it leaves a sparse list, no prob
-(void)removeControlViewAtIndex:(NSUInteger)index;

//Removes all views
-(void)removeAllControlViews;

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

//Convenience setter that saves you from creating your own UIImageView
-(void)setBarBackgroundImage:(UIImage *)barBackgroundImage;
//Returns the UIImage used to create the bg
-(UIImage *)barBackgroundImage;

#pragma mark - Retracting

//Shows or hides the tab bar, and shrinks or stretches the contentView respectively
-(void)show:(BOOL)shouldShow animated:(BOOL)shouldAnimate;

@end


@protocol GBRetractableTabBarDelegate <NSObject>
@optional

//Called when a view controller is shown
-(void)tabBar:(GBRetractableTabBar *)tabBar didShowViewControllerWithIndex:(NSUInteger)index viewController:(UIViewController *)viewController;

//Called when a view controller is hidden
-(void)tabBar:(GBRetractableTabBar *)tabBar didHideViewControllerWithIndex:(NSUInteger)index viewController:(UIViewController *)viewController;

//Called when a view controller is replaced, essentially combines the above two for when you need to know them both within the same context
-(void)tabBar:(GBRetractableTabBar *)tabBar didReplaceViewControllerWithOldIndex:(NSUInteger)oldIndex oldViewController:(UIViewController *)oldViewController withViewControllerWithNewIndex:(NSUInteger)newIndex newViewController:(UIViewController *)newViewController;

@end