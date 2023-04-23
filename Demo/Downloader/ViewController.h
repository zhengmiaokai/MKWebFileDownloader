//
//  ViewController.h
//  Downloader
//
//  Created by zhengmiaokai on 2023/4/23.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (nonatomic, weak) IBOutlet UIButton *downloadBtn;
@property (nonatomic, weak) IBOutlet UILabel *statusLab;
@property (nonatomic, weak) IBOutlet UITextField *textField;

- (IBAction)download:(id)sender;

@end

