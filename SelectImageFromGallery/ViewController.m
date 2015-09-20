
//to do, fix the png display issue

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
{
    NSData *jpgdata;
    NSData *jpgSubImgData;
    bool isRegionClassify;
    NSData *syncResData;
    NSMutableURLRequest *request;
    UIActivityIndicatorView *indicator;
    
    #define URL            @"http://54.67.90.20:5000/classify_upload_json"  // change this URL
    #define NO_CONNECTION  @"No Connection"
    #define NO_IMAGE       @"NO IMAGE SELECTED"
    #define REQUESTED_COUNT 5
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    jpgdata = nil;
    jpgSubImgData = nil;
    isRegionClassify = false;
    [self initPB];
}

- (IBAction)tagRegion:(id)sender {
    isRegionClassify = true;
}

- (IBAction) pickImage:(id)sender{
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}


// credits http://stackoverflow.com/questions/6141298/how-to-scale-down-a-uiimage-and-make-it-crispy-sharp-at-the-same-time-instead
- (UIImage *)resizeImage:(UIImage*)image newSize:(CGSize)newSize
{
    
    if ((image.size.width > 512) && (image.size.height > 512)) { //go about resizing, otherwise leave alone
        CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
        NSLog(@"Resize dimensions hieght=%f, width=%f", newSize.height, newSize.width);
        CGImageRef imageRef = image.CGImage;
        
        UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // Set the quality level to use when rescaling
        CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
        CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
        
        CGContextConcatCTM(context, flipVertical);
        // Draw into the context; this scales the image
        CGContextDrawImage(context, newRect, imageRef);
        
        // Get the resized image from the context and a UIImage
        CGImageRef newImageRef = CGBitmapContextCreateImage(context);
        UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
        
        CGImageRelease(newImageRef);
        UIGraphicsEndImageContext();
        
        return newImage;
    }
    else {
        NSLog(@"No resize done");
        return image;
    }
}


#pragma mark -
#pragma mark UIImagePickerControllerDelegate


- (void) imagePickerController:(UIImagePickerController *)picker
         didFinishPickingImage:(UIImage *)image
                   editingInfo:(NSDictionary *)editingInfo
{
    self.imageView.image = image;
    
    NSLog(@"Original Image dimensions height=%f, width=%f", image.size.height, image.size.width);

    //resize before we compress
    UIImage *resizedImage = [self resizeImage:image newSize:CGSizeMake(320, 480)];
    NSLog(@"Resized Image dimensions %f, %f", resizedImage.size.height, resizedImage.size.width);
    
    //pngData = UIImagePNGRepresentation(image);
    //pngData = UIImagePNGRepresentation(resizedImage);
    //NSLog(@"Size of PNG data %lu", (unsigned long)[pngData length]);
    
    
    //jpgdata = UIImageJPEGRepresentation(image, 0.75);
    jpgdata = UIImageJPEGRepresentation(resizedImage, 0.60);
    NSLog(@"Size of JPG data %lu", (unsigned long)[jpgdata length]);

    [self dismissModalViewControllerAnimated:YES];
}




-(BOOL) setPostParams{
    
//    if(pngData != nil){
    if(jpgdata != nil){
        [indicator startAnimating];
        
        request = [NSMutableURLRequest new];
        request.timeoutInterval = 20.0;
        [request setURL:[NSURL URLWithString:URL]];
        [request setHTTPMethod:@"POST"];
        //[request setCachePolicy:NSURLCacheStorageNotAllowed];
        
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        
        
        [request setValue:@"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" forHTTPHeaderField:@"Accept"];
        [request setValue:@"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_5) AppleWebKit/536.26.14 (KHTML, like Gecko) Version/6.0.1 Safari/536.26.14" forHTTPHeaderField:@"User-Agent"];
        
        NSMutableData *body = [NSMutableData data];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"imagefile\"; filename=\"%@.png\"\r\n", @"Uploaded_file"] dataUsingEncoding:NSUTF8StringEncoding]];
        
        //auro
        // TODO should the mime type be image/jpeg
        [body appendData:[@"Content-Type: image/png" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        if (isRegionClassify) {
            [body appendData:[NSData dataWithData:jpgSubImgData]];
        }
        else {
            [body appendData:[NSData dataWithData:jpgdata]];
        }
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        [request setHTTPBody:body];
        [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];
        
        NSLog(@"HTTP Content Length = %lu", (unsigned long)body.length);
        
        return TRUE;
        
    }else{
        
        response.text = NO_IMAGE;
     
        return FALSE;
    }
}

