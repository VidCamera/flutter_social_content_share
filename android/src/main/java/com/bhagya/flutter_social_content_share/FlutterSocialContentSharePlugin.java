package com.bhagya.flutter_social_content_share;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import com.facebook.FacebookSdk;
import com.facebook.share.model.ShareLinkContent;
import com.facebook.share.widget.ShareDialog;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * FlutterSocialContentSharePlugin
 */
public class FlutterSocialContentSharePlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
	/// The MethodChannel that will the communication between Flutter and native Android
	///
	/// This local reference serves to register the plugin with the Flutter Engine and unregister it
	/// when the Flutter Engine is detached from the Activity
	private MethodChannel channel;
	private Activity activity;
	private static final String INSTAGRAM_PACKAGE_NAME = "com.instagram.android";
	private static final String SNAPCHAT_PACKAGE_NAME = "com.snapchat.android";
	private static final String WHATSAPP_PACKAGE_NAME = "com.whatsapp";
	private static final String FACEBOOK_PACKAGE_NAME = "com.facebook.katana";
	private static final String TWITTER_PACKAGE_NAME = "com.twitter.android";
	private static final String TELEGRAM_PACKAGE_NAME = "org.telegram.messenger";

	@Override
	public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
		channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "social_share");
		channel.setMethodCallHandler(this);

		//FacebookSdk.sdkInitialize(activity.getApplicationContext());
	}

	@Override
	public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

		switch (call.method) {
			case "getPlatformVersion":
				result.success("Android " + android.os.Build.VERSION.RELEASE);
				break;
			case "shareOnFacebook":
				final String quote = call.argument("quote");
				final String url = call.argument("url");
				shareToFacebook(url, quote, result);
				break;
			case "shareOnInstagram":
				final String filePath = call.argument("filePath");
				final File image = new File(filePath);
				final Uri uri = FileProvider.getUriForFile(activity, activity.getPackageName() + ".social_share", image);

				final Intent feedIntent = new Intent(Intent.ACTION_SEND);
				feedIntent.setType("video/*");
				feedIntent.putExtra(Intent.EXTRA_STREAM, uri);
				feedIntent.setPackage(INSTAGRAM_PACKAGE_NAME);

				//story
				Intent storiesIntent = new Intent("com.instagram.share.ADD_TO_STORY");
				storiesIntent.setDataAndType(uri, ".mp4");
				storiesIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
				storiesIntent.setPackage(INSTAGRAM_PACKAGE_NAME);

				final Intent chooserIntent = Intent.createChooser(feedIntent, "Share via Instagram");
				chooserIntent.putExtra(Intent.EXTRA_INITIAL_INTENTS, new Intent[]{storiesIntent});

				try {
					result.success(true);
					activity.startActivity(chooserIntent);
				} catch (ActivityNotFoundException e) {
					e.printStackTrace();
					result.success(false);
				}
				break;
			case "shareOnWhatsupp":
				final String textMsg = call.argument("text");
				shareWhatsApp(textMsg, result);
				break;
			case "shareOnSms":
				final ArrayList<String> recipients = call.argument("recipients");
				final String text = call.argument("text");
				shareSMS(recipients, text, result);
				break;
			case "shareOnEmail":
				final ArrayList<String> recipientsEmail = call.argument("recipients");
				final ArrayList<String> ccrecipients = call.argument("ccrecipients");
				final ArrayList<String> bccrecipients = call.argument("bccrecipients");
				final String body = call.argument("body");
				final String subject = call.argument("subject");
				shareEmail(recipientsEmail, ccrecipients, bccrecipients, subject, body, result);
				break;
			case "shareOnSnapchat":
				final String filePathSnapchat = call.argument("filePath");
				final File imageSnapchat = new File(filePathSnapchat);
				final Uri uriSnapchat = FileProvider.getUriForFile(activity, activity.getPackageName() + ".social_share", imageSnapchat);
				final Intent intentSnapchat = new Intent(Intent.ACTION_SEND);
				intentSnapchat.setType("video/*");
				intentSnapchat.putExtra(Intent.EXTRA_STREAM, uriSnapchat);
				intentSnapchat.setPackage(SNAPCHAT_PACKAGE_NAME);
				intentSnapchat.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

				final Intent chooserSnapchat = Intent.createChooser(intentSnapchat, "Share to");
				final List<ResolveInfo> resInfoListSnapchat = activity.getPackageManager().queryIntentActivities(chooserSnapchat, PackageManager.MATCH_DEFAULT_ONLY);

				for (final ResolveInfo resolveInfo : resInfoListSnapchat) {
					final String packageName = resolveInfo.activityInfo.packageName;
					activity.grantUriPermission(packageName, uriSnapchat, Intent.FLAG_GRANT_READ_URI_PERMISSION);
				}
				if (activity.getPackageManager().resolveActivity(chooserSnapchat, 0) != null) {
					activity.startActivity(chooserSnapchat);
					result.success(true);
				} else {
					result.success(false);
				}
				break;
			case "shareOptions":
				shareOptions(call, result);
				break;
			case "copyToClipboard":
				final String content = call.argument("content");
				final ClipboardManager clipboard = (ClipboardManager) activity.getSystemService(Context.CLIPBOARD_SERVICE);
				final ClipData clip = ClipData.newPlainText("", content);
				if (clipboard != null) {
					clipboard.setPrimaryClip(clip);
					result.success(true);
				} else {
					result.success(false);
				}
				break;
			case "shareOnTwitter":
				shareOnTwitter(call, result);
				break;
			case "shareOnTelegram":
				shareOnTelegram(call, result);
				break;
			case "checkInstalledApps":
				result.success(checkInstalledApps());
				break;
		}
	}

	@SuppressLint("IntentReset")
	private Map<String, Object> checkInstalledApps() {
		final Map<String, Object> apps = new HashMap<>();
		final PackageManager packageManager = activity.getPackageManager();
		final List<ApplicationInfo> packages = packageManager.getInstalledApplications(PackageManager.GET_META_DATA);
		final Intent intent = new Intent(Intent.ACTION_SENDTO).addCategory(Intent.CATEGORY_DEFAULT);
		intent.setType("vnd.android-dir/mms-sms");
		intent.setData(Uri.parse("sms:"));
		final List<ResolveInfo> resolvedActivities = packageManager.queryIntentActivities(intent, 0);
		apps.put("sms", !resolvedActivities.isEmpty());
		apps.put("instagram", isPackageAvailable(INSTAGRAM_PACKAGE_NAME, packages));
		apps.put("snapchat", isPackageAvailable(SNAPCHAT_PACKAGE_NAME, packages));
		apps.put("facebook", isPackageAvailable(FACEBOOK_PACKAGE_NAME, packages));
		apps.put("twitter", isPackageAvailable(TWITTER_PACKAGE_NAME, packages));
		apps.put("whatsapp", isPackageAvailable(WHATSAPP_PACKAGE_NAME, packages));
		apps.put("telegram", isPackageAvailable(TELEGRAM_PACKAGE_NAME, packages));

		return apps;
	}

	private boolean isPackageAvailable(String packageName, List<ApplicationInfo> packages) {
		for (ApplicationInfo appPackage : packages) {
			if (appPackage.packageName.contains(packageName)) {
				return true;
			}
		}
		return false;
	}

	private void shareOnTelegram(MethodCall call, Result result) {
		final String content = call.argument("content");
		final Intent intent = new Intent(Intent.ACTION_SEND);
		intent.setType("text/plain");
		intent.setPackage("org.telegram.messenger");
		intent.putExtra(Intent.EXTRA_TEXT, content);
		try {
			activity.startActivity(intent);
			result.success(true);
		} catch (ActivityNotFoundException e) {
			result.success(false);
		}
	}

	private void shareOnTwitter(MethodCall call, Result result) {
		final String text = call.argument("captionText");
		final String url = call.argument("url");
		final String urlScheme = "http://www.twitter.com/intent/tweet?text=" + text + url;
		final Intent intent = new Intent(Intent.ACTION_VIEW);
		intent.setData(Uri.parse(urlScheme));
		try {
			activity.startActivity(intent);
			result.success("true");
		} catch (ActivityNotFoundException exception) {
			result.success("false");
		}
	}

	private void shareOptions(MethodCall call, Result result) {
		final String content = call.argument("content");
		final String image = call.argument("image");
		final Intent intent = new Intent(Intent.ACTION_SEND);
		intent.putExtra(Intent.EXTRA_TEXT, content);

		if (image != null) {
			final File imageFile = new File(image, image);
			final Uri imageFileUri = FileProvider.getUriForFile(activity, activity.getPackageName() + ".social_share", imageFile);
			intent.setType("video/*");
			intent.putExtra(Intent.EXTRA_STREAM, imageFileUri);
		} else {
			intent.setType("text/plain");
		}

		final Intent chooserIntent = Intent.createChooser(intent, null);

		if (activity.getPackageManager().resolveActivity(chooserIntent, 0) != null) {
			activity.startActivity(chooserIntent);
			result.success(true);
		} else {
			result.success(false);
		}
	}

	/**
	 * share to Facebook
	 *
	 * @param url    String
	 * @param quote  String
	 * @param result Result
	 */
	private void shareToFacebook(String url, String quote, Result result) {
		final ShareDialog shareDialog = new ShareDialog(activity);
		final ShareLinkContent content = new ShareLinkContent.Builder()
			.setContentUrl(Uri.parse(url))
			//.setQuote(quote)
			.build();
		if (ShareDialog.canShow(ShareLinkContent.class)) {
			shareDialog.show(content, ShareDialog.Mode.FEED);
			result.success(true);
		} else {
			result.success(false);
		}
	}

	/**
	 * share on Whatsapp
	 *
	 * @param text   String
	 * @param result Result
	 */
	private void shareWhatsApp(String text, Result result) {
		Intent intent = new Intent(Intent.ACTION_SEND);
		intent.setType("text/plain");
		intent.setPackage(WHATSAPP_PACKAGE_NAME);
		intent.putExtra(Intent.EXTRA_TEXT, text);
		try {
			activity.startActivity(intent);
		} catch (android.content.ActivityNotFoundException ex) {
			result.success(false);
		}
		result.success(true);
	}

	/**
	 * share on SMS
	 *
	 * @param recipients ArrayList<String>
	 * @param text       String
	 * @param result     Result
	 */
	@SuppressLint("IntentReset")
	private void shareSMS(ArrayList<String> recipients, String text, Result result) {
		try {
			Intent intent = new Intent(Intent.ACTION_VIEW);
			intent.setData(Uri.parse("smsto:"));
			intent.setType("vnd.android-dir/mms-sms");
			intent.putExtra("address", recipients);
			intent.putExtra("sms_body", text);
			activity.startActivity(Intent.createChooser(intent, "Send sms via:"));
			result.success(true);
		} catch (Exception e) {
			result.success("Message service is not available");
			result.success(false);
		}
	}

	/**
	 * share on Email
	 *
	 * @param recipients    ArrayList<String>
	 * @param ccrecipients  ArrayList<String>
	 * @param bccrecipients ArrayList<String>
	 * @param subject       String
	 * @param body          String
	 * @param result        Result
	 */
	private void shareEmail(ArrayList<String> recipients, ArrayList<String> ccrecipients, ArrayList<String> bccrecipients, String subject, String body, Result result) {

		Intent shareIntent = new Intent(Intent.ACTION_SENDTO, Uri.fromParts(
			"mailto", "", null));
		shareIntent.putExtra(Intent.EXTRA_SUBJECT, subject);
		shareIntent.putExtra(Intent.EXTRA_TEXT, body);
		shareIntent.putExtra(Intent.EXTRA_EMAIL, recipients);
		shareIntent.putExtra(Intent.EXTRA_CC, ccrecipients);
		shareIntent.putExtra(Intent.EXTRA_BCC, bccrecipients);
		try {
			activity.startActivity(Intent.createChooser(shareIntent, "Send email using..."));
			result.success(true);
		} catch (android.content.ActivityNotFoundException ex) {
			result.success(false);
		}
	}

	@Override
	public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
		channel.setMethodCallHandler(null);
	}

	@Override
	public void onAttachedToActivity(ActivityPluginBinding binding) {
		activity = binding.getActivity();
	}

	@Override
	public void onDetachedFromActivityForConfigChanges() {

	}

	@Override
	public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
		activity = binding.getActivity();
	}

	@Override
	public void onDetachedFromActivity() {

	}
}
