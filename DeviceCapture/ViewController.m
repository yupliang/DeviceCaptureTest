//
//  ViewController.m
//  DeviceCapture
//
//  Created by app-01 on 2020/10/26.
//  Copyright © 2020 app-01 org. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Photos/Photos.h>

@interface ViewController () <AVCapturePhotoCaptureDelegate>
@property (nonatomic,strong) NSString *videoPath;
@property (nonatomic,strong) AVCapturePhotoOutput *imageOutput;
@property (nonatomic,strong) NSData *imageData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    AVCaptureSession *session = [AVCaptureSession new];
    AVCaptureDevice *device = [self getDevice:AVCaptureDevicePositionFront];
    NSError *err = nil;
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&err];
    
    if (err) {
        NSLog(@"err %@", [err localizedDescription]);
    }
    [session addInput:deviceInput];
    [session beginConfiguration];
    session.sessionPreset = AVCaptureSessionPresetPhoto;
    AVCapturePhotoOutput *photo = [AVCapturePhotoOutput new];
    [session addOutput:photo];
    photo.highResolutionCaptureEnabled = true;
    photo.livePhotoCaptureEnabled = photo.isLivePhotoCaptureSupported;
    self.imageOutput = photo;
    
    AVCaptureVideoPreviewLayer *previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
    previewLayer.frame = CGRectMake(10, [UIApplication sharedApplication].statusBarFrame.size.height, 300, 400);
    [previewLayer setBackgroundColor:[UIColor greenColor].CGColor];
    [self.view.layer addSublayer:previewLayer];
    [session commitConfiguration];
    [session startRunning];
fail:
    {
        if (err) {
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", err.code] message:err.localizedDescription delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }
}

- (IBAction)takePhoto:(id)sender {
    NSDictionary *settingDic = @{AVVideoCodecKey:AVVideoCodecTypeHEVC};
    AVCapturePhotoSettings *setting = [AVCapturePhotoSettings photoSettingsWithFormat:settingDic];
    setting.livePhotoMovieFileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Photosshot_%lld.mov", [setting uniqueID]]]];
    NSError *err = nil;
    [[NSFileManager defaultManager] removeItemAtPath:setting.livePhotoMovieFileURL error:&err];
    NSLog(@"err %@", err);
    setting.flashMode = AVCaptureFlashModeOff;
    setting.autoStillImageStabilizationEnabled = self.imageOutput.stillImageStabilizationSupported;
    [self.imageOutput capturePhotoWithSettings:setting delegate:self];
}

- (AVCaptureDevice *)getDevice:(AVCaptureDevicePosition)position {
    __block AVCaptureDevice *device = nil;
    [[AVCaptureDevice devices] enumerateObjectsUsingBlock:^(AVCaptureDevice * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.position == position) {
            device = obj;
            NSLog(@"%@", device);
//            *stop = YES;
        }
    }];
    return device;
}

//MARK: AVCapthrePhotoCaptureDelegate
//- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error {
//    NSLog(@"%s", __func__);
//    NSData *data = [AVCapturePhotoOutput JPEGPhotoDataRepresentationForJPEGSampleBuffer:photoSampleBuffer previewPhotoSampleBuffer:previewPhotoSampleBuffer];
//    UIImage *img = [UIImage imageWithData:data];
//    UIImageWriteToSavedPhotosAlbum(img, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
//}
- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(NSError *)error {
    NSLog(@"%s", __func__);
    self.imageData = [photo fileDataRepresentation];
    UIImage *img = [UIImage imageWithData:self.imageData];
    NSLog(@"");
}

//- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
//    NSLog(@"%s", __func__);
//    NSString *msg = nil;
//    if (error != NULL) {
//        msg = @"保存失败";
//    } else {
//        msg = @"保存成功";
//    }
//    NSLog(@"++++++ %@", msg);
//}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings error:(NSError *)error {
    NSLog(@"%s %@", __func__,error);
    [self saveLivePhotoToPhotosLibrary:self.imageData livePhotoMoviewURL:outputFileURL];
}

- (void)saveLivePhotoToPhotosLibrary:(NSData *)stillImageData livePhotoMoviewURL:(NSURL *)url {
    NSLog(@"%s", __func__);
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetCreationRequest *creationRequest = [PHAssetCreationRequest creationRequestForAsset];
        [creationRequest addResourceWithType:PHAssetResourceTypePhoto data:stillImageData options:nil];
        PHAssetResourceCreationOptions *options = [PHAssetResourceCreationOptions new];
        options.shouldMoveFile = true;
        [creationRequest addResourceWithType:PHAssetResourceTypePairedVideo fileURL:url options:options];
        NSLog(@"");
    } completionHandler:^(BOOL success, NSError * _Nullable err) {
        NSLog(@"live photo %d %@", success,err);
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if (err) {
                UIAlertController *alertView = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"Failed with error %d", err.code] message:err.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
                UIAlertAction *ok = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    NSLog(@"ok");
                }];
                [alertView addAction:ok];
                [self presentViewController:alertView animated:YES completion:nil];
            }
        });
    }];
}

@end
