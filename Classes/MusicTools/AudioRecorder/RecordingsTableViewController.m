//
//  RecordingsTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/26/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "RecordingsTableViewController.h"
#import "RecordingTableViewController.h"

#import "User.h"
#import "Group.h"
#import "Recording.h"

@interface RecordingsTableViewController ()

@property (nonatomic) Recording *selectedRecording;
@property (nonatomic) User *selectedRecordingUser;
@property (nonatomic) Group *selectedRecordingGroup;

@end

@implementation RecordingsTableViewController

//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Recording Data Updated"
                                               object:nil];
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Recording Data Updated"])
    {
        [self.tableView reloadData];
    }
}


//*****************************************************************************/
#pragma mark - Table view data source
//*****************************************************************************/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.user)
    {
        return self.user.groups.count + 1;
    }
    else if (self.group)
    {
        return 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.user)
    {
        NSString *sectionName;
        if (section == 0) {
            sectionName = @"Unassigned";
            
        } else {
            Group *group = [self.user.groups objectAtIndex:section - 1];
            sectionName = group.name;
        }
        return sectionName;
    }
    
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.group) {
        return self.group.recordings.count;
    } else if (self.user) {
        
        if (section == 0)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", self.user.userID];
            NSArray *recordings = [self.user.recordings filteredArrayUsingPredicate:predicate];
            
            return recordings.count;
            
        }
        else
        {
            Group *group = [self.user.groups objectAtIndex:section - 1];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", group.groupID];
            NSArray *recordings = [self.user.recordings filteredArrayUsingPredicate:predicate];
            
            return recordings.count;
        }
    }
    
    return 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
    }
    
    Recording *recording;
    
    if (self.group)
    {
        recording = [self.group.recordings objectAtIndex:indexPath.row];
        
    }
    else if (self.user)
    {
        if (indexPath.section == 0)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", self.user.userID];
            NSArray *recordings = [self.user.recordings filteredArrayUsingPredicate:predicate];
            
            recording = [recordings objectAtIndex:indexPath.row];
        }
        else
        {
            Group *group = [self.user.groups objectAtIndex:indexPath.section - 1];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", group.groupID];
            NSArray *recordings = [self.user.recordings filteredArrayUsingPredicate:predicate];
            
            recording = [recordings objectAtIndex:indexPath.row];
        }
        
    }
    
    cell.textLabel.text = recording.name;
    
    return cell;
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.group)
    {
        self.selectedRecording = [self.group.recordings objectAtIndex:indexPath.row];
        self.selectedRecordingGroup = self.group;
        self.selectedRecordingUser = nil;
    }
    else if (self.user)
    {
        self.selectedRecordingUser = self.user;
        if (indexPath.section == 0)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", self.user.userID];
            NSArray *recordings = [self.user.recordings filteredArrayUsingPredicate:predicate];
            
            self.selectedRecording = [recordings objectAtIndex:indexPath.row];
            self.selectedRecordingGroup = nil;
        }
        else
        {
            Group *group = [self.user.groups objectAtIndex:indexPath.section - 1];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", group.groupID];
            NSArray *recordings = [self.user.recordings filteredArrayUsingPredicate:predicate];
            
            self.selectedRecording = [recordings objectAtIndex:indexPath.row];
            self.selectedRecordingGroup = group;
        }
    }
    
    [self performSegueWithIdentifier:@"viewRecording" sender:self];
}


//*****************************************************************************/
#pragma mark - Navigation
//*****************************************************************************/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"viewRecording"])
    {
        RecordingTableViewController *destViewController = segue.destinationViewController;
        destViewController.recording = self.selectedRecording;
        
        destViewController.group = self.selectedRecordingGroup;
        destViewController.user = self.selectedRecordingUser;
    }
}


@end
