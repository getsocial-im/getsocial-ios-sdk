# GetSocial iOS SDK

## Version History

### v5.3.3

+ FIXED memory issues

---

### v5.3.2

+ FIXED memory issue with image cache

---

### v5.3.1

+ FIXED orientation change now reflects application's settings

---

### v5.3.0

+ ADDED Polish and Ukrainian localizations
+ FIXED issue that prevented auto configuration of Chinese languages
+ FIXED window resizing issue on iPad on iOS 10, if device is in landscape mode
+ REMOVED the need to add `NSPhotoLibraryUsageDescription` in the `info.plist`
+ FIXED orientation change now reflects application's settings

---

### v5.2.3

+ FIXED issue that blocked receiving chat messages after reconnecting

---

### v5.2.2

+ FIXED issue that prevented forwarding Universal Links callbacks to main AppDelegate

---

### v5.2.1

+ IMPROVED network communications

---

### v5.2.0

+ ADDED KakaoTalk invite plugin
+ ADDED Social graph

---

### v5.1.9

+ FIXED issue with landscape mode on iOS7

---

### v5.1.8

+ FIXED issue with landscape mode on iOS8

---

### v5.1.7

+ FIXED issue with native share on iOS7
+ FIXED sharing content on FB Messenger

---

### v5.1.6

+ FIXED Modal Window issue on iOS10
+ FIXED Orientation issue when building with Xcode 8

---

### v5.1.5

+ FIXED Facebook Smart Invites showing a blank browser on iOS 10
+ FIXED Chat issue when connecting to a public room
+ FIXED Supported orientations issue

---

### v5.1.4

+ CHANGED connection to SSL
+ FIXED custom title for Smart Invites view

---

### v5.1.3

+ FIXED UI became unresponsive after inviting using `inviteUsingProvider`

---

### v5.1.2

+ FIXED status bar appearing even if the app hide it
+ FIXED UI became unresponsive after inviting using `inviteUsingProvider`

---

### v5.1.1

+ ADDED calls to inviteFriendBlock also on cancel and error when supported (twitter/sms/email)

---

### v5.1.0

+ ADDED Chat API to use custom Chat views
+ ADDED native share option to Smart Invites
+ ADDED Facebook Messanger as Smart Invites provider
+ ADDED Indonesian, Tagalog, Malay, Brazilian Portuguese and Vietnamese localization
+ FIXED blurry button images on non-retina display 
+ FIXED status bar overlaps GetSocial SDK views

---

### v5.0.9

+ IMPROVED SDK network communications to GetSocial services

---

### v5.0.8

+ CHANGED Now registering for push notifications on iOS is **ENABLED** by default. Call `[GetSocial sharedInstance].disableAutoRegistrationForPushNotifications = YES;` before initializing the SDK to avoid automatic registration of push notifications on GetSocial initialization.

---

### v5.0.7

+ FIXED bugs in Analytics

---

### v5.0.6

+ FIX multiple invitation view can be opened

---

### v5.0.5

+ FIX unresponsive window after opening animation

---

### v5.0.4

+ ADDED option to delay registering for Push Notifications
+ ADDED support for delay SDK initialization

---

### v5.0.3

+ FIX handling of font size issue if set programmatically

---

### v5.0.2

+ FIX handling of received push notifications

---

### v5.0.1

+ IMPROVED SDK initialization with poor internet connectivity
+ ADDED no connection placeholders when needed
+ ADDED `GetSocialActionOpenSmartInvites` as `GetSocialAction` to use on `OnUserActionPerformHandler`
+ ADDED loading indicators on Activities and Chat views
+ ADDED `OnWindowStateChangedHandler` to be notified when any GetSocial SDK view is opened/closed
+ FIXED issue generating an incorrect unread notification number

---

### v5.0.0

