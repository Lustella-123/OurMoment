// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Our moment';

  @override
  String get navHome => '홈';

  @override
  String get navHomeScreen => '홈화면';

  @override
  String get navFeed => '피드';

  @override
  String get navDiary => '일기';

  @override
  String get navMemo => '메모';

  @override
  String get navCalendar => '달력';

  @override
  String get navSettings => '설정';

  @override
  String get homeTitle => '홈';

  @override
  String get homeRecordButton => '오늘의 기록 남기기';

  @override
  String get homeTodayPhotoTitle => '오늘의 순간 올리기';

  @override
  String get homeTodayPhotoSubtitle => '사진 한 장과 짧은 일기로 오늘을 남겨보세요.';

  @override
  String get homeLoveTemperature => '사랑의 온도';

  @override
  String get homeLoveTemperatureHint => '사진·출석·좋아요·댓글로 온도가 올라가요.';

  @override
  String get homeLoveTemperatureRange => '0° – 100°';

  @override
  String get feedTitle => '피드';

  @override
  String get diaryTitle => '일기';

  @override
  String get calendarTitle => '달력';

  @override
  String get calendarLoadError => '달력을 불러오지 못했어요.';

  @override
  String get calendarRetry => '재시도';

  @override
  String get calendarAnniversaryFirstYear => '1주년';

  @override
  String calendarAnniversaryYear(int years) {
    return '$years주년';
  }

  @override
  String calendarAnniversaryHundredDays(int days) {
    return '${days}일';
  }

  @override
  String get calendarBirthdayMine => '내 생일';

  @override
  String get calendarBirthdayPartner => '상대 생일';

  @override
  String get calendarLegendMine => '내 일정';

  @override
  String get calendarLegendPartner => '상대 일정';

  @override
  String get calendarAddSchedule => '일정 추가';

  @override
  String get calendarEditSchedule => '일정 수정';

  @override
  String get calendarScheduleTitleHint => '일정 제목';

  @override
  String get calendarScheduleNoteHint => '메모 (선택)';

  @override
  String get calendarPickTime => '시간';

  @override
  String get calendarDeleteConfirm => '이 일정을 삭제할까요?';

  @override
  String get calendarSortTime => '시간순';

  @override
  String get calendarSortCreated => '등록순';

  @override
  String get calendarSave => '저장';

  @override
  String get calendarCancel => '취소';

  @override
  String get settingsTitle => '설정';

  @override
  String get settingsSectionGeneral => '일반';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsCalendarDisplay => '달력 표시';

  @override
  String get settingsCalendarShowAnniversaries => '연애 기념일 표시';

  @override
  String get settingsCalendarShowBirthdays => '생일 표시';

  @override
  String get settingsLanguageKo => '한국어';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsAppearance => '테마 색상';

  @override
  String get settingsBackgroundColor => '배경 색';

  @override
  String get settingsAccentColor => '포인트·아이콘 색';

  @override
  String get settingsSubscription => '구독';

  @override
  String get settingsSubscriptionHint => '한 명만 구독해도 둘 다 혜택이 적용돼요.';

  @override
  String get settingsVersion => '버전';

  @override
  String get settingsDeveloperMenu => '개발자';

  @override
  String get settingsDeveloperMenuHint => '버전을 5번 누르면 열려요.';

  @override
  String get settingsLogout => '로그아웃';

  @override
  String freeTierPhotosLabel(int count) {
    return '무료 플랜: 월 $count장까지 업로드 가능';
  }

  @override
  String get adPlaceholder => '광고';

  @override
  String get premiumActive => '프리미엄 사용 중';

  @override
  String get premiumInactive => '무료 플랜';

  @override
  String get authSubtitle => 'Google·Apple 또는 이메일로 로그인하세요.';

  @override
  String get authGoogle => 'Google로 계속하기';

  @override
  String get authApple => 'Apple로 계속하기';

  @override
  String get authEmailSection => '이메일';

  @override
  String get authEmailLoginSection => '이메일 로그인';

  @override
  String get authEmailLabel => '이메일';

  @override
  String get authPasswordLabel => '비밀번호';

  @override
  String get authPasswordConfirmLabel => '비밀번호 확인';

  @override
  String get authLogin => '로그인';

  @override
  String get authRegister => '회원가입';

  @override
  String get authRegisterPrompt => '아직 계정이 없나요?';

  @override
  String get authRegisterTitle => '회원가입';

  @override
  String get authRegisterSubtitle =>
      '이메일과 비밀번호를 입력한 뒤 가입을 완료하세요. 인증 메일이 발송됩니다.';

  @override
  String get authRegisterSubmit => '가입 완료';

  @override
  String get authPasswordMismatch => '비밀번호가 서로 다릅니다.';

  @override
  String get authPasswordTooShort => '비밀번호는 6자 이상이어야 합니다.';

  @override
  String get authGoogleIosHint =>
      'Google 로그인 오류 시 Firebase 콘솔에서 plist를 다시 받아 REVERSED_CLIENT_ID를 Info.plist URL Types에 추가했는지 확인하세요.';

  @override
  String get verifyEmailTitle => '이메일 인증';

  @override
  String get verifyEmailBody =>
      '가입하신 주소로 인증 메일을 보냈어요. 메일의 링크를 누른 뒤 아래에서 확인해 주세요. 이메일 가입자는 인증 완료 전까지 앱을 쓸 수 없어요.';

  @override
  String get verifyEmailSpamHint =>
      '5~10분 정도 걸릴 수 있어요. 받은편지함에 없으면 스팸·프로모션함을 확인해 주세요. Gmail은 noreply@firebase.com 또는 firebaseapp.com 발신일 수 있어요.';

  @override
  String get verifyEmailSent => '인증 메일을 보냈어요.';

  @override
  String get verifyEmailResend => '인증 메일 다시 보내기';

  @override
  String get verifyEmailCheck => '인증 확인';

  @override
  String get verifyEmailSignOut => '로그아웃';

  @override
  String get pairingTitle => '상대와 연결';

  @override
  String get pairingBody =>
      '내 초대 코드는 계정마다 고정이에요. 상대에게 알려주거나, 상대 코드를 입력해 연결하세요.';

  @override
  String get pairingCodeFixedHint => '코드는 바뀌지 않아요. 앱을 다시 켜도 동일합니다.';

  @override
  String get pairingCodeLoadRetry => '내 코드 다시 만들기';

  @override
  String get pairingInviteCodeMissingBody =>
      '초대 코드를 아직 받지 못했어요. Firestore 규칙에 inviteCodes가 있는지 확인한 뒤 아래를 눌러 주세요.';

  @override
  String get pairingCreate => '초대 코드 만들기';

  @override
  String get pairingYourCode => '내 초대 코드';

  @override
  String get pairingShare => '링크·코드 공유';

  @override
  String get pairingCodeHint => '6자리 코드';

  @override
  String get pairingConnect => '연결하기';

  @override
  String inviteShareText(String code, String link) {
    return 'Our moment에서 함께해요!\n코드: $code\n앱에서 입력하거나 링크를 눌러주세요: $link';
  }

  @override
  String get inviteErrorInvalid => '코드를 찾을 수 없어요.';

  @override
  String get inviteErrorExpired => '만료된 초대예요. 새로 만들어 주세요.';

  @override
  String get inviteErrorUsed => '이미 사용된 초대예요.';

  @override
  String get inviteErrorSelf => '본인이 만든 초대는 사용할 수 없어요.';

  @override
  String get inviteErrorAlreadyPaired => '이미 연결된 계정이에요.';

  @override
  String get inviteErrorFull => '이미 다른 분과 연결됐어요.';

  @override
  String get inviteErrorGeneric => '연결에 실패했어요. 다시 시도해 주세요.';

  @override
  String get authErrorCancelled => '로그인이 취소됐어요.';

  @override
  String get authErrorGeneric => '로그인에 실패했어요.';

  @override
  String get developerPremiumDenied => '허용된 이메일이 아니에요.';

  @override
  String get developerPremiumGranted => '프리미엄이 적용됐어요 (로컬).';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get errorProfileLoadTitle => '프로필을 불러오지 못했어요';

  @override
  String get errorFirestoreTitle => '데이터를 불러오지 못했어요';

  @override
  String get splashLoading => '잠시만 기다려 주세요';

  @override
  String get homeTogetherDays => '함께한 날';

  @override
  String get homeWeddingDday => '결혼 기념일';

  @override
  String get homeDdayNotSet => '미설정';

  @override
  String get feedEmptyTitle => '아직 순간이 없어요';

  @override
  String get calendarEmptyTitle => '달력';

  @override
  String get calendarEmptyBody => '사진과 글이 없더라도 좋은 하루 보내셨길 바래요.';

  @override
  String get diaryPhotoPick => '사진·일기 올리기';

  @override
  String get diaryIntroBody => '오늘 하루는 어떤 사진인가요?';

  @override
  String get diaryFirestorePermissionDenied =>
      '저장 권한이 없어요. 앱을 다시 실행하거나 Firebase 규칙 배포를 확인해 주세요.';

  @override
  String get diaryPrepareSnackbar => '사진·일기 기능은 곧 열려요.';

  @override
  String get authForgotPassword => '비밀번호를 잊으셨나요?';

  @override
  String get authResetPasswordTitle => '비밀번호 재설정';

  @override
  String get authResetPasswordBody => '가입한 이메일 주소를 입력하면 재설정 링크를 보내드려요.';

  @override
  String get authResetSend => '링크 보내기';

  @override
  String get authResetSent => '이메일을 확인해 주세요. 링크가 없으면 스팸함을 확인해 주세요.';

  @override
  String get authEmailRequired => '이메일을 입력해 주세요.';

  @override
  String get authEmailInvalid => '올바른 이메일 형식이 아니에요.';

  @override
  String get authPasswordRequired => '비밀번호를 입력해 주세요.';

  @override
  String get feedConnectFirst => '커플 연결 후 피드를 볼 수 있어요.';

  @override
  String get feedEmptyBody => '홈에서 순간을 남겨보세요.';

  @override
  String get homeMe => '나';

  @override
  String get homePartnerPlaceholder => '상대';

  @override
  String get momentCommentsTitle => '댓글';

  @override
  String get momentCommentHint => '댓글을 입력하세요';

  @override
  String get momentSend => '보내기';

  @override
  String momentLikeCount(int count) {
    return '좋아요 $count';
  }

  @override
  String get momentDelete => '이 순간 삭제';

  @override
  String get momentDeleteConfirm => '삭제할까요? 사진과 댓글이 함께 지워져요.';

  @override
  String get diaryPickPhoto => '갤러리에서 사진 선택';

  @override
  String get diaryCaptionHint => '오늘의 한마디 (선택)';

  @override
  String get diaryPublish => '올리기';

  @override
  String get diarySave => '저장';

  @override
  String get diaryNoPhotosYet => '사진을 선택해 주세요';

  @override
  String get diaryPostedSuccess => '순간을 남겼어요.';

  @override
  String get diaryQuotaExceeded => '이번 달 무료 업로드 한도에 도달했어요.';

  @override
  String get diaryNeedCaptionOrPhoto => '사진이나 메모 중 하나는 입력해 주세요.';

  @override
  String get calendarNoCouple => '커플 연결 후 달력을 쓸 수 있어요.';

  @override
  String get settingsCoupleSection => '커플·기념일';

  @override
  String get settingsCoupleNotPaired => '연결 후 연애 시작일·결혼 기념일을 맞출 수 있어요.';

  @override
  String get settingsDisplayName => '내 이름 (앱에 표시)';

  @override
  String get settingsSaveName => '이름 저장';

  @override
  String get settingsRelationshipStart => '연애 시작일';

  @override
  String get settingsWeddingDate => '결혼 기념일';

  @override
  String get settingsTapToSet => '눌러서 설정';

  @override
  String get settingsClear => '지우기';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonCancel => '취소';

  @override
  String get milestonesOnboardingTitle => '기념일을 알려주세요';

  @override
  String get milestonesOnboardingBody =>
      '연애 시작일과 결혼 기념일은 각각 선택 사항이에요. 하나만 넣어도 되고, 둘 다 비워도 괜찮아요.';

  @override
  String get milestonesSkip => '나중에';

  @override
  String get milestonesConfirm => '저장하고 계속';

  @override
  String get profileTitle => '프로필';

  @override
  String get profileEntrySubtitle => '이름·사진·초대 코드';

  @override
  String get profilePhotoPick => '사진 변경';

  @override
  String get profileNameHint => '표시 이름';

  @override
  String get profileSave => '저장';

  @override
  String get profileInviteCode => '내 초대 코드';

  @override
  String get profileCopyCode => '코드 복사';

  @override
  String get profileEnsureCode => '코드 발급받기';

  @override
  String get diaryPickPhotos => '사진 추가';

  @override
  String get memoTitle => '메모';

  @override
  String get memoAdd => '메모 추가';

  @override
  String get memoNoCouple => '커플 연결 후 함께 쓰는 메모를 만들 수 있어요.';

  @override
  String get memoEmpty => '아직 메모가 없어요. 첫 메모를 추가해 보세요.';

  @override
  String get memoFilterTodo => '메모';

  @override
  String get memoFilterDone => '완료';

  @override
  String get memoMySection => '내 메모';

  @override
  String get memoPartnerSection => '상대 메모';

  @override
  String get memoCreateTitle => '새 메모';

  @override
  String get memoEditTitle => '메모 수정';

  @override
  String get memoFieldTitle => '제목';

  @override
  String get memoFieldNote => '메모';

  @override
  String get memoNoDueDate => '기한 없음';

  @override
  String get memoPickDueDate => '기한 선택';

  @override
  String get subscriptionCardTitle => 'Our moment 프리미엄';

  @override
  String get subscriptionCardSubtitle => '한 명만 구독해도 두 분 모두 혜택이에요.';

  @override
  String get subscriptionComingSoon => '스토어 연동 예정';

  @override
  String subscriptionCtaMonthly(int price) {
    return '월간 구독 · ₩$price/월';
  }

  @override
  String subscriptionCtaYearly(int price) {
    return '연간 구독 · ₩$price/년';
  }

  @override
  String subscriptionPriceLine(int monthly, int yearly) {
    return '₩$monthly/월 · ₩$yearly/년';
  }
}
