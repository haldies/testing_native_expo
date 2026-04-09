#import <React/RCTViewManager.h>

@interface RCT_EXTERN_MODULE(DualCameraViewManager, RCTViewManager)

RCT_EXPORT_VIEW_PROPERTY(onRecordingStateChanged, RCTDirectEventBlock)
RCT_EXTERN_METHOD(setIsDualMode:(nonnull NSNumber *)node dual:(BOOL)dual)
RCT_EXTERN_METHOD(toggleRecording:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(flipCamera:(nonnull NSNumber *)node)
RCT_EXTERN_METHOD(setFPS:(nonnull NSNumber *)node fps:(nonnull NSNumber *)fps)
RCT_EXTERN_METHOD(setResolution:(nonnull NSNumber *)node res:(nonnull NSString *)res)
RCT_EXTERN_METHOD(setIsMirrored:(nonnull NSNumber *)node mirrored:(BOOL)mirrored)

@end
