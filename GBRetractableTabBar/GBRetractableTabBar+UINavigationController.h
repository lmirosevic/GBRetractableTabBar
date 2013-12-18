//
//  GBRetractableTabBar+UINavigationController.h
//  GBRetractableTabBar
//
//  Created by Luka Mirosevic on 12/07/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBRetractableTabBar.h"

//if you make your GBRetractableTabBar a delegate of UINavigationController, then it can handle some stuff like hiding the bar
@interface GBRetractableTabBar (UINavigationController) <UINavigationControllerDelegate>

@property (assign, nonatomic) BOOL      shouldRestoreBarWhenNavigating;

@end
