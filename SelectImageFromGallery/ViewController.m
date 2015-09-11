
#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
{
    NSData *pngData;
    NSData *syncResData;
    NSMutableURLRequest *request;
    UIActivityIndicatorView *indicator;
    
    #define URL            @"http://54.67.90.20:5000/classify_upload_json"  // change this URL
    #define NO_CONNECTION  @"No Connection"
    #define NO_IMAGE      @"NO IMAGE SELECTED"
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    pngData = nil;
    [self initPB];
}

- (IBAction) pickImage:(id)sender{
    
    UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
    pickerController.delegate = self;
    [self presentViewController:pickerController animated:YES completion:nil];
}

#pragma mark -
#pragma mark UIImagePickerControllerDelegate

- (void) imagePickerController:(UIImagePickerController *)picker
         didFinishPickingImage:(UIImage *)image
                   editingInfo:(NSDictionary *)editingInfo
{
    self.imageView.image = image;
    pngData = UIImagePNGRepresentation(image);
    [self dismissModalViewControllerAnimated:YES];
}

-(BOOL) setParams{
    
    if(pngData != nil){
        
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
        [body appendData:[@"Content-Type: image/png" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[NSData dataWithData:pngData]];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        
        [request setHTTPBody:body];
        [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];
        
        NSLog(@"Length = %lu", (unsigned long)body.length);
        
        return TRUE;
        
    }else{
        
        response.text = NO_IMAGE;
     
        return FALSE;
    }
}

- (IBAction) uploadImageSync:(id)sender
{
    
    if( [self setParams]){
        
        NSError *error = nil;
        NSURLResponse *responseStr = nil;
        syncResData = [NSURLConnection sendSynchronousRequest:request returningResponse:&responseStr error:&error];
        NSString *returnString = [[NSString alloc] initWithData:syncResData encoding:NSUTF8StringEncoding];
        
        NSLog(@"ERROR %@", error);
        NSLog(@"RES %@", responseStr);
        
        NSLog(@"RETURN STRING:%@", returnString);
        
//        if(error == nil){
//            response.text = returnString;
//        }
        
        NSError *jsonError = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: [returnString dataUsingEncoding:NSUTF8StringEncoding] options: NSJSONReadingMutableContainers error: &jsonError];
        NSArray* result = (NSArray*)[dict objectForKey:@"result"];
        
        response.text = @""; //clear
        //response.textAlignment = UITextAlignmentLeft;
        //get the first five
        NSArray* detectedObjs = (NSArray*)[result objectAtIndex:1];
        for (int i = 0; i <= 4; i++){
            NSArray * detect = (NSArray*) [detectedObjs objectAtIndex:i];
            NSLog(@"Detected %@ with probability %@", [detect objectAtIndex:0], [detect objectAtIndex:1]);
            response.text = [response.text stringByAppendingString:[detect objectAtIndex:0]];
            response.text = [response.text stringByAppendingString:@", "];
        }
        
        //get the next five
        detectedObjs = (NSArray*)[result objectAtIndex:2];
        //get the first five
        for (int i = 0; i <= 4; i++){
            NSArray * detect = (NSArray*) [detectedObjs objectAtIndex:i];
            NSLog(@"Detected %@ with probability %@", [detect objectAtIndex:0], [detect objectAtIndex:1]);
            response.text = [response.text stringByAppendingString:[detect objectAtIndex:0]];
            response.text = [response.text stringByAppendingString:@", "];
        }
        
        [indicator stopAnimating];
    
    }
    
}

- (IBAction) uploadImageAsync1:(id)sender
{

     if( [self setParams]){
    
        NSOperationQueue *queue = [[NSOperationQueue alloc]init];
        
        // Loads the data for a URL request and executes a handler block on an operation queue when the request completes or fails.
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:queue
                               completionHandler:^(NSURLResponse *urlResponse, NSData *data, NSError *error){
                                   NSLog(@"Completed");
                                   
                                   response.text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                   
                                   [indicator stopAnimating];
                                   [UIApplication sharedApplication].networkActivityIndicatorVisible = FALSE;
                                   
                                   if (error) {
                                       NSLog(@"error:%@", error.localizedDescription);
                                   }
                                  
                               }];
     }
    

}

- (IBAction) uploadImageAsync2:(id)sender{
    
     if( [self setParams]){
    
         // Returns an initialized URL connection and begins to load the data for the URL request.
         if([[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES]){
         
         };
         
     }
    
}

- (IBAction) uploadImageAsync3:(id)sender{
    
    if( [self setParams]){
        
       //Creates and returns an initialized URL connection and begins to load the data for the URL request.
        
        if([NSURLConnection connectionWithRequest:request delegate:self]){
            
        };
    }
    
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
