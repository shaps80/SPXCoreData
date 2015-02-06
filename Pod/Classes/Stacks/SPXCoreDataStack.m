//
//  SPXCoreDataStack.m
//  CoreData
//
//  Created by Shaps Mohsenin on 23/03/2014.
//  Copyright (c) 2014 Snippex. All rights reserved.
//

#import "SPXCoreDataStack.h"
#import "SPXLoggingDefines.h"

const NSDictionary *entityMappings;

@interface NSManagedObjectContext ()
@property (nonatomic) NSString *contextName;
@end

@interface SPXCoreDataStack ()

@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, strong) NSManagedObjectContext *rootContext;
@property (nonatomic, strong) NSManagedObjectContext *mainThreadContext;

+ (void)handleError:(NSError *)error;
- (void)mergeChanges:(NSNotification *)notification;
- (NSManagedObjectContext *)contextWithParent:(NSManagedObjectContext *)parent;

@end

@implementation SPXCoreDataStack

__attribute__((constructor)) static void SPXCoreDataStackConstructor(void) {
  @autoreleasepool {
    [SPXCoreDataStack sharedInstance];
    [SPXCoreDataStack mapEntities];
  }
}

+ (instancetype)sharedInstance
{
	static SPXCoreDataStack *_sharedInstance = nil;
	static dispatch_once_t oncePredicate;
	dispatch_once(&oncePredicate, ^{
		_sharedInstance = [[self alloc] initWithDefaultStore];
	});
	
	return _sharedInstance;
}

+ (void)mapEntities
{
  NSManagedObjectModel *model = [[[SPXCoreDataStack sharedInstance] coordinator] managedObjectModel];
  NSMutableDictionary *mappings = [NSMutableDictionary new];
  
  [model.entitiesByName enumerateKeysAndObjectsUsingBlock:^(NSString *entityName, NSEntityDescription *entityDescription, BOOL *stop) {
    mappings[entityDescription.managedObjectClassName] = entityName;
  }];
  
  entityMappings = mappings.copy;
}

- (instancetype)initWithDefaultStore
{
  self = [super init];
  
  if (self) {
    NSManagedObjectModel *model = [NSManagedObjectModel mergedModelFromBundles:nil];
    _coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSError *error = nil;
    NSURL *url = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *storeName = [NSBundle mainBundle].infoDictionary[@"CFBundleName"];
    url = [url URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.sqlite", storeName]];
    NSPersistentStore *store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:[self.class autoMigratingOptions] error:&error];

    if (!store && error) {
      SPXLog(@"%@", error);
      error = nil;
      
      if (![[NSFileManager defaultManager] removeItemAtURL:url error:&error]) {
        SPXLog(@"%@", error);
      }
      
      store = [_coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:[self.class autoMigratingOptions] error:&error];
    }
  }
  
  return self;
}

+ (NSDictionary *)autoMigratingOptions
{
  return @{  NSMigratePersistentStoresAutomaticallyOption : @(YES),
             NSInferMappingModelAutomaticallyOption       : @(YES),
          };
}

+ (void)handleError:(NSError *)error
{
  NSDictionary *userInfo = [error userInfo];
  for (NSArray *detailedError in [userInfo allValues]) {
    if ([detailedError isKindOfClass:[NSArray class]])
    {
      for (NSError *e in detailedError) {
        if ([e respondsToSelector:@selector(userInfo)]) {
          SPXLog(@"Error Details: %@", [e userInfo]);
        }
        else {
          SPXLog(@"Error Details: %@", e);
        }
      }
    }
    else
    {
      SPXLog(@"Error: %@", detailedError);
    }
  }
  
  SPXLog(@"Error Message: %@", [error localizedDescription]);
  SPXLog(@"Error Domain: %@", [error domain]);
  SPXLog(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);
}

- (NSManagedObjectContext *)contextWithParent:(NSManagedObjectContext *)parent
{
  NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  
  if (parent) {
    context.parentContext = parent;
    [context setContextName:[NSString stringWithFormat:@"%@ > Background Context", parent.contextName]];
  } else {
    context.persistentStoreCoordinator = self.coordinator;
    [context setContextName:[NSString stringWithFormat:@"Background Context"]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mergeChanges:) name:NSManagedObjectContextDidSaveNotification object:context];
  }
  
  return context;
}

- (NSManagedObjectContext *)rootContext
{
  if (_rootContext) {
    return _rootContext;
  }
  
  _rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
  _rootContext.persistentStoreCoordinator = _coordinator;
  [_rootContext setContextName:@"Root Context"];
  
  return _rootContext;
}

- (NSManagedObjectContext *)mainThreadContext
{
  if (_mainThreadContext) {
    return _mainThreadContext;
  }
  
  _mainThreadContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
  _mainThreadContext.parentContext = [self rootContext];
  [_mainThreadContext setContextName:@"Main Context"];
  
  return _mainThreadContext;
}

- (void)mergeChanges:(NSNotification *)notification
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self.mainThreadContext mergeChangesFromContextDidSaveNotification:notification];
  });
  
  [[NSNotificationCenter defaultCenter] removeObserver:self name:NSManagedObjectContextDidSaveNotification object:notification.object];
}

@end
