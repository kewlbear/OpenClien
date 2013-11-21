//
//  AppDelegate.m
//  Clien
//
// Copyright 2013 Changbeom Ahn
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "GAI.h"

#ifdef __IPHONE_7_0

#import <JavaScriptCore/JavaScriptCore.h>

#endif

@implementation AppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self initializeGoogleAnalytics];
    
    NSManagedObjectContext* context = self.managedObjectContext;
    if (!context) {
        NSLog(@"%s: context is nil", __func__);
        // TODO:
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        MainViewController* controller = [[MainViewController alloc] initWithStyle:UITableViewStylePlain];
        
        controller.managedObjectContext = context;
        
        UINavigationController* navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
        navigationController.delegate = self;
        navigationController.toolbarHidden = NO;
        if ([navigationController.navigationBar respondsToSelector:@selector(setBarTintColor:)]) {
            UIColor* color = [UIColor colorWithRed:0 green:145/255.f blue:233/255.f alpha:1];
            _window.tintColor = color;
            [UINavigationBar appearance].barTintColor = color;
            [UINavigationBar appearance].tintColor = [UIColor whiteColor];
            [UINavigationBar appearance].titleTextAttributes = @{UITextAttributeTextColor: [UIColor whiteColor]};
            [UIToolbar appearance].barTintColor = color;
            [UIToolbar appearance].tintColor = [UIColor whiteColor];
            [UISearchBar appearance].barTintColor = color;
            [UISearchBar appearance].tintColor = [UIColor whiteColor];
            // http://stackoverflow.com/questions/19022210/preferredstatusbarstyle-doesnt-to-get-called/19513714#19513714
            navigationController.navigationBar.barStyle = UIBarStyleBlack;
        } else {
            [UINavigationBar appearance].tintColor = [UIColor orangeColor];
            [UIToolbar appearance].tintColor = [UIColor orangeColor];
        }
        
        self.window.rootViewController = navigationController;
        [self.window makeKeyAndVisible];
    } else {
        UISplitViewController* splitViewController = (UISplitViewController*) _window.rootViewController;
        splitViewController.delegate = self;
        UINavigationController* navigationController = (UINavigationController*) splitViewController.viewControllers[0];
        MainViewController* mainViewController = (MainViewController*) navigationController.viewControllers[0];
        mainViewController.managedObjectContext = context;
        [self.window makeKeyAndVisible];
        navigationController = splitViewController.viewControllers[1];
        UIBarButtonItem* barButtonItem = navigationController.navigationBar.topItem.leftBarButtonItem;
        if (barButtonItem) {
            [_popoverController presentPopoverFromBarButtonItem:barButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
        }
    }
    
#ifdef __IPHONE_7_0
    
    if ([application respondsToSelector:@selector(setMinimumBackgroundFetchInterval:)]) {
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    }

    if ([JSContext class]) {
        JSContext* c = [[JSContext alloc] init];
        JSValue* v = [c evaluateScript:@"2 + 2"];
        NSLog(@"%d", [v toInt32]);
    }
    
#endif
    
    return YES;
}

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
    UINavigationController* navigationController = (UINavigationController*) [svc.viewControllers objectAtIndex:1];
    barButtonItem.title = @"Clien.net";
    navigationController.navigationBar.topItem.leftBarButtonItem = barButtonItem;
    if (svc.view.window) {
        pc.contentViewController = aViewController;
//        pc.popoverContentSize = CGSizeMake(320, 480);
        [pc presentPopoverFromBarButtonItem:barButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
    }
    _popoverController = pc;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
    UINavigationController* nc = (UINavigationController*) svc.viewControllers[1];
    nc.navigationBar.topItem.leftBarButtonItem = nil;
    _popoverController = nil;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    navigationController.navigationBarHidden = NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        } 
    }
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Clien" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"Clien.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

#ifdef __IPHONE_7_0

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"%s", __func__);
    // fixme
    completionHandler(UIBackgroundFetchResultNewData);
}

#endif

- (void)initializeGoogleAnalytics {
    // Optional: automatically send uncaught exceptions to Google Analytics.
    [GAI sharedInstance].trackUncaughtExceptions = YES;
    
    // Optional: set Google Analytics dispatch interval to e.g. 20 seconds.
//    [GAI sharedInstance].dispatchInterval = 20;
    
    // Optional: set Logger to VERBOSE for debug information.
//    [[[GAI sharedInstance] logger] setLogLevel:kGAILogLevelVerbose];
    
    // Initialize tracker.
    id<GAITracker> tracker = [[GAI sharedInstance] trackerWithTrackingId:@"UA-45616617-1"];
}

@end
