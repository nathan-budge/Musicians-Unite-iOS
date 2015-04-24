//
//  MessageViewController.m
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "CRToast.h"

#import "AppConstant.h"
#import "SharedData.h"
#import "Utilities.h"

#import "MessageViewController.h"
#import "MessageTableViewCell.h"
#import "MessageTextView.h"

#import "Message.h"
#import "MessageThread.h"
#import "User.h"
#import "Group.h"


@interface MessageViewController ()

@property (nonatomic) Firebase *ref;
@property (nonatomic) Firebase *messageThreadRef;

@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic) SharedData *sharedData;

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
        _messageThreadRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@", kMessageThreadsFirebaseNode, self.messageThread.messageThreadID, kMessagesFirebaseNode]];
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


/*****************************************************************************/
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
    [self.tableView registerClass:[MessageTableViewCell class] forCellReuseIdentifier:kMessageCellIdentifier];
    
    [self.rightButton setTitle:kSendButtonTitle forState:UIControlStateNormal];
    
    self.textInputbar.autoHideRightButton = YES;
    self.textInputbar.maxCharCount = 256;
    self.textInputbar.counterStyle = SLKCounterStyleSplit;
    self.textInputbar.counterPosition = SLKCounterPositionTop;
    
    self.navigationItem.title = self.messageThread.title;
    
    for (Message *message in self.messageThread.messages) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        UITableViewRowAnimation rowAnimation = UITableViewRowAnimationBottom;
        UITableViewScrollPosition scrollPosition = UITableViewScrollPositionBottom;
        
        [self.tableView beginUpdates];
        
        [self.messages insertObject:message atIndex:0];
        [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
        
        [self.tableView endUpdates];
        
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
        
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kNewMessageNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kMessageRemovedNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:kMessageThreadRemovedNotification
                                               object:nil];
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kNewMessageNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            NSArray *newMessageData = notification.object;
            if ([[newMessageData objectAtIndex:0] isEqual:self.messageThread])
            {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                UITableViewRowAnimation rowAnimation = UITableViewRowAnimationBottom;
                UITableViewScrollPosition scrollPosition = UITableViewScrollPositionBottom;
                
                [self.tableView beginUpdates];
                
                Message *newMessage = [newMessageData objectAtIndex:1];
                [self.messages insertObject:newMessage atIndex:0];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
                
                [self.tableView endUpdates];
                
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
            
        });
    }
    else if ([[notification name] isEqualToString:kMessageRemovedNotification])
    {
        NSArray *removedMessageData = notification.object;
        if ([[removedMessageData objectAtIndex:0] isEqual:self.messageThread])
        {
            Message *removedMessage = [removedMessageData objectAtIndex:1];
            [self.messages removeObject:removedMessage];
            [self.tableView reloadData];
        }
    }
    else if ([[notification name] isEqualToString:kMessageThreadRemovedNotification])
    {
        NSArray *removedThreadData = notification.object;
        if ([[removedThreadData objectAtIndex:1] isEqual:self.messageThread])
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}


//*****************************************************************************/
#pragma mark - Action Methods
//*****************************************************************************/

- (void)deleteMessage:(UIGestureRecognizer *)gesture
{
    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateBegan) {
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                 delegate:self
                                                        cancelButtonTitle:kCancelButtonTitle
                                                   destructiveButtonTitle:kDeleteButtonTitle
                                                        otherButtonTitles: nil];
        
        MessageTableViewCell *cell = (MessageTableViewCell *)gesture.view;
        actionSheet.tag = cell.indexPath.row;
        [actionSheet showInView:gesture.view];
    }
}


//*****************************************************************************/
#pragma mark - UIActionSheet Methods
//*****************************************************************************/

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self removeMessage:actionSheet.tag];
            break;
        default:
            break;
    }
}

- (void)removeMessage:(NSInteger)row
{
    Message *removedMessage = [self.messages objectAtIndex:row];
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@", kMessagesFirebaseNode, removedMessage.messageID]] removeValue];
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"%@/%@/%@/%@", kMessageThreadsFirebaseNode, self.messageThread.messageThreadID, kMessagesFirebaseNode, removedMessage.messageID]] removeValue];
    
    [Utilities redToastMessage:kMessageRemovedSuccessMessage];
}


//*****************************************************************************/
#pragma mark - Overriden Methods
//*****************************************************************************/

- (void)didPressRightButton:(id)sender
{
    [self.textView refreshFirstResponder];
    
    Firebase *newMessage = [[self.ref childByAppendingPath:kMessagesFirebaseNode] childByAutoId];
    
    NSDictionary *messageData = @{
                                  kMessageSenderFirebaseField:self.sharedData.user.userID,
                                  kMessageTextFirebaseField:[self.textView.text copy],
                                  };
    
    [newMessage setValue:messageData];
    
    [self.messageThreadRef updateChildValues:@{newMessage.key:@YES}];
    
    [super didPressRightButton:sender];
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
    MessageTableViewCell *cell = (MessageTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:kMessageCellIdentifier];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteMessage:)];
    [cell addGestureRecognizer:longPress];
    
    Message *message = [self.messages objectAtIndex:indexPath.row];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", message.senderID];
    NSArray *member = [self.group.members filteredArrayUsingPredicate:predicate];
    
    User *sender;
    if (member.count > 0)
    {
        sender = [member objectAtIndex:0];
    }
    else
    {
        sender = self.sharedData.user;
    }
    
    
    cell.titleLabel.text = [NSString stringWithFormat:@"%@ %@", sender.firstName, sender.lastName];
    cell.bodyLabel.text = message.text;
    
    cell.thumbnailView.image = sender.profileImage;
    cell.thumbnailView.layer.shouldRasterize = YES;
    cell.thumbnailView.layer.rasterizationScale = [UIScreen mainScreen].scale;
    
    cell.indexPath = indexPath;
    cell.usedForMessage = YES;
    
    cell.transform = self.tableView.transform;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView])
    {
        Message *message = [self.messages objectAtIndex:indexPath.row];
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.userID=%@", message.senderID];
        NSArray *member = [self.group.members filteredArrayUsingPredicate:predicate];
        
        User *sender;
        if (member.count > 0)
        {
            sender = [member objectAtIndex:0];
        }
        else
        {
            sender = self.sharedData.user;
        }
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16.0],
                                     NSParagraphStyleAttributeName: paragraphStyle};
        
        CGFloat width = CGRectGetWidth(tableView.frame)-kAvatarSize;
        width -= 25.0;
        
        CGRect titleBounds = [sender.firstName boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        CGRect bodyBounds = [message.text boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        
        if (message.text.length == 0)
        {
            return 0.0;
        }
        
        CGFloat height = CGRectGetHeight(titleBounds);
        height += CGRectGetHeight(bodyBounds);
        height += 50.0;
        
        if (height < kMinimumHeight)
        {
            height = kMinimumHeight;
        }
        
        return height;
    }
    else
    {
        return kMinimumHeight;
    }
}


//*****************************************************************************/
#pragma mark - UIScrollViewDelegate Methods
//*****************************************************************************/

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [super scrollViewDidScroll:scrollView];
}

- (BOOL)textView:(SLKTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return [super textView:textView shouldChangeTextInRange:range replacementText:text];
}

- (void)textViewDidChangeSelection:(SLKTextView *)textView
{
    [super textViewDidChangeSelection:textView];
}

@end
