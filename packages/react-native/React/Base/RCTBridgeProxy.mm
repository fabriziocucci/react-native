/*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RCTBridgeProxy.h"
#import <React/RCTBridge+Private.h>
#import <React/RCTBridge.h>
#import <React/RCTLog.h>
#import <React/RCTUIManager.h>
#import <jsi/jsi.h>

using namespace facebook;

@interface RCTUIManagerProxy : NSProxy
- (instancetype)initWithViewRegistry:(RCTViewRegistry *)viewRegistry NS_DESIGNATED_INITIALIZER;

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
- (void)forwardInvocation:(NSInvocation *)invocation;
@end

@implementation RCTBridgeProxy {
  RCTUIManagerProxy *_uiManagerProxy;
  RCTModuleRegistry *_moduleRegistry;
  RCTBundleManager *_bundleManager;
  RCTCallableJSModules *_callableJSModules;
  void (^_dispatchToJSThread)(dispatch_block_t);
  void (^_registerSegmentWithId)(NSNumber *, NSString *);
}

- (instancetype)initWithViewRegistry:(RCTViewRegistry *)viewRegistry
                      moduleRegistry:(RCTModuleRegistry *)moduleRegistry
                       bundleManager:(RCTBundleManager *)bundleManager
                   callableJSModules:(RCTCallableJSModules *)callableJSModules
                  dispatchToJSThread:(void (^)(dispatch_block_t))dispatchToJSThread
               registerSegmentWithId:(void (^)(NSNumber *, NSString *))registerSegmentWithId
{
  self = [super self];
  if (self) {
    self->_uiManagerProxy = [[RCTUIManagerProxy alloc] initWithViewRegistry:viewRegistry];
    self->_moduleRegistry = moduleRegistry;
    self->_bundleManager = bundleManager;
    self->_callableJSModules = callableJSModules;
    self->_dispatchToJSThread = dispatchToJSThread;
    self->_registerSegmentWithId = registerSegmentWithId;
  }
  return self;
}

- (void)dispatchBlock:(dispatch_block_t)block queue:(dispatch_queue_t)queue
{
  [self logWarning:@"Please migrate to dispatchToJSThread: @synthesize dispatchToJSThread = _dispatchToJSThread"
               cmd:_cmd];

  if (queue == RCTJSThread) {
    _dispatchToJSThread(block);
  } else if (queue) {
    dispatch_async(queue, block);
  }
}

/**
 * Used By:
 *  - RCTDevSettings
 */
- (Class)executorClass
{
  [self logWarning:@"This method is unsupported. Returning nil." cmd:_cmd];
  return nil;
}

/**
 * Used By:
 *  - RCTBlobCollector
 */
- (jsi::Runtime *)runtime
{
  [self logWarning:@"This method is unsupported. Returning nullptr." cmd:_cmd];
  return nullptr;
}

/**
 * RCTModuleRegistry
 */
- (id)moduleForName:(NSString *)moduleName
{
  [self logWarning:@"Please migrate to RCTModuleRegistry: @synthesize moduleRegistry = _moduleRegistry." cmd:_cmd];
  return [_moduleRegistry moduleForName:[moduleName UTF8String]];
}

- (id)moduleForName:(NSString *)moduleName lazilyLoadIfNecessary:(BOOL)lazilyLoad
{
  [self logWarning:@"Please migrate to RCTModuleRegistry: @synthesize moduleRegistry = _moduleRegistry." cmd:_cmd];
  return [_moduleRegistry moduleForName:[moduleName UTF8String] lazilyLoadIfNecessary:lazilyLoad];
}

- (id)moduleForClass:(Class)moduleClass
{
  [self logWarning:@"Please migrate to RCTModuleRegistry: @synthesize moduleRegistry = _moduleRegistry." cmd:_cmd];
  NSString *moduleName = RCTBridgeModuleNameForClass(moduleClass);
  return [_moduleRegistry moduleForName:[moduleName UTF8String] lazilyLoadIfNecessary:YES];
}

- (NSArray *)modulesConformingToProtocol:(Protocol *)protocol
{
  [self logError:@"The TurboModule system cannot load modules by protocol. Returning an empty NSArray*." cmd:_cmd];
  return @[];
}

- (BOOL)moduleIsInitialized:(Class)moduleClass
{
  [self logWarning:@"Please migrate to RCTModuleRegistry: @synthesize moduleRegistry = _moduleRegistry." cmd:_cmd];
  return [_moduleRegistry moduleIsInitialized:moduleClass];
}

- (NSArray<Class> *)moduleClasses
{
  [self logError:@"The TurboModuleManager does not implement this method. Returning an empty NSArray*." cmd:_cmd];
  return @[];
}

/**
 * RCTBundleManager
 */
- (void)setBundleURL:(NSURL *)bundleURL
{
  [self logWarning:@"Please migrate to RCTBundleManager: @synthesize bundleManager = _bundleManager." cmd:_cmd];
  [_bundleManager setBundleURL:bundleURL];
}

