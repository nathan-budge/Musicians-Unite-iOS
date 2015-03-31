//
//  MessageViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//
//  Adapted from https://github.com/slackhq/SlackTextViewController/blob/master/Examples/Messenger/Messenger-Shared/MessageViewController.m
//

#import <Firebase/Firebase.h>

#import "AppConstant.h"
#import "Utilities.h"
#import "SharedData.h"

#import "MessageViewController.h"
#import "MessageTableViewCell.h"
#import "MessageTextView.h"

#import "Message.h"
#import "MessageThread.h"
#import "Group.h"
#import "User.h"

static NSString *MessengerCellIdentifier = @"MessengerCell";
static NSString *AutoCompletionCellIdentifier = @"AutoCompletionCell";

@interface MessageViewController ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *messageThreadRef;

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic) SharedData *sharedData;

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *emojis;

@property (nonatomic, strong) NSArray *searchResult;

@end


@implementation MessageViewController

//*****************************************************************************/
#pragma mark - Lazy Instantiation
//*****************************************************************************/

-(Firebase *)ref
{
    if (!_ref) {
        _ref = [[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    
    return _ref;
}

-(Firebase *)messageThreadRef
{
    if (!_messageThreadRef) {
        _messageThreadRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"message_threads/%@/messages", self.messageThread.messageThreadID]];
    }
    
    return _messageThreadRef;
}

-(NSMutableArray *)messages
{
    if (!_messages) {
        _messages = [[NSMutableArray alloc] init];
    }
    
    return _messages;
}

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}


//*****************************************************************************/
#pragma mark - Instantiation
//*****************************************************************************/

- (id)init
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self) {
        [self registerClassForTextView:[MessageTextView class]];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self registerClassForTextView:[MessageTextView class]];
    }
    return self;
}

+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.bounces = YES;
    self.shakeToClearEnabled = YES;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = NO;
    self.inverted = YES;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[MessageTableViewCell class] forCellReuseIdentifier:MessengerCellIdentifier];
    
    [self.rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    
    self.textInputbar.autoHideRightButton = YES;
    self.textInputbar.maxCharCount = 256;
    self.textInputbar.counterStyle = SLKCounterStyleSplit;
    
    self.typingIndicatorView.canResignByTouch = YES;

    
    NSMutableString *title = [[NSMutableString alloc] init];
    if ([self.messageThread.members count] == 1) {
        User *member = [self.messageThread.members objectAtIndex:0];
        [title appendString:[NSString stringWithFormat:@"%@", member.firstName]];
        
    } else if ([self.messageThread.members count] == 2){
        for (int i = 0; i < [self.messageThread.members count]; i++) {
            
            User *member = [self.messageThread.members objectAtIndex:i];
            
            if (i == ([self.messageThread.members count] - 1)) {
                [title appendString:[NSString stringWithFormat:@"and %@", member.firstName]];
                
            } else {
                [title appendString:[NSString stringWithFormat:@"%@ ", member.firstName]];
                
            }
        }
        
    } else {
        for (int i = 0; i < [self.messageThread.members count]; i++) {
            
            User *member = [self.messageThread.members objectAtIndex:i];
            
            if (i == ([self.messageThread.members count] - 1)) {
                [title appendString:[NSString stringWithFormat:@"and %@", member.firstName]];
                
            } else {
                [title appendString:[NSString stringWithFormat:@"%@, ", member.firstName]];
                
            }
        }

    }
    
    self.navigationItem.title = title;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Message Data Updated"
                                               object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    for (Message *message in self.messageThread.messages) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        UITableViewRowAnimation rowAnimation = self.inverted ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop;
        UITableViewScrollPosition scrollPosition = self.inverted ? UITableViewScrollPositionBottom : UITableViewScrollPositionTop;
        
        [self.tableView beginUpdates];
        [self.messages insertObject:message atIndex:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
        [self.tableView endUpdates];
        
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
        
        // Fixes the cell from blinking (because of the transform, when using translucent cells)
        // See https://github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Message Data Updated"])
    {
        MessageThread *updatedMessageThread = notification.object;
        if (updatedMessageThread.messageThreadID == self.messageThread.messageThreadID) {
            dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
               
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                UITableViewRowAnimation rowAnimation = self.inverted ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop;
                UITableViewScrollPosition scrollPosition = self.inverted ? UITableViewScrollPositionBottom : UITableViewScrollPositionTop;
                
                [self.tableView beginUpdates];
                [self.messages insertObject:[self.messageThread.messages lastObject] atIndex:0];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
                [self.tableView endUpdates];
                
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            });
        }
    }
}


//*****************************************************************************/
#pragma mark - Action Methods
//*****************************************************************************/

- (void)editCellMessage:(UIGestureRecognizer *)gesture
{
    MessageTableViewCell *cell = (MessageTableViewCell *)gesture.view;
    Message *message = self.messages[cell.indexPath.row];
    
    [self editText:message.text];
    
    [self.tableView scrollToRowAtIndexPath:cell.indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}


- (void)editOrDeleteMessage:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:@"Delete"
                                                        otherButtonTitles: nil];
        
        MessageTableViewCell *cell = (MessageTableViewCell *)gesture.view;
        actionSheet.tag = cell.indexPath.row;
        [actionSheet showInView:gesture.view];
    }
}


