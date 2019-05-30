# DApi.framework



## Version
1.0.0


## Installation
#### CocoaPods
Add `pod 'DApi-ios'` into your [Podfile](https://guides.cocoapods.org/syntax/podfile.html).


## Usage
To implement DApi, add a DApiView to the view controller:
 
    - (void)viewDidLoad {
        [super viewDidLoad];

        DApiView *dApiView = [[DApiView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        dApiView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        dApiView.delegate = self;
        [self.view insertSubview:dApiView atIndex:0];
    }
    
or subclass the view controller to DApiViewController (which will add a DApiView by itself):

    @interface DApiViewController : UIViewController<DApiDelegate>
    @end

then implement the DApiDelegate methods in your view controller:

    //Triggered when a new drift is detected on the screen.
    - (void)driftDetected:(Drift *)drift;
    //Triggered when a detected drift has moved.
    - (void)driftMoved:(Drift *)drift;
    //Triggered when a detected drift has been removed from the screen.
    - (void)driftEnded:(Drift *)drift;

where Drift is an NSObject that represent the detected physical drift object.


Drift contains the following properties:

    //A unique instance ID for the Drift object.
    //The first detected drift with have an instanceId value = 0, the second drift with have a value = 1 and etc.
    //This value is guaranteed to be the same throughout the life cycle of a drift, from DriftDetected to DriftEnded,
    //and is guaranteed to be unique for different drift instance (unless overflowed uint).
    @property (nonatomic, assign, readonly) uint instanceId;

    //Screen pixel coordinates, (0, 0) at top left.
    @property (nonatomic) CGPoint center;
        
    //Rotation in radian, range = [0..2PI), initial side on positive y-axis, clockwise.
    @property (nonatomic) double rotation;


You can read / write from the drift with the following methods:

    //Read data from the drift.
    //Address ranges from 0 to 15.
    //Callback returns the data stored at the address location, or an error code with negative value.
    - (void)readFromDriftAddress:(uint)address Callback:(void (^)(int))callback;


    //Write data to the drift.
    //Address ranges from 1 to 15 (Address 0 stores the unique id of the drift and is read-only).
    //Data ranges from 0 to 65535.
    //Callback returns 1 if request has successed, or an error code with negative value.
    - (void)writeToDriftAddress:(uint)address Data:(uint)data Callback:(void (^)(int))callback;


The following is the list of possible error codes:
    
    RequestErrorCancelled = -1              //The drift object is destroyed (e.g. left the screen) before completing the request.
    RequestErrorTimeout = -2                //Failed to receive any signal from the drift before timeout.
    RequestErrorReadFailed = -3             //Failed to receive a valid signal from the drift when performing a read request.
    RequestErrorMultipleRequests = -4       //Trying to send a request to the drift before the previous request has completed.
    RequestErrorInvalidAddr = -5            //Trying to send a request with an invalid address value.
    RequestErrorInvalidData = -6            //Trying to send a request with an invalid data value.
