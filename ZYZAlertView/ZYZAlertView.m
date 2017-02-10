//
//  ZYZAlertView.m
//  WitCarLoan
//
//  Created by AsiaZhang on 15/11/5.
//  Copyright © 2015年 zhifu360. All rights reserved.

#import "ZYZAlertView.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#define IS_IPAD (UI_USER_INTERFACE_IDIOM()==UIUserInterfaceIdiomPad)

#define kContentLabelWidth      ScreenWidth - 80
#define ZContentLabelWidth      ScreenWidth - 80 - 20
#define ButtonWidth (ScreenWidth - 80)/2
#define ZYZAlertLeavel  300

static CGFloat kTransitionDuration = 0.3f;
static NSMutableArray *gAlertViewStack = nil;
static UIWindow *gPreviouseKeyWindow = nil;
static UIWindow *gMaskWindow = nil;
@implementation NSObject (ZYZAlert)

- (void)alertCustomDlg:(NSString *)message
{
    ZYZAlertView *alert = [[ZYZAlertView alloc] initWithTitle:@"温馨提示"
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:@"知道了"
                                          otherButtonTitles:nil];
    [alert show];
}

- (void)dismissAllCustomAlerts
{
    for (ZYZAlertView *alert in gAlertViewStack)
    {
        if ([alert delegate] == self && alert.visible) {
            [alert setDelegate:nil];
            [alert dismiss];
        }
    }
}

@end

/*********************************************************************/
@interface ZYZAlertView(){
     NSInteger clickedButtonIndex;
}

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *bodyTextLabel;
@property (nonatomic, strong) UITextView *bodyTextView;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UIView *contentView;

@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *otherButton;
//orientation
- (void)registerObservers;
- (void)removeObservers;
- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation;
- (void)sizeToFitOrientation:(BOOL)transform;
- (CGAffineTransform)transformForOrientation;

+ (ZYZAlertView *)getStackTopAlertView;
+ (void)pushAlertViewInStack:(ZYZAlertView *)alertView;
+ (void)popAlertViewFromStack;

+ (void)presentMaskWindow;
+ (void)dismissMaskWindow;

+ (void)addAlertViewOnMaskWindow:(ZYZAlertView *)alertView;
+ (void)removeAlertViewFormMaskWindow:(ZYZAlertView *)alertView;

- (void)bounce0Animation;
- (void)bounce1AnimationDidStop;
- (void)bounce2AnimationDidStop;
- (void)bounceDidStop;

- (void)dismissAlertView;
//tools
+ (CGFloat)heightOfString:(NSString *)message withWidth:(CGFloat)width;
@end

@implementation ZYZAlertView

-(void)dealloc{
    _delegate = nil;
    _cancelBlock = nil;
    _confirmBlock = nil;
    [self removeObserver:self forKeyPath:@"dimBackground"];
    [self removeObserver:self forKeyPath:@"contentAlignment"];
}

