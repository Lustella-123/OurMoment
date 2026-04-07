// App Store Connect에 동일 상품·가격으로 등록 후 in_app_purchase와 연동합니다.
// 클라이언트 상수는 표시용·검증용이며, 실제 과금은 스토어가 권위입니다.

/// iOS 자동 갱신 구독 제품 ID (App Store Connect와 동일해야 함)
const String kIosSubscriptionMonthlyId =
    'com.jscompany.ourmoment.premium.monthly';
const String kIosSubscriptionYearlyId =
    'com.jscompany.ourmoment.premium.yearly';

/// 월 구독 가격 (원) — 기획안
const int kSubscriptionMonthlyKrw = 2900;

/// 연 구독 가격 (원) — 기획안
const int kSubscriptionYearlyKrw = 29000;

/// 첫 이용 무료 기간 (일) — 인트로 오퍼·서버 정책과 맞출 것
const int kFreeTrialDays = 30;
