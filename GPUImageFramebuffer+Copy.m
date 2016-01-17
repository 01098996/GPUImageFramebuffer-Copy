#import "GPUImageFramebuffer+Copy.h"
#import "GPUImageFilter.h"

static GLProgram *kCopyProgram = nil;
static GLint kCopyPosition = 0;
static GLint kCopyInputTextureCoordinate = 0;
static GLint kCopyInputImageTexture = 0;

@implementation GPUImageFramebuffer (Copy)

+ (GPUImageFramebuffer *)createFramebufferWithCopyFramebuffer:(GPUImageFramebuffer *)framebuffer
{
#ifdef DEBUG
    GPUImageFramebuffer *fb = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[framebuffer size]
                                                                                    onlyTexture:NO];
#else
    GPUImageFramebuffer *fb = [[GPUImageContext sharedFramebufferCache] fetchFramebufferForSize:[framebuffer size]
                                                                                    onlyTexture:[framebuffer missingFramebuffer]];
#endif
    [fb copyFramebufferToSelf:framebuffer];
    return fb;
}

- (void)copyFramebufferToSelf:(GPUImageFramebuffer *)framebuffer
{
    runSynchronouslyOnVideoProcessingQueue(^{
        [GPUImageContext useImageProcessingContext];
        
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            kCopyProgram = [[GPUImageContext sharedImageProcessingContext] programForVertexShaderString:kGPUImageVertexShaderString fragmentShaderString:kGPUImagePassthroughFragmentShaderString];
            
            if (!kCopyProgram.initialized)
            {
                [kCopyProgram addAttribute:@"position"];
                [kCopyProgram addAttribute:@"inputTextureCoordinate"];
                
                if (![kCopyProgram link])
                {
                    NSString *progLog = [kCopyProgram programLog];
                    NSLog(@"Program link log: %@", progLog);
                    NSString *fragLog = [kCopyProgram fragmentShaderLog];
                    NSLog(@"Fragment shader compile log: %@", fragLog);
                    NSString *vertLog = [kCopyProgram vertexShaderLog];
                    NSLog(@"Vertex shader compile log: %@", vertLog);
                    kCopyProgram = nil;
                    NSAssert(NO, @"Filter shader link failed");
                }
            }
            
            kCopyPosition = [kCopyProgram attributeIndex:@"position"];
            kCopyInputTextureCoordinate = [kCopyProgram attributeIndex:@"inputTextureCoordinate"];
            kCopyInputImageTexture = [kCopyProgram uniformIndex:@"inputImageTexture"]; // This does assume a name of "inputImageTexture" for the fragment shader
             [GPUImageContext setActiveShaderProgram:kCopyProgram];
            
            glEnableVertexAttribArray(kCopyPosition);
            glEnableVertexAttribArray(kCopyInputTextureCoordinate);
        });
        
         [GPUImageContext setActiveShaderProgram:kCopyProgram];
        
        static const GLfloat imageVertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f, 1.0f,
            1.0f, 1.0f,
        };
        
        [self activateFramebuffer];
        
        glClearColor(0.0, 0.0, 0.0, 0.0);
        glClear(GL_COLOR_BUFFER_BIT);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, [framebuffer texture]);
        glUniform1i(kCopyInputImageTexture, 0);
        
        const  GLfloat *texCoords = [GPUImageFilter textureCoordinatesForRotation:kGPUImageNoRotation];
        
        glVertexAttribPointer(kCopyInputTextureCoordinate, 2, GL_FLOAT, GL_FALSE, 0,texCoords);
        glVertexAttribPointer(kCopyPosition, 2, GL_FLOAT, GL_FALSE, 0, imageVertices);
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    });
}

@end
