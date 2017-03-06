//
//  ViewController.m
//  ReactiveCocoaDemo
//
//  Created by 宋俊红 on 17/3/2.
//  Copyright © 2017年 Juny_song. All rights reserved.
//



#import "ViewController.h"
#import "NextViewController.h"


#import <ReactiveObjC/ReactiveObjC.h>
@interface ViewController ()

typedef void(^RWSignInResponse)(BOOL sucess );

@property (weak, nonatomic) IBOutlet UITextField *userNameTF;
@property (weak, nonatomic) IBOutlet UITextField *pwdTF;
@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _tipsLabel.hidden = YES;
    RACSignal *validUserNameSignal = [self.userNameTF.rac_textSignal map:^id (NSString *  value) {
       return @([self isValidUsername:value]);
   }];
    
    RACSignal *validpwdSignal = [self.pwdTF.rac_textSignal map:^id (NSString *  value) {
        return @([self isValidpwd:value]);
    }];
    
    RAC(self.userNameTF,backgroundColor) = [validUserNameSignal map:^id (NSNumber   *value) {
        return [value boolValue]?[UIColor clearColor]:[UIColor redColor];
    }];

    RAC(self.pwdTF,backgroundColor) = [validpwdSignal map:^id (NSNumber   *value) {
        return [value boolValue]?[UIColor clearColor]:[UIColor redColor];
    }];
    
    
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validUserNameSignal,validpwdSignal]
                                                      reduce:^id (NSNumber*usernameValid, NSNumber *passwordValid){
                                                          return @([usernameValid boolValue]&&[passwordValid boolValue]);
    }];
    
    [signUpActiveSignal subscribeNext:^(NSNumber*signupActive) {
        self.loginButton.enabled = [signupActive boolValue];
    }];
   
    
    /*
     你可以看到doNext:是直接跟在按钮点击事件的后面。而且doNext: block并没有返回值。因为它是附加操作，并不改变事件本身。
     
     
     
     上面的doNext: block把按钮置为不可点击，隐藏登录失败提示。然后在subscribeNext: block里重新把按钮置为可点击，并根据登录结果来决定是否显示失败提示。
     */
   [ [[[self.loginButton rac_signalForControlEvents:UIControlEventTouchUpInside]
      doNext:^( id x) {
          self.loginButton.enabled = NO;
          self.tipsLabel.hidden = YES;
      }]
     flattenMap:^id (id x) {
         return [self signInSignal];
     }]
     
    subscribeNext:^(NSNumber *signInSignal) {
        self.loginButton.enabled = YES;
        BOOL success = [signInSignal boolValue];
        self.tipsLabel.hidden = success;
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NextViewController *vc = [[NextViewController alloc]init];
                [self presentViewController:vc animated:YES completion:^{
                    
                }];
            });
           
        }
         NSLog(@"Sign in result: %@", signInSignal);
    }];
}

- (BOOL)isValidUsername:(NSString*)text{
    if (text.length>3) {
        return YES;
    }
    return NO;
}

- (RACSignal*)signInSignal{
    return [RACSignal createSignal:^RACDisposable * (id<RACSubscriber>subscriber) {
       [self signInWithUsername:self.userNameTF.text password:self.pwdTF.text complete:^(BOOL sucess) {
           [subscriber sendNext:@(sucess)];
           [subscriber sendCompleted];
       }];
        return nil;
    }];
}

- (BOOL)isValidpwd:(NSString*)text{
    if (text.length>=6) {
        return YES;
    }
    return NO;
}

- (void)signInWithUsername:(NSString *)username
                  password:(NSString *)password
                  complete:(RWSignInResponse)completeBlock{
    
    if ([self isValidUsername:username]&&[self isValidpwd:password]) {
        if ([username isEqualToString:@"username"] && [password isEqualToString:@"password"]) {
            completeBlock(YES);
        }
        completeBlock(NO);
        
    }else{
        completeBlock(NO);
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