- (NSURL *)bundleURL
{
  [self logWarning:@"Please migrate to RCTBundleManager: @synthesize bundleManager = _bundleManager." cmd:_cmd];
  return [_bundleManager bundleURL];
}

/**
 * RCTCallableJSModules
 */
- (void)enqueueJSCall:(NSString *)moduleDotMethod args:(NSArray *)args
{
  [self logWarning:@"Please migrate to RCTCallableJSModules: @synthesize callableJSModules = _callableJSModules."
               cmd:_cmd];

  NSArray<NSString *> *ids = [moduleDotMethod componentsSeparatedByString:@"."];
  NSString *module = ids[0];
  NSString *method = ids[1];
  [_callableJSModules invokeModule:module method:method withArgs:args];
}

- (void)enqueueJSCall:(NSString *)module
               method:(NSString *)method
                 args:(NSArray *)args
           completion:(dispatch_block_t)completion
{
  [self logWarning:@"Please migrate to RCTCallableJSModules: @synthesize callableJSModules = _callableJSModules."
               cmd:_cmd];
  [_callableJSModules invokeModule:module method:method withArgs:args onComplete:completion];
}

- (void)registerSegmentWithId:(NSUInteger)segmentId path:(NSString *)path
{
  self->_registerSegmentWithId(@(segmentId), path);
}

- (id<RCTBridgeDelegate>)delegate
{
  [self logError:@"This method is unsupported. Returning nil." cmd:_cmd];
  return nil;
}

- (NSDictionary *)launchOptions
{
  [self logError:@"Bridgeless mode doesn't support launchOptions. Returning nil." cmd:_cmd];
  return nil;
}

- (BOOL)loading
{
  [self logWarning:@"This method is not implemented. Returning NO." cmd:_cmd];
  return NO;
}

- (BOOL)valid
{
  [self logWarning:@"This method is not implemented. Returning NO." cmd:_cmd];
  return NO;
}

- (RCTPerformanceLogger *)performanceLogger
{
  [self logWarning:@"Bridgeless mode does not support RCTPerformanceLogger. Returning nil." cmd:_cmd];
  return nil;
}

- (void)reload
{
  [self logError:@"Please use RCTReloadCommand instead. Nooping." cmd:_cmd];
}

- (void)reloadWithReason:(NSString *)reason
{
  [self logError:@"Please use RCTReloadCommand instead. Nooping." cmd:_cmd];
}

- (void)onFastRefresh
{
  [[NSNotificationCenter defaultCenter] postNotificationName:RCTBridgeFastRefreshNotification object:self];
}

- (void)requestReload __deprecated_msg("Use RCTReloadCommand instead")
{
  [self logError:@"Please use RCTReloadCommand instead. Nooping." cmd:_cmd];
}

- (BOOL)isBatchActive
{
  [self logWarning:@"Bridgeless mode does not support batching. Returning NO." cmd:_cmd];
  return NO;
}

/**
 * RCTBridge ()
 */

- (NSString *)bridgeDescription
{
  [self logWarning:@"Bridgeless mode does not support bridgeDescription. Returning \"BridgeProxy\"." cmd:_cmd];
  return @"BridgeProxy";
}

- (void)enqueueCallback:(NSNumber *)cbID args:(NSArray *)args
{
  [self logError:@"Bridgeless mode does not queuing callbacks by ids. No-oping." cmd:_cmd];
}

- (RCTBridge *)batchedBridge
{
  [self logWarning:@"Bridgeless mode does not support batchedBridge. Returning bridge proxy." cmd:_cmd];
  return (RCTBridge *)self;
}

- (void)setBatchedBridge
{
  [self logError:@"Bridgeless mode does not support setBatchedBridge. No-oping." cmd:_cmd];
}

- (RCTBridgeModuleListProvider)moduleProvider
{
  [self logWarning:@"Bridgeless mode does not support RCTBridgeModuleListProvider. Returning empty block" cmd:_cmd];
  return ^{
    return @[];
  };
}

- (RCTModuleRegistry *)moduleRegistry
{
  return _moduleRegistry;
}

/**
 * RCTBridge (RCTCxxBridge)
 */

- (RCTBridge *)parentBridge
{
  [self logWarning:@"Bridgeless mode does not support parentBridge. Returning bridge proxy." cmd:_cmd];
  return (RCTBridge *)self;
}

- (BOOL)moduleSetupComplete
{
  [self logWarning:@"Bridgeless mode does not implement moduleSetupComplete. Returning YES." cmd:_cmd];
  return YES;
}

- (void)start
{
  [self
      logError:
          @"Starting the bridge proxy does nothing. If you want to start React Native, please use RCTHost start. Nooping"
           cmd:_cmd];
}

- (void)registerModuleForFrameUpdates:(id<RCTBridgeModule>)module withModuleData:(RCTModuleData *)moduleData
{
  [self logError:@"Bridgeless mode does not allow custom modules to register themselves for frame updates. Nooping"
             cmd:_cmd];
}

