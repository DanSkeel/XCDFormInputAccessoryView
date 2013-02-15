//
//  XCDFormInputAccessoryView.m
//
//  Created by Cédric Luthi on 2012-11-10
//  Copyright (c) 2012 Cédric Luthi. All rights reserved.
//

#import "XCDFormInputAccessoryView.h"

// counting from right edge.
#define DONE_BUTTON_IDX 0
#define CLEAR_BUTTON_IDX (NSInteger)(self.hasDoneButton)

static NSString * UIKitLocalizedString(NSString *string)
{
	NSBundle *UIKitBundle = [NSBundle bundleForClass:[UIApplication class]];
	return UIKitBundle ? [UIKitBundle localizedStringForKey:string value:string table:nil] : string;
}

static NSArray * EditableTextInputsInView(UIView *view)
{
	NSMutableArray *textInputs = [NSMutableArray new];
	for (UIView *subview in view.subviews)
	{
		BOOL isTextField = [subview isKindOfClass:[UITextField class]];
		BOOL isEditableTextView = [subview isKindOfClass:[UITextView class]] && [(UITextView *)subview isEditable];
		if (isTextField || isEditableTextView)
			[textInputs addObject:subview];
		else
			[textInputs addObjectsFromArray:EditableTextInputsInView(subview)];
	}
	return textInputs;
}

@implementation XCDFormInputAccessoryView
{
	UIToolbar *_toolbar;
}

- (id) initWithFrame:(CGRect)frame
{
	return [self initWithResponders:nil];
}

- (id) initWithResponders:(NSArray *)responders
{
	if (!(self = [super initWithFrame:CGRectZero]))
		return nil;
	
	_responders = responders;
	
	_toolbar = [[UIToolbar alloc] init];
	_toolbar.tintColor = nil;
	_toolbar.barStyle = UIBarStyleBlack;
	_toolbar.translucent = YES;
	_toolbar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[ UIKitLocalizedString(@"Previous"), UIKitLocalizedString(@"Next") ]];
	[segmentedControl addTarget:self action:@selector(selectAdjacentResponder:) forControlEvents:UIControlEventValueChanged];
	segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
	segmentedControl.momentary = YES;
	UIBarButtonItem *segmentedControlBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	_toolbar.items = @[ segmentedControlBarButtonItem, flexibleSpace ];
	self.hasDoneButton = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone;
    self.hasClearButton = YES;
    
	[self addSubview:_toolbar];
	
	self.frame = _toolbar.frame = (CGRect){CGPointZero, [_toolbar sizeThatFits:CGSizeZero]};
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputDidBeginEditing:) name:UITextFieldTextDidBeginEditingNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputDidBeginEditing:) name:UITextViewTextDidBeginEditingNotification object:nil];
	
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) updateSegmentedControl
{
	NSArray *responders = self.responders;
	if ([responders count] == 0)
		return;
	
	UISegmentedControl *segmentedControl = (UISegmentedControl *)[_toolbar.items[0] customView];
	BOOL isFirst = [[responders objectAtIndex:0] isFirstResponder];
	BOOL isLast = [[responders lastObject] isFirstResponder];
	[segmentedControl setEnabled:!isFirst forSegmentAtIndex:0];
	[segmentedControl setEnabled:!isLast forSegmentAtIndex:1];
}

- (void) willMoveToWindow:(UIWindow *)window
{
	if (!window)
		return;
	
	[self updateSegmentedControl];
}

- (void) textInputDidBeginEditing:(NSNotification *)notification
{
	[self updateSegmentedControl];
}

- (NSArray *) responders
{
	if (_responders)
		return _responders;
	
	NSArray *textInputs = EditableTextInputsInView([[UIApplication sharedApplication] keyWindow]);
	return [textInputs sortedArrayUsingComparator:^NSComparisonResult(UIView *textInput1, UIView *textInput2) {
		UIView *commonAncestorView = textInput1.superview;
		while (commonAncestorView && ![textInput2 isDescendantOfView:commonAncestorView])
			commonAncestorView = commonAncestorView.superview;
		
		CGRect frame1 = [textInput1 convertRect:textInput1.bounds toView:commonAncestorView];
		CGRect frame2 = [textInput2 convertRect:textInput2.bounds toView:commonAncestorView];
		return [@(CGRectGetMinY(frame1)) compare:@(CGRectGetMinY(frame2))];
	}];
}

- (UIResponder *)currentResponder {
    for (UIResponder *responder in self.responders) {
        if ([responder isFirstResponder]) {
            return responder;
        }
    }
    return nil;
}

- (BOOL *)isEditing {
    return ([self currentResponder] != nil);
}

- (void) setHasDoneButton:(BOOL)hasDoneButton
{
	[self setHasDoneButton:hasDoneButton animated:NO];
}

- (void) setHasDoneButton:(BOOL)hasDoneButton animated:(BOOL)animated
{
	if (_hasDoneButton == hasDoneButton)
		return;
	
	[self willChangeValueForKey:@"hasDoneButton"];
	_hasDoneButton = hasDoneButton;
	[self didChangeValueForKey:@"hasDoneButton"];
	
	NSMutableArray *items = _toolbar.items.mutableCopy;
    NSInteger shift = DONE_BUTTON_IDX;
	if (hasDoneButton)
		[items insertObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)]
                    atIndex:items.count-shift];
	else
		[items removeObjectAtIndex:items.count-shift];
	
	[_toolbar setItems:items animated:animated];
}

- (void)setHasClearButton:(BOOL)hasClearButton {
 	if (_hasClearButton == hasClearButton)
		return;
	
	_hasClearButton = hasClearButton;
	
	NSMutableArray *items = _toolbar.items.mutableCopy;
    NSInteger shift = CLEAR_BUTTON_IDX;
	if (hasClearButton)
        [items insertObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(clear)]
                    atIndex:items.count-shift];
	else {
		[items removeObjectAtIndex:items.count-shift];
    }
	[_toolbar setItems:items];
}

#pragma mark - Actions

- (void) selectAdjacentResponder:(UISegmentedControl *)sender
{
	NSArray *firstResponders = [self.responders filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(UIResponder *responder, NSDictionary *bindings) {
		return [responder isFirstResponder];
	}]];
	UIResponder *firstResponder = [firstResponders lastObject];
	NSInteger offset = sender.selectedSegmentIndex == 0 ? -1 : +1;
	NSInteger firstResponderIndex = [self.responders indexOfObject:firstResponder];
	NSInteger adjacentResponderIndex = firstResponderIndex != NSNotFound ? firstResponderIndex + offset : NSNotFound;
	UIResponder *adjacentResponder = nil;
	if (adjacentResponderIndex >= 0 && adjacentResponderIndex < (NSInteger)[self.responders count])
		adjacentResponder = [self.responders objectAtIndex:adjacentResponderIndex];
	
	[adjacentResponder becomeFirstResponder];
}

- (void) done
{
	[[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
}

- (void)clear {
    UIResponder *currentResponder = [self currentResponder];
    if ([currentResponder respondsToSelector:@selector(setText:)]) {
        [currentResponder performSelector:@selector(setText:) withObject:@""];
    }
}

@end
