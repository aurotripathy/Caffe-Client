

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <UINavigationControllerDelegate,
UIImagePickerControllerDelegate, NSURLConnectionDelegate>{

    IBOutlet UILabel *response;
    NSMutableData *_responseData;
    
}


@property (strong, nonatomic) IBOutlet UIImageView* imageView;

- (IBAction) pickImage:(id)sender;

- (IBAction)tagRegion:(id)sender;

- (IBAction)tagEntire:(id)sender;

@end

