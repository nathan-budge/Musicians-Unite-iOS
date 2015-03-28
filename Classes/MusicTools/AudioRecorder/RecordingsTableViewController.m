//
//  RecordingsTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/26/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>

#import "RecordingsTableViewController.h"

#import "User.h"
#import "Group.h"
#import "Recording.h"

@interface RecordingsTableViewController ()

@property (nonatomic, retain) AVAudioPlayer *audioPlayer;

@end

@implementation RecordingsTableViewController

//*****************************************************************************/
#pragma mark - View Lifecycle
//*****************************************************************************/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
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
    if (self.group) {
        return self.group.recordings.count;
    } else if (self.user) {
        return self.user.recordings.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
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
        recording = [self.user.recordings objectAtIndex:indexPath.row];
    }
    
    cell.textLabel.text = recording.name;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //[self.audioPlayer stop];
    
    self.audioPlayer = nil;
    
    Recording *recording;
    
    if (self.group)
    {
        recording = [self.group.recordings objectAtIndex:indexPath.row];
    }
    else if (self.user)
    {
        recording = [self.user.recordings objectAtIndex:indexPath.row];
    }
    
    self.audioPlayer = [[AVAudioPlayer alloc] initWithData:recording.data error:nil];
    
    [self.audioPlayer play];
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