+ IMPROVED Chat module with a complete refactor
+ IMPROVED network communications
+ ADDED presence details
+ ADDED sticky activity at the top
+ ADDED `GetSocialCurrentUser` object 
+ ADDED methods to set `DisplayName` and `AvatarUrl` for the current user
+ ADDED methods to add/remove identities for the current user with conflict support
+ ADDED methods to reset the current user
+ ADDED `OnUserActionPerformHandler` to intercept all user interactions
+ ADDED support for BitCode

---

### v4.0.3

+ ADDED `ACTIVITY_COMMENT_BG_COLOR` property to configure comments background color
+ FIXED User chat messages displayed incorrectly in pressed state

---

### v4.0.2

+ ADDED 5 new languages: Icelandic, Korean, Japanese, Chinese Simplified, Chinese Traditional
+ FIXED crash on start on iOS 7

---

### v4.0.1

+ ADDED support for iOS 9 Universal Links for Smart Invites
+ ADDED `GetSocialAnimationStyleNone` as an option for animation-style to disable all animations

---

### v4.0.0

Release v4.0.0 brings a lot of new features, improvements and few breaking changes. The most notable are:

+ ADDED source param to the onUserAvatarClickHandler
+ ADDED functionality to get an external provider ID by getSocial ID
+ ADDED modularization, `Core` (Activity Feed, Notifications, Smart Invites) and `Chat` modules. [Learn more...](http://docs.getsocial.im/#upgrade-guide)
+ ADDED support for Facebook SDK v4.x [Learn more...](http://docs.getsocial.im/#integration-with-facebook)
+ ADDED support for App in Like list
+ ADDED support for App as sender of notifications
+ ADDED friends list view. [Learn more...](http://docs.getsocial.im/#friends-list)
+ ADDED support for linking multiple user accounts. [Learn more...](http://docs.getsocial.im/#adding-identity-info)
+ ADDED setOnUserIdentityUpdatedHandler that will be invoked on login/logout add/remove IdentityInfo
+ REPLACED generic `openXyz` view method with sophisticated builders API. To obtain view builder call `createXyzView()`.
+ IMPROVED UI configuration system. Now all UI properties can be customized via JSON configuration file. [Learn more...](http://docs.getsocial.im/ui-customization/#developers-guide)
+ IMPROVED most of the `GetSocial` methods to more meaningful names (e.g. `authenticateGame(...)` => `init(...)`, `verifyUserIdentity(...)` => `login(...)`, etc.). [Learn more...](http://docs.getsocial.im/#upgrade-guide)
+ IMPROVED internal queue management
+ IMPROVED internal notifications management
+ FIXED bug affecting FB Login and Invites return to app with a cold start
+ FIXED bug affecting Unity 5 apps hiding GetSocial SDK UI after becoming inactive 

---

### v3.5.4

+ FIXED Chat Bubble maximum width calculation

---

### v3.5.3

+ ADDED support for FB SDK 4.x tracking of smart invites

---

### v3.5.2

+ Bug fixes

---

### v3.5.1

+ ADDED user content moderation callback

---

### v3.5.0

+ ADDED ReferralData on SmartInvites
+ ADDED onReferralDataReceivedHandler
+ ADDED onInviteButtonClickHandler
+ ADDED support for deeplinking
+ ADDED onUserGeneratedContentHandler for moderation purposes

---

### v3.4.0

+ ADDED support for activities with image, button, action
+ ADDED onGameAvatarClick handler
+ ADDED onActivityActionClick handler
+ ADDED Leaderboard data exposed to developer

---

### v3.3.0

+ ADDED Global Chat Room

---

### v3.2.0

+ ADDED Save State functionality
+ ADDED auto integration of push notification by intercepting AppDelegate methods
+ REMOVED the need of a id and key to authenticate. Now, only key is required
+ ADDED ability to post activity with tags and retrieve activities per group
+ ADDED Kakao and Kik invite providers
+ ADDED onLoginRequestHandler to override the login
+ IMPROVED PushNotification code
+ IMPROVED UI experience
+ IMPROVED analytics management
+ ADDED smart invite view
+ ADDED installation tracking
+ ADDED activities filtering by group

---

### v2.7.0

+ FIXED issue with Whatsapp invite
+ FIXED orientation issues for iOS8
+ FIXED problems while signing up with email
+ ADDED support for new API with HTTPS protocol
+ ADDED Ability to take Screenshot and exposed a method for the developers to post a screenshot
+ ADDED Images in Chat
+ ADDED Localization in Spanish
+ ADDED Invite friends via SMS, Email & Whatsapp
+ ADDED Push Notifications with support to open specific Activities, Profiles or Chat
+ FIXED Leaderboard Time Format
+ FIXED Create a chat group when the user has no following
+ FIXED Quickly tapping on Connect to Facebook causes issues
+ FIXED Loading indication position is incorrect when you open a image on a Full Screen
+ FIXED Flush the operation queue twice in a row

---

### v2.5.0

+ FIXED Navigation bugs
+ FIXED #27 SB handle is not correctly shown on iPad
+ FIXED #28 Minor problem with Invite Friends button on Leaderboards and Profile
+ FIXED #17 Login with Email doesn't work when there is no FB plugin register
+ FIXED #24 Alignment issue within activities page
+ FIXED #26 FB Invite button appears even if there is no plugin registered
+ ADDED authentication plugins with facebook support
+ ADDED facebook invite plugin
+ IMPROVED UI by making all table cell margins/styles the same
+ FIXED achievements resize text glitch
+ FIXED error message if username has spaces in it
+ FIXED auto-capitalize/auto-correct behaviour in Login/Signup/Post
+ ADDED a max length for username (16) during signup
+ IMPROVED UI of activities/comments
+ ADDED set social bar in Modal mode
+ ADDED download custom picture for the Social bar handle
+ ADDED Group chat
+ IMPROVED Activities
  + Added ability to post images and screenshots
  + Redesigned posting UI
+ ADDED Post Purchase Activity feature
  + Post a purchase activity with custom text, image, item ID, item name and image URL
  + Register a callback for the action where user presses action button on a purchase
  + Settings toggle that allows the user to post the purchase activities anonymously
+ ADDED User cache
+ ADDED Welcome Page

---

### v1.4.1
+ FIXED bug flickering avatar
+ IMPROVED UI of user profiles
+ IMPROVED hiding post input fields in activities when you are scrolling
+ ADDED the ability to see the list of following/followers users
+ ADDED the ability to see the list of users who liked an activity
+ ADDED the ability to upload a new avatar from the user's profile
+ ADDED queueing of Leaderboard/Achievement operations if the user is logged out
+ ADDED avatar caching on device
+ FIXED bug showing incorrectly the height of the activities
+ FIXED bug showing negative timestamps and 60m instead of 1h, 24h instead of 1d, etc
+ FIXED notification icons persisting after logout.

---

### v1.4.0
+ ADDED Chat one-on-one which includes:
  + Chat history
  + Chat List aka List of Conversations
  + Chat notification on top header
  + Option to block Users for Chat
+ IMPROVED Setting social bar handle position (similar to Android)
+ IMPROVED Hiding social bar handle (similar to Android)
+ IMPROVED UI of User avatars (i.e circular)
+ IMPROVED UI of Menu
+ IMPROVED UI of Achievements & Leaderboards margins
+ IMPROVED UI of Registration and login pages (better Error Handling)
+ FIXED bug that showed negative ‘like’ count
+ REMOVED 'You' and 'Trending' tabs from Activity view

---

### v1.0.2

+ ADDED openSocialBar and closeSocialBar methods

---

### v1.0.1

+ FIXED auto refresh activity indicator
+ ADDED method to allow developers to change the offset of the handle
+ ADDED method to allow developers to change the background color of the handle
+ ADDED New size, icon, default color and default position of the handle
+ REMOVED not visible activities on memory warning

---

### v1.0

+ Initial Version