- (IBAction)tagEntire:(id)sender {
        
        if( [self setPostParams]){
            
            response.text = @""; //clear
            
            NSError *error = nil;
            NSURLResponse *responseStr = nil;
            syncResData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseStr error:&error];
            NSString *returnString = [[NSString alloc] initWithData:syncResData encoding:NSUTF8StringEncoding];
            
            NSLog(@"ERROR %@", error);
            NSLog(@"RES %@", responseStr);
            
            NSLog(@"RETURN STRING:%@", returnString);
            
            if (error == nil) {
                
                NSError *jsonError = nil;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: [returnString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error: &jsonError];
                NSArray* result = (NSArray*)[dict objectForKey:@"result"];
                
                
                //response.textAlignment = UITextAlignmentLeft;
                //get the first five
                NSArray* detectedObjs = (NSArray*)[result objectAtIndex:1];
                response.text = [response.text stringByAppendingString:@"MORE SPECIFIC: "];
                for (int i = 0; i <= REQUESTED_COUNT - 1; i++){
                    NSArray * detect = (NSArray*) [detectedObjs objectAtIndex:i];
                    NSLog(@"Detected %@ with probability %@", [detect objectAtIndex:0], [detect objectAtIndex:1]);
                    response.text = [response.text stringByAppendingString:[detect objectAtIndex:0]];
                    
                    //round up the probability to two decimal places
                    float prob = [[detect objectAtIndex:1] floatValue];
                    //float truncFloat = [[NSString stringWithFormat:@"%.2f", prob] floatValue];
                    response.text = [response.text stringByAppendingString:[NSString stringWithFormat:@"(%.2f)", prob]];
                    response.text = [response.text stringByAppendingString:@", "];
                }
                response.text = [response.text stringByAppendingString:@"\n"];
                //get the next five
                detectedObjs = (NSArray*)[result objectAtIndex:2];
                response.text = [response.text stringByAppendingString:@"MORE GENERIC: "];
                for (int i = 0; i <= REQUESTED_COUNT - 1; i++){
                    NSArray * detect = (NSArray*) [detectedObjs objectAtIndex:i];
                    NSLog(@"Detected %@ with probability %@", [detect objectAtIndex:0], [detect objectAtIndex:1]);
                    response.text = [response.text stringByAppendingString:[detect objectAtIndex:0]];
                    response.text = [response.text stringByAppendingString:@", "];
                }
                
                [indicator stopAnimating];
                
            }
            else {
                response.text = [response.text stringByAppendingString:@"Error"];
            }
        }
}


//deleted uploadImageAsync1, 2, & 3; use later


#pragma mark - Cropping the Image

- (UIImage *)croppingImageByImageName:(UIImage *)imageToCrop toRect:(CGRect)rect{
    
    
    NSLog(@"Image to crop: height=%f width=%f", imageToCrop.size.height, imageToCrop.size.width);
    
    //scale the dimensions based on the actual dimensions not the display dimensions.
    float ratioX = imageToCrop.size.width/300; //TODO: remove hard constants alter
    float ratioY = imageToCrop.size.height/250;
    
    rect.origin.x *= ratioX;
    rect.origin.y *= ratioY;
    
    rect.size.width *=ratioY;
    rect.size.height *=ratioX;
    
    NSLog(@"Rect to crop: Org.x=%f Org.y=%f hieght=%f width=%f", rect.origin.x, rect.origin.y, rect.size.height, rect.size.width);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([imageToCrop CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
//    self.imageView = [[UIImageView alloc] initWithImage:cropped];
//    [self.imageView setFrame:CGRectMake(0, 500, rect.size.width, rect.size.height)];
//    [[self view] addSubview:self.imageView];
   
    return cropped;
    
    
}

#pragma mark - Touch Methods

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    
    
    UIImage *croppedImg = nil;
    
    static bool firstTime = true;
    
    UITouch *touch = [touches anyObject];
    CGPoint currentPoint = [touch locationInView:self.imageView]; //coordinates of the touch
    
    UIView *myBox  = [[UIView alloc] initWithFrame:CGRectMake(currentPoint.x, currentPoint.y, 128, 128)];

    if (firstTime) {
        myBox.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0];
        myBox.layer.borderWidth = 1.0;
        myBox.layer.borderColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0].CGColor;
        [self.imageView addSubview:myBox];
        firstTime = false;
        isRegionClassify = true;
    }
    
    CGRect cropRect = CGRectMake(currentPoint.x , currentPoint.y,   128,  128);
    
    NSLog(@"Touch x %0.0f, y %0.0f, width %0.0f, height %0.0f", cropRect.origin.x, cropRect.origin.y,   cropRect.size.width,  cropRect.size.height );
    
    croppedImg = [self croppingImageByImageName:self.imageView.image toRect:cropRect];
    NSLog(@"Cropped Image: hieght=%f, width=%f", croppedImg.size.height, croppedImg.size.width);
    

    // Create and show the new image from bitmap data
    // credits http://iosdevelopertips.com/graphics/how-to-crop-an-image.html
//    self.imageView = [[UIImageView alloc] initWithImage:croppedImg];
//    [self.imageView setFrame:CGRectMake(200, 500, 128, 128)];
//    [[self view] addSubview:self.imageView];
    //[self.imageView release];
    
    
    jpgSubImgData = [[NSData alloc] initWithData:UIImageJPEGRepresentation((croppedImg), 0.75)];
    NSLog(@"Cropped Image (jpeg) : size=%lu", (unsigned long)jpgSubImgData.length);
    
}
-(void) initPB{
    indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicator.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width)/2, ([UIScreen mainScreen].bounds.size.height)/2 , 40.0, 40.0);
    indicator.center = self.view.center;
    [self.view addSubview:indicator];
    [indicator bringSubviewToFront:self.view];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = TRUE;
}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    // A response has been received, this is where we initialize the instance var you created
    // so that we can append data to it in the didReceiveData method
    // Furthermore, this method is called each time there is a redirect so reinitializing it
    // also serves to clear it
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    // Append the new data to the instance variable you declared
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    // Return nil to indicate not necessary to store a cached response for this connection
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // The request is complete and data has been received
    // You can parse the stuff in your instance variable now
    
    
    response.text = [[NSString alloc] initWithData:_responseData encoding:NSUTF8StringEncoding];
    NSLog(@"_responseData %@", response.text);
    
    [indicator stopAnimating];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    // The request has failed for some reason!
    // Check the error var
    
    NSLog(@"didFailWithError %@", error);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end
