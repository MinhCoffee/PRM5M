# AI UI Generation & Design Specification

**Dự án:** AttendEase - FPT Academic Attendance & Sync Portal  
**Nền tảng:** Flutter Mobile App (Android-first, Responsive Desktop)  
**Minh chứng phục vụ:** Slide 05 (AI UI Generation)

---

## 1. Prompt nguyên văn dùng để sinh giao diện AI (Original Prompt)

Để tạo ra bộ thiết kế ban đầu (Initial Stitch / AI UI Generations) tại thư mục `design/`, câu lệnh prompt được xây dựng với đầy đủ các thành tố: **Persona, Nhiệm vụ (Task), Nền tảng (Platform), Ràng buộc (Constraints) và Phong cách thẩm mỹ (Visual Style)**:

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

## 2. Kết quả AI UI Generation ban đầu (Initial Stitch UI Output)

Dựa trên prompt trên, công cụ AI đã sinh ra 11 bộ màn hình chuẩn tại thư mục `design/`:

1. `design/attendease_login/` (`code.html` + `screen.png`):
   - Màn hình đăng nhập tối ưu cho mobile, gồm dải màu nhận diện ba màu (Cam - Xanh dương - Xanh lá), thông báo học kỳ Fall 2026 đang hoạt động, form xác thực tài khoản Google với nút Single Sign-On (SSO).
2. `design/attendease_lecturer_dashboard/` (`code.html` + `screen.png`):
   - Bảng điều khiển gồm thanh chào giảng viên, chỉ số nhanh (Slots hoàn thành, tỷ lệ có mặt trung bình 92.4%, 3 sinh viên nguy cơ cấm thi), và danh sách ca học hôm nay.
3. `design/attendease_take_attendance_browse/` (`code.html` + `screen.png`):
   - Bộ lọc ca học theo ngày (Today, Tomorrow, Pick Date), trạng thái ca học (Chưa điểm danh, Đã nộp, Đang diễn ra).
4. `design/attendease_attendance_detail_marking/` (`code.html` + `screen.png`):
   - Danh sách sinh viên theo dạng thẻ hàng dọc (List Cards), mỗi thẻ gồm ảnh đại diện, họ tên, mã số sinh viên (Roll number), nút chuyển nhanh Có mặt/Vắng mặt to bản dễ bấm ngón tay cái, và ô ghi chú thu gọn.
5. `design/attendease_weekly_timetable/` (`code.html` + `screen.png`):
   - Lịch tuần trực quan theo các Slot học từ Slot 1 đến Slot 6.
6. `design/attendease_attendance_report/` (`code.html` + `screen.png`):
   - Biểu đồ phân bố chuyên cần và danh sách sinh viên vượt ngưỡng cảnh báo 15% và 20%.
7. `design/attendease_fap_sync_center/` (`code.html` + `screen.png`):
   - Trạng thái đồng bộ với cổng FAP, nút xuất báo cáo và đối soát dữ liệu.
8. `design/attendease_ai_assistant/` (`code.html` + `screen.png`):
   - Giao diện trợ lý soạn thảo thư cảnh báo sinh viên tự động dựa trên phân tích số buổi vắng.

---

## 3. Nguyên tắc thiết kế cốt lõi (Design Principles)

1. **Mobile-First & Thumb-Friendly:** Các nút bấm thao tác nhiều nhất (Present, Absent, Submit) đặt ở nửa dưới màn hình để giảng viên dễ thao tác bằng 1 tay khi đang cầm điện thoại đứng trên bục giảng.
2. **Instant Status Feedback:** Đổi trạng thái tức thì không cần chờ mạng; sử dụng hiệu ứng viền và màu nền nhẹ nhàng, không gây chói mắt.
3. **No Dead Ends (Không ngõ cụt):** Luôn có nút quay lại (Back navigation), nút thoát khỏi modal và tùy chọn thử lại (Retry) khi phát sinh lỗi.
