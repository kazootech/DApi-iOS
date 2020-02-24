//
//  ViewController.m
//  DApiSample
//
//  Created by Jacky Cho on 29/4/2019.
//  Copyright © 2019 Kazoo. All rights reserved.
//

#import "ViewController.h"
#import "DriftLayer.h"


@implementation ViewController {
    NSMutableArray<Drift *> *driftArray;
    NSMutableDictionary<NSNumber *, DriftLayer *> *driftDict;
    
    __weak IBOutlet UITextField *addressText;
    __weak IBOutlet UITextField *dataText;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    driftArray = [NSMutableArray array];
    driftDict = [NSMutableDictionary dictionary];
    
    addressText.delegate = self;
    dataText.delegate = self;
}


#pragma mark - DApiDelegate

- (void)driftDetected:(Drift *)drift {
    NSLog(@"DriftDetected: %d", [drift instanceId]);
    
    DriftLayer *layer = [[DriftLayer alloc] init];
    [layer setPosition:drift.center];
    [layer setRotation:drift.rotation];
    [self.view.layer addSublayer:layer];

    [driftDict setObject:layer forKey:[NSNumber numberWithInt:[drift instanceId]]];
    [driftArray addObject:drift];

    //Automatically read address 0 from drift.
    [self readFromDrift:drift Address:0 MaxRetry:3];
}


- (void)driftMoved:(Drift *)drift {
//    NSLog(@"DriftMoved: %d", [drift instanceId]);
    
    DriftLayer *layer = [driftDict objectForKey:[NSNumber numberWithInt:[drift instanceId]]];
    [layer setPosition:drift.center];
    [layer setRotation:drift.rotation];
}


- (void)driftEnded:(Drift *)drift {
    NSLog(@"DriftEnded: %d", [drift instanceId]);
    
    DriftLayer *layer = [driftDict objectForKey:[NSNumber numberWithInt:[drift instanceId]]];
    [layer removeFromSuperlayer];

    [driftDict removeObjectForKey:[NSNumber numberWithInt:[drift instanceId]]];
    [driftArray removeObject:drift];
}


#pragma mark - DAPi helper functions

- (NSString *)getDriftErrorString:(int)errorInt isRead:(bool)isRead {
    NSString *errorString = @"";
    switch (errorInt) {
        case RequestErrorCancelled:
            errorString = @"Cancelled";
            break;
        case RequestErrorTimeout:
            errorString = @"Time out";
            break;
        case RequestErrorReadFailed:
            errorString = @"Read failed";
            break;
        case RequestErrorMultipleRequests:
            errorString = @"Multiple request";
            break;
        case RequestErrorInvalidAddr:
            if (isRead) {
                errorString = @"Valid address range is 0-15";
            } else {
                errorString = @"Valid address range is 1-15";
            }
            break;
        case RequestErrorInvalidData:
            errorString = @"Valid data range is 0-15";
            break;
    }
    
    return errorString;
}

- (void)readFromDrift:(Drift *)drift Address:(uint)address MaxRetry:(int)maxRetry {
    
    __weak typeof(self) weakSelf = self;
    __weak DriftLayer *layer = [driftDict objectForKey:[NSNumber numberWithInt:[drift instanceId]]];
    __block int retryCount = 0;
    __block void (^readFromDrift)(void) = nil;
    __weak Drift *weakDrift = drift;
    
    readFromDrift = ^{
        [weakDrift readFromDriftAddress:address Callback:^(int i) {
            //Error
            if (i < 0) {
                NSString *errorString = [weakSelf getDriftErrorString:i isRead:true];
                [layer setText:[NSString stringWithFormat:@"Read Address: %d, Error: %@, RetryCount: %d", address, errorString, retryCount]];

                if (i != RequestErrorMultipleRequests && retryCount < maxRetry) {
                    retryCount++;
                    
                    //Retry after 0.5 seconds.
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * 500), dispatch_get_main_queue(), ^{
                        readFromDrift();
                    });
                } else {
                    readFromDrift = nil;
                }
            } else {
                [layer setText:[NSString stringWithFormat:@"Read Address: %d, Result: %d", address, i]];
                readFromDrift = nil;
            }
        }];
    };
    
    //Read request
    readFromDrift();
}

- (void)writeToDrift:(Drift *)drift Address:(uint)address Data:(uint)data MaxRetry:(int)maxRetry {
    
    __weak typeof(self) weakSelf = self;
    DriftLayer *layer = [driftDict objectForKey:[NSNumber numberWithInt:[drift instanceId]]];
    __block int retryCount = 0;
    __block void (^writeToDrift)(void) = nil;
    __weak Drift *weakDrift = drift;
    
    writeToDrift = ^{
        [weakDrift writeToDriftAddress:address Data:data Callback:^(int i) {
            //Error
            if (i < 0) {
                NSString *errorString = [weakSelf getDriftErrorString:i isRead:false];
                [layer setText:[NSString stringWithFormat:@"Write Address: %d, Error: %@, RetryCount: %d", address, errorString, retryCount]];
                
                if (i != RequestErrorMultipleRequests && retryCount < maxRetry) {
                    retryCount++;
                    
                    //Retry after 0.5 seconds.
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_MSEC * 500), dispatch_get_main_queue(), ^{
                        writeToDrift();
                    });
                } else {
                    writeToDrift = nil;
                }
            } else {
                [layer setText:[NSString stringWithFormat:@"Write Address: %d, Result: %d", address, i]];
                writeToDrift = nil;
            }
        }];
    };

    //Write request
    writeToDrift();
}


#pragma mark - Sample UI IBAction

- (IBAction)clickRead:(id)sender {
    if (addressText.text != nil) {
        uint address = (uint)[addressText.text intValue];
        
        for (Drift *drift in driftArray) {

            //Read from drift and retry if the request returns an error code.
            [self readFromDrift:drift Address:address MaxRetry:3];
            
            //Or, a simple read request.
//            [drift readFromDriftAddress:address Callback:^(int i) {
//                [layer setText:[NSString stringWithFormat:@"Read Address: %d, result: %d", address, i]];
//            }];
        }
    }
}

- (IBAction)clickWrite:(id)sender {
    
    if (addressText.text != nil) {
        uint address = (uint)[addressText.text intValue];
        uint data = (uint)[dataText.text intValue];
        
        for (Drift *drift in driftArray) {
            
            //Write to drift and retry if the request returns an error code.
            [self writeToDrift:drift Address:address Data:data MaxRetry:3];
            
            //Or, a simple write request.
//            [drift writeToDriftAddress:address Data:data Callback:^(int i) {
//                [layer setText:[NSString stringWithFormat:@"Write Address: %d, data: %d, result: %d", address, data, i]];
//            }];
        }
    }
}


#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *numbersOnly = [NSCharacterSet characterSetWithCharactersInString:@"0123456789"];
    NSCharacterSet *characterSetFromTextField = [NSCharacterSet characterSetWithCharactersInString:string];
    
    BOOL stringIsValid = [numbersOnly isSupersetOfSet:characterSetFromTextField];
    return stringIsValid;
}

@end
