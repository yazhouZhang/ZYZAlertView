//
//  ZYZAlertView.h
//  WitCarLoan
//
//  Created by AsiaZhang on 15/11/5.
//  Copyright © 2015年 zhifu360. All rights reserved.
// @discussion  这是一个自定义的AlertView，类似于系统的UIAlertView,好处是可以自定义UI,
/*!
 @header      ZYZAlertView
 @abstract    自定义的AlertView
 @author      张亚洲
 @version     v1.0  15-11-5
 1、实现时采用了新创建的window, 可使改控件不至于被其他view挡住。
 2、有一个保存alertView的栈，可同时弹出多个alertView，切不会因此重叠
 3、12-11-5 ,添加字段判断在确定后是否应该消失
 4、12-11-15, 添加可以设置文本对齐方式的属性
 5、12-11-17, 添加大数据量文本的兼容
 6、13-01-15, 添加NSObject注入方法
 */

#import <UIKit/UIKit.h>
@interface NSObject (ZYZAlertView)

- (void)alertCustomDlg:(NSString *)message;

- (void)dismissAllCustomAlerts;

@end
/*!
 @enum      ZYZAlertViewStyle
 @abstract  alertView的style，通过style来确定UI, 现在只有两种UI
 */
typedef enum {
    ZYZAlertViewStyleDefault,        //有title带标题,nil不带标题
    ZYZAlertViewStyle1,              //图书里面用的
    ZYZAlertViewStyleCustomView,     //可放入自定义的view
    ZYZAlertViewStyleLottery,        //彩票里面使用
    ZYZAlertViewStyleSmartCar,   //标题左边样式
    ZYZAlertViewStyleRightCornerCancle   //右上角取消按钮
}ZYZAlertViewStyle;

#if NS_BLOCKS_AVAILABLE
typedef void (^ZYZBasicBlock)(void);
#endif
@protocol ZYZAlertViewDelegate;

@interface ZYZAlertView : UIView
{
@private
    id <ZYZAlertViewDelegate> __weak _delegate;
    UILabel   *_titleLabel;
    UILabel   *_bodyTextLabel;
    UITextView *_bodyTextView;
    UIView    *_customView;
    UIView    *_contentView;
    UIView    *_backgroundView;
    BOOL    _visible;
    BOOL    _dimBackground;
    UIInterfaceOrientation _orientation;
    ZYZAlertViewStyle   _style;
#if NS_BLOCKS_AVAILABLE
    ZYZBasicBlock    _cancelBlock;
    ZYZBasicBlock    _confirmBlock;
#endif
}

/*!
 是否正在显示
 */
@property (nonatomic, readonly, getter=isVisible) BOOL visible;

/*!
 背景是否有渐变背景, 默认YES
 */
@property (nonatomic, assign) BOOL dimBackground;       //是否渐变背景，默认YES

/*!
 背景视图，覆盖全屏的，默认nil
 */
@property (nonatomic, strong) UIView *backgroundView;   //背景view, 可无
@property (nonatomic, assign) ZYZAlertViewStyle style;

/*!
 在点击确认后,是否需要dismiss, 默认YES
 */
@property (nonatomic, assign) BOOL shouldDismissAfterConfirm;

/*!
 文本对齐方式
 */
@property (nonatomic, assign) NSTextAlignment contentAlignment;


@property (nonatomic, weak) id<ZYZAlertViewDelegate> delegate;

/*!
 @abstract      点击取消按钮的回调
 @discussion    如果你不想用代理的方式来进行回调，可使用该方法
 @param         block  点击取消后执行的程序块
 */
- (void)setCancelBlock:(ZYZBasicBlock)block;

/*!
 @abstract      点击确定按钮的回调
 @discussion    如果你不想用代理的方式来进行回调，可使用该方法
 @param         block  点击确定后执行的程序块
 */
- (void)setConfirmBlock:(ZYZBasicBlock)block;

/*!
 @abstract      初始话方法，默认的style：ZYZAlertViewStyleDefault
 @param         title  标题
 @param         message  内容
 @param         delegate  代理
 @param         cancelButtonTitle  取消按钮title
 @param         otherButtonTitle  其他按钮，如确定
 @result        ZYZAlertView的对象
 */
- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
           delegate:(id <ZYZAlertViewDelegate>)delegate
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString *)otherButtonTitle;

/*!
 @abstract      user this to init with content view
 */
- (id)initWithContentView:(UIView *)contentView;

/*!
 @abstract      初始话方法，默认的style：ZYZAlertViewStyleDefault
 @param         style  UI类型
 @param         title  标题
 @param         message  内容
 @param         customView 自定义的view,位于内容和button的中间（不常用），一般设为nil
 @param         delegate  代理
 @param         cancelButtonTitle  取消按钮title
 @param         otherButtonTitle  其他按钮，如确定
 @result        ZYZAlertView的对象
 */
- (id)initWithStyle:(ZYZAlertViewStyle)style
              Title:(NSString *)title
            message:(NSString *)message
         customView:(UIView *)customView
           delegate:(id <ZYZAlertViewDelegate>)delegate
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSString *)otherButtonTitle;

/*!
 @abstract      弹出
 */
- (void)show;


- (void)dismiss;

@end

/*********************************************************************/

@protocol ZYZAlertViewDelegate <NSObject>

@optional

- (void)alertView:(ZYZAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex; // before animation and hiding view
- (void)alertView:(ZYZAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;

- (void)didRotationToInterfaceOrientation:(BOOL)Landscape view:(UIView*)view alertView:(ZYZAlertView *)aletView;
@end
