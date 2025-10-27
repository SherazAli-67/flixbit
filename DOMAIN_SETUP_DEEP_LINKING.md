# Domain Setup for Deep Linking - Complete Guide

## 🌐 Overview

For deep linking to work properly with Universal Links (iOS) and App Links (Android), you need to host verification files on your domain that prove you own both the domain and the mobile app.

---

## 📋 Prerequisites

### What You Need:
1. **A domain name** (e.g., `flixbit.app`, `flixbit.com`)
2. **HTTPS hosting** (SSL certificate required)
3. **Access to domain root directory** (to upload `.well-known` files)
4. **App signing certificates** (Android: SHA-256 fingerprint, iOS: Team ID)

---

## 🔧 Complete Setup Process

### **Step 1: Get Your App Credentials**

#### **For Android (SHA-256 Certificate Fingerprint)**

**Debug certificate (for testing):**
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Release certificate (for production):**
```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-key-alias
```

Look for the line:
```
SHA256: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99
```

**Remove the colons** for the JSON file:
```
AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899
```

#### **For iOS (Team ID & Bundle Identifier)**

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Click on your account name → **Membership Details**
3. Find your **Team ID** (e.g., `9JA89QQLNQ`)
4. Your **Bundle ID** is in Xcode or `Info.plist` (e.g., `com.flixbit.app`)

---

### **Step 2: Create Verification Files**

You need to create two files in your domain's `.well-known` directory:

```
https://flixbit.app/
├── .well-known/
│   ├── assetlinks.json          (for Android)
│   └── apple-app-site-association (for iOS)
```

---

#### **File 1: Android App Links** 
**Path:** `https://flixbit.app/.well-known/assetlinks.json`

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.flixbit.app",
    "sha256_cert_fingerprints": [
      "AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899"
    ]
  }
}]
```

**Replace:**
- `com.flixbit.app` → Your actual package name from `android/app/build.gradle`
- `AABBCC...` → Your actual SHA-256 fingerprint (from Step 1)

**Important notes:**
- ✅ File must be **exactly** `assetlinks.json` (no `.txt` extension)
- ✅ Must be accessible via **HTTPS only**
- ✅ Must return `Content-Type: application/json`
- ✅ No redirects allowed (must be 200 OK response)
- ✅ Must be publicly accessible (no authentication)

**For multiple apps (debug + release):**
```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.flixbit.app",
    "sha256_cert_fingerprints": [
      "DEBUG_SHA256_HERE",
      "RELEASE_SHA256_HERE"
    ]
  }
}]
```

---

#### **File 2: iOS Universal Links**
**Path:** `https://flixbit.app/.well-known/apple-app-site-association`

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "9JA89QQLNQ.com.flixbit.app",
        "paths": [
          "/referral",
          "/referral/*"
        ]
      }
    ]
  }
}
```

**Replace:**
- `9JA89QQLNQ` → Your actual Team ID
- `com.flixbit.app` → Your actual Bundle Identifier
- `appID` format is always: `TEAM_ID.BUNDLE_ID`

**Important notes:**
- ✅ File name is **exactly** `apple-app-site-association` (NO file extension!)
- ✅ Must be accessible via **HTTPS only**
- ✅ Must return `Content-Type: application/json`
- ✅ Must be signed or served from Apple CDN
- ✅ Can also be at root: `https://flixbit.app/apple-app-site-association`

**Path patterns explained:**
- `"/referral"` → Matches exactly `https://flixbit.app/referral`
- `"/referral/*"` → Matches `https://flixbit.app/referral/anything`
- `"*"` → Matches all paths (use carefully!)
- `"NOT /admin/*"` → Exclude specific paths

---

### **Step 3: Upload Files to Your Server**

#### **Option A: Manual Upload (cPanel/FTP)**

1. Connect to your server via FTP or file manager
2. Navigate to your domain's root directory (usually `public_html/` or `www/`)
3. Create folder: `.well-known/`
4. Upload both files to `.well-known/` directory
5. Set file permissions to **644** (readable by all)

**Directory structure:**
```
/public_html/
├── .well-known/
│   ├── assetlinks.json
│   └── apple-app-site-association
├── index.html
└── ... (other files)
```

#### **Option B: Firebase Hosting**

**firebase.json:**
```json
{
  "hosting": {
    "public": "public",
    "headers": [
      {
        "source": "/.well-known/assetlinks.json",
        "headers": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ]
      },
      {
        "source": "/.well-known/apple-app-site-association",
        "headers": [
          {
            "key": "Content-Type",
            "value": "application/json"
          }
        ]
      }
    ]
  }
}
```

