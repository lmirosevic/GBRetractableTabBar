//
//  GBRetractableTabBarControlView.h
//  GBRetractableTabBar
//
//  Created by Luka Mirosevic on 17/05/2013.
//  Copyright (c) 2013 Goonbee. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol GBRetractableTabBarControlView <NSObject>
@required

//Can be any view but it has to be able to change its drawing state
-(void)setIsActive:(BOOL)isActive;
-(BOOL)isActive;

//Note: also make sure your views don't do any event handling, and let that pass through to the TabBar

@end