- (void)initData
{
    _shouldDismissAfterConfirm = YES;
    _dimBackground = YES;
    self.backgroundColor = [UIColor clearColor];
    _contentAlignment =  NSTextAlignmentCenter;
    
    [self addObserver:self
           forKeyPath:@"dimBackground"
              options:NSKeyValueObservingOptionNew
              context:NULL];
    
    [self addObserver:self
           forKeyPath:@"contentAlignment"
              options:NSKeyValueObservingOptionNew
              context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if ([keyPath isEqualToString:@"dimBackground"]) {
        [self setNeedsDisplay];
    }else if ([keyPath isEqualToString:@"contentAlignment"]){
        self.bodyTextLabel.textAlignment = self.contentAlignment;
        self.bodyTextView.textAlignment = self.contentAlignment;
    }
}

-(id)initWithTitle:(NSString *)title message:(NSString *)message delegate:(id<ZYZAlertViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitle{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        [self initData];
        _delegate = delegate;
        _style = ZYZAlertViewStyleDefault;
        //默认温馨提示
        CGFloat titleHeight = 0.0;
        if (title != nil) {
            titleHeight = 30.0;
        }
        //content view
        CGFloat centerY = self.bounds.size.height * 0.46;
        CGFloat boxWidth = 260;   //弹出框宽度
        CGFloat contentWidth = 220;
        CGRect titleBgFrame = CGRectMake(0, 3, boxWidth, titleHeight+10);
        CGRect titleFrame = CGRectMake((boxWidth-contentWidth)/2, titleBgFrame.origin.y, contentWidth, 40);
        
       // 计算content
        UIFont *titleFont = [UIFont systemFontOfSize:20.0f];
        UIFont *contentFont = [UIFont systemFontOfSize:16.0f];
        CGSize size = CGSizeMake(contentWidth, 1000);
        CGSize messageSize = [message boundingRectWithSize:size options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:contentFont} context:nil].size;
        CGFloat contentHeight = messageSize.height > 20 ? messageSize.height : 20; 
        BOOL isNeedUseTextView = NO;
        if (contentHeight > 240)  //content最高240,12行
        {
            isNeedUseTextView = YES;
            contentHeight = 240;
        }else if (contentHeight < 60){
            contentHeight = 60;
        }
         CGRect contentFrame = CGRectMake((boxWidth-contentWidth)/2, CGRectGetMaxY(titleBgFrame), contentWidth, contentHeight);
        //button 1
        CGFloat btnTop = CGRectGetMaxY(contentFrame) + 9;
        CGFloat btnHeight = 35;
        if(cancelButtonTitle && otherButtonTitle){
            [self.cancelButton setTitleColor:[UIColor darkGrayColor]
                                    forState:UIControlStateNormal];
            [self.cancelButton setTitleShadowColor:[UIColor whiteColor]
                                          forState:UIControlStateNormal];
            //            self.cancelButton.titleLabel.shadowOffset = CGSizeMake(0.5, 0.5);
            [self.cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
            [self.cancelButton setFrame:CGRectMake(10, btnTop, ButtonWidth, btnHeight)];
            [self.cancelButton setTag:0];
            
            [self.otherButton setTitleColor:[UIColor whiteColor]
                                   forState:UIControlStateNormal];
            [self.otherButton setTitleShadowColor:[UIColor whiteColor]
                                         forState:UIControlStateNormal];
            //            self.otherButton.titleLabel.shadowOffset = CGSizeMake(0.5, 0.5);
            [self.otherButton setTitle:otherButtonTitle forState:UIControlStateNormal];
            [self.otherButton setFrame:CGRectMake(CGRectGetMaxX(self.cancelButton.frame)+10, btnTop, ButtonWidth, btnHeight)];
            [self.otherButton setTag:1];
            
            [self.contentView addSubview:self.cancelButton];
            [self.contentView addSubview:self.otherButton];
        }else if (cancelButtonTitle){
            [self.cancelButton setTitleColor:[UIColor whiteColor]
                                    forState:UIControlStateNormal];
            [self.cancelButton setTitleShadowColor:[UIColor whiteColor]
                                          forState:UIControlStateNormal];
            //            self.cancelButton.titleLabel.shadowOffset = CGSizeMake(0.5, 0.5);
            [self.cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
            [self.cancelButton setFrame:CGRectMake(60, btnTop, kContentLabelWidth,btnHeight)];
            [self.cancelButton setTag:0];
            [self.contentView addSubview:self.cancelButton];
        }else if (otherButtonTitle){
            [self.otherButton setTitleColor:[UIColor whiteColor]
                                   forState:UIControlStateNormal];
            [self.otherButton setTitleShadowColor:[UIColor whiteColor]
                                         forState:UIControlStateNormal];
            //            self.otherButton.titleLabel.shadowOffset = CGSizeMake(0.5, 0.5);
            [self.otherButton setTitle:otherButtonTitle forState:UIControlStateNormal];
            [self.otherButton setFrame:CGRectMake(60, btnTop, kContentLabelWidth, btnHeight)];
            [self.otherButton setTag:0];
            [self.contentView addSubview:self.otherButton];
        }
        CGFloat boxHeight =  CGRectGetMaxY(titleBgFrame)+contentHeight+10+btnHeight+10;
        CGRect boxFrame = CGRectMake((self.frame.size.width-boxWidth)/2, centerY-boxHeight/2, boxWidth, boxHeight);
        self.contentView.frame = boxFrame;
        self.contentView.clipsToBounds = YES;
        self.contentView.layer.cornerRadius = 1.0;
        self.contentView.backgroundColor = [UIColor whiteColor];
        if (title != nil)
        {
            //titleBg imageView
            UIImageView *titleBg = [[UIImageView alloc] init];
            titleBg.layer.shadowColor = [UIColor grayColor].CGColor;
            titleBg.layer.shadowOffset = CGSizeMake(0.7, 0.7);
            titleBg.layer.shadowOpacity = 0.8;
            titleBg.clipsToBounds = NO;
            titleBg.frame = titleBgFrame;
            titleBg.image = [UIImage imageNamed:@"system_nav_bg.png"];
            [self.contentView addSubview:titleBg];
            
            //titleLabel
            self.titleLabel.text = title;
            self.titleLabel.frame = titleFrame;
            self.titleLabel.textColor = [UIColor darkTextColor];
            self.titleLabel.shadowOffset = CGSizeMake(1, 1);
            self.titleLabel.shadowColor = [UIColor grayColor];
            self.titleLabel.font = titleFont;
            [self.contentView addSubview:self.titleLabel];
        }
       
        if (isNeedUseTextView) {
            self.bodyTextView.text = message;
            self.bodyTextView.frame = contentFrame;
            self.bodyTextView.font = contentFont;
            self.bodyTextView.textColor = [UIColor grayColor];
            [self.contentView addSubview:self.bodyTextView];
        }else{
            self.bodyTextLabel.text = message;
            self.bodyTextLabel.frame = contentFrame;
            self.bodyTextLabel.font = contentFont;
            self.bodyTextLabel.textColor = [UIColor grayColor];
            //            self.bodyTextLabel.shadowOffset = CGSizeMake(1, 1);
            //            self.bodyTextLabel.shadowColor = [UIColor navTintColor];
            [self.contentView addSubview:self.bodyTextLabel];
        }
    }
    return self;
}

- (id)initWithContentView:(UIView *)contentView
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        [self initData];
        
        self.contentView = contentView;
        self.contentView.center = self.center;
        [self addSubview:self.contentView];
        _style = ZYZAlertViewStyleCustomView;
    }
    return self;
}

