#import <React/RCTBridgeModule.h>

@interface RCT_EXTERN_MODULE(MemoryModule, NSObject)

RCT_EXTERN_METHOD(getMemories:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject)

@end
