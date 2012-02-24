//
//  AppSettingsViewController.m
//  iSugarCRM
//
//  Created by pramati on 2/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "AppSettingsViewController.h"
#import "TextFieldTableCell.h"
#import "SettingsStore.h"
#import "ApplicationKeyStore.h"
#import "SyncSettingsViewController.h"
#import "AppDelegate.h"
#define kLogoutCell @"login"
#define kTextFieldCell @"textFieldCell"

@interface AppSettingsViewController ()
{
    UIAlertView *waitAlertView;
}
@property (strong) NSArray* cellIdentifierArray;
@property (strong)UIDatePicker *pickerView;    
@property (strong) NSDateFormatter *dateFormatter; 
@property (strong) UIBarButtonItem *saveButton;
@property (strong) UIActionSheet *actionSheet;
@property (strong) NSString *username;
@property (strong) NSString *password;
@property (strong) NSString *urlString;
@property (strong) ApplicationKeyStore *keyChain; 
@property (strong) UIView *footerView;
-(void) logout;
@end

@implementation AppSettingsViewController
@synthesize cellIdentifierArray; 
@synthesize pickerView;
@synthesize dateFormatter;
@synthesize saveButton;
@synthesize actionSheet;
@synthesize username;
@synthesize password;
@synthesize urlString;
@synthesize keyChain,footerView;
- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
        
            NSArray* userSettings = [[NSArray alloc] initWithObjects:kTextFieldCell,kTextFieldCell,kTextFieldCell, nil];
            NSArray* syncSettings = [[NSArray alloc] initWithObjects:kSyncSettingsIdentifier, nil];
            cellIdentifierArray = [[NSArray alloc] initWithObjects:userSettings, syncSettings,[NSArray arrayWithObject:kLogoutCell],nil];  
            saveButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStyleDone target:self action:@selector(saveSettings:)];
        }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.dateFormatter = [[NSDateFormatter alloc] init];
	[self.dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    self.navigationItem.rightBarButtonItem = self.saveButton;
    self.title = @"Settings";
    keyChain = [[ApplicationKeyStore alloc]initWithName:@"iSugarCRM-keystore"];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    if(waitAlertView)
    {
        [waitAlertView dismissWithClickedButtonIndex:0 animated:NO];
        waitAlertView = nil;
    }
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.cellIdentifierArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self.cellIdentifierArray objectAtIndex:section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* cellIdentifier = [[self.cellIdentifierArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]; //will throw arrayoutofbounds if rows are more
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    NSString* value = [SettingsStore objectForKey:cellIdentifier];
    if (cell == nil)
    {   
        if([cellIdentifier isEqualToString:kTextFieldCell])
        {
            cell = (TextFieldTableCell*) [[[NSBundle mainBundle] loadNibNamed:@"TextFieldTableCell"  owner:self options:nil] objectAtIndex:0];
            ((TextFieldTableCell*)cell).textField.textAlignment = UITextAlignmentRight;
            ((TextFieldTableCell*)cell).textField.returnKeyType = UIReturnKeyDone;
            cell.accessoryType = UITableViewCellAccessoryNone;
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            ((TextFieldTableCell*)cell).textField.delegate = self;
        }
        else{
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        }
    }

    if(indexPath.section == 0 && indexPath.row == 0 && [cellIdentifier isEqualToString:kTextFieldCell])
    {
        [((TextFieldTableCell*)cell).label setText:@"Url"];
        NSString *url = [SettingsStore objectForKey:@"sugarEndpoint"];
        if(!value){
            if([url length] == 0)
                value = sugarEndpoint;
            else
                value = url;
        }
        [((TextFieldTableCell*)cell).textField setText:value];
        ((TextFieldTableCell*)cell).textField.tag = kURLTag;
        [((TextFieldTableCell*)cell).textField addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
    }
    else if(indexPath.section == 0 && indexPath.row == 1 && [cellIdentifier isEqualToString:kTextFieldCell])
    {
        [((TextFieldTableCell*)cell).label setText:@"Username"];
        if(!value){
            //value = @"will";
            value = [keyChain objectForKey:(__bridge id)kSecAttrAccount];
        }
        [((TextFieldTableCell*)cell).textField setText:value];
        ((TextFieldTableCell*)cell).textField.tag = kUsernameTag;
        [((TextFieldTableCell*)cell).textField addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
    }
    else if(indexPath.section == 0 && indexPath.row == 2 && [cellIdentifier isEqualToString:kTextFieldCell])
    {
        [((TextFieldTableCell*)cell).label setText:@"Password"];
        [((TextFieldTableCell*)cell).textField setSecureTextEntry:YES];
        if(!value){
            value = [keyChain objectForKey:(__bridge id)kSecValueData];//kSecValueData is to encrypt password
        }
        [((TextFieldTableCell*)cell).textField setText:value];
        ((TextFieldTableCell*)cell).textField.tag = kPasswordTag;
        [((TextFieldTableCell*)cell).textField addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
    }
    else  if([cellIdentifier isEqualToString:kSyncSettingsIdentifier])
        {
            cell.textLabel.text = @"Sync Settings";
            cell.textLabel.textAlignment = UITextAlignmentCenter;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    else  if([cellIdentifier isEqualToString:kLogoutCell])
    {
        cell.textLabel.text = @"Logout";
        cell.textLabel.textAlignment = UITextAlignmentCenter;
    }
return cell;
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString* identifier = [[self.cellIdentifierArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
    if([identifier isEqualToString:kSyncSettingsIdentifier])
    {
        SyncSettingsViewController *syncSettings = [[SyncSettingsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        syncSettings.title = @"Sync Settings";
        [self.navigationController pushViewController:syncSettings animated:YES];
    }
    else if([[[cellIdentifierArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] isEqualToString:kLogoutCell])
    {
        waitAlertView = [[UIAlertView alloc] initWithTitle:@"Please Wait..." message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
        [waitAlertView show];
        
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        
        // Adjust the indicator so it is up a few pixels from the bottom of the alert
        indicator.center = CGPointMake(waitAlertView.bounds.size.width / 2, waitAlertView.bounds.size.height - 50);
        [indicator startAnimating];
        [waitAlertView addSubview:indicator];        
        [self performSelectorInBackground:@selector(logout) withObject:nil];
        //[(AppDelegate*)[[UIApplication sharedApplication] delegate] logout];
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        
    }  
}

-(void) logout
{
    [(AppDelegate*)[[UIApplication sharedApplication] delegate] logout];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField 
{
	return YES;
}

- (void) textChanged:(id)sender {
    UITextField *textField = (UITextField *)sender;
    if(textField.tag == kUsernameTag){
        username = textField.text;
    }else if(textField.tag == kPasswordTag){
        password = textField.text;
    }else if(textField.tag ==  kURLTag){
        urlString = textField.text;
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
	return YES;
}

-(IBAction)saveSettings:(id)sender
{
    
    [keyChain addObject:username forKey:(__bridge id)kSecAttrAccount];
    [keyChain addObject:password forKey:(__bridge id)kSecValueData];
    [SettingsStore setObject:urlString forKey:@"sugarEndpoint"];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