-(id)initWithStyle:(ZYZAlertViewStyle)style Title:(NSString *)title message:(NSString *)message customView:(UIView *)customView delegate:(id<ZYZAlertViewDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSString *)otherButtonTitle
{
    _style = style;
    switch (style) {
        case ZYZAlertViewStyleDefault:
        {
            return [self initWithTitle:title
                               message:message
                              delegate:delegate
                     cancelButtonTitle:cancelButtonTitle
                     otherButtonTitles:otherButtonTitle];

        }
            break;
        case ZYZAlertViewStyle1:
        {
            self = [super initWithFrame:[UIScreen mainScreen].bounds];
            if (self) {
                [self initData];
                _delegate = delegate;
                
                //content view
                CGFloat titleHeight = 42.0f;
                CGFloat bodyHeight = [ZYZAlertView heightOfString:message withWidth:kContentLabelWidth]+30;
                CGFloat customViewHeight = 0.0f;
                if (customView) {
                    self.customView = customView;
                    customViewHeight = customView.frame.size.height;
                }
                CGFloat buttonPartHeight = 50.0f;
                BOOL isNeedUserTextView = bodyHeight > 170;
                bodyHeight = isNeedUserTextView?170:bodyHeight;
                
                CGFloat finalHeight = titleHeight+bodyHeight+customViewHeight+buttonPartHeight+10;
                self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
                self.contentView.layer.cornerRadius = 6.0;
                CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height-20;
                self.contentView.frame = CGRectMake(40, (screenHeight-finalHeight)/2.0, kContentLabelWidth, finalHeight);
                UIView *alertMainView = [[UIView alloc] init];
                alertMainView.frame = CGRectMake(5, 5, 270, finalHeight-10);
                alertMainView.backgroundColor =[UIColor colorWithRed:231/255.0 green:236/255.0 blue:239/255.0 alpha:1.0];
                alertMainView.layer.cornerRadius = 4.0;
                [self.contentView addSubview:alertMainView];
                UIImageView *titleBgImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 270, titleHeight)];
                UIImage *image1 = [UIImage imageNamed:@"alert_title_bg.png"];
                UIImage *streImage1 = [image1 stretchableImageWithLeftCapWidth:image1.size.width/2 topCapHeight:0];
                titleBgImageView.image = streImage1;
                [alertMainView addSubview:titleBgImageView];
                //titleLabel
                UIImageView *titleTipImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"alert_title_tip.png"]];
                UIFont *titleFont = [UIFont boldSystemFontOfSize:20.0f];
                CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName:titleFont}];
                CGFloat titleWidth = titleSize.width<240?titleSize.width:240;
                self.titleLabel.text = title;
                self.titleLabel.font = titleFont;
                self.titleLabel.textColor = [UIColor whiteColor];
                self.titleLabel.adjustsFontSizeToFitWidth = YES;
                CGFloat orgionX = 5+(240-titleWidth)/2+20;
                self.titleLabel.frame = CGRectMake(orgionX, 0, titleWidth, titleHeight);
                titleTipImageView.frame = CGRectMake(self.titleLabel.frame.origin.x-22, 11, 20, 20);
                [alertMainView addSubview:titleTipImageView];
                [alertMainView addSubview:self.titleLabel];
                //bodyLabel
                if (isNeedUserTextView) {
                    self.bodyTextView.text = message;
                    self.bodyTextView.frame = CGRectMake(5, titleHeight, kContentLabelWidth, bodyHeight);
                    self.bodyTextView.font = [UIFont systemFontOfSize:16.0f];
                    [alertMainView addSubview:self.bodyTextView];
                }else{
                    self.bodyTextLabel.text = message;
                    self.bodyTextLabel.frame = CGRectMake(5, titleHeight, kContentLabelWidth, bodyHeight);
                    self.bodyTextLabel.font = [UIFont systemFontOfSize:16.0f];
                    [alertMainView addSubview:self.bodyTextLabel];
                }
                //sepLine
                UIImageView *sepLine = [[UIImageView alloc] initWithFrame:CGRectMake(0, titleHeight+bodyHeight, 270, 1)];
                UIImage *image2 = [UIImage imageNamed:@"concave_line.png"];
                UIImage *streImage2 = [image2 stretchableImageWithLeftCapWidth:image2.size.width/2 topCapHeight:0];
                sepLine.image = streImage2;
                [alertMainView addSubview:sepLine];
                //custom view
                if (customView) {
                    customView.frame = CGRectMake(0, titleHeight+bodyHeight+5, customView.frame.size.width, customView.frame.size.height);
                    [alertMainView addSubview:customView];
                }
                //buttons
                if (cancelButtonTitle && otherButtonTitle) {
                    CGFloat buttonTopPosition = titleHeight+bodyHeight+customViewHeight+10;
                    [self.cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
                    [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    [self.cancelButton setFrame:CGRectMake(30, buttonTopPosition, 80, 33)];
                    [self.cancelButton setTag:0];
                    [self.otherButton setTitle:otherButtonTitle forState:UIControlStateNormal];
                    [self.otherButton setFrame:CGRectMake(CGRectGetMaxX(self.cancelButton.frame)+50, buttonTopPosition, 80, 33)];
                    [self.otherButton setTag:1];
                    [alertMainView addSubview:self.cancelButton];
                    [alertMainView addSubview:self.otherButton];
                }else if (cancelButtonTitle){
                    CGFloat buttonTopPosition = titleHeight+bodyHeight+customViewHeight+10;
                    [self.cancelButton setTitle:cancelButtonTitle?cancelButtonTitle:otherButtonTitle forState:UIControlStateNormal];
                    [self.cancelButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    [self.cancelButton setFrame:CGRectMake(30, buttonTopPosition, 210, 33)];
                    [self.cancelButton setTag:0];
                    [alertMainView addSubview:self.cancelButton];
                }else if (otherButtonTitle){
                    CGFloat buttonTopPosition = titleHeight+bodyHeight+customViewHeight+10;
                    [self.otherButton setTitle:cancelButtonTitle?cancelButtonTitle:otherButtonTitle forState:UIControlStateNormal];
                    [self.otherButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
                    [self.otherButton setFrame:CGRectMake(30, buttonTopPosition, 210, 33)];
                    [self.otherButton setTag:0];
                    [alertMainView addSubview:self.otherButton];
                }
            }
            return self;
            break;
        }
        case ZYZAlertViewStyleCustomView:
        {
        
        }
        case ZYZAlertViewStyleSmartCar:
        {
            self = [super initWithFrame:[UIScreen mainScreen].bounds];
            if (self) {
                [self initData];
                
                _delegate = delegate;
                
                //content view
                CGFloat titleHeight = 0.0f;
                if (title)
                {
                    titleHeight = 40.0f;
                }
                
                CGFloat bodyHeight = 0.0f;
                
                if (message)
                {
                    bodyHeight = [ZYZAlertView heightOfString:message withWidth:kContentLabelWidth]+30;
                }
                
                CGFloat customViewHeight = 0.0f;
                if (customView) {
                    self.customView = customView;
                    customViewHeight = customView.frame.size.height;
                }
                CGFloat buttonPartHeight = 50.0f;

                BOOL isNeedUserTextView = bodyHeight > 170;
                bodyHeight = isNeedUserTextView?170:bodyHeight;
                
                CGFloat finalHeight = titleHeight+bodyHeight+customViewHeight+buttonPartHeight + 5;
                self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
                self.contentView.layer.cornerRadius = 6.0;
                CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height-20;
                self.contentView.frame = CGRectMake(40, (screenHeight-finalHeight)/2.0, kContentLabelWidth, finalHeight);
                
                UIView *alertMainView = [[UIView alloc] init];
                alertMainView.frame = CGRectMake(0, 0, kContentLabelWidth, finalHeight);
                alertMainView.backgroundColor = [UIColor whiteColor];
                alertMainView.layer.cornerRadius = 6.0;
                [self.contentView addSubview:alertMainView];
                
                UIFont *titleFont = [UIFont boldSystemFontOfSize:19.0f];
                if (!(title.length > 0)) {
                    title = @"提示";
                }
                CGSize titleSize = [title sizeWithAttributes:@{NSFontAttributeName:titleFont}];
                CGFloat titleWidth = titleSize.width<240?titleSize.width:240;
                self.titleLabel.text = title;
                self.titleLabel.font = titleFont;
                self.titleLabel.textColor = [UIColor colorWithRed:215/255.0 green:0/255.0 blue:15/255.0 alpha:1.0];
                self.titleLabel.adjustsFontSizeToFitWidth = YES;
                self.titleLabel.frame = CGRectMake(10, 0, titleWidth, titleHeight);
                [alertMainView addSubview:self.titleLabel];
                
                UIView *topLine = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame)- 1, kContentLabelWidth, 1)];
                topLine.backgroundColor = [UIColor colorWithRed:227/255.0 green:227/255.0 blue:227/255.0 alpha:1.0];

                [alertMainView addSubview:topLine];
                
                UIView *redLine = [[UIView alloc]initWithFrame:CGRectMake(0, CGRectGetMaxY(self.titleLabel.frame)- 1, ButtonWidth - 30, 2)];
                redLine.backgroundColor = [UIColor colorWithRed:215/255.0 green:0/255.0 blue:15/255.0 alpha:1.0];
                [alertMainView addSubview:redLine];
                //bodyLabel
                if (isNeedUserTextView) {
                    self.bodyTextView.text = message;
                    self.bodyTextView.frame = CGRectMake(10, CGRectGetMaxY(self.titleLabel.frame) + 5, ZContentLabelWidth, bodyHeight);
                    self.bodyTextView.textColor = [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0];
                    self.bodyTextView.font = [UIFont systemFontOfSize:15.0f];
                    [alertMainView addSubview:self.bodyTextView];
                }else{
                    self.bodyTextLabel.text = message;
                    self.bodyTextLabel.frame = CGRectMake(10, CGRectGetMaxY(self.titleLabel.frame) + 5, ZContentLabelWidth, bodyHeight);
                    self.bodyTextLabel.font = [UIFont systemFontOfSize:15.0f];
                    self.bodyTextLabel.textColor = [UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0];
                    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc]initWithString:message];;
                    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc]init];
                    [paragraphStyle setLineSpacing:5];
                    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, message.length)];
                    self.bodyTextLabel.attributedText = attributedString;
                    [alertMainView addSubview:self.bodyTextLabel];
                }
                
                CGFloat buttonTopPosition = titleHeight + bodyHeight+customViewHeight+5;
                UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, buttonTopPosition - 1, kContentLabelWidth, 1)];
                lineView.backgroundColor = [UIColor colorWithRed:227/255.0 green:227/255.0 blue:227/255.0 alpha:1.0];
                [alertMainView addSubview:lineView];
                
                //custom view
                if (customView) {
                    customView.frame = CGRectMake(0, 0, customView.frame.size.width, customView.frame.size.height);
                    [alertMainView addSubview:customView];
                }
                
                //buttons
                if (cancelButtonTitle && otherButtonTitle) {
                    [self.cancelButton setBackgroundColor:[UIColor whiteColor]];
                    [self.cancelButton setTitle:cancelButtonTitle forState:UIControlStateNormal];
                    [self.cancelButton setTitleColor:[UIColor colorWithRed:102/255.0 green:102/255.0 blue:102/255.0 alpha:1.0] forState:UIControlStateNormal];
                    [self.cancelButton setTag:0];
                    [self.cancelButton setFrame:CGRectMake(0, buttonTopPosition, ButtonWidth, buttonPartHeight)];
                    [self setViewStyleLeft:self.cancelButton];
                    [self.otherButton setBackgroundColor:[UIColor colorWithRed:215/255.0 green:0/255.0 blue:15/255.0 alpha:1.0]];
                    [self setViewStyleRight:self.otherButton];
                    [self.otherButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    [self.otherButton setTitle:otherButtonTitle forState:UIControlStateNormal];
                    [self.otherButton setTag:1];
                    [self.otherButton setFrame:CGRectMake(ButtonWidth, buttonTopPosition, ButtonWidth, buttonPartHeight)];
                    [alertMainView addSubview:self.cancelButton];
                    [alertMainView addSubview:self.otherButton];
                }else if (cancelButtonTitle){
                    [self.cancelButton setBackgroundColor:[UIColor colorWithRed:215/255.0 green:0/255.0 blue:15/255.0 alpha:1.0]];
                    [self.cancelButton setTitle:cancelButtonTitle?cancelButtonTitle:otherButtonTitle forState:UIControlStateNormal];
                    [self.cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    [self.cancelButton setFrame:CGRectMake(0, buttonTopPosition, kContentLabelWidth, buttonPartHeight)];
                    [self.cancelButton setTag:0];
                    [self setViewStyleRightAndLeft:self.cancelButton];
                    [alertMainView addSubview:self.cancelButton];
                }else if (otherButtonTitle){
                    [self.otherButton setBackgroundColor:[UIColor colorWithRed:215/255.0 green:0/255.0 blue:15/255.0 alpha:1.0]];
                    [self.otherButton setTitle:cancelButtonTitle?cancelButtonTitle:otherButtonTitle forState:UIControlStateNormal];
                    [self.otherButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                    [self.otherButton setFrame:CGRectMake(0, buttonTopPosition, kContentLabelWidth, buttonPartHeight)];
                    [self.otherButton setTag:0];
                     [self setViewStyleRightAndLeft:self.otherButton];
                    [alertMainView addSubview:self.otherButton];
                }
            }
            return self;
            break;
        }
        case ZYZAlertViewStyleLottery:
        {
            return [self initWithTitle:title
                               message:message
                              delegate:delegate
                     cancelButtonTitle:cancelButtonTitle
                     otherButtonTitles:otherButtonTitle];
            return self;
            break;
        }
        case ZYZAlertViewStyleRightCornerCancle:
        {
            self = [super initWithFrame:[UIScreen mainScreen].bounds];
            if (self) {
                [self initData];
                
                _delegate = delegate;
                
                //content view
                CGFloat bodyHeight = 0.0f;
                
                if (message)
                {
                    bodyHeight = [ZYZAlertView heightOfString:message withWidth:ZContentLabelWidth]+20;
                }
                
                CGFloat customViewHeight = 0.0f;
                if (customView) {
                    self.customView = customView;
                    customViewHeight = customView.frame.size.height;
                }
                CGFloat buttonPartHeight = 50.0f;
                
                BOOL isNeedUserTextView = bodyHeight > 170;
                bodyHeight = isNeedUserTextView?170:bodyHeight;
                
                CGFloat finalHeight = 20 + bodyHeight+customViewHeight+buttonPartHeight;
                self.contentView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
                self.contentView.layer.cornerRadius = 6.0;
                CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height-20;
                self.contentView.frame = CGRectMake(40, (screenHeight-finalHeight)/2.0, kContentLabelWidth, finalHeight);
                
                UIView *alertMainView = [[UIView alloc] init];
                alertMainView.frame = CGRectMake(0, 0, kContentLabelWidth, finalHeight);
                alertMainView.backgroundColor = [UIColor whiteColor];
                alertMainView.layer.cornerRadius = 8.0;
                [self.contentView addSubview:alertMainView];
                //bodyLabel
                if (isNeedUserTextView) {
                    self.bodyTextView.text = message;
                    self.bodyTextView.frame = CGRectMake(10, 20, ZContentLabelWidth, bodyHeight);
                    self.bodyTextView.font = [UIFont systemFontOfSize:16.0f];
                    [alertMainView addSubview:self.bodyTextView];
                }else{
                    self.bodyTextLabel.text = message;
                    self.bodyTextLabel.frame = CGRectMake(10, 20, ZContentLabelWidth, bodyHeight);
                    self.bodyTextLabel.font = [UIFont systemFontOfSize:16.0f];
                    [alertMainView addSubview:self.bodyTextLabel];
                }
                
                //custom view
                if (customView) {
                    customView.frame = CGRectMake(0, 0, customView.frame.size.width, customView.frame.size.height);
                    [alertMainView addSubview:customView];
                }
                CGFloat buttonTopPosition = 20 + bodyHeight+customViewHeight+10;
                UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(0, buttonTopPosition - 1, kContentLabelWidth, 1)];
                lineView.backgroundColor = [UIColor colorWithRed:227/255.0 green:227/255.0 blue:227/255.0 alpha:1.0];
                [alertMainView addSubview:lineView];
                if (cancelButtonTitle != nil) {
                    [self.cancelButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
                    [self.cancelButton setFrame:CGRectMake(kContentLabelWidth - 40, 5, 30, 30)];
                    [self.cancelButton setTag:0];
                    [alertMainView addSubview:self.cancelButton];
                }
                self.otherButton.backgroundColor = [UIColor whiteColor];
                [self.otherButton setTitleColor:[UIColor colorWithRed:227/255.0 green:9/255.0 blue:52/255.0 alpha:1.0] forState:UIControlStateNormal];
                [self.otherButton setTitle:otherButtonTitle forState:UIControlStateNormal];
                [self.otherButton setFrame:CGRectMake(0, buttonTopPosition, kContentLabelWidth, 33)];
                [self.otherButton setTag:1];
                [alertMainView addSubview:self.otherButton];
            }
            return self;
            break;
        }
        default:
            break;
    }
     return [super initWithFrame:[UIScreen mainScreen].bounds];
}

