# Flutter Design Handoff & Technical Summary

**Dự án:** AttendEase (AttendPass) - FPT Academic Attendance & Sync Portal (PRM393 - Lab 2 Android App)  
**Tên ứng dụng:** `Academic Portal - Attendance`  
**Nhóm phát triển:**
- **Hồ Minh** (MinhCoffee) - System Architecture & Alignment
- **Lâm Thiên Hải Anh** - Android Native Adaptation & Responsive UI
**Kho mã nguồn GitHub:** [https://github.com/MinhCoffee/PRM5M.git](https://github.com/MinhCoffee/PRM5M.git) (Nhánh `main`)  
**Figma Canvas URL:** [Figma PRM Design (Node 2:2)](https://www.figma.com/design/3L02La4yWxZ96fvHavz2ws/PRM?node-id=2-2&t=HFkQ5sszMdvBAJUP-1)  
**Minh chứng phục vụ:** Slide 12 (Flutter Handoff / Technical Summary)  
**Cập nhật lần cuối:** 15/10/2026 — Đồng bộ 100% theo mã nguồn thực tế trong `lib/`

---

## 1. Mục đích của tài liệu Flutter Handoff (Handoff Overview)

**Design Handoff** là tài liệu bàn giao kỹ thuật giữa bộ phận Thiết kế (UI/UX Designer / Figma / AI UI Generation) và bộ phận Lập trình Flutter. Tài liệu này trả lời 3 câu hỏi cốt lõi:
1. **Mỗi màn hình được xây dựng bằng widget nào, nằm ở file nào, route là gì?**
2. **Quy tắc Responsive, Design Tokens (màu, font, bo góc) và trạng thái tương tác chuyển đổi ra sao?**
3. **Các tình huống biên (Edge cases, mất mạng, lỗi dữ liệu, xác nhận an toàn) được lập trình xử lý như thế nào?**

---

## 2. Đặc tả Handoff chuẩn 6 mục theo từng màn hình thực tế (Screen Spec Handoff)

### 📱 SCR-01: Login Screen
1. **Screen Name & Route:** `LoginPage` (`/login`), file: [login_page.dart](lib/features/auth/login_page.dart)
2. **Layout & Responsive Behavior:** Căn giữa màn hình (`Center`), giới hạn chiều rộng tối đa `maxWidth: 420` bằng `ConstrainedBox` trên cả Mobile lẫn Desktop. Nền `AppColors.surface` (`#F8F9FF`).
3. **Design Tokens Applied:** `AppColors.surface`, `AppColors.primary` (`#0072BC`), `headlineLarge` (20sp w600), bo góc `Card` 6px viền `#D1D5DB`.
4. **Widgets & Components:** `Scaffold`, `Card`, `FilledButton.icon`, `CircularProgressIndicator`, biểu tượng trường học `Icons.school_outlined`.
5. **Interactive States:** 
   - *Normal:* Nút "Sign in with Google".
   - *Loading:* Vòng xoay tiến trình vô hiệu hóa nút (`onPressed: null`), nhãn đổi thành "Connecting...".
   - *Error:* Dòng chữ đỏ báo lỗi xác thực hoặc lỗi thiếu cấu hình `.env`.
6. **Edge Cases & Error Handling:**
   - **Android Native:** Sử dụng `GoogleSignIn.instance.authenticate` (Google Play Services Account Picker gốc, không cần localhost callback).
   - **Desktop/Loopback:** Tự động đăng nhập lại nếu còn cached credentials (`hasCachedCredentials()`); khi logout (`/login?logout=1`), xóa sạch token đã lưu để buộc chọn lại tài khoản Google.

---

### 📱 SCR-02: Lecturer Dashboard (Home)
1. **Screen Name & Route:** `HomePage` (`/home`), file: [home_page.dart](lib/features/home/home_page.dart)
2. **Layout & Responsive Behavior:**
   - *Mobile (< 600px):* Thẻ thống kê dàn 2 cột co giãn linh hoạt (`width: (constraints.maxWidth - 12) / 2`); chip trạng thái ca học đặt bên dưới tiêu đề để giữ độ rộng hiển thị.
   - *Desktop ($\ge 600\text{px}$):* Thẻ thống kê cố định `width: 250px` dàn hàng ngang; chip trạng thái đặt bên phải tên ca học.
3. **Design Tokens Applied:** `AppColors.primary`, `AppColors.green` (`#6CB33F`), `AppColors.error` (`#D93025`), `AppColors.tertiary` (`#BA4C00`), `headlineLarge`, `headlineMedium`.
4. **Widgets & Components:** `ListView`, `Wrap`, 4 thẻ Metric thống kê thực tế (*Classes today*, *Overall attendance*, *Banned students*, *Draft sessions*), danh sách thẻ ca học hôm nay (*Today's sessions*), thẻ hướng dẫn nhanh (*Quick Guide & Session Status Glossary*), nút Refresh dữ liệu.
5. **Interactive States:** Tap vào thẻ ca học để điều hướng ngay tới trang điểm danh (`/attendance/:sessionId`); nút làm mới dữ liệu gọi `stats.load(force: true)`.
6. **Edge Cases & Error Handling:** Không có ca học hôm nay $\rightarrow$ Hiển thị Card rỗng: *"No sessions scheduled for today."*.

---

### 📱 SCR-03: Weekly Timetable
1. **Screen Name & Route:** `TimetablePage` (`/timetable`), file: [timetable_page.dart](lib/features/timetable/timetable_page.dart)
2. **Layout & Responsive Behavior:**
   - *Mobile (< 700px):* Danh sách cuộn dọc chia theo từng ngày trong tuần (Thứ 2 $\rightarrow$ Chủ nhật), mỗi ngày là một danh sách các thẻ ca học có viền màu trạng thái 4px bên trái.
   - *Desktop ($\ge 700\text{px}$):* Lưới ma trận toàn cảnh **8 Slot học $\times$ 7 ngày** (chiều rộng tối thiểu 1280px, cuộn ngang mượt mà).
3. **Design Tokens Applied:** `AppColors.primaryDark` (nền header ngày), `AppColors.surfaceContainer`, viền phân cách `#E2E8F0`, màu viền theo trạng thái ca học (`taken` = xanh lá, `inProgress` = cam, `overdueNotTaken` = đỏ, `notTaken` = xanh dương).
4. **Widgets & Components:** Thanh điều hướng tuần (*Previous week*, *Today*, *Next week*), ma trận ô slot, thẻ ca học mini hiển thị mã môn, mã lớp, trạng thái.
5. **Interactive States:** Chạm vào bất kỳ ô ca học nào để mở ngay màn hình điểm danh tương ứng.
6. **Edge Cases & Error Handling:** Ngày không có ca học trên mobile hiển thị nhãn xám *"No sessions"*; ô trống trên desktop để trắng không có sự kiện click.

---

### 📱 SCR-04: My Classes
1. **Screen Name & Route:** `MyClassesPage` (`/my-classes`), file: [my_classes_page.dart](lib/features/classes/my_classes_page.dart)
2. **Layout & Responsive Behavior:**
   - *Mobile (< 700px):* Danh sách thẻ lớp học (`_classCard`), mỗi thẻ gồm tên lớp, tên môn, thanh tiến độ học phần `LinearProgressIndicator` và các chỉ số Warning/Banned.
   - *Desktop ($\ge 700\text{px}$):* `DataTable` 6 cột (CLASS, SUBJECT, STUDENTS, PROGRESS, WARNING, BANNED).
3. **Design Tokens Applied:** `AppColors.primary`, `AppColors.tertiary`, `AppColors.error`, bo góc `6px`.
4. **Widgets & Components:** Thẻ lớp học, thanh tiến độ, chi tiết danh sách ca học của lớp khi được chọn (`_sessionsView`), nút Back quay lại danh sách lớp.
5. **Interactive States:** Nhấp vào hàng/thẻ lớp để xem chi tiết toàn bộ các ca học của lớp đó; nhấp vào ca học để mở trang điểm danh.
6. **Edge Cases & Error Handling:** Lớp chưa bắt đầu có tiến độ 0%; lớp hoàn thành đạt 100%.

---

### 📱 SCR-05: Take Attendance Session Selector
1. **Screen Name & Route:** `AttendanceBrowsePage` (`/take-attendance`), file: [attendance_browse_page.dart](lib/features/attendance/attendance_browse_page.dart)
2. **Layout & Responsive Behavior:** Phân thành 2 nhóm danh sách ngang: *"Today's sessions"* (tối đa 8 slot/ngày) và *"Upcoming classes"* (tối đa 16 ca kế tiếp). Hỗ trợ kéo cảm ứng (`GestureDetector` horizontal drag) và nút mũi tên cuộn trái/phải (`ScrollController.animateTo`).
3. **Design Tokens Applied:** `accentColor` sinh động theo mã băm môn học, `headlineMedium`, `bodyMedium`, viền `outlineVariant`.
4. **Widgets & Components:** Thẻ ca học (`_sessionCard`, width 300px), dải màu 8px ở đầu card theo môn học, chip số lượng ca học, nút *Seed sample data*.
5. **Interactive States:** Chạm vào thẻ ca học để chuyển thẳng vào bàn làm việc điểm danh (`/attendance/:id`).
6. **Edge Cases & Error Handling:** Chưa có ca học nào trong sheet schedule $\rightarrow$ Hiển thị Empty State kèm nút nổi bật *"Create sample data"* để nạp dữ liệu demo an toàn.

---

### 📱 SCR-06: Attendance Detail & Marking Workbench (Màn hình trọng tâm)
1. **Screen Name & Route:** `AttendanceDetailPage` (`/attendance/:sessionId`), file: [attendance_detail_page.dart](lib/features/attendance/attendance_detail_page.dart)
2. **Layout & Responsive Behavior:**
   - *Mobile (< 700px):* Roster hiển thị dạng **danh sách thẻ học viên hàng dọc** (`_studentCard`). Session Card chia **2 cột**.
   - *Desktop ($\ge 700\text{px}$):* Roster hiển thị dạng **DataTable 8 cột** cuộn ngang dọc có cố định chiều cao 420px. Session Card dàn đủ **4 cột**.
3. **Design Tokens Applied:** `AppColors.primary`, `AppColors.errorText` (`#B3261E`), `AppColors.warningText` (`#8A5300`), `AppColors.successText` (`#1B6E2E`), viền input `AppColors.outline` (`#717882`).
4. **Widgets & Components:**
   - **Session Card:** Mã môn, tên môn, lớp, phòng, ngày, Slot, số buổi học (`Session x / y`).
   - **Control Bar:** Bộ đếm sĩ số (*Enrolled, Present, Absent, Rate*); nút thao tác hàng loạt (*Mark All Present*, *Mark All Absent*, *Reset*, *Save Draft*, *Submit*); ô tìm kiếm mã/tên sinh viên; Dropdown lọc trạng thái (All / Present / Absent).
   - **Status Toggle Button (`_statusButton`):** Đạt chuẩn kích thước ngón tay cái $\ge 48\times 48\text{ dp}$ (`minHeight: 48, minWidth: 72`), có icon trực quan (`check` cho Present, `close` cho Absent) và bọc `Semantics`.
   - **Absence Chip (`_absenceChip`):** Tự động đồng bộ màu theo ngưỡng thiết lập trong Settings (`_banThreshold` và `_warnThreshold`).
5. **Interactive States:** 
   - Đổi Present/Absent lập tức cập nhật giao diện và tỷ lệ vắng tức thì qua `setState`, không chờ mạng.
   - Nút Submit mở `AlertDialog` xác nhận trước khi nộp chính thức.
6. **Edge Cases & Error Handling:**
   - Phân biệt rõ trạng thái **Draft** (`sync_status = 'draft'`) và **Submitted** (`sync_status = 'submitted'`).
   - Đã nộp thì nút đổi thành *"Update & Submit"* và thanh thông báo đáy đổi icon `cloud_done_outlined`.

---

### 📱 SCR-07: FAP Sync & Export Center
1. **Screen Name & Route:** `ExportPage` (Route `/fap-sync`, nhãn menu: `Export`), file: [export_page.dart](lib/features/export/export_page.dart)
2. **Layout & Responsive Behavior:** Bộ lọc đa tiêu chí phía trên (Lớp, Từ ngày, Đến ngày); bảng/danh sách ca học bên dưới. Mobile tự động xếp dọc các nút hành động.
3. **Design Tokens Applied:** `AppColors.primary`, `AppColors.primaryDark`, `StatusChip` (*Submitted, Draft, Not Taken*).
4. **Widgets & Components:** Dropdown chọn lớp, Date Picker chọn khoảng ngày, nút *Export CSV (FAP format)*, ô nhập fallback class code và 2 nút *Import Students (CSV / Excel)*.
5. **Interactive States:** Quá trình xuất/nhập hiển thị trạng thái *"Exporting..."* / *"Importing..."*.
6. **Edge Cases & Error Handling:**
   - Nhập file CSV/Excel tự động lọc bỏ các mã sinh viên đã tồn tại trong sheet `students`.
   - Xuất file gọi qua `FileService.saveTextFile`: Trên Android mở Native Save Dialog, trên Windows hỗ trợ mở thư mục chứa file qua SnackBar Action *"Open Folder"*.

---

### 📱 SCR-08: AI Risk Assistant
1. **Screen Name & Route:** `AiAssistantPage` (`/ai-assistant`), file: [ai_assistant_page.dart](lib/features/ai_assistant/ai_assistant_page.dart)
2. **Layout & Responsive Behavior:** Bố cục dạng dòng hội thoại thẻ thông báo (`Card` chứa các phản hồi AI dạng robot `Icons.smart_toy_outlined`).
3. **Design Tokens Applied:** `AppColors.primary`, `AppColors.error`, `AppColors.surfaceContainer`.
4. **Widgets & Components:** Nút truy vấn nhanh *At-risk students*, *Highest absence subject*, Dropdown chọn học viên + nút *Ask history*.
5. **Interactive States:** Tự động chạy quy tắc quét buổi thiếu điểm danh và sinh viên cảnh báo ngay khi mở trang; bấm câu hỏi để nhận ngay kết quả tính toán.
6. **Edge Cases & Error Handling:**
   - Động cơ **Rule-Based**: Áp dụng nhất quán ngưỡng cấu hình trong Settings, loại bỏ sự mơ hồ của LLM khi xử lý quyết định cấm thi.
   - Gửi thông báo JSON qua `ATTENDANCE_NOTIFICATION_ENDPOINT`; sử dụng danh sách khóa sự kiện `_sentEventsKey` lưu trong `SharedPreferences` để triệt tiêu việc gửi trùng lặp email cho cùng một sinh viên.

---

### 📱 SCR-09: Attendance Reports & Analytics
1. **Screen Name & Route:** `ReportsPage` (`/reports`), file: [reports_page.dart](lib/features/reports/reports_page.dart)
2. **Layout & Responsive Behavior:** Bộ lọc 3 tiêu chí (Semester, Subject, Class). Mobile hiển thị dạng thẻ sinh viên dọc; Desktop hiển thị dạng `DataTable` 6 cột.
3. **Design Tokens Applied:** `AppColors.primaryDark`, `AppColors.error` (BANNED), `AppColors.tertiary` (WARNING), `AppColors.green` (OK).
4. **Widgets & Components:** 3 Dropdown bộ lọc, danh sách dữ liệu sinh viên (số ca đã học, số ca vắng, % vắng, trạng thái), nút *Export CSV*.
5. **Interactive States:** Khi đổi giá trị dropdown, danh sách tự lọc lại tức thời theo bộ nhớ cache cục bộ.
6. **Edge Cases & Error Handling:** Bộ lọc không khớp sinh viên nào $\rightarrow$ Bảng rỗng; xuất file báo rõ đường dẫn lưu tệp.

---

### 📱 SCR-10: Supporting UX States & Shell
1. **Screen Name & Scope:** `AppShell` ([app_shell.dart](lib/core/widgets/app_shell.dart)), `AppHeader`, `NavBar`, `MobileNavBar`.
2. **Layout & Responsive Behavior:**
   - Điểm gãy giao diện: **`breakpoint = 700dp`**.
   - **Mobile (< 700dp):** `AppHeader` cao 56dp (logo + tiêu đề + nút Logout); thanh `NavigationBar` dưới đáy gồm 4 mục chính (**Home, Classes, Timetable, Attendance**) + nút **More** mở `showModalBottomSheet` chứa 4 mục phụ (*Export, AI Assistant, Reports, Settings*). Ẩn footer.
   - **Desktop ($\ge 700\text{dp}$):** `AppHeader` cao 60dp bổ sung tag học kỳ/campus và tên GV; thanh `NavBar` ngang cao 48dp hiển thị đủ 8 mục; hiện `AppFooter`.
3. **Interactive States:** Mục điều hướng tự động tô màu active tương ứng với route URL hiện tại (kể cả khi đang ở URL con `/attendance/:id`).
4. **Feedback States:** Đầy đủ các trạng thái `CircularProgressIndicator` khi tải, thông báo lỗi text rõ ràng khi Sheets API thất bại, SnackBar thông báo kết quả thao tác.

---

### 📱 SCR-11: Settings Screen
1. **Screen Name & Route:** `SettingsPage` (`/settings`), file: [settings_page.dart](lib/features/settings/settings_page.dart)
2. **Layout & Responsive Behavior:** Giới hạn `maxWidth: 900` căn giữa; thẻ nhóm cài đặt bo góc 6px.
3. **Design Tokens Applied:** `AppColors.surface`, `AppColors.primary`, `AppColors.outline`.
4. **Widgets & Components:** Ô nhập ngưỡng nhắc nhở (% Warning), ô nhập ngưỡng cấm thi (% Banned), nút *Save*, nút *Regenerate sample data* (kèm cảnh báo đỏ xóa dữ liệu), Card hiển thị trạng thái kết nối tài khoản Google.
5. **Interactive States:** Lưu ngưỡng ngay vào `SharedPreferences` thông qua `stats.setThresholds()`; báo kết quả qua SnackBar.
6. **Edge Cases & Error Handling:** Ràng buộc chặt chẽ $0 \le \text{Warn} < \text{Ban} \le 100$; hộp thoại xác nhận xóa dữ liệu khi regenerate sample data.

---

## 3. Bảng ánh xạ Design Tokens $\rightarrow$ Flutter Theme (`lib/core/theme/app_theme.dart`)

| Design Token | Mã màu Hex | Ánh xạ mã nguồn Flutter | Vai trò & Sử dụng thực tế |
| :--- | :---: | :--- | :--- |
| `primary` | `#0072BC` | `AppColors.primary` / `ColorScheme.primary` | Màu nhận diện chính, nút bấm chính, Present active |
| `primary-dark` | `#005994` | `AppColors.primaryDark` / `onPrimaryContainer` | Header bảng DataTable, mục NavBar active |
| `secondary` | `#35618D` | `AppColors.secondary` / `ColorScheme.secondary` | Nút Save Draft, màu phụ |
| `tertiary` | `#BA4C00` | `AppColors.tertiary` | Nút Submit, trạng thái ca học inProgress |
| `orange` / `green` | `#F36F21` / `#6CB33F` | `AppColors.orange` / `AppColors.green` | Dải nhận diện ba màu thương hiệu FPT, ca học taken |
| `surface` | `#F8F9FF` | `AppColors.surface` / `scaffoldBackgroundColor` | Nền tổng thể ứng dụng, nền ô nhập liệu |
| `surface-container` | `#E5EEFF` | `AppColors.surfaceContainer` | Nền khung toggle trạng thái điểm danh |
| `surface-high` | `#DCE9FF` | `AppColors.surfaceHigh` | Nền thanh tiêu đề Active Roster Verification |
| `on-surface` | `#0B1C30` | `AppColors.onSurface` | Màu chữ chính (Tương phản 16.3:1 trên surface) |
| `on-surface-variant` | `#404751` | `AppColors.onSurfaceVariant` | Màu chữ phụ, caption (Tương phản 8.9:1) |
| `outline` | `#717882` | `AppColors.outline` | **Viền ô nhập liệu TextField (Tương phản 4.2:1 đạt WCAG 1.4.11)** |
| `outline-variant` | `#C0C7D3` | `AppColors.outlineVariant` | Đường viền thẻ Card, đường kẻ phân cách |
| `error` | `#D93025` | `AppColors.error` | Trạng thái vắng mặt đã chọn, cảnh báo cấm thi |
| `error-container` | `#FCE8E6` | `AppColors.errorContainer` | Nền chip Absent / Banned |
| **`errorText`** | **`#B3261E`** | **`AppColors.errorText`** | **Chữ chip Absent/Banned (Tương phản 5.5:1 đạt chuẩn AA)** |
| **`warningText`** | **`#8A5300`** | **`AppColors.warningText`** | **Chữ chip Warning/Draft (Tương phản 5.7:1 đạt chuẩn AA)** |
| **`successText`** | **`#1B6E2E`** | **`AppColors.successText`** | **Chữ chip Present (Tương phản 5.3:1 đạt chuẩn AA)** |
| `headline-lg` | 20px / Line 1.4 / w600 | `TextTheme.headlineLarge` | Tiêu đề đầu các trang |
| `headline-md` | 16px / Line 1.5 / w600 | `TextTheme.headlineMedium` | Tiêu đề khối / Session card |
| `body-md` | 14px / Line 1.43 / w400 | `TextTheme.bodyMedium` | Chữ nội dung đọc chính |
| `borderRadius` | 6px | `BorderRadius.circular(6)` | Bo góc đồng bộ toàn bộ Card, Button, Input |

---

## 4. Bảng ánh xạ Master Components $\rightarrow$ Flutter Widgets

| Master Component (Design) | Biến thể (Variants) | Flutter Widget tương ứng | Tệp mã nguồn |
| :--- | :--- | :--- | :--- |
| **Status Chip** | `present`, `absent`, `warning`, `neutral` (có hỗ trợ icon) | `StatusChip` | [status_chip.dart](lib/core/widgets/status_chip.dart) |
| **Top Navigation Bar** | Desktop ngang (8 mục, 48px) | `NavBar` | [nav_bar.dart](lib/core/widgets/nav_bar.dart) |
| **Bottom Navigation Bar** | Mobile đáy (4 mục chính + More bottom sheet) | `MobileNavBar` | [nav_bar.dart](lib/core/widgets/nav_bar.dart) |
| **Top App Header** | Dải 3 màu nhận diện FPT, Campus tag, User Avatar, Logout | `AppHeader` | [app_header.dart](lib/core/widgets/app_header.dart) |
| **Breadcrumb Bar** | Thanh đường dẫn điều hướng ngữ cảnh | `BreadcrumbBar` | [breadcrumb_bar.dart](lib/core/widgets/breadcrumb_bar.dart) |
| **Responsive Shell** | Bọc layout tự động hoán chuyển tại 700dp | `AppShell` | [app_shell.dart](lib/core/widgets/app_shell.dart) |
| **Attendance Toggle Button** | Present / Absent; $\ge 48\times 48\text{ dp}$ có icon + semantics | `_statusButton` | [attendance_detail_page.dart](lib/features/attendance/attendance_detail_page.dart) |
| **Per-Student Card** | Thẻ dọc học viên trên màn hình mobile | `_studentCard` | [attendance_detail_page.dart](lib/features/attendance/attendance_detail_page.dart) |

---

## 5. Kết quả đạt được & Cam kết chất lượng (Technical Verification)

### ✅ Kết quả kỹ thuật đã hoàn thành 100%
1. **Google OAuth Native trên Android (v7):** Tích hợp `google_sign_in: ^7.2.0` mở Account Picker trực tiếp trên hệ điều hành Android, loại bỏ sự cố ngắt kết nối ngầm.
2. **Bố cục Responsive hai chiều:** Tối ưu hóa hoàn toàn cho thiết bị cầm tay màn hình nhỏ (360dp–412dp) với dạng thẻ Card cuộn dọc, đồng thời hiển thị ma trận bảng rộng hoàn chỉnh trên Desktop.
3. **Đạt chuẩn Trợ năng WCAG 2.1 AA:**
   - 100% các cặp màu chữ/nền đạt tỷ lệ tương phản $\ge 4.5:1$ (chữ chip đạt $5.3:1 \sim 5.7:1$, chữ chính đạt $16.3:1$).
   - Viền ô nhập liệu đạt $4.2:1$ (vượt chuẩn $3:1$ cho thành phần UI).
   - Nút chuyển trạng thái đạt kích thước tối thiểu $\ge 48\times 48\text{ dp}$, kèm biểu tượng hình học và nhãn chữ hoa, không phụ thuộc duy nhất vào màu sắc.
4. **Đồng bộ hóa quy tắc rủi ro toàn diện:** Cơ chế cấu hình ngưỡng điểm danh trong Settings được đồng bộ tự động xuyên suốt qua AI Assistant, Roster và Reports.
5. **Chất lượng mã nguồn sạch:** Đạt `flutter analyze: 0 issues` và `flutter test: All tests passed`.

---

## 6. Thông tin bàn giao dự án (Deliverables & Submission Links)
* **Kho lưu trữ GitHub:** [https://github.com/MinhCoffee/PRM5M.git](https://github.com/MinhCoffee/PRM5M.git)
* **Nhánh kiểm tra:** `main`
* **Thư mục ứng dụng di động:** `Lab2-AndroidApp/flutter_androidApp`
