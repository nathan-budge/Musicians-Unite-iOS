//
//  TasksTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import "UIViewController+ECSlidingViewController.h"

#import "TasksTableViewController.h"
#import "TaskViewController.h"
#import "NavigationDrawerViewController.h"

#import "User.h"
#import "Task.h"

@interface TasksTableViewController ()

@property (nonatomic) User *user;

@property (nonatomic) Task *selectedTask;

@end

@implementation TasksTableViewController

//*****************************************************************************/
#pragma mark - View lifecycle
//*****************************************************************************/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NavigationDrawerViewController *navigationDrawerViewController = (NavigationDrawerViewController *)self.slidingViewController.underLeftViewController;
    self.user = navigationDrawerViewController.user;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionCheckbox:(id)sender
{
    //Adapted from http://stackoverflow.com/questions/11936126/how-to-pass-uitableview-indexpath-to-uibutton-selector-by-parameters-in-ios
    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    
    Task *task = [self.user.tasks objectAtIndex:indexPath.row];
    
    task.completed = !task.completed;
    
    if (task.completed) {
        [self.user.tasks removeObject:task];
        [self.user.tasks insertObject:task atIndex:0];
        [self.tableView reloadData];
    } else {
        [self.user.tasks removeObject:task];
        [self.user.tasks addObject:task];
        [self.tableView reloadData];
    }
}

- (IBAction)actionNewTask:(id)sender
{
    self.selectedTask = nil;
    [self performSegueWithIdentifier:@"taskDetail" sender:nil];
}


//*****************************************************************************/
#pragma mark - Table view data source
//*****************************************************************************/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.user.tasks.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell"];
    
    Task *task = [self.user.tasks objectAtIndex:indexPath.row];
    
    UIButton *checkbox = (UIButton *)[cell viewWithTag:1];
    UILabel *taskTitle = (UILabel *)[cell viewWithTag:2];
    
    if (task.completed) {
        [checkbox setImage:[UIImage imageNamed:@"checkbox"] forState:UIControlStateNormal];
    } else {
        [checkbox setImage:[UIImage imageNamed:@"checkbox_completed"] forState:UIControlStateNormal];
    }
    
    taskTitle.text = task.title;
    
    return cell;
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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedTask = [self.user.tasks objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"taskDetail" sender:nil];
}


//*****************************************************************************/
#pragma mark - Navigation
//*****************************************************************************/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"taskDetail"]) {
        TaskViewController *destViewController = segue.destinationViewController;
        destViewController.task = self.selectedTask;
    }
}


@end
