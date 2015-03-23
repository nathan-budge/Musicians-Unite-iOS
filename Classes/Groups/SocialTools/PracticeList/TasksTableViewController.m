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
#import "NavigationDrawerViewController.h"

#import "AppConstant.h"

#import "User.h"
#import "Task.h"
#import "Group.h"


@interface TasksTableViewController ()

@property (nonatomic) Firebase *ref;

@property (nonatomic) User *user;

@property (nonatomic) Task *selectedTask;
@property (nonatomic) NSMutableArray *tasks;

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

-(NSMutableArray *)tasks
{
    if (!_tasks) {
        _tasks = [[NSMutableArray alloc] init];
    }
    return _tasks;
}


//*****************************************************************************/
#pragma mark - View lifecycle
//*****************************************************************************/

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.group) {
        NavigationDrawerViewController *navigationDrawerViewController = (NavigationDrawerViewController *)self.slidingViewController.underLeftViewController;
        self.user = navigationDrawerViewController.user;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.tabBarController.title = @"Practice List";
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    UIBarButtonItem *newTaskButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(actionAddTask)];
    
    if (self.group) {
        self.tasks = [NSMutableArray arrayWithArray:self.group.tasks];
        self.tabBarController.navigationItem.rightBarButtonItems = @[newTaskButton, self.editButtonItem];
        
        if (!self.inset) {
            self.tableView.contentInset = UIEdgeInsetsMake(65.0, 0.0, 0.0, 0.0);
            self.inset = YES;
        } else {
            self.tableView.contentInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        }
        
    } else {
        self.tasks = [NSMutableArray arrayWithArray:self.user.tasks];
        self.navigationItem.rightBarButtonItems = @[newTaskButton, self.editButtonItem];
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (self.group) {
        [self.group.tasks removeAllObjects];
        self.group.tasks = [NSMutableArray arrayWithArray:self.tasks];
    } else {
        [self.user.tasks removeAllObjects];
        self.user.tasks = [NSMutableArray arrayWithArray:self.tasks];
    }
    
    self.inset = NO;
    
    [self.tasks removeAllObjects];
}


//*****************************************************************************/
#pragma mark - Buttons
//*****************************************************************************/

- (IBAction)actionDrawerToggle:(id)sender {
    [self.slidingViewController anchorTopViewToRightAnimated:YES];
}

- (IBAction)actionCheckbox:(id)sender
{
    //Adapted from http://stackoverflow.com/questions/11936126/how-to-pass-uitableview-indexpath-to-uibutton-selector-by-parameters-in-ios
    CGPoint touchPoint = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:touchPoint];
    
    Task *task = [self.tasks objectAtIndex:indexPath.row];
    
    Firebase *taskRef = [self.ref childByAppendingPath:[NSString stringWithFormat:@"tasks/%@", task.taskID]];
    
    task.completed = !task.completed;
    task.completed ? [taskRef updateChildValues:@{@"completed":@YES}] : [taskRef updateChildValues:@{@"completed":@NO}];
    
    if (task.completed) {
        [self.tasks removeObject:task];
        [self.tasks addObject:task];
        [self.tableView reloadData];
    } else {
        [self.tasks removeObject:task];
        [self.tasks insertObject:task atIndex:0];
        [self.tableView reloadData];
    }
}

- (void)actionAddTask
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
    return self.tasks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TaskCell"];
    
    Task *task = [self.tasks objectAtIndex:indexPath.row];
    
    UIButton *checkbox = (UIButton *)[cell viewWithTag:1];
    UILabel *taskTitle = (UILabel *)[cell viewWithTag:2];
    
    if (!task.completed) {
        [checkbox setImage:[UIImage imageNamed:@"checkbox"] forState:UIControlStateNormal];
        cell.backgroundColor = [UIColor clearColor];
    } else {
        [checkbox setImage:[UIImage imageNamed:@"checkbox_completed"] forState:UIControlStateNormal];
        cell.backgroundColor = [UIColor lightGrayColor];
    }
    
    taskTitle.text = task.title;
    
    return cell;
}

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

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedTask = [self.tasks objectAtIndex:indexPath.row];
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
