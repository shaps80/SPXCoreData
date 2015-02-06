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

#import <CoreData/CoreData.h>
#import "SPXCoreDataObjectQuery.h"

@interface NSManagedObject (SPXCoreDataStackAdditions) <SPXCoreDataObjectQuery>

// Returns the model's entity name for this managed object
+ (NSString *)entityName;

// Returns multiple objects based on filtering and sorting parameters
+ (NSArray *)allInContext:(NSManagedObjectContext *)context;
+ (NSArray *)allSorted:(NSArray *)sortDescriptors inContext:(NSManagedObjectContext *)context;
+ (NSArray *)allSorted:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;
+ (NSArray *)allSorted:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate faulted:(BOOL)faulted inContext:(NSManagedObjectContext *)context;

// Returns the number of objects based on fitering parameters
+ (NSUInteger)countAllInContext:(NSManagedObjectContext *)context;
+ (NSUInteger)countAllSorted:(NSArray *)sortDescriptors inContext:(NSManagedObjectContext *)context;
+ (NSUInteger)countAllSorted:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

// Returns a fetchedResultsController based on filtering, grouping and sorting parameters
+ (NSFetchedResultsController *)fetchedWithSorting:(NSArray *)sortDescriptors;
+ (NSFetchedResultsController *)fetchedWithSorting:(NSArray *)sortDescriptors predicate:(NSPredicate *)predicate;
+ (NSFetchedResultsController *)fetchedWithSorting:(NSArray *)sortDescriptors grouping:(NSString *)grouping predicate:(NSPredicate *)predicate;
+ (NSFetchedResultsController *)fetchedWithSorting:(NSArray *)sortDescriptors grouping:(NSString *)grouping predicate:(NSPredicate *)predicate preFetch:(BOOL)fetch;

// Returns a specific object, if the object isn't found you can specify to automatically create the object
+ (instancetype)objectWithIdentifier:(id)identifier inContext:(NSManagedObjectContext *)context;
+ (instancetype)objectWithIdentifier:(id)identifier faulted:(BOOL)faulted inContext:(NSManagedObjectContext *)context;
+ (instancetype)objectWithIdentifier:(id)identifier create:(BOOL)create inContext:(NSManagedObjectContext *)context;
+ (instancetype)objectWithIdentifier:(id)identifier faulted:(BOOL)faulted create:(BOOL)create inContext:(NSManagedObjectContext *)context;

// Returns multiple specific objects, if the objects are not found you can specify to  automatically create them. These methods are optimized for high performance when importing a large number of items in batches
+ (NSArray *)objectsWithIdentifiers:(NSArray *)identifiers inContext:(NSManagedObjectContext *)context;
+ (NSArray *)objectsWithIdentifiers:(NSArray *)identifiers create:(BOOL)create inContext:(NSManagedObjectContext *)context;
+ (NSArray *)objectsWithIdentifiers:(NSArray *)identifiers sorting:(NSArray *)sortDescriptors create:(BOOL)create inContext:(NSManagedObjectContext *)context;
+ (NSArray *)objectsWithIdentifiers:(NSArray *)identifiers sorting:(NSArray *)sortDescriptors faulted:(BOOL)faulted create:(BOOL)create inContext:(NSManagedObjectContext *)context;

// Inserts a new object into the context
+ (instancetype)insertInContext:(NSManagedObjectContext *)context;

// Deletes objects from the context
+ (void)deleteAllInContext:(NSManagedObjectContext *)context;
+ (void)deleteAllMatching:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

// Deletes specific objects from the context
+ (void)deleteObjects:(NSArray *)objects inContext:(NSManagedObjectContext *)context;
+ (void)deleteObjectWithIdentifier:(id)identifier inContext:(NSManagedObjectContext *)context;

+ (void)deleteObjectWithObjectID:(NSManagedObjectID *)identifier inContext:(NSManagedObjectContext *)context;

@end
