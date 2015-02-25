//
//  MessagingTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 2/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "MessagingTableViewController.h"
#import "NewMessageTableViewController.h"
#import "MessageViewController.h"

#import "Group.h"
#import "User.h"
#import "MessageThread.h"

@interface MessagingTableViewController ()

@property (nonatomic) MessageThread *selectedMessageThread;

@end


@implementation MessagingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tabBarController.title = @"Messages";
    self.tabBarController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionNewGroup)];
    
    [self.tableView reloadData];
}



#pragma mark - Buttons

-(void)actionNewGroup
{
    [self performSegueWithIdentifier:@"newMessage" sender:self];
}



#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.group.messageThreads count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    MessageThread *messageThread = [self.group.messageThreads objectAtIndex:indexPath.row];
   
    NSMutableString *title = [[NSMutableString alloc] init];
    if ([messageThread.members count] == 1) {
        
        [title appendString:@"You and "];
        
        User *member = [messageThread.members objectAtIndex:0];
        
        if (member.completedRegistration) {
            [title appendString:[NSString stringWithFormat:@"%@ %@", member.firstName, member.lastName]];
        } else {
            [title appendString:[NSString stringWithFormat:@"%@",member.email]];
        }
    } else {
        
        [title appendString:@"You, "];
        
        for (int i = 0; i < [messageThread.members count]; i++) {
            
            User *member = [messageThread.members objectAtIndex:i];
            
            if (i == ([messageThread.members count] - 1)) {
                if (member.completedRegistration) {
                    [title appendString:[NSString stringWithFormat:@"and %@ %@", member.firstName, member.lastName]];
                } else {
                    [title appendString:[NSString stringWithFormat:@"and %@",member.email]];
                }
            } else {
                if (member.completedRegistration) {
                    [title appendString:[NSString stringWithFormat:@"%@ %@, ", member.firstName, member.lastName]];
                } else {
                    [title appendString:[NSString stringWithFormat:@"%@, ",member.email]];
                }
            }
        }
    }
    
    cell.textLabel.text = title;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedMessageThread = [self.group.messageThreads objectAtIndex:indexPath.row];
    
    [self performSegueWithIdentifier:@"viewThread" sender:nil];
}



#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"newMessage"]) {
        NewMessageTableViewController *destViewController = segue.destinationViewController;
        destViewController.group = self.group;
    } else if ([segue.identifier isEqualToString:@"viewThread"]) {
        MessageViewController *destViewController = segue.destinationViewController;
        destViewController.messageThread = self.selectedMessageThread;
    }
}


@end