-(void)setViewStyleLeft:(UIView *)view{
    
    UIBezierPath * maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ButtonWidth, 50)
                                                    byRoundingCorners:(UIRectCornerBottomLeft)
                                                          cornerRadii:CGSizeMake(6.0f, 6.0f)];
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.frame  = CGRectMake(0, 0, ButtonWidth, 50);
    maskLayer.path   = maskPath.CGPath;
    view.layer.mask  = maskLayer;
    [view.layer setMasksToBounds:YES];
}

-(void)setViewStyleRight:(UIView *)view{
    
    UIBezierPath * maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ButtonWidth, 50)
                                                    byRoundingCorners:(UIRectCornerBottomRight)
                                                          cornerRadii:CGSizeMake(6.0f, 6.0f)];
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.frame  = CGRectMake(0, 0, ButtonWidth, 50);
    maskLayer.path   = maskPath.CGPath;
    view.layer.mask  = maskLayer;
    [view.layer setMasksToBounds:YES];
}


-(void)setViewStyleRightAndLeft:(UIView *)view{
    
    UIBezierPath * maskPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, kContentLabelWidth, 50)
                                                    byRoundingCorners:(UIRectCornerBottomLeft|UIRectCornerBottomRight)
                                                          cornerRadii:CGSizeMake(6.0f, 6.0f)];
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.frame  = CGRectMake(0, 0, kContentLabelWidth, 50);
    maskLayer.path   = maskPath.CGPath;
    view.layer.mask  = maskLayer;
    [view.layer setMasksToBounds:YES];
}