//*****************************************************************************/
#pragma mark - Overriden Methods
//*****************************************************************************/

- (void)didChangeKeyboardStatus:(SLKKeyboardStatus)status
{
    // Notifies the view controller that the keyboard changed status.
}

- (void)textWillUpdate
{
    // Notifies the view controller that the text will update.

    [super textWillUpdate];
}

- (void)textDidUpdate:(BOOL)animated
{
    // Notifies the view controller that the text did update.

    [super textDidUpdate:animated];
}

- (void)didPressLeftButton:(id)sender
{
    [super didPressLeftButton:sender];
}

- (void)didPressRightButton:(id)sender
{
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];
    
    Message *message = [Message new];
    message.sender = self.user;
    message.text = [self.textView.text copy];
    
    Firebase *newMessage = [[self.ref childByAppendingPath:@"messages"] childByAutoId];
    
    NSDictionary *messageData = @{
                                  @"sender":self.user.userID,
                                  @"text":message.text,
                                  };
    
    [newMessage setValue:messageData];
    
    [self.messageThreadRef updateChildValues:@{newMessage.key:@YES}];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewRowAnimation rowAnimation = self.inverted ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop;
    UITableViewScrollPosition scrollPosition = self.inverted ? UITableViewScrollPositionBottom : UITableViewScrollPositionTop;

    [self.tableView beginUpdates];
    [self.messages insertObject:message atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
    [self.tableView endUpdates];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
    
    // Fixes the cell from blinking (because of the transform, when using translucent cells)
    // See https://github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [super didPressRightButton:sender];
}


- (NSString *)keyForTextCaching
{
    return [[NSBundle mainBundle] bundleIdentifier];
}


- (void)willRequestUndo
{
    // Notifies the view controller when a user did shake the device to undo the typed text
    
    [super willRequestUndo];
}

- (BOOL)canPressRightButton
{
    return [super canPressRightButton];
}


//*****************************************************************************/
#pragma mark - Table view data source
//*****************************************************************************/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self messageCellForRowAtIndexPath:indexPath];
}

- (MessageTableViewCell *)messageCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MessageTableViewCell *cell = (MessageTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:MessengerCellIdentifier];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(editOrDeleteMessage:)];
    [cell addGestureRecognizer:longPress];
    
    if (!cell.textLabel.text) {
        
    }
    
    Message *message = self.messages[indexPath.row];
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@ %@", message.sender.firstName, message.sender.lastName];
    cell.bodyLabel.text = message.text;
    
    cell.tumbnailView.image = message.sender.profileImage;
    cell.tumbnailView.layer.shouldRasterize = YES;
    cell.tumbnailView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    cell.indexPath = indexPath;
    cell.usedForMessage = YES;
    
    // Cells must inherit the table view's transform
    // This is very important, since the main table view may be inverted
    cell.transform = self.tableView.transform;
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]) {
        Message *message = self.messages[indexPath.row];
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                     NSParagraphStyleAttributeName: paragraphStyle};
        
        CGFloat width = CGRectGetWidth(tableView.frame)-kAvatarSize;
        width -= 25.0;
        
        CGRect titleBounds = [message.sender.firstName boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        CGRect bodyBounds = [message.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        
        if (message.text.length == 0) {
            return 0.0;
        }
        
        CGFloat height = CGRectGetHeight(titleBounds);
        height += CGRectGetHeight(bodyBounds);
        height += 40.0;
        if (message.attachment) {
            height += 80.0 + 10.0;
        }
        
        if (height < kMinimumHeight) {
            height = kMinimumHeight;
        }
        
        return height;
    }
    else {
        return kMinimumHeight;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:self.autoCompletionView]) {
        UIView *topView = [UIView new];
        topView.backgroundColor = self.autoCompletionView.separatorColor;
        return topView;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if ([tableView isEqual:self.autoCompletionView]) {
        return 0.5;
    }
    return 0.0;
}


//*****************************************************************************/
#pragma mark - UIScrollViewDelegate Methods
//*****************************************************************************/

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you ovveride this method, to call super.
    [super scrollViewDidScroll:scrollView];
}


/** UITextViewDelegate */
- (BOOL)textView:(SLKTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return [super textView:textView shouldChangeTextInRange:range replacementText:text];
}

- (void)textViewDidChangeSelection:(SLKTextView *)textView
{
    [super textViewDidChangeSelection:textView];
}


-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            [self removeMessage:actionSheet.tag];
            break;
        case 1:
            //[self editCellMessage:];
            break;
        default:
            break;
    }
    
}

- (void)removeMessage:(NSInteger)row
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    
    Message *removedMessage = [self.messages objectAtIndex:row];
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"messages/%@", removedMessage.messageID]] removeValue];
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"message_threads/%@/messages/%@", self.messageThread.messageThreadID, removedMessage.messageID]] removeValue];
    
    [self.messages removeObjectAtIndex:row];
    [self.messageThread.messages removeObject:removedMessage];
    
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
}


@end
