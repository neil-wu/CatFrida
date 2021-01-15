

#import <Cocoa/Cocoa.h>

@interface FNHUD : NSView

+(void)showMessage:(NSString*)msg inView:(NSView*)view;

//+(void)showSuccess:(NSString*)msg inView:(NSView*)view;

//+(void)showError:(NSString*)msg inView:(NSView*)view;

+(void)showLoading:(NSString*)msg inView:(NSView*)view;
//
//+(void)showLoading:(NSString*)msg inView:(NSView*)view cancelBlock:(void(^)(void))cancelBlock;

+(void)hide;

+(void)setup;

@end

@interface HUDNoMouseView : NSView
@end