- (RCTModuleData *)moduleDataForName:(NSString *)moduleName
{
  [self logError:@"Bridgeless mode does not use RCTModuleData. Returning nil." cmd:_cmd];
  return nil;
}

- (void)registerAdditionalModuleClasses:(NSArray<Class> *)newModules
{
  [self
      logError:
          @"This API is unsupported. Please return all module classes from your app's RCTTurboModuleManagerDelegate getModuleClassFromName:. Nooping."
           cmd:_cmd];
}

- (void)updateModuleWithInstance:(id<RCTBridgeModule>)instance
{
  [self logError:@"Bridgeless mode does not support module replacement. Nooping." cmd:_cmd];
}

- (void)startProfiling
{
  [self logWarning:@"Bridgeless mode does not support this method. Nooping." cmd:_cmd];
}

- (void)stopProfiling:(void (^)(NSData *))callback
{
  [self logWarning:@"Bridgeless mode does not support this method. Nooping." cmd:_cmd];
}

- (id)callNativeModule:(NSUInteger)moduleID method:(NSUInteger)methodID params:(NSArray *)params
{
  [self logError:@"Bridgeless mode does not support this method. Nooping and returning nil." cmd:_cmd];
  return nil;
}

- (void)logMessage:(NSString *)message level:(NSString *)level
{
  [self logWarning:@"Bridgeless mode does not support this method. Nooping." cmd:_cmd];
}

- (void)_immediatelyCallTimer:(NSNumber *)timer
{
  [self logWarning:@"Bridgeless mode does not support this method. Nooping." cmd:_cmd];
}

/**
 * RCTBridge (Inspector)
 */
- (BOOL)inspectable
{
  [self logWarning:@"Bridgeless mode does not support this method. Returning NO." cmd:_cmd];
  return NO;
}

/**
 * RCTBridge (RCTUIManager)
 */
- (RCTUIManager *)uiManager
{
  return (RCTUIManager *)_uiManagerProxy;
}

/**
 * NSProxy setup
 */
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel;
{
  return [RCTCxxBridge instanceMethodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  [self logError:@"This method is unsupported." cmd:invocation.selector];
}

/**
 * Logging
 * TODO(155977839): Add a means to configure/disable these logs, so people do not ignore all LogBoxes
 */
- (void)logWarning:(NSString *)message cmd:(SEL)cmd
{
  RCTLogWarn(@"RCTBridgeProxy: Calling [bridge %@]. %@", NSStringFromSelector(cmd), message);
}

- (void)logError:(NSString *)message cmd:(SEL)cmd
{
  RCTLogError(@"RCTBridgeProxy: Calling [bridge %@]. %@", NSStringFromSelector(cmd), message);
}

@end

@implementation RCTUIManagerProxy {
  RCTViewRegistry *_viewRegistry;
}
- (instancetype)initWithViewRegistry:(RCTViewRegistry *)viewRegistry
{
  self = [super self];
  if (self) {
    _viewRegistry = viewRegistry;
  }
  return self;
}

/**
 * RCTViewRegistry
 */
- (UIView *)viewForReactTag:(NSNumber *)reactTag
{
  [self logWarning:@"Please migrate to RCTViewRegistry: @synthesize viewRegistry_DEPRECATED = _viewRegistry_DEPRECATED."
               cmd:_cmd];
  return [_viewRegistry viewForReactTag:reactTag];
}

- (void)addUIBlock:(RCTViewManagerUIBlock)block
{
  [self
      logWarning:
          @"This method isn't implemented faithfully: the viewRegistry passed to RCTViewManagerUIBlock is nil. Please migrate to RCTViewRegistry: @synthesize viewRegistry_DEPRECATED = _viewRegistry_DEPRECATED."
             cmd:_cmd];
  __weak __typeof(self) weakSelf = self;
  RCTExecuteOnMainQueue(^{
    __typeof(self) strongSelf = weakSelf;
    if (strongSelf) {
      block((RCTUIManager *)strongSelf, nil);
    }
  });
}

/**
 * NSProxy setup
 */
- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
  return [RCTUIManager instanceMethodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  [self logError:@"This methid is unsupported." cmd:invocation.selector];
}

/**
 * Logging
 * TODO(155977839): Add a means to configure/disable these logs, so people do not ignore all LogBoxes
 */
- (void)logWarning:(NSString *)message cmd:(SEL)cmd
{
  RCTLogWarn(
      @"RCTBridgeProxy (RCTUIManagerProxy): Calling [bridge.uiManager %@]. %@", NSStringFromSelector(cmd), message);
}

- (void)logError:(NSString *)message cmd:(SEL)cmd
{
  RCTLogError(
      @"RCTBridgeProxy (RCTUIManagerProxy): Calling [bridge.uiManager %@]. %@", NSStringFromSelector(cmd), message);
}

@end
