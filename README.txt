** Development Instructions **
X-Schedule is an application built by X Students for X Students--always remember that when developing.
While AI is impossible to predict at the time of writing this, please use it cautiously:
- Do not expose any API keys, keystore files, or personal / school data while developing.
- Ensure that all code remains well commented and understandable for future developers.
While developing, keep in mind the longevity of this app, and how future student developers will have to take it over.
Thus, make sure documentation is kept up-to-date, and never overcomplicate the app at risk of placing a larger burden on future devs.
When new versions are developed, be sure to both alpha test and beta test the app. Even smaller changes risk breaking the app in unforeseeable ways.
While code remains fairly consistent, the development platforms we release to change all the time, so be sure to follow online documentation and be cautious when building new versions.
Follow other instructions in this repository when building the app locally on your machine.
Remember that this app is used by thousands of students, teachers, and parents: mistakes may happen, but you can never be to cautious.
Good Luck

- John Daniher '26
Founding Developer of X-Schedule



** Installing Flutter **

Recommended Process: Install via VS Code
1) Launch VS Code
2) Install Flutter extension for VS Code via Extensions (Ctrl+Shift+X)
3) Open command prompt (Ctrl+Shift+P) and type ">flutter: new project"
4) As VS Code prompts to locate flutter sdk, click "Download SDK" (ignore template prompt). Consider installing under "C:\[INSERT USER\dev"
5) Once output panel displays that flutter is done initializing, type ">flutter: run doctor" in the command prompt to ensure everything was successful.
NOTE: Once installed, you don't have to use VS Code if you don't want to (I recommend Android Studio), it just makes it easier to install. Make sure to add SDK when installing.

Flutter Installation Documentation
https://docs.flutter.dev/get-started/install/windows/mobile

** Additional Flutter Configuration **

When making the following changes, make sure to run "flutter clean" upon changes.
To verify Flutter's health on your machine, run "flutter doctor"

Configuring Flutter for Android Studio
1) Install the flutter plugin for Android Studio
2) Go to Settings>Languages & Frameworks>Flutter
3) Insert the Flutter SDK file path

Installing Windows Desktop C++ Development Tools
1) Install Visual Studio (Not VS Code, Visual Studio)
2) During installation, select the workload "Desktop development with C++"" (Likely to change in the future, see online Flutter documentation for more)
3) Enable Windows desktop support in Flutter. Run: "flutter config --enable-windows-desktop"

Allowing http get requests with chrome client
1) Open [Flutter SDK Path]\packages\flutter_tools\lib\src\web\chrome.dart
2) Find '--disable-extensions'
3) Insert '--disable-web-security' below that line



** Mac Setup for Building iOS IPA **

1) Install GitHub Desktop. Its recommended you move GitHub into the applications folder, but admin permission will be required to do so, and it can still run slowly through Downloads.
2) Install IDE of choice. Xcode does not have support for dart and/or flutter, so you will need to install an additional IDE. I recommend VS Code, as it requires very little additional setup, and others such as Android Studio don't work as well with Mac. It's also recommended to move this into the applications folder.
3) Install the Flutter SDK. Save the path, including the path to the bin.
4) Determine if your mac uses bash of zsh. Then, in the command line, write "touch ~/.[bash or zsh]rc", then "nano ~/.[bash or zsh]rc", then "export PATH="$PATH:[Path to flutter bin", then control O, Enter, Control X, N, and then save the line "source ~/.[bash or zsh]rc". Run "flutter doctor" to ensure proper setup.
4) Install Homebrew. There are ways to ignore this step, but this is the easiest method to access cocoapods. View info here: https://docs.brew.sh/Installation
5) Run "brew install cocoapods". Cocoapods is the application responsible for installing various flutter plugins we use from the internet.
6) Ensure both MacOS and XCode are up to date. Once you configure minor things through Xcode, you'll be good to go.



