//
//  XCDFormInputAccessoryView.h
//
//  Created by Cédric Luthi on 2012-11-10
//  Copyright (c) 2012 Cédric Luthi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XCDFormInputAccessoryView : UIView

- (id) initWithResponders:(NSArray *)responders; // Objects must be UIResponder instances

@property (nonatomic, strong) NSArray *responders;

@property (nonatomic, assign) BOOL *isEditing; // if some of responders is firstResponder

@property (nonatomic, assign) BOOL hasDoneButton; // Defaults to YES on iPhone, NO on iPad

@property (nonatomic, assign) BOOL hasClearButton;

- (void) setHasDoneButton:(BOOL)hasDoneButton animated:(BOOL)animated;

@end
