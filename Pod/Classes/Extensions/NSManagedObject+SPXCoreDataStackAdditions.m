/*
   Copyright (c) 2014 Snippex. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY Snippex `AS IS' AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 EVENT SHALL Snippex OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSManagedObject+SPXCoreDataStackAdditions.h"
#import "SPXCoreDataStack.h"
#import "KZPropertyMapperCommon.h"

extern NSDictionary *entityMappings;

@interface SPXCoreDataStack ()
@property (nonatomic, strong) NSManagedObjectContext *mainThreadContext;
+ (instancetype)sharedInstance;
+ (void)handleError:(NSError *)error;
@end

@implementation NSManagedObject (SPXCoreDataStackAdditions)

+ (NSString *)entityName
{
  return entityMappings[NSStringFromClass(self)] ?: NSStringFromClass(self);
}

+ (NSString *)singularDescription
{
  return self.entityName;
}

+ (NSString *)pluralDescription
{
  return self.entityName;
}

+ (NSString *)deleteString
{
  return @"Delete";
}

+ (BOOL)supportsCreate
{
  return NO;
}

+ (BOOL)supportsDelete
{
  return NO;
}

+ (BOOL)supportsEdit
{
  return NO;
}

+ (NSFetchRequest *)createFetchRequestInContext:(NSManagedObjectContext *)context
{
  NSEntityDescription *entity = [NSEntityDescription entityForName:[self entityName] inManagedObjectContext:context];
  NSFetchRequest *request = [NSFetchRequest new];
  request.entity = entity;
  return request;
}

+ (NSArray *)executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
  __block NSArray *results = nil;
  
  [context performBlockAndWait:^{
    NSError *error = nil;
    results = [context executeFetchRequest:request error:&error];
    
    if (results == nil) {
      [SPXCoreDataStack handleError:error];
    }
    
  }];
  
	return results;
}

#pragma mark - Multiples Objects

+ (NSArray *)allInContext:(NSManagedObjectContext *)context
{
  return [self allSorted:nil predicate:nil inContext:context];
}

+ (NSArray *)allSorted:(NSArray *)sortDescriptors inContext:(NSManagedObjectContext *)context
{
  return [self allSorted:sortDescriptors inContext:context];
}

+ (NSArray *)allSorted:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
  return [self allSorted:sortDescriptors predicate:predicate faulted:YES inContext:context];
}

+ (NSArray *)allSorted:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate faulted:(BOOL)faulted inContext:(NSManagedObjectContext *)context
{
  for (id sortDescriptor in sortDescriptors) {
    SPXAssertTrueOrReturnNil([sortDescriptor isKindOfClass:[NSSortDescriptor class]]);
  }
  
  NSFetchRequest *request = [self createFetchRequestInContext:context];
  
  [request setSortDescriptors:sortDescriptors];
  [request setPredicate:predicate];
  [request setReturnsObjectsAsFaults:faulted];

  return [self executeFetchRequest:request inContext:context];
}

#pragma mark - Count

+ (NSUInteger)countAllInContext:(NSManagedObjectContext *)context
{
  return [self countAllSorted:nil predicate:nil inContext:context];
}

+ (NSUInteger)countAllSorted:(NSArray *)sortDescriptors inContext:(NSManagedObjectContext *)context
{
  return [self countAllSorted:sortDescriptors predicate:nil inContext:context];
}

+ (NSUInteger)countAllSorted:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
  NSFetchRequest *request = [self createFetchRequestInContext:context];
  __block NSUInteger count = 0;
  
  [request setSortDescriptors:sortDescriptors];
  [request setPredicate:predicate];
  
  [context performBlockAndWait:^{
    count = [context countForFetchRequest:request error:nil];
  }];
  
  return count;
}

#pragma mark - FetchedResultsController

+ (NSFetchedResultsController *)fetchedWithSorting:(NSArray *)sortDescriptors
{
  return [self fetchedWithSorting:sortDescriptors grouping:nil predicate:nil preFetch:YES];
}

+ (NSFetchedResultsController *)fetchedWithSorting:(NSArray *)sortDescriptors grouping:(NSString *)grouping
{
  return [self fetchedWithSorting:sortDescriptors grouping:grouping predicate:nil preFetch:YES];
}

+ (NSFetchedResultsController *)fetchedWithSorting:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate
{
  return [self fetchedWithSorting:sortDescriptors grouping:nil predicate:predicate preFetch:YES];
}

+ (NSFetchedResultsController *)fetchedWithSorting:(NSArray *)sortDescriptors grouping:(NSString *)grouping predicate:(NSPredicate *)predicate
{
  return [self fetchedWithSorting:sortDescriptors grouping:grouping predicate:predicate preFetch:YES];
}

+ (NSFetchedResultsController *)fetchedWithSorting:(NSArray *)sortDescriptors grouping:(NSString *)grouping predicate:(NSPredicate *)predicate preFetch:(BOOL)fetch
{
  NSManagedObjectContext *context = [[SPXCoreDataStack sharedInstance] mainThreadContext];
  NSFetchRequest *request = [self createFetchRequestInContext:context];
  
  [request setSortDescriptors:sortDescriptors];
  [request setPredicate:predicate];
  [request setFetchBatchSize:20];
  
  NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:grouping cacheName:nil];
  
  if (fetch) {
    NSError *error = nil;
    if (![controller performFetch:&error]) {
      [SPXCoreDataStack handleError:error];
    }
  }
  
  return controller;
}

#pragma mark - Single Objects

+ (id)objectWithIdentifier:(id)identifier inContext:(NSManagedObjectContext *)context
{
  return [self objectWithIdentifier:identifier faulted:NO create:NO inContext:context];
}

+ (instancetype)objectWithIdentifier:(id)identifier faulted:(BOOL)faulted inContext:(NSManagedObjectContext *)context
{
  return [self objectWithIdentifier:identifier faulted:faulted create:NO inContext:context];
}

+ (id)objectWithIdentifier:(id)identifier create:(BOOL)create inContext:(NSManagedObjectContext *)context
{
  return [self objectWithIdentifier:identifier faulted:NO create:create inContext:context];
}

+ (instancetype)objectWithIdentifier:(id)identifier faulted:(BOOL)faulted create:(BOOL)create inContext:(NSManagedObjectContext *)context;
{
  NSFetchRequest *request = [self createFetchRequestInContext:context];
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"identifier", identifier];
  request.predicate = predicate;
  request.fetchLimit = 1;
  request.returnsObjectsAsFaults = faulted;
  
  id object = [self executeFetchRequest:request inContext:context].firstObject;
  
  if (!object && create) {
    object = [self insertInContext:context];
    [object setValue:identifier forKey:@"identifier"];
  }
  
  return object;
}

+ (NSArray *)objectsWithIdentifiers:(NSArray *)identifiers inContext:(NSManagedObjectContext *)context
{
  return [self objectsWithIdentifiers:identifiers sorting:nil faulted:YES create:YES inContext:context];
}

+ (NSArray *)objectsWithIdentifiers:(NSArray *)identifiers create:(BOOL)create inContext:(NSManagedObjectContext *)context
{
  return [self objectsWithIdentifiers:identifiers sorting:nil faulted:YES create:create inContext:context];
}

+ (NSArray *)objectsWithIdentifiers:(NSArray *)identifiers sorting:(NSArray *)sortDescriptors create:(BOOL)create inContext:(NSManagedObjectContext *)context
{
  return [self objectsWithIdentifiers:identifiers sorting:sortDescriptors faulted:YES create:create inContext:context];
}

+ (NSArray *)objectsWithIdentifiers:(NSArray *)identifiers sorting:(NSArray *)sortDescriptors faulted:(BOOL)faulted create:(BOOL)create inContext:(NSManagedObjectContext *)context
{
  NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier IN %@", identifiers];
  NSArray *objects = [self allSorted:nil predicate:predicate faulted:faulted inContext:context];
  
  if (!create) {
    return [objects sortedArrayUsingDescriptors:sortDescriptors];
  }
  
  NSMutableArray *results = [NSMutableArray new];
  [results addObjectsFromArray:objects];
  
  NSMutableSet *identifiersSet = [NSMutableSet setWithArray:identifiers];
  NSSet *existingIdentifiersSet = [NSSet setWithArray:[objects valueForKey:@"identifier"]];
  
  [identifiersSet minusSet:existingIdentifiersSet];
  
  for (id identifier in identifiersSet) {
    id newObject = [self insertInContext:context];
    [newObject setValue:identifier forKey:@"identifier"];
    [results addObject:newObject];
  }
  
  return [results sortedArrayUsingDescriptors:sortDescriptors];
}

#pragma mark - Insert Object

+ (instancetype)insertInContext:(NSManagedObjectContext *)context
{
  __block id object = nil;
  
  [context performBlockAndWait:^{
    object = [NSEntityDescription insertNewObjectForEntityForName:[self.class entityName] inManagedObjectContext:context];
  }];
  
  return object;
}

#pragma mark - Delete Objects

+ (void)deleteAllInContext:(NSManagedObjectContext *)context
{
  [self deleteAllMatching:nil inContext:context];
}

+ (void)deleteAllMatching:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
  NSArray *objects = [self allSorted:nil predicate:predicate inContext:context];
  [self deleteObjects:objects inContext:context];
}

+ (void)deleteObjects:(NSArray *)objects inContext:(NSManagedObjectContext *)context
{
  [context performBlockAndWait:^{
    for (id object in objects) {
      [context deleteObject:object];
    }
  }];
}

+ (void)deleteObjectWithIdentifier:(id)identifier inContext:(NSManagedObjectContext *)context
{
  id object = [self objectWithIdentifier:identifier inContext:context];
  
  if (!object) {
    return;
  }
  
  [context performBlockAndWait:^{
    [context deleteObject:object];
  }];
}

+ (void)deleteObjectWithObjectID:(NSManagedObjectID *)identifier inContext:(NSManagedObjectContext *)context
{
  id object = [context objectWithID:identifier];
  
  if (!object) {
    return;
  }
  
  [context performBlock:^{
    [context deleteObject:object];
  }];
}

@end
