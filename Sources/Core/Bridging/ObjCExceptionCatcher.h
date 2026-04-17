#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ObjCExceptionCatcher : NSObject

/// Executes the given block inside an ObjC @try/@catch.
/// Returns YES on success. If an NSException is thrown, returns NO
/// and populates *error with the exception details.
+ (BOOL)tryExecuting:(NS_NOESCAPE void(^)(void))block
               error:(NSError * _Nullable * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