-(BOOL)isVisible
{
    return _visible;
}

- (void)drawRect:(CGRect)rect
{
    if (_dimBackground) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        size_t gradLocationsNum = 2;
        CGFloat gradLocations[2] = {0.0f, 0.0f};
        CGFloat gradColors[8] = {0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.0f,0.40f};
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, gradColors, gradLocations, gradLocationsNum);
        CGColorSpaceRelease(colorSpace);
        
        //Gradient center
        CGPoint gradCenter = self.contentView.center;
        //Gradient radius
        float gradRadius = 320 ;
        //Gradient draw
        CGContextDrawRadialGradient (context, gradient, gradCenter,
                                     0, gradCenter, gradRadius,
                                     kCGGradientDrawsAfterEndLocation);
        CGGradientRelease(gradient);
    }
}

#pragma mark -
#pragma mark orientation

- (void)registerObservers{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)removeObservers{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)orientationDidChange:(NSNotification*)notify
{
    
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if ([self shouldRotateToOrientation:orientation]) {
        if ([_delegate respondsToSelector:@selector(didRotationToInterfaceOrientation:view:alertView:)]) {
            [_delegate didRotationToInterfaceOrientation:UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) view:_customView alertView:self];
        }
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.25f];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationBeginsFromCurrentState:YES];
        [self sizeToFitOrientation:YES];
        [UIView commitAnimations];
    }
}

