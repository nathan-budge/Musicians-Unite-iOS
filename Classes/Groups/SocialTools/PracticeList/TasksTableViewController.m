//
//  TasksTableViewController.m
//  Musicians-Unite-iOS
//
//  Created by Nathan Budge on 3/22/15.
//  Copyright (c) 2015 CWRU. All rights reserved.
//

#import <Firebase/Firebase.h>
#import "UIViewController+ECSlidingViewController.h"

#import "TasksTableViewController.h"
#import "TaskViewController.h"

#import "AppConstant.h"
#import "SharedData.h"

#import "User.h"
#import "Task.h"
#import "Group.h"


@interface TasksTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) User *user;

@property (nonatomic) Task *selectedTask;
@property (nonatomic) NSMutableArray *incompleteTasks;
@property (nonatomic) NSMutableArray *completedTasks;

@property (nonatomic) SharedData *sharedData;

@end


@implementation TasksTableViewController

//*****************************************************************************/
#pragma mark - Lazy instantiation
//*****************************************************************************/

-(Firebase *)ref
{
    if(!_ref){
        _ref =[[Firebase alloc] initWithUrl:FIREBASE_URL];
    }
    return _ref;
}

-(NSMutableArray *)incompleteTasks
{
    if (!_incompleteTasks) {
        _incompleteTasks = [[NSMutableArray alloc] init];
    }
    return _incompleteTasks;
}

-(NSMutableArray *)completedTasks
{
    if (!_completedTasks) {
        _completedTasks = [[NSMutableArray alloc] init];
    }
    return _completedTasks;
}

-(SharedData *)sharedData
{
    if (!_sharedData) {
        _sharedData = [SharedData sharedInstance];
    }
    return _sharedData;
}


//*****************************************************************************/
#pragma mark - View lifecycle
//*****************************************************************************/

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.group)
    {
        self.user = self.sharedData.user;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"New Task"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Task Removed"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receivedNotification:)
                                                 name:@"Task Data Updated"
                                               object:nil];
    
    
    NSMutableArray *tasks;
    if (self.group)
    {
        tasks = [NSMutableArray arrayWithArray:self.group.tasks];
    }
    else if (self.user)
    {
        tasks = [NSMutableArray arrayWithArray:self.user.tasks];
    }
    
    for (Task *task in tasks)
    {
        if (task.completed)
        {
            [self.completedTasks addObject:task];
        }
        else
        {
            [self.incompleteTasks addObject:task];
        }
    }
    
    [self.tableView reloadData];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIBarButtonItem *newTaskButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionAddTask)];
    
    if (self.group)
    {
        self.tabBarController.title = @"Practice List";
        self.tabBarController.navigationItem.rightBarButtonItem = newTaskButton;
        
        if (!self.inset)
        {
            self.tableView.contentInset = UIEdgeInsetsMake(65.0, 0.0, 0.0, 0.0);
            self.inset = YES;
        }
        else
        {
            self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        }
        
    }
    else if (self.user)
    {
        self.navigationItem.rightBarButtonItem = newTaskButton;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    self.inset = NO;
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionDrawerToggle:(id)sender
{
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

- (IBAction)actionCheckbox:(id)sender
{
    //Adapted from http://stackoverflow.com/questions/11936126/how-to-pass-uitableview-indexpath-to-uibutton-selector-by-parameters-in-ios
    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    
    Task *task;
    if (indexPath.section == 0)
    {
        if (self.incompleteTasks.count == 0)
        {
            task = [self.completedTasks objectAtIndex:indexPath.row];
        }
        else
        {
            task = [self.incompleteTasks objectAtIndex:indexPath.row];\
        }
    }
    else if (indexPath.section == 1)
    {
        task = [self.completedTasks objectAtIndex:indexPath.row];
    }
    
    Firebase *taskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"tasks/%@", task.taskID]];
    
    task.completed = !task.completed;
    task.completed ? [taskRef updateChildValues:@{@"completed":@YES}] : [taskRef updateChildValues:@{@"completed":@NO}];
    
    if (task.completed)
    {
        [self.incompleteTasks removeObject:task];
        [self.completedTasks addObject:task];
        [self.tableView reloadData];
    }
    else
    {
        [self.completedTasks removeObject:task];
        [self.incompleteTasks addObject:task];
        [self.tableView reloadData];
    }
}

- (void)actionAddTask
{
    self.selectedTask = nil;
    [self performSegueWithIdentifier:@"taskDetail" sender:nil];
}


//*****************************************************************************/
#pragma mark - Notification Center
//*****************************************************************************/

