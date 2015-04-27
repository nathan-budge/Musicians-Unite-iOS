//
//  RecordingsTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/26/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "CRToast.h"

#import "AppConstant.h"
#import "SharedData.h"
#import "Utilities.h"

#import "RecordingsTableViewController.h"
#import "RecordingTableViewController.h"

#import "User.h"
#import "Group.h"
#import "Recording.h"


@interface RecordingsTableViewController ()

@property (nonatomic) SharedData *sharedData;

@property (nonatomic) Recording *selectedRecording;
@property (nonatomic) Group *selectedRecordingGroup;

@property (nonatomic) NSMutableArray *groupNames;

@end


@implementation RecordingsTableViewController

//*****************************************************************************/
#pragma mark - Lazy Instantiation
//*****************************************************************************/

-(NSMutableArray *)groupNames
{
    if (!_groupNames) {
        _groupNames = [[NSMutableArray alloc] init];
    }
    return _groupNames;
}

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}


//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.group)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kNewGroupRecordingNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kGroupRecordingDataUpdatedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kGroupRecordingRemovedNotification
                                                   object:nil];
    }
    else
    {
        for (Group *group in self.sharedData.user.groups) {
            [self.groupNames addObject:group.name];
        }
        
        [self.groupNames insertObject:kUnassignedRecordingTitle atIndex:0];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kNewUserRecordingNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kUserRecordingDataUpdatedNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(receivedNotification:)
                                                     name:kUserRecordingRemovedNotification
                                                   object:nil];
    }
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:kNewUserRecordingNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            [self.tableView reloadData];
            
        });
    }
    else if ([[notification name] isEqualToString:kNewGroupRecordingNotification])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            
            NSArray *newRecordingData = notification.object;
            if ([[newRecordingData objectAtIndex:0] isEqual:self.group])
            {
                [self.tableView reloadData];
            }
            
        });
    }
    else if ([[notification name] isEqualToString:kUserRecordingDataUpdatedNotification])
    {
        [self.tableView reloadData];
    }
    else if ([[notification name] isEqualToString:kGroupRecordingDataUpdatedNotification])
    {
        NSArray *updatedRecordingData = notification.object;
        if ([[updatedRecordingData objectAtIndex:0] isEqual:self.group])
        {
            [self.tableView reloadData];
        }
    }
    else if ([[notification name] isEqualToString:kUserRecordingRemovedNotification])
    {
        [self.tableView reloadData];
        
        [Utilities redToastMessage:kRecordingRemovedSuccessMessage];
    }
    else if ([[notification name] isEqualToString:kGroupRecordingRemovedNotification])
    {
        NSArray *removedRecordingData = notification.object;
        if ([[removedRecordingData objectAtIndex:0] isEqual:self.group])
        {
            [self.tableView reloadData];
            
            [Utilities redToastMessage:kRecordingRemovedSuccessMessage];
        }
    }
}


//*****************************************************************************/
#pragma mark - Table view data source
//*****************************************************************************/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.group || self.sharedData.user.recordings.count == 0)
    {
        return 1;
    }
    else
    {
        return self.sharedData.user.groups.count + 1;
    }
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.group)
    {
        if (self.group.recordings.count == 0)
        {
            return @"No Recordings";
        }
    }
    else
    {
        if (self.sharedData.user.recordings.count == 0 )
        {
            return @"No Recordings";
        }
        else
        {
            if (section == 0)
            {
                return kUnassignedRecordingTitle;
            }
            else
            {
                Group *group = [self.sharedData.user.groups objectAtIndex:section - 1];
                return group.name;
            }
        }
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.group)
    {
        return self.group.recordings.count;
    }
    else
    {
        if (section == 0)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", self.sharedData.user.userID];
            NSArray *recordings = [self.sharedData.user.recordings filteredArrayUsingPredicate:predicate];
            
            return recordings.count;
        }
        else
        {
            Group *group = [self.sharedData.user.groups objectAtIndex:section - 1];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", group.groupID];
            NSArray *recordings = [self.sharedData.user.recordings filteredArrayUsingPredicate:predicate];
            
            return recordings.count;
        }
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGenericCellIdentifier];
    
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kGenericCellIdentifier];
    }
    
    Recording *recording;
    
    if (self.group)
    {
        recording = [self.group.recordings objectAtIndex:indexPath.row];
    }
    else
    {
        if (indexPath.section == 0)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", self.sharedData.user.userID];
            NSArray *recordings = [self.sharedData.user.recordings filteredArrayUsingPredicate:predicate];
            
            recording = [recordings objectAtIndex:indexPath.row];
        }
        else
        {
            Group *group = [self.sharedData.user.groups objectAtIndex:indexPath.section - 1];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", group.groupID];
            NSArray *recordings = [self.sharedData.user.recordings filteredArrayUsingPredicate:predicate];
            
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
    }
    else
    {
        self.selectedRecordingGroup = nil;
        if (indexPath.section == 0)
        {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", self.sharedData.user.userID];
            NSArray *recordings = [self.sharedData.user.recordings filteredArrayUsingPredicate:predicate];
            
            self.selectedRecording = [recordings objectAtIndex:indexPath.row];
        }
        else
        {
            Group *group = [self.sharedData.user.groups objectAtIndex:indexPath.section - 1];
            
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.ownerID=%@", group.groupID];
            NSArray *recordings = [self.sharedData.user.recordings filteredArrayUsingPredicate:predicate];
            
            self.selectedRecording = [recordings objectAtIndex:indexPath.row];
        }
    }
    
    [self performSegueWithIdentifier:kRecordingSegueIdentifier sender:self];
}


//*****************************************************************************/
#pragma mark - Navigation
//*****************************************************************************/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:kRecordingSegueIdentifier])
    {
        RecordingTableViewController *destViewController = segue.destinationViewController;
        destViewController.recording = self.selectedRecording;
        destViewController.group = self.selectedRecordingGroup;
    }
}


@end
