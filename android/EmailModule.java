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
