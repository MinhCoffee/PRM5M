# AI UI Generation & Design Specification

**Dự án:** AttendEase (AttendPass) - FPT Academic Attendance & Sync Portal  
**Tên hiển thị trong app:** `Academic Portal - Attendance`  
**Nền tảng:** Flutter Mobile App (Android-first, Responsive Desktop/Windows)  
**Minh chứng phục vụ:** Slide 05 (AI UI Generation)  
**Figma Canvas URL:** [Figma PRM Design (Node 2:2)](https://www.figma.com/design/3L02La4yWxZ96fvHavz2ws/PRM?node-id=2-2&t=HFkQ5sszMdvBAJUP-1)  
**Cập nhật lần cuối:** 15/10/2026 — đồng bộ theo mã nguồn hiện tại trong `lib/`

---

## 1. Prompt nguyên văn dùng để sinh giao diện AI (Original Prompt)

Để tạo ra bộ thiết kế ban đầu (Initial Stitch / AI UI Generations) tại thư mục `design/` và khớp với wireframe Figma Frame `2:2`, câu lệnh prompt được xây dựng với đầy đủ các thành tố: **Persona, Nhiệm vụ (Task), Nền tảng (Platform), Ràng buộc (Constraints) và Phong cách thẩm mỹ (Visual Style)**:

```text
Act as a Senior UI/UX Designer and Mobile Design System Architect.

1. Target Persona:
University Lecturer (Mr. Minh, 38 years old, Software Engineering faculty at FPT University). He needs to take classroom attendance rapidly within 60 seconds at the start of a 90-minute lecture slot using a smartphone with one-handed operation.

2. Core Task & Screen Scope:
Design a production-grade, enterprise mobile screen for "AttendEase: FPT Academic Attendance & Sync Portal" for Android (viewport width 360dp - 412dp), specifically:
- Lecturer Dashboard with daily slot summary and student risk alerts.
- Quick Attendance Marking screen with responsive student roster card layout.
- Attendance Report & AI Risk Assistant with email notification integration.

3. Platform & Technical Constraints:
- Mobile-first Android design (target touch target minimum 48x48 dp for all primary interactive elements).
- Material Design 3 guidelines with Bottom Navigation and clear status badges.
- Avoid desktop data-grids on mobile: render student rosters as clean vertical cards with instant status toggles (Present / Absent) and note expansion.
- Must include clear feedback states: Default, Loading skeleton, Error/Offline banner, and Empty states.
- High accessibility (WCAG 2.1 AA): Contrast ratio >= 4.5:1, do not rely on color alone (pair colors with clear typography badges and icons for color-blind accessibility).

4. Visual Style & Brand Aesthetics:
- Professional Institutional EdTech aesthetic reflecting FPT University identity.
- Primary colors: Deep Academic Navy (#005994) and Portal Cyan (#0072BC).
- Accent/Brand colors: FPT Heritage Orange (#BA4C00 / #F36F21) and Green (#6CB33F).
- Background: Soft modern tinted surface (#F8F9FF) with crisp white card containers (#FFFFFF) and subtle 1px border (#C0C7D3).
- Clean Inter typography hierarchy with defined scale (headline-lg, headline-md, body-md, label-lg).
- Output: Clean Tailwind CSS markup with exact semantic design tokens and corresponding component structure.
```

---

## 2. Kết quả AI UI Generation → Hiện thực hoá trong Flutter

Bộ mockup AI trong `design/` (khớp Figma `node-id=2-2`) được chuyển thành các màn hình Flutter dưới đây. Cột **Trạng thái** phản ánh đúng code hiện tại.

| # | Màn hình (mockup) | Route | File Flutter | Trạng thái so với mockup |
| :-- | :-- | :-- | :-- | :-- |
| SCR-01 | Login (`attendease_login/`) | `/login` | `lib/features/auth/login_page.dart` | **Rút gọn** |
| SCR-02 | Lecturer Dashboard (`attendease_lecturer_dashboard/`) | `/home` | `lib/features/home/home_page.dart` | **Đã làm** |
| SCR-03 | Weekly Timetable (`attendease_weekly_timetable/`) | `/timetable` | `lib/features/timetable/timetable_page.dart` | **Đã làm** |
| SCR-04 | My Courses (`attendease_take_attendance_browse/`) | `/my-classes` | `lib/features/classes/my_classes_page.dart` | **Đã làm** |
| SCR-05 | Take Attendance Selector (`attendease_take_attendance_browse/`) | `/take-attendance` | `lib/features/attendance/attendance_browse_page.dart` | **Sửa đổi** |
| SCR-06 | Attendance Detail & Marking (`attendease_attendance_detail_marking/`) | `/attendance/:sessionId` | `lib/features/attendance/attendance_detail_page.dart` | **Đã làm** |
| SCR-07 | FAP Sync & Export (`attendease_fap_sync_center/`) | `/fap-sync` | `lib/features/export/export_page.dart` | **Sửa đổi** |
| SCR-08 | AI Risk Assistant (`attendease_ai_assistant/`) | `/ai-assistant` | `lib/features/ai_assistant/ai_assistant_page.dart` | **Sửa đổi** |
| SCR-09 | Reports & Analytics (`attendease_attendance_report/`) | `/reports` | `lib/features/reports/reports_page.dart` | **Rút gọn** |
| SCR-10 | Supporting UX States (`academic_utility_portal/`) | (tất cả) | Mỗi page tự xử lý | **Một phần** |
| SCR-11 | Settings (`attendease_settings/`) | `/settings` | `lib/features/settings/settings_page.dart` | **Sửa đổi** |

### Chi tiết từng màn hình

1. **SCR-01 Login** — Card căn giữa (max 420px): logo, tiêu đề `Academic Portal`, nút duy nhất **Sign in with Google**. Tự đăng nhập lại nếu còn credentials đã cache; `/login?logout=1` sẽ xoá token và hiện lại account picker.
   - *Khác mockup:* chưa có Campus selector, banner học kỳ và dải 3 màu trên trang Login (dải 3 màu chỉ nằm ở `AppHeader`).
2. **SCR-02 Home** — 4 thẻ chỉ số tính từ dữ liệu thật: *Classes today*, *Overall attendance*, *Banned students*, *Draft sessions*; danh sách *Today's sessions* (bấm để vào điểm danh) + nút Refresh; thẻ hướng dẫn và giải thích các trạng thái buổi học (Upcoming / Taking Attendance / Completed / Missing Attendance).
3. **SCR-03 Timetable** — Desktop: lưới **8 slot × 7 ngày** (rộng 1280px, cuộn ngang). Mobile (< 700dp): danh sách theo từng ngày. Có nút tuần trước / *Today* / tuần sau; mỗi ô có màu theo trạng thái buổi học.
4. **SCR-04 My Classes** — Desktop: `DataTable` (Class, Subject, Students, Progress, Warning, Banned). Mobile: mỗi lớp là một card có progress bar. Bấm vào lớp → danh sách buổi học của lớp đó → vào điểm danh.
5. **SCR-05 Take Attendance** — 2 hàng card cuộn ngang: *Today's sessions* (tối đa 8 slot/ngày) và *Upcoming classes* (tối đa 16). Card có thanh màu theo môn, mã môn, lớp, phòng, ngày, slot, `Session x/y`. Có nút *Seed sample data* và empty state *Create sample data*.
   - *Khác mockup:* bỏ bộ lọc Today / Tomorrow / Pick Date và chip trạng thái `NOT TAKEN / SUBMITTED` trên card.
6. **SCR-06 Attendance Detail** — Gồm 4 khối:
   - **Session card:** Subject, Cohort & Schedule, Room/Date, Session x/y (mobile: 2 cột).
   - **Control bar:** bộ đếm Enrolled / Present / Absent / Rate; nút *Mark All Present*, *Mark All Absent*, *Reset*, *Save Draft*, *Submit* (hoặc *Update & Submit*); ô tìm kiếm theo roll/tên; lọc All / Present / Absent.
   - **Roster:** Desktop là `DataTable` 8 cột (No., Photo, Roll No., Full Name + Major, Gender, Attendance Status, Cumulative Absence, Note). Mobile là **card dọc** cho mỗi sinh viên, có avatar, roll · major · gender, chip tỷ lệ vắng, nút Present/Absent và ô ghi chú.
   - **Status bar:** báo *đã submit* hoặc *chưa submit*.
   - Submit có hộp thoại xác nhận; kết quả báo bằng SnackBar.
7. **SCR-07 Export & FAP Sync** — Lọc theo lớp + khoảng ngày, xuất **CSV** chuẩn FAP (`FAP_Attendance_<class>_<timestamp>.csv`), **import danh sách sinh viên từ CSV/Excel** vào sheet `students` (bỏ qua dòng trùng). Bảng/card buổi học có badge *Submitted / Draft / Not Taken*.
   - *Khác mockup:* không có đồng bộ trực tiếp với cổng FAP (chỉ xuất file).
8. **SCR-08 AI Assistant** — Chạy theo luật (rule-based), không dùng LLM. Khi mở trang sẽ tự quét và báo các buổi thiếu điểm danh, số sinh viên warning/banned, đồng thời gửi email qua `ATTENDANCE_NOTIFICATION_ENDPOINT` (không gửi lại sự kiện đã gửi). Có 3 câu hỏi nhanh: *At-risk students*, *Highest absence subject*, *Student history*.
9. **SCR-09 Reports** — Lọc theo Semester (năm) / Subject / Class; bảng (desktop) hoặc card (mobile) gồm Student, Class, Sessions held, Absent, Absence %, Status (OK / WARNING / BANNED); có nút **Export CSV**.
   - *Khác mockup:* chưa có biểu đồ phân bố.
10. **SCR-10 UX States** — Đã có: Loading (`CircularProgressIndicator`), Error (text lỗi), Empty (*No sessions…*), hộp thoại xác nhận (Submit, Regenerate data), SnackBar phản hồi.
    - *Chưa có:* Skeleton loading, Offline banner kèm nút Retry, hộp thoại xác nhận khi Logout.
11. **SCR-11 Settings** — Chỉnh ngưỡng **Warning / Banned (%)** (lưu bằng `SharedPreferences`, dùng chung cho các trang), **Regenerate sample data** (có xác nhận) và xem trạng thái kết nối Google.
    - *Khác mockup:* chưa có tần suất đồng bộ tự động, campus mặc định và hồ sơ giảng viên.

---

## 3. Kiến trúc điều hướng (App Shell)

`AppShell` ([app_shell.dart](lib/core/widgets/app_shell.dart)) bọc mọi route sau đăng nhập, breakpoint **700dp**:

| Thành phần | Mobile (< 700dp) | Desktop (≥ 700dp) |
| :-- | :-- | :-- |
| `AppHeader` | Cao 56; logo + tiêu đề + icon Logout | Cao 60; thêm tag `Semester: Fall 2026`, `FU - HCM`, tên GV, nút Logout |
| Dải nhận diện | 4px: Cam `#F36F21` · Xanh `#0072BC` · Lá `#6CB33F` | Giống mobile |
| Điều hướng | `NavigationBar` dưới đáy: **Home, My Classes, Timetable, Attendance, More** | `NavBar` ngang (48px, nền `#0072BC`) với đủ 8 mục |
| More (bottom sheet) | Export, AI Assistant, Reports, Settings | — |
| `BreadcrumbBar` | Có | Có |
| `AppFooter` | Ẩn | Hiện |

Thứ tự 8 mục: Home · My Classes · Timetable · Export · AI Assistant · Take Attendance · Reports · Settings. Khi đang ở `/attendance/:id`, mục *Take Attendance* vẫn được đánh dấu active.

---

## 4. Design Tokens (theo `lib/core/theme/app_theme.dart`)

### 4.1. Màu sắc (`AppColors`)

| Token | Hex | Dùng cho |
| :-- | :-- | :-- |
| `surface` | `#F8F9FF` | Nền scaffold, nền input |
| `surfaceLow` / `surfaceContainer` / `surfaceHigh` | `#EFF4FF` / `#E5EEFF` / `#DCE9FF` | Nền toggle, header roster |
| `onSurface` | `#0B1C30` | Chữ chính |
| `onSurfaceVariant` | `#404751` | Chữ phụ |
| `outline` / `outlineVariant` | `#717882` / `#C0C7D3` | Viền |
| `primary` | `#0072BC` | Nút chính, NavBar, Present đã chọn |
| `primaryDark` | `#005994` | Header bảng, mục nav đang chọn |
| `secondary` | `#35618D` | Nút *Save Draft* |
| `tertiary` | `#BA4C00` | Nút *Submit*, trạng thái warning/in-progress |
| `orange` / `green` | `#F36F21` / `#6CB33F` | Dải nhận diện, trạng thái *taken* |
| `error` / `errorContainer` | `#D93025` / `#FCE8E6` | Absent, banned, lỗi |
| `errorText` | `#B3261E` | Chữ chip Absent / Banned (tương phản 5.5:1 đạt chuẩn AA) |
| `warningText` | `#8A5300` | Chữ chip Warning / Draft (tương phản 5.7:1 đạt chuẩn AA) |
| `successText` | `#1B6E2E` | Chữ chip Present (tương phản 5.3:1 đạt chuẩn AA) |

### 4.2. Typography (`fontFamily: 'Inter'`)

| Style | Size / Line-height / Weight |
| :-- | :-- |
| `headlineLarge` | 20 / 1.4 / w600 |
| `headlineMedium` | 16 / 1.5 / w600 |
| `headlineSmall` | 14 / 1.43 / w600 |
| `bodyLarge` / `bodyMedium` / `bodySmall` | 15 / 14 / 13 |
| `labelLarge` / `labelMedium` / `labelSmall` | 13 w600 / 12 w500 / 11 w600 |

### 4.3. Shape & Component

- **Card:** nền trắng, `elevation: 0`, bo góc 6, viền 1px `#D1D5DB`.
- **Input:** dạng dense, filled `#F8F9FF`, bo góc 6, viền `outline` (`#717882`, tương phản 4.2:1 đạt chuẩn WCAG 1.4.11); khi focus viền `primary` dày 2px.
- **StatusChip** ([status_chip.dart](lib/core/widgets/status_chip.dart)): 4 loại `present` (xanh lá), `absent` (đỏ), `warning` (hổ phách), `neutral` (xám), dùng bộ token chữ tương phản cao (`successText`, `errorText`, `warningText`), có hỗ trợ icon cảnh báo.
- **Nút chuyển đổi trạng thái (Present / Absent Toggle):** Đạt chuẩn kích thước chạm ngón tay cái $\ge 48\times 48\text{ dp}$ (`minHeight: 48, minWidth: 72`), tích hợp icon trạng thái (`check` / `close`) và hỗ trợ `Semantics` cho trợ năng.
- **Mã màu trạng thái buổi học:** `taken` → green, `inProgress` → tertiary, `overdueNotTaken` → error, `notTaken` → primary.

---

## 5. Nguyên tắc thiết kế cốt lõi (Design Principles)

1. **Mobile-First & Thumb-Friendly:** Thanh `NavigationBar` nằm ở đáy màn hình, các bảng nhiều cột được thay bằng card khi màn hình < 700dp. Các nút hành động hàng loạt (Mark All, Save Draft, Submit) và nút toggle Có mặt/Vắng mặt đạt chuẩn $\ge 48\times 48\text{ dp}$ thuận tiện thao tác 1 tay trên bục giảng.
2. **Instant Status Feedback:** Đổi Present/Absent chỉ cập nhật state cục bộ (`setState`), không chờ mạng; bộ đếm và tỷ lệ cập nhật ngay. Dữ liệu chỉ được ghi lên Google Sheets khi bấm *Save Draft* / *Submit*.
3. **No Dead Ends:** Breadcrumb, nút Back trong *My Classes*, nút Cancel trong mọi dialog, nút *Create sample data* khi chưa có dữ liệu, và luôn hiện thông báo lỗi rõ ràng khi tải thất bại.
4. **WCAG 2.1 AA Accessibility:** 100% các thành phần chữ và điều khiển đạt chuẩn tương phản ($\ge 4.5:1$ cho chữ, $\ge 3:1$ cho viền input), không biểu thị thông tin độc nhất bằng màu sắc (kết hợp nhãn chữ hoa, biểu tượng hình học và icon check/close).