- (BOOL)shouldRotateToOrientation:(UIInterfaceOrientation)orientation
{
    BOOL result = NO;
    if (_orientation != orientation) {
        result = (orientation == UIInterfaceOrientationPortrait ||
                  orientation == UIInterfaceOrientationPortraitUpsideDown ||
                  orientation == UIInterfaceOrientationLandscapeLeft ||
                  orientation == UIInterfaceOrientationLandscapeRight);
    }
    
    return result;
}

- (void)sizeToFitOrientation:(BOOL)transform
{
    if (transform) {
        self.transform = CGAffineTransformIdentity;
    }
    _orientation = [UIApplication sharedApplication].statusBarOrientation;
    [self sizeToFit];
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    [self setCenter:CGPointMake(screenSize.width/2, screenSize.height/2)];
    if (transform) {
        self.transform = [self transformForOrientation];
    }
}

- (CGAffineTransform)transformForOrientation
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return CGAffineTransformMakeRotation(M_PI*1.5f);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation(M_PI/2.0f);
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGAffineTransformMakeRotation(-M_PI);
    } else {
        return CGAffineTransformIdentity;
    }
}

#pragma mark -
#pragma mark view getters

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.textAlignment = NSTextAlignmentCenter;// UITextAlignmentCenter;
        _titleLabel.backgroundColor = [UIColor clearColor];
    }
    return _titleLabel;
}