Upload files to `public/.well-known/` and deploy:
```bash
firebase deploy --only hosting
```

#### **Option C: Nginx Server**

**nginx.conf:**
```nginx
server {
    listen 443 ssl;
    server_name flixbit.app;
    
    # SSL configuration
    ssl_certificate /path/to/ssl/certificate.crt;
    ssl_certificate_key /path/to/ssl/private.key;
    
    # Serve .well-known files
    location /.well-known/ {
        root /var/www/flixbit.app;
        default_type application/json;
        add_header Content-Type application/json;
    }
    
    # Rest of your configuration
    location / {
        # your app configuration
    }
}
```

#### **Option D: Apache Server**

**.htaccess in root directory:**
```apache
<IfModule mod_rewrite.c>
    # Serve .well-known files with correct content type
    <FilesMatch "assetlinks\.json">
        Header set Content-Type "application/json"
    </FilesMatch>
    
    <FilesMatch "apple-app-site-association">
        Header set Content-Type "application/json"
    </FilesMatch>
</IfModule>
```

---

### **Step 4: Verify Files Are Accessible**

#### **Test Android File:**
```bash
curl -I https://flixbit.app/.well-known/assetlinks.json
```

Expected response:
```
HTTP/2 200
content-type: application/json
```

View content:
```bash
curl https://flixbit.app/.well-known/assetlinks.json
```

#### **Test iOS File:**
```bash
curl -I https://flixbit.app/.well-known/apple-app-site-association
```

Expected response:
```
HTTP/2 200
content-type: application/json
```

#### **Use Online Validators:**

**For Android:**
- Google's Statement List Generator: https://developers.google.com/digital-asset-links/tools/generator
- Test your links: `https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=https://flixbit.app&relation=delegate_permission/common.handle_all_urls`

**For iOS:**
- Apple's App Site Association Validator: https://search.developer.apple.com/appsearch-validation-tool/
- Branch.io Validator: https://branch.io/resources/aasa-validator/

---

### **Step 5: Configure Your Mobile App**

#### **Android: AndroidManifest.xml**

```xml
<activity android:name=".MainActivity">
    <!-- Your existing intent filters -->
    
    <!-- App Links with autoVerify -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        
        <!-- Must match your domain -->
        <data
            android:scheme="https"
            android:host="flixbit.app"
            android:pathPrefix="/referral" />
    </intent-filter>
</activity>
```

**Key points:**
- `android:autoVerify="true"` → Android will automatically verify the domain
- `android:host` must match your domain exactly
- Multiple domains? Add multiple `<data>` tags

#### **iOS: Info.plist**

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:flixbit.app</string>
</array>
```

**Also enable in Xcode:**
1. Select your target → **Signing & Capabilities**
2. Click **+ Capability**
3. Add **Associated Domains**
4. Add domain: `applinks:flixbit.app`

---

### **Step 6: Test Deep Links**

#### **Test on Android:**

**Via ADB (Android Debug Bridge):**
```bash
# Test HTTPS link
adb shell am start -a android.intent.action.VIEW \
  -d "https://flixbit.app/referral?code=JOHN1234" \
  com.flixbit.app

# Test custom scheme
adb shell am start -a android.intent.action.VIEW \
  -d "flixbit://referral?code=JOHN1234" \
  com.flixbit.app
```

**Via Browser:**
1. Open Chrome on device
2. Type: `https://flixbit.app/referral?code=JOHN1234`
3. Should open app directly (not browser)

**Check verification status:**
```bash
adb shell pm get-app-links com.flixbit.app
```

Expected output:
```
com.flixbit.app:
  ID: ...
  Signatures: [...]
  Domain verification state:
    flixbit.app: verified
```

#### **Test on iOS:**

**Via Safari:**
1. Open Safari on device
2. Type: `https://flixbit.app/referral?code=JOHN1234`
3. Should open app directly

**Via Simulator:**
```bash
xcrun simctl openurl booted "https://flixbit.app/referral?code=JOHN1234"
```

**Via Notes app:**
1. Open Notes app
2. Type the link: `https://flixbit.app/referral?code=JOHN1234`
3. Long press → Should show "Open in Flixbit"

---

## 🚨 Common Issues & Solutions

### **Issue 1: Android shows "Open with" dialog instead of opening app directly**

