#import <CoreImage/CoreImage.h>
#import "FNHUD.h"

static CGFloat HUD_Message_Max_Width = 320;
static CGFloat HUD_Message_Min_Width = 80; //120;
static CGFloat HUD_Message_Max_Height = 240;
static CGFloat HUD_Image_Width_Height = 48;
static CGFloat HUD_Image_Message_Margin = 10;
static NSColor* HUD_backgroudColor;
static NSColor* HUD_messageColor;

static NSEdgeInsets HUD_Padding;
static NSFont* HUD_Font;

static NSImage* HUD_Image_Success;
static NSImage* HUD_Image_Error;

static int64_t HUD_Auto_Hide_Seconds = 3;

NSMutableArray<NSView*>* __allHuds;      //记录所有展现的HUD

@interface FNHUD () {
@private
    
}

@end

@implementation FNHUD

+(void)showLoading:(NSString*)msg inView:(NSView*)view {
    [self _createUIWithMsg:msg image:nil inView:view withMask:YES autoHide:NO];
}

+(void)setup {
    
    //初始化参数
    if (HUD_Font==nil) HUD_Font = [NSFont boldSystemFontOfSize:15];
    HUD_Padding = NSEdgeInsetsMake(12, 12, 12, 12);
    if (__allHuds==nil) __allHuds = [NSMutableArray new];
    if (HUD_backgroudColor==nil) HUD_backgroudColor = [NSColor colorWithWhite:0 alpha:0.65];
    if (HUD_messageColor==nil) HUD_messageColor = [NSColor colorWithWhite:1 alpha:1];
    if (HUD_Image_Success==nil) HUD_Image_Success = [NSImage imageNamed:@"yy_hud_success"];
    if (HUD_Image_Error==nil) HUD_Image_Error = [NSImage imageNamed:@"yy_hud_fail"];
    
}

+(instancetype)_createInstanceWithFrame:(CGRect)frame {
    
    FNHUD* hud = [[FNHUD alloc] initWithFrame:frame];
    hud.wantsLayer = YES;
    hud.layer.backgroundColor = HUD_backgroudColor.CGColor;
    hud.layer.cornerRadius = 6;
    hud.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin;
    return hud;
}

/*
 计算弹出对话框的大小
 算法：计算文本在HUD_Message_Max_Width x HUD_Message_Max_Height内的实际大小：f
 如果存在图标，高度增加图标高度
 加上padding
 */
+(CGRect)_calcRectWithMessage:(NSString*)message hasImage:(BOOL)hasImage parentSize:(CGSize)parentSize {
    
    CGRect f = [message boundingRectWithSize:CGSizeMake(HUD_Message_Max_Width, HUD_Message_Max_Height) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:HUD_Font} context:nil];
    f.size.width = MAX(f.size.width, HUD_Message_Min_Width);
    f.size.height += hasImage?(HUD_Image_Width_Height + HUD_Image_Message_Margin):0;
    f.size.width += HUD_Padding.left + HUD_Padding.right;
    f.size.height += HUD_Padding.top + HUD_Padding.bottom;
    f.origin.x = (parentSize.width - f.size.width) / 2;
    f.origin.y = (parentSize.height - f.size.height) / 2;
    return f;
}

+(void)showMessage:(NSString*)msg inView:(NSView*)view {
    [self _createUIWithMsg:msg image:nil inView:view withMask:NO autoHide:YES];
}

+(void)showSuccess:(NSString*)msg inView:(NSView*)view {
    [self _createUIWithMsg:msg image:HUD_Image_Success inView:view withMask:NO autoHide:YES];
}

+(void)showError:(NSString*)msg inView:(NSView*)view {
    [self _createUIWithMsg:msg image:HUD_Image_Error inView:view withMask:NO autoHide:YES];
}

