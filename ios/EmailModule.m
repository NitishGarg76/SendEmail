#import "EmailModule.h"
#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>

@implementation EmailModule

RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(sendEmail:(NSString *)recipient subject:(NSString *)subject body:(NSString *)body) {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Choose Email Client"
                                                                                 message:nil
                                                                          preferredStyle:UIAlertControllerStyleActionSheet];

        // Check if Gmail app is installed
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"googlegmail://"]]) {
            UIAlertAction *gmailAction = [UIAlertAction actionWithTitle:@"Gmail"
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
                                                                    [self sendEmailWithClient:@"googlegmail://co?to=%@&subject=%@&body=%@" recipient:recipient subject:subject body:body];
                                                                }];
            [alertController addAction:gmailAction];
        } else {
            NSLog(@"Gmail app is not installed");
        }

        // Check if Outlook app is installed
        if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"ms-outlook://"]]) {
            UIAlertAction *outlookAction = [UIAlertAction actionWithTitle:@"Outlook"
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * _Nonnull action) {
                                                                       [self sendEmailWithClient:@"ms-outlook://compose?to=%@&subject=%@&body=%@" recipient:recipient subject:subject body:body];
                                                                   }];
            [alertController addAction:outlookAction];
        } else {
            NSLog(@"Outlook app is not installed");
        }

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel"
                                                                style:UIAlertActionStyleCancel
                                                              handler:nil];
        [alertController addAction:cancelAction];

        // Get the root view controller to present the alert controller
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (rootViewController.presentedViewController) {
            rootViewController = rootViewController.presentedViewController;
        }
        [rootViewController presentViewController:alertController animated:YES completion:nil];
    });
}

- (void)sendEmailWithClient:(NSString *)clientURL recipient:(NSString *)recipient subject:(NSString *)subject body:(NSString *)body {
    NSString *urlString = [NSString stringWithFormat:clientURL,
                           [self urlEncode:recipient],
                           [self urlEncode:subject],
                           [self urlEncode:body]];
    NSURL *url = [NSURL URLWithString:urlString];

    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    } else {
        NSLog(@"Cannot open %@", clientURL);
        // Handle error - unable to open client URL
        // For example, provide a fallback option like sending via MFMailComposeViewController
        [self sendEmailWithMFMailCompose:recipient subject:subject body:body];
    }
}

- (NSString *)urlEncode:(NSString *)string {
    NSCharacterSet *allowedCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"] invertedSet];
    return [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacterSet];
}

- (void)sendEmailWithMFMailCompose:(NSString *)recipient subject:(NSString *)subject body:(NSString *)body {
    if ([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *mailComposeVC = [[MFMailComposeViewController alloc] init];
        mailComposeVC.mailComposeDelegate = self;
        [mailComposeVC setToRecipients:@[recipient]];
        [mailComposeVC setSubject:subject];
        [mailComposeVC setMessageBody:body isHTML:NO];

        // Get the root view controller to present the mail compose view controller
        UIViewController *rootViewController = [UIApplication sharedApplication].keyWindow.rootViewController;
        if (rootViewController.presentedViewController) {
            rootViewController = rootViewController.presentedViewController;
        }
        [rootViewController presentViewController:mailComposeVC animated:YES completion:nil];
    } else {
        NSLog(@"Mail services are not available");
        // Handle error - mail services are not available
    }
}

@end