**Causes:**
- `android:autoVerify="true"` not set
- Domain verification failed
- assetlinks.json not accessible

**Debug:**
```bash
adb shell pm get-app-links com.flixbit.app
```

If shows `none` or `ask`, verification failed.

**Solutions:**
- Wait 20 seconds after install (Android needs time to verify)
- Check assetlinks.json is publicly accessible
- Verify SHA-256 fingerprint matches
- Clear app data and reinstall

### **Issue 2: iOS opens Safari instead of app**

**Causes:**
- apple-app-site-association not found
- File has wrong content-type
- Associated domains not configured in Xcode

**Debug:**
- Check file exists: `curl https://flixbit.app/.well-known/apple-app-site-association`
- Check Team ID and Bundle ID are correct
- Verify associated domains in Xcode capabilities

**Solutions:**
- Ensure file has NO extension
- Content-Type must be `application/json`
- Add domain in Xcode: Signing & Capabilities → Associated Domains
- Rebuild and reinstall app

### **Issue 3: Links work on one domain but not subdomain**

**Example:** Works on `flixbit.app` but not `www.flixbit.app`

**Solution:** Add both to configurations:

**Android:**
```xml
<data android:scheme="https" android:host="flixbit.app" />
<data android:scheme="https" android:host="www.flixbit.app" />
```

**iOS:**
```xml
<array>
    <string>applinks:flixbit.app</string>
    <string>applinks:www.flixbit.app</string>
</array>
```

Upload files to both:
- `https://flixbit.app/.well-known/`
- `https://www.flixbit.app/.well-known/`

### **Issue 4: File returns 404**

**Solutions:**
- Check file name spelling (no typos!)
- Ensure `.well-known` folder exists
- Check file permissions (644)
- Verify server doesn't block `.well-known` directory
- Check `.htaccess` isn't blocking access

---

## 🎯 Alternative: Firebase Dynamic Links (No Domain Setup Required)

If you **don't own a domain** or want easier setup:

### **Advantages:**
- ✅ No server configuration needed
- ✅ Built-in app install attribution
- ✅ Automatic verification
- ✅ Analytics included
- ✅ Works across app install

### **Disadvantages:**
- ❌ URLs are longer: `https://flixbit.page.link/AbCdEf`
- ❌ Less branding control
- ❌ Dependent on Firebase service

### **Setup:**
```dart
// Add to pubspec.yaml
firebase_dynamic_links: ^5.4.0

// Generate dynamic link
final dynamicLinkParams = DynamicLinkParameters(
  link: Uri.parse('https://flixbit.app/referral?code=JOHN1234'),
  uriPrefix: 'https://flixbit.page.link',
  androidParameters: AndroidParameters(packageName: 'com.flixbit.app'),
  iosParameters: IOSParameters(bundleId: 'com.flixbit.app'),
);

final ShortDynamicLink shortLink = await dynamicLinks.buildShortLink(dynamicLinkParams);
final Uri url = shortLink.shortUrl;
// url = https://flixbit.page.link/AbCd
```

---

## 📊 Summary: What You Actually Need

### **Minimum Setup (Custom Scheme Only):**
- ✅ No domain needed
- ✅ Works for: `flixbit://referral?code=XXX`
- ❌ Doesn't work if app not installed
- ⏱️ Setup time: 10 minutes

### **Full Setup (Universal Links):**
- ✅ Domain with HTTPS required
- ✅ Two verification files needed
- ✅ Works even if app not installed (falls back to web)
- ✅ Better user experience
- ⏱️ Setup time: 1-2 hours

### **Quick Checklist:**

**For Android App Links:**
- [ ] Get SHA-256 fingerprint
- [ ] Create `assetlinks.json`
- [ ] Upload to `https://yourdomain.com/.well-known/assetlinks.json`
- [ ] Verify file is accessible (returns 200, JSON content-type)
- [ ] Add intent-filter with `android:autoVerify="true"`
- [ ] Test with `adb shell pm get-app-links`

**For iOS Universal Links:**
- [ ] Get Team ID and Bundle ID
- [ ] Create `apple-app-site-association` (no extension!)
- [ ] Upload to `https://yourdomain.com/.well-known/apple-app-site-association`
- [ ] Verify file is accessible (returns 200, JSON content-type)
- [ ] Add associated domains in Info.plist and Xcode
- [ ] Test in Safari/Notes app

---

This complete domain setup will enable full deep linking functionality with proper app install attribution!
