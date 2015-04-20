//
//  MessageViewController.m
//  Messenger
//
//  Created by Ignacio Romero Zurbuchen on 8/15/14.
//  Copyright (c) 2014 Slack Technologies, Inc. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "SVProgressHUD.h"

#import "AppConstant.h"
#import "SharedData.h"

#import "MessageViewController.h"
#import "MessageTableViewCell.h"
#import "MessageTextView.h"

#import "Message.h"
#import "MessageThread.h"
#import "User.h"


static NSString *MessengerCellIdentifier = @"MessengerCell";

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


/*****************************************************************************/
#pragma mark - Instantiation
//*****************************************************************************/

- (id)init
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self) {
        // Register a subclass of SLKTextView, if you need any special appearance and/or behavior customisation.
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
    self.textInputbar.counterPosition = SLKCounterPositionTop;
    
    self.navigationItem.title = self.messageThread.title;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"New Message"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Message Removed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Thread Removed"
                                               object:nil];
    
    for (Message *message in self.messageThread.messages) {
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        UITableViewRowAnimation rowAnimation = UITableViewRowAnimationBottom;
        UITableViewScrollPosition scrollPosition = UITableViewScrollPositionBottom;
        
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
    if ([[notification name] isEqualToString:@"New Message"])
    {
        MessageThread *updatedMessageThread = notification.object;
        
        if (updatedMessageThread.messageThreadID == self.messageThread.messageThreadID)
        {
            dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
                
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                UITableViewRowAnimation rowAnimation = UITableViewRowAnimationBottom;
                UITableViewScrollPosition scrollPosition = UITableViewScrollPositionBottom;
                
                [self.tableView beginUpdates];
                [self.messages insertObject:[self.messageThread.messages lastObject] atIndex:0];
                [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
                [self.tableView endUpdates];
                
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                
            });
        }
    }
    else if ([[notification name] isEqualToString:@"Message Removed"])
    {
        Message *removedMessage = notification.object;
        [self.messages removeObject:removedMessage];
        [self.tableView reloadData];
    }
    else if ([[notification name] isEqualToString:@"Thread Removed"])
    {
        if ([notification.object isEqual:self.messageThread]) {
            [SVProgressHUD showInfoWithStatus:@"Thread Removed" maskType:SVProgressHUDMaskTypeBlack];
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
                                                        cancelButtonTitle:@"Cancel"
                                                   destructiveButtonTitle:@"Delete"
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
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"messages/%@", removedMessage.messageID]] removeValue];
    [[self.ref childByAppendingPath:[NSString stringWithFormat:@"message_threads/%@/messages/%@", self.messageThread.messageThreadID, removedMessage.messageID]] removeValue];
}


//*****************************************************************************/
#pragma mark - Overriden Methods
//*****************************************************************************/

- (void)didPressRightButton:(id)sender
{
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];
    
    Firebase *newMessage = [[self.ref childByAppendingPath:@"messages"] childByAutoId];
    
    NSDictionary *messageData = @{
                                  @"sender":self.user.userID,
                                  @"text":[self.textView.text copy],
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
    MessageTableViewCell *cell = (MessageTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:MessengerCellIdentifier];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteMessage:)];
    [cell addGestureRecognizer:longPress];
    
    dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
        
        Message *message = [self.messages objectAtIndex:indexPath.row];
        
        User *sender = message.sender;
        
        cell.titleLabel.text = [NSString stringWithFormat:@"%@ %@", sender.firstName, sender.lastName];
        cell.bodyLabel.text = message.text;
        
        cell.thumbnailView.image = sender.profileImage;
        cell.thumbnailView.layer.shouldRasterize = YES;
        cell.thumbnailView.layer.rasterizationScale = [UIScreen mainScreen].scale;
        
        cell.indexPath = indexPath;
        cell.usedForMessage = YES;
        
        // Cells must inherit the table view's transform
        // This is very important, since the main table view may be inverted
        cell.transform = self.tableView.transform;
        
    });
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView])
    {
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
        
        if (message.text.length == 0)
        {
            return 0.0;
        }
        
        CGFloat height = CGRectGetHeight(titleBounds);
        height += CGRectGetHeight(bodyBounds);
        height += 50.0;
        if (message.attachment)
        {
            height += 80.0 + 10.0;
        }
        
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
    // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you ovveride this method, to call super.
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
