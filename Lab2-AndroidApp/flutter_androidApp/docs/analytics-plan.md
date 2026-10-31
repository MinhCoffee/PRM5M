# Firebase Analytics Measurement Plan
**Dự án:** FAP Attendance App (Lab 3)  
**Tài liệu theo dõi sự kiện người dùng (Analytics Plan)**  
**Trạng thái:** Hoàn thiện & Tuân thủ chính sách bảo mật PII  

---

## 1. Mục tiêu theo dõi (Objectives)
Tài liệu này xác định các sự kiện hành vi chính của giảng viên trên ứng dụng FAP Attendance nhằm:
* Đo lường hiệu quả quy trình điểm danh theo thời gian thực.
* Phân tích tỷ lệ xuất báo cáo chuyên cần (CSV/FAP Format).
* Giám sát tính ổn định của luồng xác thực đăng nhập Google OAuth.
* Đánh giá mức độ sử dụng các tính năng nâng cao (bộ lọc lịch dạy, trợ lý AI, tùy chỉnh ngưỡng chuyên cần Remote Config).

---

## 2. Nguyên tắc bảo vệ thông tin cá nhân (PII Compliance)
Tuân thủ nghiêm ngặt điều khoản Google Analytics for Firebase:
* **TUYỆT ĐỐI KHÔNG** truyền thông tin cá nhân (Personally Identifiable Information - PII) như: Họ tên sinh viên, địa chỉ email, số điện thoại, mật khẩu, mã căn cước công dân trong các tham số (`parameters`).
* Sử dụng mã định danh người dùng ẩn danh `uid` được cấp phát từ Firebase Authentication thông qua hàm:
  ```dart
  FirebaseAnalytics.instance.setUserId(id: uid);
  ```

---

## 3. Danh mục 7+ sự kiện Analytics bắt buộc

| STT | Tên sự kiện (`name`) | Mục đích & Thời điểm kích hoạt (Trigger) | Vị trí trong Code | Tham số (`parameters`) | Kiểu dữ liệu | Ví dụ giá trị | Tuân thủ PII |
|:---:|:---|:---|:---|:---|:---:|:---|:---:|
| **1** | `login` | Giảng viên hoàn tất quá trình xác thực đăng nhập vào hệ thống | `lib/features/auth/viewmodel/auth_viewmodel.dart` | `method` | String | `"google_oauth_firebase"` |  Hợp lệ (không chứa email) |
| **2** | `screen_view` | Giảng viên chuyển sang xem màn hình mới | Các ViewModel khi `load()` thành công | `screen_name` | String | `"home_screen"`, `"reports_screen"`, `"timetable_screen"` |  Hợp lệ |
| **3** | `attendance_marked` | Giảng viên tích chọn trạng thái có mặt/vắng cho sinh viên trong ca | `lib/features/attendance/viewmodel/attendance_detail_viewmodel.dart` | `session_id`<br>`present_count`<br>`absent_count` | String<br>Integer<br>Integer | `"SES_SE1801_S1"`<br>`28`<br>`2` |  Hợp lệ (chỉ truyền ID ca & số lượng) |
| **4** | `attendance_submitted` | Giảng viên bấm nút nộp và đồng bộ dữ liệu điểm danh chính thức | `lib/features/attendance/viewmodel/attendance_detail_viewmodel.dart` | `session_id`<br>`class_code` | String<br>String | `"SES_SE1801_S1"`<br>`"SE1801"` |  Hợp lệ |
| **5** | `export_report` | Giảng viên xuất báo cáo chuyên cần hoặc file đồng bộ FAP | `lib/features/reports/viewmodel/reports_viewmodel.dart`<br>`lib/features/export/viewmodel/export_viewmodel.dart` | `class_code`<br>`file_type` | String<br>String | `"SE1801"`<br>`"csv"` hoặc `"fap_csv"` |  Hợp lệ |
| **6** | `filter_changed` | Giảng viên thao tác thay đổi bộ lọc học kỳ, môn học hoặc mã lớp | `lib/features/reports/viewmodel/reports_viewmodel.dart`<br>`lib/features/attendance/viewmodel/attendance_browse_viewmodel.dart` | `filter_type`<br>`filter_value` | String<br>String | `"semester"`, `"2026"`<br>`"class"`, `"SE1801"` |  Hợp lệ |
| **7** | `save_thresholds` | Giảng viên điều chỉnh ngưỡng cảnh báo vắng (Warning/Banned) | `lib/features/settings/viewmodel/settings_viewmodel.dart` | `warn`<br>`ban` | Double<br>Double | `0.15`<br>`0.20` |  Hợp lệ |
| **8** *(Bonus)* | `seed_sample_data` | Giảng viên tạo lại dữ liệu mẫu kiểm thử | `lib/features/settings/viewmodel/settings_viewmodel.dart` | `subjects`<br>`classes` | Integer<br>Integer | `4`<br>`6` |  Hợp lệ |

---

## 4. Chi tiết triển khai mã nguồn (Code Implementation)

### 4.1. Thiết lập User ID sau khi đăng nhập thành công
Ngay sau khi Google Sign-In & Firebase Auth thành công, ViewModel gọi:
```dart
final verifiedUser = user ?? UserProfile.defaultLecturer();
await FirebaseAnalytics.instance.setUserId(id: verifiedUser.id);
```

### 4.2. Ghi nhận các sự kiện nghiệp vụ
Thông qua `IAnalyticsService` được inject trong `ServiceLocator`:
```dart
// 1. Ghi nhận đăng nhập
await analyticsService.logLogin('google_oauth_firebase');

// 2. Chuyển màn hình
await analyticsService.logScreenView('reports_screen');

// 3. Đánh dấu điểm danh
await analyticsService.logAttendanceMarked(
  sessionId: 'SES_101',
  presentCount: 28,
  absentCount: 2,
);

// 4. Nộp điểm danh
await analyticsService.logAttendanceSubmitted(
  sessionId: 'SES_101',
  classCode: 'SE1801',
);

// 5. Xuất báo cáo
await analyticsService.logExportReport(
  classCode: 'SE1801',
  fileType: 'csv',
);

// 6. Đổi bộ lọc
await analyticsService.logFilterChanged(
  filterType: 'class',
  value: 'SE1801',
);

// 7. Lưu ngưỡng chuyên cần
await analyticsService.logEvent('save_thresholds', {
  'warn': 0.15,
  'ban': 0.20,
});
```

---

## 5. Hướng dẫn kiểm thử thời gian thực với Firebase DebugView

Để kiểm tra các sự kiện Analytics xuất hiện ngay lập tức trên Firebase Console (menu **Analytics** > **DebugView**):

1. Kết nối máy ảo Android hoặc thiết bị thật qua USB/Wi-Fi.
2. Mở terminal và chạy lệnh:
   ```bash
   adb shell setprop debug.firebase.analytics.app com.example.flutter_application_1
   ```
3. Mở ứng dụng, thao tác đăng nhập, điểm danh, xuất báo cáo.
4. Mở tab **DebugView** trên Firebase Console để quan sát timeline các sự kiện đổ về trong vòng vài giây.
5. Sau khi kiểm thử xong, tắt chế độ debug bằng lệnh:
   ```bash
   adb shell setprop debug.firebase.analytics.app .none.
   ```
