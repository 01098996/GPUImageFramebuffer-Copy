#import "GPUImageFramebuffer.h"

@interface GPUImageFramebuffer (Copy)

+ (GPUImageFramebuffer *)createFramebufferWithCopyFramebuffer:(GPUImageFramebuffer *)framebuffer;

- (void)copyFramebufferToSelf:(GPUImageFramebuffer *)framebuffer;

@end