- (UILabel *)bodyTextLabel
{
    if (!_bodyTextLabel) {
        _bodyTextLabel = [[UILabel alloc] init];
        _bodyTextLabel.textColor = [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1.0];
        _bodyTextLabel.numberOfLines = 0;
        _bodyTextLabel.lineBreakMode = NSLineBreakByCharWrapping; //UILineBreakModeCharacterWrap;
        _bodyTextLabel.textAlignment = _contentAlignment;
        _bodyTextLabel.backgroundColor = [UIColor clearColor];
    }
    return _bodyTextLabel;
}

- (UITextView *)bodyTextView
{
    if (!_bodyTextView) {
        _bodyTextView = [[UITextView alloc] init];
        _bodyTextLabel.textColor = [UIColor colorWithRed:34/255.0 green:34/255.0 blue:34/255.0 alpha:1.0];
        _bodyTextView.textAlignment = _contentAlignment;
        _bodyTextView.bounces = NO;
        _bodyTextView.backgroundColor = [UIColor clearColor];
        _bodyTextView.editable = NO;
    }
    return _bodyTextView;
}

- (UIView *)contentView
{
    if (!_contentView) {
        _contentView = [[UIView alloc] init];
        [self addSubview:_contentView];
    }
    return _contentView;
}

- (UIButton *)cancelButton{
    
    if (!_cancelButton) {
        _cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_cancelButton setTitle:@"Ok" forState:UIControlStateNormal];
        [_cancelButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelButton;
    
}


- (UIButton *)otherButton{
    
    if (!_otherButton) {
        _otherButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_otherButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_otherButton setTitle:@"Ok" forState:UIControlStateNormal];
        [_otherButton addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    return _otherButton;
    
}

#pragma mark -
#pragma mark block setter

- (void)setCancelBlock:(ZYZBasicBlock)block
{
    _cancelBlock = [block copy];
}

- (void)setConfirmBlock:(ZYZBasicBlock)block
{
    _confirmBlock = [block copy];
}

#pragma mark -
#pragma mark button action

- (void)buttonTapped:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSInteger tag = button.tag;
    clickedButtonIndex = tag;
    
    if ([_delegate conformsToProtocol:@protocol(ZYZAlertViewDelegate)]) {
        
        if ([_delegate respondsToSelector:@selector(alertView:willDismissWithButtonIndex:)]) {
            
            [_delegate alertView:self willDismissWithButtonIndex:tag];
        }
    }
    
    if (button == self.cancelButton) {
        if (_cancelBlock) {
            _cancelBlock();
        }
        [self dismiss];
    }
    else if (button == self.otherButton)
    {
        if (_confirmBlock) {
            _confirmBlock();
        }
        if (_shouldDismissAfterConfirm) {
            [self dismiss];
        }
    }
    
}

#pragma mark -
#pragma mark lify cycle

- (void)show
{
    if (_visible) {
        return;
    }
    _visible = YES;
    
    [self registerObservers];//添加消息，在设备发生旋转时会有相应的处理
    [self sizeToFitOrientation:NO];
    
    
    //如果栈中没有alertview,就表示maskWindow没有弹出，所以弹出maskWindow
    if (![ZYZAlertView getStackTopAlertView]) {
        [ZYZAlertView presentMaskWindow];
    }
    
    //如果有背景图片，添加背景图片
    if (nil != self.backgroundView && ![[gMaskWindow subviews] containsObject:self.backgroundView]) {
        [gMaskWindow addSubview:self.backgroundView];
    }
    //将alertView显示在window上
    [ZYZAlertView addAlertViewOnMaskWindow:self];
    
    self.alpha = 1.0;
    
    //alertView弹出动画
    [self bounce0Animation];
}

- (void)dismiss
{
    if (!_visible) {
        return;
    }
    _visible = NO;
    
    UIView *__bgView = self->_backgroundView;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(dismissAlertView)];
    self.alpha = 0;
    [UIView commitAnimations];
    
    if (__bgView && [[gMaskWindow subviews] containsObject:__bgView]) {
        [__bgView removeFromSuperview];
    }
}