** Building an IPA for the Apple App Store **
NOTE: Building IPAs can be finicky, especially as new plugins are introduced to the app and Apple makes changes are their end. Don't hesitate to reference online documentation for more help.
1) Verify that your Mac is set up to build X-Schedule IPAs (see instructions above).
2) Launch XCode by opening /ios/Runner.xcworkspace
3) Inside XCode, select "Runner" in the left toolbar, select "Targets>Runner" in the toolbar that appears, and go to "Signing and Capabilities" in the bar up top.
4) Verify that the development team is "St. Xavier High School, Inc", the bundle ID is "org.stxavier.xschedule" (both can be temporarily changed when testing), "Automatically manage signing" is enabled, and all capabilities required are enabled below.
5) Open the Mac's terminal and open the source(s) required to reference Flutter (see instructions above).
6) To build the app bundle, run "flutter build ipa", and wait for it to finish.
7) To test, in XCode, select the development device in the top bar, select "Manage Run Destinations...",
 select your phone (or add it if required), wait for your phone to connect, press the "+" button to add an app, and select /build/ios/ipa/Runner.ipa.
NOTE: Immediate testing required enabling Developer Mode on your iphone (Settings > Privacy & Security > Developer Mode) and trusting yourself as a developer (Settings > General > VPN & Device Management > Developer App).
8) To upload the app, open the transported app, ensure you are signed into stxapps@stxavier.org or any other developer account with access, select the "+" button, select /build/ios/ipa/xschedule.ipa, and wait for it to finish uploading.



** Managing the app on the Apple App Store **
Once the IPA is uploaded and processed, you can manage the app on the app store by going to appstoreconnect.apple.com.
There, you can customize the app's appearance on the App Store, manage versions, and beta test.

Beta testing is handled through TestFlight. We have beta testing divied up into groups dependant on status (e.g. student, teacher, parent).
All Beta testers will receive an email upon invitation, prompting them to install the TestFlight app and beta test.

Once a version is ready to be published, changes must be submitted to apple for review. Review may take up to several days, so be sure to try it in advance.
Apple will not accept a broken or buggy app, so make sure the app is presentable and well explained through notes. It's a good idea to send the app in for review at the same time you begin beta testing to have it ready in time.
Once verified, Apple app versions require manual release, and afterwards will be updated in a matter of minutes.



** Building an App Bundle for the Google Play Store **
1) To build an appbundle to be accepted by Google, ensure that the keystore files are properly located under /android. These files should be stored on an X-Schedule USB drive, and SHOULD NOT be shared ANYWHERE online, inclduign email.
2) Ensure that "Android SDK Build-Tools" and "Android SDK Command-line tools" are installed by going to Android Studio > SDK Manager > Languages and Frameworks > Android SDK > SDK Tools
3) Make sure to increment the build ID for rach version you upload to the Google Play Store. The console will not accept duplicate versions IDs OR IDs < current ID.
4) Once ready, run "flutter build appbundle"



** Managing the app on the Google Play Store **
The app can be managed on the Google Play Store by going to play.google.com/console
Google appbundles must be manually uploaded and can be attached to a variety of points throughout the console. Seperate uploads are required for Alpha testing, beta testing, release, etc.
Any changes made to the app (Vanity of appbundle) require Google developer verification. The process is slightly mroe efficient than Apple's, but somehow takes longer, so plan accordingly.



** Onboarding Developers **
When adding additional developers, be sure to add them to the development team on GitHub, App Store Connect, and Google Play Console.
Once they have made their first changes, be sure to add them to the credits as a developer.



** Offboarding Developers **
Once a developer is offboarding, be sure to transfer all leadership tech they have to a future developer:
- Ensure that they have access to both the android keystore files and the Mac account to be able to properly build the app.
- Ensure their leadership is transferred on GitHub (feel free to keep them in for memorabelia)
- Ensure they are marked as "Development Alumni" in the credits
- Ensure their positions are revoked from App Store Connect and the Google Play Console (these pose security risks for the school).