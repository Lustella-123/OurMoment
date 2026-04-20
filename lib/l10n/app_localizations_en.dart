// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Our moment';

  @override
  String get navHome => 'Home';

  @override
  String get navHomeScreen => 'Home';

  @override
  String get navFeed => 'Feed';

  @override
  String get navDiary => 'Diary';

  @override
  String get navMemo => 'Memo';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navSettings => 'Settings';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeRecordButton => 'Record today';

  @override
  String get homeTodayPhotoTitle => 'Today\'s moment';

  @override
  String get homeTodayPhotoSubtitle =>
      'Save today with one photo and a short note.';

  @override
  String get homeLoveTemperature => 'Love temperature';

  @override
  String get homeLoveTemperatureHint =>
      'Warm up with photos, check-ins, likes, and comments.';

  @override
  String get homeLoveTemperatureRange => '0° – 100°';

  @override
  String get feedTitle => 'Feed';

  @override
  String get diaryTitle => 'Diary';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarLegendMine => 'Mine';

  @override
  String get calendarLegendPartner => 'Partner';

  @override
  String get calendarAddSchedule => 'Add schedule';

  @override
  String get calendarEditSchedule => 'Edit schedule';

  @override
  String get calendarScheduleTitleHint => 'Schedule title';

  @override
  String get calendarScheduleNoteHint => 'Memo (optional)';

  @override
  String get calendarPickTime => 'Time';

  @override
  String get calendarDeleteConfirm => 'Delete this schedule?';

  @override
  String get calendarSortTime => 'By time';

  @override
  String get calendarSortCreated => 'By created';

  @override
  String get calendarSave => 'Save';

  @override
  String get calendarCancel => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageKo => 'Korean';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsAppearance => 'Theme colors';

  @override
  String get settingsBackgroundColor => 'Background';

  @override
  String get settingsAccentColor => 'Accent & icons';

  @override
  String get settingsSubscription => 'Subscription';

  @override
  String get settingsSubscriptionHint =>
      'If one of you subscribes, both get the benefits.';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsDeveloperMenu => 'Developer';

  @override
  String get settingsDeveloperMenuHint => 'Tap version 5 times to open.';

  @override
  String get settingsLogout => 'Log out';

  @override
  String freeTierPhotosLabel(int count) {
    return 'Free plan: up to $count photos per month';
  }

  @override
  String get adPlaceholder => 'Ad';

  @override
  String get premiumActive => 'Premium active';

  @override
  String get premiumInactive => 'Free plan';

  @override
  String get authSubtitle => 'Sign in with Google, Apple, or email.';

  @override
  String get authGoogle => 'Continue with Google';

  @override
  String get authApple => 'Continue with Apple';

  @override
  String get authEmailSection => 'Email';

  @override
  String get authEmailLoginSection => 'Email sign-in';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordConfirmLabel => 'Confirm password';

  @override
  String get authLogin => 'Log in';

  @override
  String get authRegister => 'Create account';

  @override
  String get authRegisterPrompt => 'Don\'t have an account?';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterSubtitle =>
      'Enter email and password. We\'ll send a verification email.';

  @override
  String get authRegisterSubmit => 'Sign up';

  @override
  String get authPasswordMismatch => 'Passwords do not match.';

  @override
  String get authPasswordTooShort => 'Password must be at least 6 characters.';

  @override
  String get authGoogleIosHint =>
      'If Google sign-in fails, re-download GoogleService-Info.plist and add REVERSED_CLIENT_ID to URL Types in Info.plist.';

  @override
  String get verifyEmailTitle => 'Verify email';

  @override
  String get verifyEmailBody =>
      'We sent a verification link to your email. Open it, then tap verify below. Email sign-ups must verify before using the app.';

  @override
  String get verifyEmailSpamHint =>
      'Delivery can take a few minutes. Check spam/promotions. Gmail may show noreply@firebase.com or firebaseapp.com.';

  @override
  String get verifyEmailSent => 'Verification email sent.';

  @override
  String get verifyEmailResend => 'Resend email';

  @override
  String get verifyEmailCheck => 'I verified';

  @override
  String get verifyEmailSignOut => 'Log out';

  @override
  String get pairingTitle => 'Connect with partner';

  @override
  String get pairingBody =>
      'Your invite code is fixed to your account. Share it, or enter your partner\'s code.';

  @override
  String get pairingCodeFixedHint =>
      'The code stays the same every time you open the app.';

  @override
  String get pairingCodeLoadRetry => 'Create / refresh my code';

  @override
  String get pairingInviteCodeMissingBody =>
      'We could not create your invite code yet. Check Firestore rules include inviteCodes, then tap below.';

  @override
  String get pairingCreate => 'Create invite code';

  @override
  String get pairingYourCode => 'Your invite code';

  @override
  String get pairingShare => 'Share link & code';

  @override
  String get pairingCodeHint => '6-character code';

  @override
  String get pairingConnect => 'Connect';

  @override
  String inviteShareText(String code, String link) {
    return 'Join me on Our moment!\nCode: $code\nOpen the link or enter the code in the app: $link';
  }

  @override
  String get inviteErrorInvalid => 'We could not find that code.';

  @override
  String get inviteErrorExpired => 'This invite expired. Ask for a new one.';

  @override
  String get inviteErrorUsed => 'This invite was already used.';

  @override
  String get inviteErrorSelf => 'You cannot use your own invite.';

  @override
  String get inviteErrorAlreadyPaired => 'This account is already connected.';

  @override
  String get inviteErrorFull => 'That couple is already complete.';

  @override
  String get inviteErrorGeneric => 'Could not connect. Please try again.';

  @override
  String get authErrorCancelled => 'Sign-in was cancelled.';

  @override
  String get authErrorGeneric => 'Sign-in failed.';

  @override
  String get developerPremiumDenied => 'This email is not allowed.';

  @override
  String get developerPremiumGranted => 'Premium applied (local).';

  @override
  String get commonRetry => 'Try again';

  @override
  String get errorProfileLoadTitle => 'Could not load your profile';

  @override
  String get errorFirestoreTitle => 'Could not load data';

  @override
  String get splashLoading => 'Please wait';

  @override
  String get homeTogetherDays => 'Together';

  @override
  String get homeWeddingDday => 'Wedding';

  @override
  String get homeDdayNotSet => 'Not set';

  @override
  String get feedEmptyTitle => 'No moments yet';

  @override
  String get calendarEmptyTitle => 'Calendar';

  @override
  String get calendarEmptyBody =>
      'Even without photos or words, we hope you had a good day.';

  @override
  String get diaryPhotoPick => 'Add photo & note';

  @override
  String get diaryIntroBody =>
      'What photo sums up your day? Want to add a short note?';

  @override
  String get diaryFirestorePermissionDenied =>
      'No permission to save. Reopen the app or check that Firestore rules are deployed.';

  @override
  String get diaryPrepareSnackbar => 'Photo and diary uploads are coming soon.';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authResetPasswordTitle => 'Reset password';

  @override
  String get authResetPasswordBody =>
      'Enter the email you signed up with and we will send a reset link.';

  @override
  String get authResetSend => 'Send link';

  @override
  String get authResetSent =>
      'Check your email. If you do not see it, check spam.';

  @override
  String get authEmailRequired => 'Please enter your email.';

  @override
  String get authEmailInvalid => 'That email does not look valid.';

  @override
  String get authPasswordRequired => 'Please enter your password.';

  @override
  String get feedConnectFirst => 'Connect with your partner to see the feed.';

  @override
  String get feedEmptyBody => 'Capture your moment from Home.';

  @override
  String get homeMe => 'Me';

  @override
  String get homePartnerPlaceholder => 'Partner';

  @override
  String get momentCommentsTitle => 'Comments';

  @override
  String get momentCommentHint => 'Write a comment';

  @override
  String get momentSend => 'Send';

  @override
  String momentLikeCount(int count) {
    return '$count likes';
  }

  @override
  String get momentDelete => 'Delete this moment';

  @override
  String get momentDeleteConfirm =>
      'Delete? Photos and comments will be removed.';

  @override
  String get diaryPickPhoto => 'Choose from gallery';

  @override
  String get diaryCaptionHint => 'A short note (optional)';

  @override
  String get diaryPublish => 'Post';

  @override
  String get diarySave => 'Save';

  @override
  String get diaryNoPhotosYet => 'Choose photos';

  @override
  String get diaryPostedSuccess => 'Your moment was saved.';

  @override
  String get diaryQuotaExceeded =>
      'You reached this month’s free upload limit.';

  @override
  String get diaryNeedCaptionOrPhoto => 'Add a photo or a note.';

  @override
  String get calendarNoCouple =>
      'Connect with your partner to use the calendar.';

  @override
  String get settingsCoupleSection => 'Couple & dates';

  @override
  String get settingsCoupleNotPaired =>
      'After pairing you can set relationship and wedding dates.';

  @override
  String get settingsDisplayName => 'Your display name';

  @override
  String get settingsSaveName => 'Save name';

  @override
  String get settingsRelationshipStart => 'Relationship start';

  @override
  String get settingsWeddingDate => 'Wedding anniversary';

  @override
  String get settingsTapToSet => 'Tap to set';

  @override
  String get settingsClear => 'Clear';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get milestonesOnboardingTitle => 'Special dates';

  @override
  String get milestonesOnboardingBody =>
      'Relationship start and wedding anniversary are optional. You can set one, both, or neither.';

  @override
  String get milestonesSkip => 'Later';

  @override
  String get milestonesConfirm => 'Save & continue';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEntrySubtitle => 'Name, photo & invite code';

  @override
  String get profilePhotoPick => 'Change photo';

  @override
  String get profileNameHint => 'Display name';

  @override
  String get profileSave => 'Save';

  @override
  String get profileInviteCode => 'Invite code';

  @override
  String get profileCopyCode => 'Copy code';

  @override
  String get profileEnsureCode => 'Get invite code';

  @override
  String get diaryPickPhotos => 'Add photo';

  @override
  String get memoTitle => 'Memo';

  @override
  String get memoAdd => 'Add memo';

  @override
  String get memoNoCouple => 'Connect with your partner to use shared memo.';

  @override
  String get memoEmpty => 'No memos yet. Add your first one.';

  @override
  String get memoFilterTodo => 'Memo';

  @override
  String get memoFilterDone => 'Done';

  @override
  String get memoMySection => 'My memo';

  @override
  String get memoPartnerSection => 'Partner memo';

  @override
  String get memoCreateTitle => 'New memo';

  @override
  String get memoEditTitle => 'Edit memo';

  @override
  String get memoFieldTitle => 'Title';

  @override
  String get memoFieldNote => 'Note';

  @override
  String get memoNoDueDate => 'No due date';

  @override
  String get memoPickDueDate => 'Pick due date';

  @override
  String get subscriptionCardTitle => 'Our moment Premium';

  @override
  String get subscriptionCardSubtitle => 'One subscription covers both of you.';

  @override
  String get subscriptionComingSoon => 'Store integration coming soon';

  @override
  String subscriptionCtaMonthly(int price) {
    return 'Monthly · ₩$price/mo';
  }

  @override
  String subscriptionCtaYearly(int price) {
    return 'Yearly · ₩$price/yr';
  }

  @override
  String subscriptionPriceLine(int monthly, int yearly) {
    return '₩$monthly/mo · ₩$yearly/yr';
  }
}