- (void)dismissAlertView{
    [ZYZAlertView removeAlertViewFormMaskWindow:self];
    
    // If there are no dialogs visible, dissmiss mask window too.
    if (![ZYZAlertView getStackTopAlertView]) {
        [ZYZAlertView dismissMaskWindow];
    }
    
    if (_style != ZYZAlertViewStyleCustomView) {
        if ([_delegate conformsToProtocol:@protocol(ZYZAlertViewDelegate)]) {
            if ([_delegate respondsToSelector:@selector(alertView:didDismissWithButtonIndex:)]) {
                [_delegate alertView:self didDismissWithButtonIndex:clickedButtonIndex];
            }
        }
    }
    
    [self removeObservers];
}

+ (void)presentMaskWindow{
    
    if (!gMaskWindow) {
        gMaskWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        //edited by gjf 修改alertview leavel
        gMaskWindow.windowLevel = UIWindowLevelStatusBar + ZYZAlertLeavel;
        gMaskWindow.backgroundColor = [UIColor clearColor];
        gMaskWindow.hidden = YES;
        
        // FIXME: window at index 0 is not awalys previous key window.
        gPreviouseKeyWindow = [[UIApplication sharedApplication].windows objectAtIndex:0];
        [gMaskWindow makeKeyAndVisible];
        
        // Fade in background
        gMaskWindow.alpha = 0;
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        gMaskWindow.alpha = 1;
        [UIView commitAnimations];
    }
}

+ (void)dismissMaskWindow{
    // make previouse window the key again
    if (gMaskWindow) {
        [gPreviouseKeyWindow makeKeyWindow];
        gPreviouseKeyWindow = nil;
        
        gMaskWindow = nil;
    }
}

+ (ZYZAlertView *)getStackTopAlertView{
    ZYZAlertView *topItem = nil;
    if (0 != [gAlertViewStack count]) {
        topItem = [gAlertViewStack lastObject];
    }
    
    return topItem;
}

+ (void)addAlertViewOnMaskWindow:(ZYZAlertView *)alertView{
    if (!gMaskWindow ||[gMaskWindow.subviews containsObject:alertView]) {
        return;
    }
    
    [gMaskWindow addSubview:alertView];
    alertView.hidden = NO;
    
    ZYZAlertView *previousAlertView = [ZYZAlertView getStackTopAlertView];
    if (previousAlertView) {
        previousAlertView.hidden = YES;
    }
    [ZYZAlertView pushAlertViewInStack:alertView];
}

+ (void)removeAlertViewFormMaskWindow:(ZYZAlertView *)alertView{
    if (!gMaskWindow || ![gMaskWindow.subviews containsObject:alertView]) {
        return;
    }
    
    [alertView removeFromSuperview];
    alertView.hidden = YES;
    
    [ZYZAlertView popAlertViewFromStack];
    ZYZAlertView *previousAlertView = [ZYZAlertView getStackTopAlertView];
    if (previousAlertView) {
        previousAlertView.hidden = NO;
        [previousAlertView bounce0Animation];
    }
}

+ (void)pushAlertViewInStack:(ZYZAlertView *)alertView{
    if (!gAlertViewStack) {
        gAlertViewStack = [[NSMutableArray alloc] init];
    }
    [gAlertViewStack addObject:alertView];
}

+ (void)popAlertViewFromStack{
    if (![gAlertViewStack count]) {
        return;
    }
    [gAlertViewStack removeLastObject];
    
    if ([gAlertViewStack count] == 0) {
        gAlertViewStack = nil;
    }
}


#pragma mark -
#pragma mark animation

- (void)bounce0Animation{
    self.contentView.transform = CGAffineTransformScale([self transformForOrientation], 0.001f, 0.001f);
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration/1.5f];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(bounce1AnimationDidStop)];
    self.contentView.transform = CGAffineTransformScale([self transformForOrientation], 1.1f, 1.1f);
    [UIView commitAnimations];
}

- (void)bounce1AnimationDidStop{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration/2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(bounce2AnimationDidStop)];
    self.contentView.transform = CGAffineTransformScale([self transformForOrientation], 0.9f, 0.9f);
    [UIView commitAnimations];
}
- (void)bounce2AnimationDidStop{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration/2];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(bounceDidStop)];
    self.contentView.transform = [self transformForOrientation];
    [UIView commitAnimations];
}

- (void)bounceDidStop{
    
}

#pragma mark -
#pragma mark tools

+ (CGFloat)heightOfString:(NSString *)message withWidth:(CGFloat)width
{
    if (message == nil || [message isEqualToString:@""]) {
        return 20.0f;
    }
    UIFont *contentFont = [UIFont systemFontOfSize:15.0f];
    CGSize size = CGSizeMake(width, 1000);
    CGSize messageSize = [message boundingRectWithSize:size options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:contentFont} context:nil].size;
    return messageSize.height+10.0;
}

@end