+(void)_createUIWithMsg:(NSString*)msg image:(NSImage*)image inView:(NSView*)view withMask:(BOOL)withMask autoHide:(BOOL)autoHide {
    if (msg==nil) return;
    if (view==nil) return;
    [FNHUD hide];
    BOOL hasImage = image!=nil;
    if (!autoHide) hasImage = YES;
    CGRect frame = [FNHUD _calcRectWithMessage:msg hasImage:hasImage parentSize:view.frame.size];
    FNHUD* hud = [FNHUD _createInstanceWithFrame:frame];
    
    CGRect textFrame = [msg boundingRectWithSize:CGSizeMake(HUD_Message_Max_Width, HUD_Message_Max_Height) options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:HUD_Font} context:nil];
    //避免最后一个字被吃掉
    textFrame.size.width = MIN(HUD_Message_Max_Width, textFrame.size.width + 10);
    textFrame.origin.x = (frame.size.width - textFrame.size.width) / 2;
    textFrame.origin.y = frame.size.height - (textFrame.size.height + HUD_Padding.top + (hasImage?(HUD_Image_Width_Height + HUD_Image_Message_Margin):0));
    NSTextField* labMsg = [[NSTextField alloc] initWithFrame:textFrame];
    labMsg.font = HUD_Font;
    labMsg.stringValue = msg;
    labMsg.textColor = HUD_messageColor;
    labMsg.editable = NO;
    labMsg.backgroundColor = [NSColor clearColor];
    labMsg.maximumNumberOfLines = 0;
    labMsg.drawsBackground = true;
    labMsg.bordered = NO;
    [hud addSubview:labMsg];
    
    if (image) {
        //如果自动隐藏，显示普通图片，否则显示风火轮
        CGRect imageFrame = CGRectMake((frame.size.width - HUD_Image_Width_Height) / 2, frame.size.height - HUD_Padding.top - HUD_Image_Width_Height, HUD_Image_Width_Height, HUD_Image_Width_Height);
        
        
        NSImageView* imgView = [[NSImageView alloc] initWithFrame:imageFrame];
        imgView.image = image;
        imgView.imageScaling = NSImageScaleAxesIndependently;
        [hud addSubview:imgView];
        
    } else if (autoHide==NO) {
        CGRect imageFrame = CGRectMake((frame.size.width - HUD_Image_Width_Height) / 2, frame.size.height - HUD_Padding.top - HUD_Image_Width_Height, HUD_Image_Width_Height, HUD_Image_Width_Height);
        
        NSProgressIndicator* prog = [[NSProgressIndicator alloc] initWithFrame:imageFrame];
        prog.style = NSProgressIndicatorStyleSpinning;
        prog.controlSize = NSControlSizeRegular;
        prog.indeterminate = YES;
        
        [hud addSubview:prog];
        [prog startAnimation:nil];
        
        CIFilter *lighten = [CIFilter filterWithName:@"CIColorControls"];
        [lighten setDefaults];
        [lighten setValue:@1 forKey:@"inputBrightness"];
        [prog setContentFilters:[NSArray arrayWithObjects:lighten, nil]];
    }
    
    //如果允许遮照，创建一个和view一样大的UIView，禁止用户操作
    NSView* topView = nil;
    if (withMask) {
        NSView* viewMask = [[HUDNoMouseView alloc] initWithFrame:NSMakeRect(0, 0, view.frame.size.width, view.frame.size.height)];
        viewMask.autoresizingMask = NSViewMinXMargin | NSViewMaxXMargin | NSViewMinYMargin | NSViewMaxYMargin | NSViewWidthSizable | NSViewHeightSizable;
        [viewMask addSubview:hud];
        topView = viewMask;
        
    } else {
        topView = hud;
    }
    topView.alphaValue = 0;
    [view addSubview:topView];
    topView.animator.alphaValue = 1.0;
    [__allHuds addObject:topView];
    
    if (autoHide) {
        //消失定时器
        __weak NSView* weakRef = topView;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(HUD_Auto_Hide_Seconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (weakRef && weakRef.alphaValue!=0.0) {
                weakRef.animator.alphaValue = 0.0;
                [__allHuds removeObject:weakRef];
            }
        });
    }
}

+(void)hide {
    [__allHuds enumerateObjectsUsingBlock:^(NSView * _Nonnull hud, NSUInteger idx, BOOL * _Nonnull stop) {
        [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context){
            hud.animator.alphaValue = 0;
        } completionHandler:^{
            [hud removeFromSuperview];
            [__allHuds removeObject:hud];
        }];
    }];
}
@end


@implementation HUDNoMouseView
- (void)mouseDown:(NSEvent*)anEvent {
 
}
@end

