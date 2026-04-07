import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'Our moment'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get navHome;

  /// No description provided for @navFeed.
  ///
  /// In ko, this message translates to:
  /// **'피드'**
  String get navFeed;

  /// No description provided for @navDiary.
  ///
  /// In ko, this message translates to:
  /// **'일기'**
  String get navDiary;

  /// No description provided for @navMemo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get navMemo;

  /// No description provided for @navCalendar.
  ///
  /// In ko, this message translates to:
  /// **'달력'**
  String get navCalendar;

  /// No description provided for @navSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get navSettings;

  /// No description provided for @homeTitle.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get homeTitle;

  /// No description provided for @homeTodayPhotoTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 순간 올리기'**
  String get homeTodayPhotoTitle;

  /// No description provided for @homeTodayPhotoSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'사진 한 장과 짧은 일기로 오늘을 남겨보세요.'**
  String get homeTodayPhotoSubtitle;

  /// No description provided for @homeLoveTemperature.
  ///
  /// In ko, this message translates to:
  /// **'사랑의 온도'**
  String get homeLoveTemperature;

  /// No description provided for @homeLoveTemperatureHint.
  ///
  /// In ko, this message translates to:
  /// **'사진·출석·좋아요·댓글로 온도가 올라가요.'**
  String get homeLoveTemperatureHint;

  /// No description provided for @homeLoveTemperatureRange.
  ///
  /// In ko, this message translates to:
  /// **'0° – 100°'**
  String get homeLoveTemperatureRange;

  /// No description provided for @feedTitle.
  ///
  /// In ko, this message translates to:
  /// **'피드'**
  String get feedTitle;

  /// No description provided for @diaryTitle.
  ///
  /// In ko, this message translates to:
  /// **'일기'**
  String get diaryTitle;

  /// No description provided for @calendarTitle.
  ///
  /// In ko, this message translates to:
  /// **'달력'**
  String get calendarTitle;

  /// No description provided for @calendarLegendMine.
  ///
  /// In ko, this message translates to:
  /// **'내 일정'**
  String get calendarLegendMine;

  /// No description provided for @calendarLegendPartner.
  ///
  /// In ko, this message translates to:
  /// **'상대 일정'**
  String get calendarLegendPartner;

  /// No description provided for @calendarAddSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 추가'**
  String get calendarAddSchedule;

  /// No description provided for @calendarEditSchedule.
  ///
  /// In ko, this message translates to:
  /// **'일정 수정'**
  String get calendarEditSchedule;

  /// No description provided for @calendarScheduleTitleHint.
  ///
  /// In ko, this message translates to:
  /// **'일정 제목'**
  String get calendarScheduleTitleHint;

  /// No description provided for @calendarScheduleNoteHint.
  ///
  /// In ko, this message translates to:
  /// **'메모 (선택)'**
  String get calendarScheduleNoteHint;

  /// No description provided for @calendarPickTime.
  ///
  /// In ko, this message translates to:
  /// **'시간'**
  String get calendarPickTime;

  /// No description provided for @calendarDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'이 일정을 삭제할까요?'**
  String get calendarDeleteConfirm;

  /// No description provided for @calendarSortTime.
  ///
  /// In ko, this message translates to:
  /// **'시간순'**
  String get calendarSortTime;

  /// No description provided for @calendarSortCreated.
  ///
  /// In ko, this message translates to:
  /// **'등록순'**
  String get calendarSortCreated;

  /// No description provided for @calendarSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get calendarSave;

  /// No description provided for @calendarCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get calendarCancel;

  /// No description provided for @settingsTitle.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In ko, this message translates to:
  /// **'일반'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageKo.
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get settingsLanguageKo;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsAppearance.
  ///
  /// In ko, this message translates to:
  /// **'테마 색상'**
  String get settingsAppearance;

  /// No description provided for @settingsBackgroundColor.
  ///
  /// In ko, this message translates to:
  /// **'배경 색'**
  String get settingsBackgroundColor;

  /// No description provided for @settingsAccentColor.
  ///
  /// In ko, this message translates to:
  /// **'포인트·아이콘 색'**
  String get settingsAccentColor;

  /// No description provided for @settingsSubscription.
  ///
  /// In ko, this message translates to:
  /// **'구독'**
  String get settingsSubscription;

  /// No description provided for @settingsSubscriptionHint.
  ///
  /// In ko, this message translates to:
  /// **'한 명만 구독해도 둘 다 혜택이 적용돼요.'**
  String get settingsSubscriptionHint;

  /// No description provided for @settingsVersion.
  ///
  /// In ko, this message translates to:
  /// **'버전'**
  String get settingsVersion;

  /// No description provided for @settingsDeveloperMenu.
  ///
  /// In ko, this message translates to:
  /// **'개발자'**
  String get settingsDeveloperMenu;

  /// No description provided for @settingsDeveloperMenuHint.
  ///
  /// In ko, this message translates to:
  /// **'버전을 5번 누르면 열려요.'**
  String get settingsDeveloperMenuHint;

  /// No description provided for @settingsLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get settingsLogout;

  /// No description provided for @freeTierPhotosLabel.
  ///
  /// In ko, this message translates to:
  /// **'무료 플랜: 월 {count}장까지 업로드 가능'**
  String freeTierPhotosLabel(int count);

  /// No description provided for @adPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'광고'**
  String get adPlaceholder;

  /// No description provided for @premiumActive.
  ///
  /// In ko, this message translates to:
  /// **'프리미엄 사용 중'**
  String get premiumActive;

  /// No description provided for @premiumInactive.
  ///
  /// In ko, this message translates to:
  /// **'무료 플랜'**
  String get premiumInactive;

  /// No description provided for @authSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'Google·Apple 또는 이메일로 로그인하세요.'**
  String get authSubtitle;

  /// No description provided for @authGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google로 계속하기'**
  String get authGoogle;

  /// No description provided for @authApple.
  ///
  /// In ko, this message translates to:
  /// **'Apple로 계속하기'**
  String get authApple;

  /// No description provided for @authEmailSection.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get authEmailSection;

  /// No description provided for @authEmailLoginSection.
  ///
  /// In ko, this message translates to:
  /// **'이메일 로그인'**
  String get authEmailLoginSection;

  /// No description provided for @authEmailLabel.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordConfirmLabel.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 확인'**
  String get authPasswordConfirmLabel;

  /// No description provided for @authLogin.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get authLogin;

  /// No description provided for @authRegister.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get authRegister;

  /// No description provided for @authRegisterPrompt.
  ///
  /// In ko, this message translates to:
  /// **'아직 계정이 없나요?'**
  String get authRegisterPrompt;

  /// No description provided for @authRegisterTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이메일과 비밀번호를 입력한 뒤 가입을 완료하세요. 인증 메일이 발송됩니다.'**
  String get authRegisterSubtitle;

  /// No description provided for @authRegisterSubmit.
  ///
  /// In ko, this message translates to:
  /// **'가입 완료'**
  String get authRegisterSubmit;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 서로 다릅니다.'**
  String get authPasswordMismatch;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 6자 이상이어야 합니다.'**
  String get authPasswordTooShort;

  /// No description provided for @authGoogleIosHint.
  ///
  /// In ko, this message translates to:
  /// **'Google 로그인 오류 시 Firebase 콘솔에서 plist를 다시 받아 REVERSED_CLIENT_ID를 Info.plist URL Types에 추가했는지 확인하세요.'**
  String get authGoogleIosHint;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In ko, this message translates to:
  /// **'이메일 인증'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailBody.
  ///
  /// In ko, this message translates to:
  /// **'가입하신 주소로 인증 메일을 보냈어요. 메일의 링크를 누른 뒤 아래에서 확인해 주세요. 이메일 가입자는 인증 완료 전까지 앱을 쓸 수 없어요.'**
  String get verifyEmailBody;

  /// No description provided for @verifyEmailSpamHint.
  ///
  /// In ko, this message translates to:
  /// **'5~10분 정도 걸릴 수 있어요. 받은편지함에 없으면 스팸·프로모션함을 확인해 주세요. Gmail은 noreply@firebase.com 또는 firebaseapp.com 발신일 수 있어요.'**
  String get verifyEmailSpamHint;

  /// No description provided for @verifyEmailSent.
  ///
  /// In ko, this message translates to:
  /// **'인증 메일을 보냈어요.'**
  String get verifyEmailSent;

  /// No description provided for @verifyEmailResend.
  ///
  /// In ko, this message translates to:
  /// **'인증 메일 다시 보내기'**
  String get verifyEmailResend;

  /// No description provided for @verifyEmailCheck.
  ///
  /// In ko, this message translates to:
  /// **'인증 확인'**
  String get verifyEmailCheck;

  /// No description provided for @verifyEmailSignOut.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get verifyEmailSignOut;

  /// No description provided for @pairingTitle.
  ///
  /// In ko, this message translates to:
  /// **'상대와 연결'**
  String get pairingTitle;

  /// No description provided for @pairingBody.
  ///
  /// In ko, this message translates to:
  /// **'내 초대 코드는 계정마다 고정이에요. 상대에게 알려주거나, 상대 코드를 입력해 연결하세요.'**
  String get pairingBody;

  /// No description provided for @pairingCodeFixedHint.
  ///
  /// In ko, this message translates to:
  /// **'코드는 바뀌지 않아요. 앱을 다시 켜도 동일합니다.'**
  String get pairingCodeFixedHint;

  /// No description provided for @pairingCodeLoadRetry.
  ///
  /// In ko, this message translates to:
  /// **'내 코드 다시 만들기'**
  String get pairingCodeLoadRetry;

  /// No description provided for @pairingInviteCodeMissingBody.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드를 아직 받지 못했어요. Firestore 규칙에 inviteCodes가 있는지 확인한 뒤 아래를 눌러 주세요.'**
  String get pairingInviteCodeMissingBody;

  /// No description provided for @pairingCreate.
  ///
  /// In ko, this message translates to:
  /// **'초대 코드 만들기'**
  String get pairingCreate;

  /// No description provided for @pairingYourCode.
  ///
  /// In ko, this message translates to:
  /// **'내 초대 코드'**
  String get pairingYourCode;

  /// No description provided for @pairingShare.
  ///
  /// In ko, this message translates to:
  /// **'링크·코드 공유'**
  String get pairingShare;

  /// No description provided for @pairingCodeHint.
  ///
  /// In ko, this message translates to:
  /// **'6자리 코드'**
  String get pairingCodeHint;

  /// No description provided for @pairingConnect.
  ///
  /// In ko, this message translates to:
  /// **'연결하기'**
  String get pairingConnect;

  /// No description provided for @inviteShareText.
  ///
  /// In ko, this message translates to:
  /// **'Our moment에서 함께해요!\n코드: {code}\n앱에서 입력하거나 링크를 눌러주세요: {link}'**
  String inviteShareText(String code, String link);

  /// No description provided for @inviteErrorInvalid.
  ///
  /// In ko, this message translates to:
  /// **'코드를 찾을 수 없어요.'**
  String get inviteErrorInvalid;

  /// No description provided for @inviteErrorExpired.
  ///
  /// In ko, this message translates to:
  /// **'만료된 초대예요. 새로 만들어 주세요.'**
  String get inviteErrorExpired;

  /// No description provided for @inviteErrorUsed.
  ///
  /// In ko, this message translates to:
  /// **'이미 사용된 초대예요.'**
  String get inviteErrorUsed;

  /// No description provided for @inviteErrorSelf.
  ///
  /// In ko, this message translates to:
  /// **'본인이 만든 초대는 사용할 수 없어요.'**
  String get inviteErrorSelf;

  /// No description provided for @inviteErrorAlreadyPaired.
  ///
  /// In ko, this message translates to:
  /// **'이미 연결된 계정이에요.'**
  String get inviteErrorAlreadyPaired;

  /// No description provided for @inviteErrorAlreadyClaimed.
  ///
  /// In ko, this message translates to:
  /// **'이 초대 코드는 이미 사용이 시작되었어요.'**
  String get inviteErrorAlreadyClaimed;

  /// No description provided for @inviteErrorFull.
  ///
  /// In ko, this message translates to:
  /// **'이미 다른 분과 연결됐어요.'**
  String get inviteErrorFull;

  /// No description provided for @inviteErrorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'연결에 실패했어요. 다시 시도해 주세요.'**
  String get inviteErrorGeneric;

  /// No description provided for @authErrorCancelled.
  ///
  /// In ko, this message translates to:
  /// **'로그인이 취소됐어요.'**
  String get authErrorCancelled;

  /// No description provided for @authErrorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'로그인에 실패했어요.'**
  String get authErrorGeneric;

  /// No description provided for @developerPremiumDenied.
  ///
  /// In ko, this message translates to:
  /// **'허용된 이메일이 아니에요.'**
  String get developerPremiumDenied;

  /// No description provided for @developerPremiumGranted.
  ///
  /// In ko, this message translates to:
  /// **'프리미엄이 적용됐어요 (로컬).'**
  String get developerPremiumGranted;

  /// No description provided for @commonRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get commonRetry;

  /// No description provided for @errorProfileLoadTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필을 불러오지 못했어요'**
  String get errorProfileLoadTitle;

  /// No description provided for @errorFirestoreTitle.
  ///
  /// In ko, this message translates to:
  /// **'데이터를 불러오지 못했어요'**
  String get errorFirestoreTitle;

  /// No description provided for @splashLoading.
  ///
  /// In ko, this message translates to:
  /// **'잠시만 기다려 주세요'**
  String get splashLoading;

  /// No description provided for @homeTogetherDays.
  ///
  /// In ko, this message translates to:
  /// **'함께한 날'**
  String get homeTogetherDays;

  /// No description provided for @homeWeddingDday.
  ///
  /// In ko, this message translates to:
  /// **'결혼 기념일'**
  String get homeWeddingDday;

  /// No description provided for @homeDdayNotSet.
  ///
  /// In ko, this message translates to:
  /// **'미설정'**
  String get homeDdayNotSet;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'아직 순간이 없어요'**
  String get feedEmptyTitle;

  /// No description provided for @calendarEmptyTitle.
  ///
  /// In ko, this message translates to:
  /// **'달력'**
  String get calendarEmptyTitle;

  /// No description provided for @calendarEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'사진과 글이 없더라도 좋은 하루 보내셨길 바래요.'**
  String get calendarEmptyBody;

  /// No description provided for @diaryPhotoPick.
  ///
  /// In ko, this message translates to:
  /// **'사진·일기 올리기'**
  String get diaryPhotoPick;

  /// No description provided for @diaryIntroBody.
  ///
  /// In ko, this message translates to:
  /// **'오늘 하루는 어떤 사진인가요?'**
  String get diaryIntroBody;

  /// No description provided for @diaryFirestorePermissionDenied.
  ///
  /// In ko, this message translates to:
  /// **'저장 권한이 없어요. 앱을 다시 실행하거나 Firebase 규칙 배포를 확인해 주세요.'**
  String get diaryFirestorePermissionDenied;

  /// No description provided for @diaryPrepareSnackbar.
  ///
  /// In ko, this message translates to:
  /// **'사진·일기 기능은 곧 열려요.'**
  String get diaryPrepareSnackbar;

  /// No description provided for @authForgotPassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 잊으셨나요?'**
  String get authForgotPassword;

  /// No description provided for @authResetPasswordTitle.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 재설정'**
  String get authResetPasswordTitle;

  /// No description provided for @authResetPasswordBody.
  ///
  /// In ko, this message translates to:
  /// **'가입한 이메일 주소를 입력하면 재설정 링크를 보내드려요.'**
  String get authResetPasswordBody;

  /// No description provided for @authResetSend.
  ///
  /// In ko, this message translates to:
  /// **'링크 보내기'**
  String get authResetSend;

  /// No description provided for @authResetSent.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 확인해 주세요. 링크가 없으면 스팸함을 확인해 주세요.'**
  String get authResetSent;

  /// No description provided for @authEmailRequired.
  ///
  /// In ko, this message translates to:
  /// **'이메일을 입력해 주세요.'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In ko, this message translates to:
  /// **'올바른 이메일 형식이 아니에요.'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호를 입력해 주세요.'**
  String get authPasswordRequired;

  /// No description provided for @feedConnectFirst.
  ///
  /// In ko, this message translates to:
  /// **'커플 연결 후 피드를 볼 수 있어요.'**
  String get feedConnectFirst;

  /// No description provided for @feedEmptyBody.
  ///
  /// In ko, this message translates to:
  /// **'홈에서 순간을 남겨보세요.'**
  String get feedEmptyBody;

  /// No description provided for @homeMe.
  ///
  /// In ko, this message translates to:
  /// **'나'**
  String get homeMe;

  /// No description provided for @homePartnerPlaceholder.
  ///
  /// In ko, this message translates to:
  /// **'상대'**
  String get homePartnerPlaceholder;

  /// No description provided for @momentCommentsTitle.
  ///
  /// In ko, this message translates to:
  /// **'댓글'**
  String get momentCommentsTitle;

  /// No description provided for @momentCommentHint.
  ///
  /// In ko, this message translates to:
  /// **'댓글을 입력하세요'**
  String get momentCommentHint;

  /// No description provided for @momentSend.
  ///
  /// In ko, this message translates to:
  /// **'보내기'**
  String get momentSend;

  /// No description provided for @momentLikeCount.
  ///
  /// In ko, this message translates to:
  /// **'좋아요 {count}'**
  String momentLikeCount(int count);

  /// No description provided for @momentDelete.
  ///
  /// In ko, this message translates to:
  /// **'이 순간 삭제'**
  String get momentDelete;

  /// No description provided for @momentDeleteConfirm.
  ///
  /// In ko, this message translates to:
  /// **'삭제할까요? 사진과 댓글이 함께 지워져요.'**
  String get momentDeleteConfirm;

  /// No description provided for @diaryPickPhoto.
  ///
  /// In ko, this message translates to:
  /// **'갤러리에서 사진 선택'**
  String get diaryPickPhoto;

  /// No description provided for @diaryCaptionHint.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 한마디 (선택)'**
  String get diaryCaptionHint;

  /// No description provided for @diaryPublish.
  ///
  /// In ko, this message translates to:
  /// **'올리기'**
  String get diaryPublish;

  /// No description provided for @diaryPostedSuccess.
  ///
  /// In ko, this message translates to:
  /// **'순간을 남겼어요.'**
  String get diaryPostedSuccess;

  /// No description provided for @diaryQuotaExceeded.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 무료 업로드 한도에 도달했어요.'**
  String get diaryQuotaExceeded;

  /// No description provided for @diaryNeedCaptionOrPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진이나 메모 중 하나는 입력해 주세요.'**
  String get diaryNeedCaptionOrPhoto;

  /// No description provided for @calendarNoCouple.
  ///
  /// In ko, this message translates to:
  /// **'커플 연결 후 달력을 쓸 수 있어요.'**
  String get calendarNoCouple;

  /// No description provided for @settingsCoupleSection.
  ///
  /// In ko, this message translates to:
  /// **'커플·기념일'**
  String get settingsCoupleSection;

  /// No description provided for @settingsCoupleNotPaired.
  ///
  /// In ko, this message translates to:
  /// **'연결 후 연애 시작일·결혼 기념일을 맞출 수 있어요.'**
  String get settingsCoupleNotPaired;

  /// No description provided for @settingsDisplayName.
  ///
  /// In ko, this message translates to:
  /// **'내 이름 (앱에 표시)'**
  String get settingsDisplayName;

  /// No description provided for @settingsSaveName.
  ///
  /// In ko, this message translates to:
  /// **'이름 저장'**
  String get settingsSaveName;

  /// No description provided for @settingsRelationshipStart.
  ///
  /// In ko, this message translates to:
  /// **'연애 시작일'**
  String get settingsRelationshipStart;

  /// No description provided for @settingsWeddingDate.
  ///
  /// In ko, this message translates to:
  /// **'결혼 기념일'**
  String get settingsWeddingDate;

  /// No description provided for @settingsTapToSet.
  ///
  /// In ko, this message translates to:
  /// **'눌러서 설정'**
  String get settingsTapToSet;

  /// No description provided for @settingsClear.
  ///
  /// In ko, this message translates to:
  /// **'지우기'**
  String get settingsClear;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @milestonesOnboardingTitle.
  ///
  /// In ko, this message translates to:
  /// **'기념일을 알려주세요'**
  String get milestonesOnboardingTitle;

  /// No description provided for @milestonesOnboardingBody.
  ///
  /// In ko, this message translates to:
  /// **'연애 시작일과 결혼 기념일은 각각 선택 사항이에요. 하나만 넣어도 되고, 둘 다 비워도 괜찮아요.'**
  String get milestonesOnboardingBody;

  /// No description provided for @milestonesSkip.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get milestonesSkip;

  /// No description provided for @milestonesConfirm.
  ///
  /// In ko, this message translates to:
  /// **'저장하고 계속'**
  String get milestonesConfirm;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'프로필'**
  String get profileTitle;

  /// No description provided for @profileEntrySubtitle.
  ///
  /// In ko, this message translates to:
  /// **'이름·사진·초대 코드'**
  String get profileEntrySubtitle;

  /// No description provided for @profilePhotoPick.
  ///
  /// In ko, this message translates to:
  /// **'사진 변경'**
  String get profilePhotoPick;

  /// No description provided for @profileNameHint.
  ///
  /// In ko, this message translates to:
  /// **'표시 이름'**
  String get profileNameHint;

  /// No description provided for @profileSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get profileSave;

  /// No description provided for @profileInviteCode.
  ///
  /// In ko, this message translates to:
  /// **'내 초대 코드'**
  String get profileInviteCode;

  /// No description provided for @profileCopyCode.
  ///
  /// In ko, this message translates to:
  /// **'코드 복사'**
  String get profileCopyCode;

  /// No description provided for @profileEnsureCode.
  ///
  /// In ko, this message translates to:
  /// **'코드 발급받기'**
  String get profileEnsureCode;

  /// No description provided for @diaryPickPhotos.
  ///
  /// In ko, this message translates to:
  /// **'사진 추가'**
  String get diaryPickPhotos;

  /// No description provided for @memoTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memoTitle;

  /// No description provided for @memoAdd.
  ///
  /// In ko, this message translates to:
  /// **'메모 추가'**
  String get memoAdd;

  /// No description provided for @memoNoCouple.
  ///
  /// In ko, this message translates to:
  /// **'커플 연결 후 함께 쓰는 메모를 만들 수 있어요.'**
  String get memoNoCouple;

  /// No description provided for @memoEmpty.
  ///
  /// In ko, this message translates to:
  /// **'아직 메모가 없어요. 첫 메모를 추가해 보세요.'**
  String get memoEmpty;

  /// No description provided for @memoFilterTodo.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memoFilterTodo;

  /// No description provided for @memoFilterDone.
  ///
  /// In ko, this message translates to:
  /// **'완료'**
  String get memoFilterDone;

  /// No description provided for @memoMySection.
  ///
  /// In ko, this message translates to:
  /// **'내 메모'**
  String get memoMySection;

  /// No description provided for @memoPartnerSection.
  ///
  /// In ko, this message translates to:
  /// **'상대 메모'**
  String get memoPartnerSection;

  /// No description provided for @memoCreateTitle.
  ///
  /// In ko, this message translates to:
  /// **'새 메모'**
  String get memoCreateTitle;

  /// No description provided for @memoEditTitle.
  ///
  /// In ko, this message translates to:
  /// **'메모 수정'**
  String get memoEditTitle;

  /// No description provided for @memoFieldTitle.
  ///
  /// In ko, this message translates to:
  /// **'제목'**
  String get memoFieldTitle;

  /// No description provided for @memoFieldNote.
  ///
  /// In ko, this message translates to:
  /// **'메모'**
  String get memoFieldNote;

  /// No description provided for @memoNoDueDate.
  ///
  /// In ko, this message translates to:
  /// **'기한 없음'**
  String get memoNoDueDate;

  /// No description provided for @memoPickDueDate.
  ///
  /// In ko, this message translates to:
  /// **'기한 선택'**
  String get memoPickDueDate;

  /// No description provided for @subscriptionCardTitle.
  ///
  /// In ko, this message translates to:
  /// **'Our moment 프리미엄'**
  String get subscriptionCardTitle;

  /// No description provided for @subscriptionCardSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'한 명만 구독해도 두 분 모두 혜택이에요.'**
  String get subscriptionCardSubtitle;

  /// No description provided for @subscriptionComingSoon.
  ///
  /// In ko, this message translates to:
  /// **'스토어 연동 예정'**
  String get subscriptionComingSoon;

  /// No description provided for @subscriptionCtaMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월간 구독 · ₩{price}/월'**
  String subscriptionCtaMonthly(int price);

  /// No description provided for @subscriptionCtaYearly.
  ///
  /// In ko, this message translates to:
  /// **'연간 구독 · ₩{price}/년'**
  String subscriptionCtaYearly(int price);

  /// No description provided for @subscriptionPriceLine.
  ///
  /// In ko, this message translates to:
  /// **'₩{monthly}/월 · ₩{yearly}/년'**
  String subscriptionPriceLine(int monthly, int yearly);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
