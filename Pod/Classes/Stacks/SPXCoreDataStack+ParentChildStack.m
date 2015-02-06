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

#import "SPXCoreDataStack+ParentChildStack.h"
#import "NSManagedObjectContext+SPXCoreDataStackAdditions.h"

@interface SPXCoreDataStack ()
+ (instancetype)sharedInstance;
- (NSManagedObjectContext *)contextWithParent:(NSManagedObjectContext *)parent;
- (NSManagedObjectContext *)mainThreadContext;
@end

@interface NSManagedObjectContext ()
- (void)saveSynchronously:(BOOL)synchronous completion:(void (^)(BOOL success, NSError *error))completion;
@end

@implementation SPXCoreDataStack (ParentChildStack)

+ (void)saveWithContext:(NSManagedObjectContext *)context andWait:(void (^)(NSManagedObjectContext *))block
{
  [context performBlockAndWait:^{
    if (block) {
      block(context);
    }
    
    [context saveSynchronously:YES completion:nil];
  }];
}

+ (void)saveWithContext:(NSManagedObjectContext *)context block:(void (^)(NSManagedObjectContext *))block completion:(void (^)(NSError *))completion
{
  [context performBlock:^{
    if (block) {
      block(context);
    }
    
    [context saveSynchronously:NO completion:^(BOOL success, NSError *error) {
      if (completion) {
        completion(error);
      }
    }];
  }];
}

+ (void)saveWithBlockAndWait:(void (^)(NSManagedObjectContext *))block
{
  NSManagedObjectContext *mainContext = [[SPXCoreDataStack sharedInstance] mainThreadContext];
  NSManagedObjectContext *localContext = [[SPXCoreDataStack sharedInstance] contextWithParent:mainContext];
  
  [localContext performBlockAndWait:^{
    if (block) {
      block(localContext);
    }
    
    [localContext saveSynchronously:YES completion:nil];
  }];
}

+ (void)saveWithBlock:(void (^)(NSManagedObjectContext *))block completion:(void (^)(NSError *))completion
{
  NSManagedObjectContext *mainContext = [[SPXCoreDataStack sharedInstance] mainThreadContext];
  NSManagedObjectContext *localContext = [[SPXCoreDataStack sharedInstance] contextWithParent:mainContext];
  
  [localContext performBlock:^{
    if (block) {
      block(localContext);
    }
    
    [localContext saveSynchronously:NO completion:^(BOOL success, NSError *error) {
      if (completion) {
        completion(error);
      }
    }];
  }];
}

@end
