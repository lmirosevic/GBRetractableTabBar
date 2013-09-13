//
//  GBRetractableTabBar+UINavigationController.m
//  GBRetractableTabBar
//
//  Created by Luka Mirosevic on 12/07/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import "GBRetractableTabBar+UINavigationController.h"

#import <objc/runtime.h>

static BOOL const kDefaultShouldRestoreBarWhenNavigating = YES;

@implementation GBRetractableTabBar (UINavigationController)

#pragma mark - ca

static char gb_shouldRestoreBarWhenNavigating_key;

-(void)setShouldRestoreBarWhenNavigating:(BOOL)shouldRestoreBarWhenNavigating {
    objc_setAssociatedObject(self, &gb_shouldRestoreBarWhenNavigating_key, @(shouldRestoreBarWhenNavigating), OBJC_ASSOCIATION_ASSIGN);
}

-(BOOL)shouldRestoreBarWhenNavigating {
    id associatedObject = objc_getAssociatedObject(self, &gb_shouldRestoreBarWhenNavigating_key);
    if (associatedObject) {
        return [associatedObject boolValue];
    }
    else {
        return YES;
    }
}

#pragma mark - UINavigationControllerDelegate

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.shouldRestoreBarWhenNavigating) {
//        //we can be delegate to many at the same time, but we should only response to changes in the active one. if another one is programatically popped which isn't active, we don't want it to mess with our tab bar
//        if (self.activeViewController == navigationController) {
            [self show:YES animated:YES];
//        }
    }
}

@end
