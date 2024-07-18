//FOR IOS FOR IOS FOR IOS --------------

//ios/EmailModule.h///////////

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

//ios/EmailModule.h //////////////


#import <React/RCTBridgeModule.h>

@interface EmailModule : NSObject <RCTBridgeModule>
@end

//Add below extension in info.plist/////////////


<key>LSApplicationQueriesSchemes</key>

   <array>

       <string>googlegmail</string>

       <string>ms-outlook</string>
       <!-- Add other schemes your app needs to query here -->

   </array>


//add below import in appdelegate.m at top/////////////

#import <MessageUI/MessageUI.h>


//FOR ANDROID FOR ANDROID FOR ANDROID FOR ANDROID--------

//EmailModule.java////////////

package com.moodflo;

import android.content.Intent;
import android.net.Uri;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;

public class EmailModule extends ReactContextBaseJavaModule {

  private static ReactApplicationContext reactContext;

  EmailModule(ReactApplicationContext context) {
    super(context);
    reactContext = context;
  }

  @Override
  public String getName() {
    return "EmailModule";
  }

  @ReactMethod
  public void sendEmail(String recipient, String subject, String body, Promise promise) {
    Intent intent = new Intent(Intent.ACTION_SENDTO);
    intent.setData(Uri.parse("mailto:"));
    intent.putExtra(Intent.EXTRA_EMAIL, new String[]{recipient});
    intent.putExtra(Intent.EXTRA_SUBJECT, subject);
    intent.putExtra(Intent.EXTRA_TEXT, body);

    // Limit email apps to Gmail and Outlook
    Intent gmailIntent = new Intent(Intent.ACTION_SENDTO, Uri.fromParts("mailto", recipient, null));
    gmailIntent.setPackage("com.google.android.gm");

    Intent outlookIntent = new Intent(Intent.ACTION_SENDTO, Uri.fromParts("mailto", recipient, null));
    outlookIntent.setPackage("com.microsoft.office.outlook");

    Intent[] emailIntents = {gmailIntent, outlookIntent};

    // Create a chooser intent and exclude PayPal
    Intent chooserIntent = createChooserIntent("Send Email", emailIntents, new String[]{"com.paypal.android.p2pmobile"});

    if (chooserIntent.resolveActivity(reactContext.getPackageManager()) != null) {
      getCurrentActivity().startActivity(chooserIntent);
      promise.resolve(true);
    } else {
      promise.reject("mail_unavailable", "No email client available.");
    }
  }

  private Intent createChooserIntent(String title, Intent[] intents, String[] excludedPackages) {
    Intent chooserIntent = Intent.createChooser(intents[0], title);

    Intent[] filteredIntents = new Intent[intents.length];
    int index = 0;
    for (Intent intent : intents) {
      if (!isPackageExcluded(intent.getPackage(), excludedPackages)) {
        filteredIntents[index++] = intent;
      }
    }

    chooserIntent.putExtra(Intent.EXTRA_INITIAL_INTENTS, filteredIntents);
    return chooserIntent;
  }

  private boolean isPackageExcluded(String packageName, String[] excludedPackages) {
    if (packageName == null || excludedPackages == null) {
      return false;
    }

    for (String excludedPackage : excludedPackages) {
      if (packageName.equals(excludedPackage)) {
        return true;
      }
    }

    return false;
  }
}

//EmailPackage.java///////

package com.moodflo;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class EmailPackage implements ReactPackage {

  @Override
  public List<NativeModule> createNativeModules(ReactApplicationContext reactContext) {
    List<NativeModule> modules = new ArrayList<>();
    modules.add(new EmailModule(reactContext));
    return modules;
  }

  @Override
  public List<ViewManager> createViewManagers(ReactApplicationContext reactContext) {
    return Collections.emptyList();
  }
}

//Add below in MainApplication.java/////////////

packages.add(new EmailPackage());


//HOW TO USE-----------


const { EmailModule } = NativeModules;

 const handleEmail = () => {

   Platform.OS === 'android'

     ? EmailModule.sendEmail(SUPPORT_EMAIL, '', '')

         .then(() => {

           Alert.alert('Email sent successfully');

         })

         .catch(error => {

           Alert.alert('Error', error.message); 

         })

     : EmailModule.sendEmail(SUPPORT_EMAIL, '', '');

 };
