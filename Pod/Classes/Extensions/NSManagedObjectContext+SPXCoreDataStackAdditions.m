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

#import "NSManagedObjectContext+SPXCoreDataStackAdditions.h"
#import "SPXCoreDataStack.h"
#import <objc/runtime.h>

static void *SPXCoreDataStackContextName = &SPXCoreDataStackContextName;

@interface SPXCoreDataStack ()
@property (nonatomic, strong) NSManagedObjectContext *mainThreadContext;
+ (instancetype)sharedInstance;
+ (void)handleError:(NSError *)error;
@end

@interface NSManagedObjectContext ()
@property (nonatomic) NSString *contextName;
@end

@implementation NSManagedObjectContext (SPXCoreDataStackAdditions)

+ (instancetype)mainThreadContext
{
  return [[SPXCoreDataStack sharedInstance] mainThreadContext];
}

- (NSString *)contextName
{
  return objc_getAssociatedObject(self, SPXCoreDataStackContextName);
}

- (void)setContextName:(NSString *)contextName
{
  objc_setAssociatedObject(self, SPXCoreDataStackContextName, contextName, OBJC_ASSOCIATION_ASSIGN);
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"%@ | %@", [super description], self.contextName];
}

- (void)saveSynchronously:(BOOL)synchronous completion:(void (^)(BOOL success, NSError *error))completion
{  
  void(^errorBlock)(NSError *error) = ^(NSError *error) {
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^(void) {
        completion(NO, error);
      });
    }
  };
  
  void(^completionBlock)(BOOL saved, NSError *error) = ^(BOOL saved, NSError *error) {
    if (completion) {
      dispatch_async(dispatch_get_main_queue(), ^(void) {
        completion(saved, error);
      });
    }
  };
  
  void(^saveBlock)() = ^() {
    NSError *error = nil;
    BOOL saved = [self save:&error];
    
    if (!saved) {
      [SPXCoreDataStack handleError:error];
      errorBlock(error);
    } else {
      if (self.parentContext) {
        [self.parentContext saveSynchronously:synchronous completion:completion];
      } else {
        completionBlock(saved, error);
      }
    }
  };
  
  if (!self.hasChanges) {
    errorBlock(nil);
    return;
  }
  
  if (synchronous) {
    [self performBlockAndWait:saveBlock];
  } else {
    [self performBlock:saveBlock];
  }
}

@end