- (void)receivedNotification: (NSNotification *)notification
{
    if ([[notification name] isEqualToString:@"Task Data Updated"])
    {
        [self.tableView reloadData];
        
    }
    else if ([[notification name] isEqualToString:@"New Task"])
    {
        dispatch_group_notify(self.sharedData.downloadGroup, dispatch_get_main_queue(), ^{
            [self.incompleteTasks addObject:notification.object];
            [self.tableView reloadData];
        });
    }
    else if ([[notification name] isEqualToString:@"Task Removed"])
    {
        Task *removedTask = notification.object;
        
        if (removedTask.completed)
        {
            [self.completedTasks removeObject:removedTask];
        }
        else
        {
            [self.incompleteTasks removeObject:removedTask];
        }
        [self.tableView reloadData];
    }
}


//*****************************************************************************/
#pragma mark - Table view data source
//*****************************************************************************/

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if (self.incompleteTasks.count == 0 && self.completedTasks.count == 0)
    {
        return 0;
    }
    else if (self.incompleteTasks.count == 0 || self.completedTasks.count == 0)
    {
        return 1;
    }
    
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
    {
        if (self.incompleteTasks.count == 0)
        {
            return self.completedTasks.count;
        }
        else
        {
            return self.incompleteTasks.count;
        }
        
    }
    else if (section == 1)
    {
        return self.completedTasks.count;
    }
    
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        if (self.incompleteTasks.count == 0)
        {
            return @"Complete";
        }
        else
        {
            return @"Incomplete";
        }
    }
    else if (section == 1)
    {
        return @"Complete";
    }
    
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell"];
    
    Task *task;
    if (indexPath.section == 0)
    {
        if (self.incompleteTasks.count == 0)
        {
            task = [self.completedTasks objectAtIndex:indexPath.row];
        }
        else
        {
            task = [self.incompleteTasks objectAtIndex:indexPath.row];
        }
    }
    else if (indexPath.section == 1)
    {
        task = [self.completedTasks objectAtIndex:indexPath.row];
    }
    
    UIButton *checkbox = (UIButton *)[cell viewWithTag:1];
    UILabel *taskTitle = (UILabel *)[cell viewWithTag:2];
    
    if (!task.completed)
    {
        [checkbox setImage:[UIImage imageNamed:@"checkbox"] forState:UIControlStateNormal];
        cell.backgroundColor = [UIColor clearColor];
    }
    else
    {
        [checkbox setImage:[UIImage imageNamed:@"checkbox_completed"] forState:UIControlStateNormal];
        cell.backgroundColor = [UIColor lightGrayColor];
    }
    
    taskTitle.text = task.title;
    
    return cell;
}

/*
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        Task *taskToDelete = [self.tasks objectAtIndex:indexPath.row];
        Firebase *taskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"tasks/%@", taskToDelete.taskID]];
        
        Firebase *ownerTaskRef;
        
        if (self.group) {
            ownerTaskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"groups/%@/tasks/%@", self.group.groupID, taskToDelete.taskID]];
        } else {
            ownerTaskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"users/%@/tasks/%@", self.ref.authData.uid, taskToDelete.taskID]];
        }
        
        [taskRef removeValue];
        [ownerTaskRef removeValue];
        
        [self.tasks removeObject:taskToDelete];
        
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
    Task *taskToMove = [self.tasks objectAtIndex:fromIndexPath.row];
    
    [self.tasks removeObjectAtIndex:fromIndexPath.row];
    [self.tasks insertObject:taskToMove atIndex:toIndexPath.row];
    
    if (self.group) {
        [self.group.tasks removeAllObjects];
        self.group.tasks = [NSMutableArray arrayWithArray:self.tasks];
    } else {
        [self.user.tasks removeAllObjects];
        self.user.tasks = [NSMutableArray arrayWithArray:self.tasks];
    }
}
*/

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        if (self.incompleteTasks.count == 0)
        {
            self.selectedTask = [self.completedTasks objectAtIndex:indexPath.row];
        }
        else
        {
            self.selectedTask = [self.incompleteTasks objectAtIndex:indexPath.row];
        }
    }
    else if (indexPath.section == 1)
    {
        self.selectedTask = [self.completedTasks objectAtIndex:indexPath.row];
    }
    
    [self performSegueWithIdentifier:@"taskDetail" sender:nil];
}


//*****************************************************************************/
#pragma mark - Navigation
//*****************************************************************************/

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"taskDetail"]) {
        TaskViewController *destViewController = segue.destinationViewController;
        destViewController.task = self.selectedTask;
        
        if (self.group) {
            destViewController.group = self.group;
        }
    }
}


@end
