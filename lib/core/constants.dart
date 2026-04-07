/// 무료 플랜: 월간 업로드 가능 장수 (기획 확정값)
const int kFreeMonthlyPhotoLimit = 60;

/// 무료 플랜: 사진 메타데이터·스토리지 보관 기간 (일)
const int kFreePhotoRetentionDays = 365;

/// 사랑의 온도 상한 (UI·게임 설계와 동일하게 유지)
const int kLoveTemperatureMax = 100;

/// 순간(사진) 등록 시 온도 가산
const int kLoveTempDeltaNewMoment = 3;

/// 좋아요 토글 시 (상대가 눌렀을 때만 가산은 클라이언트에서 처리 가능하나, 단순히 토글마다 소량)
const int kLoveTempDeltaLike = 1;

/// 댓글 작성 시
const int kLoveTempDeltaComment = 2;
