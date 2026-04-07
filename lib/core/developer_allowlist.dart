/// 개발자 메뉴에서 프리미엄을 부여할 수 있는 이메일(소문자 기준).
const Set<String> kDeveloperPremiumEmails = {'tella4164@gmail.com'};

bool isDeveloperPremiumEmail(String email) {
  return kDeveloperPremiumEmails.contains(email.trim().toLowerCase());
}
