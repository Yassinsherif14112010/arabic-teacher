// ignore: avoid_web_libraries_in_flutter
import 'dart:js_interop';
import 'package:web/web.dart' as html;
import 'dart:convert';
import '../models/student.dart';
import '../models/attendance.dart';
import '../models/study_group.dart';

void openMonthlyAttendanceReportImpl(
  String monthStr,
  List<Student> students,
  List<Attendance> allRecords,
  List<StudyGroup> groups,
) {
  // Filter attendance records for this specific month prefix (e.g. '2026-08')
  final monthRecords = allRecords.where((a) => a.attendanceDate.startsWith(monthStr)).toList();

  // Collect all unique session dates in this month
  final sessionDates = monthRecords.map((r) => r.attendanceDate).toSet().toList();
  sessionDates.sort();

  final buffer = StringBuffer();
  buffer.writeln('''
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8">
  <title>تقرير الحضور الشهري ($monthStr) - منصة الشاعر</title>
  <link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700;800&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg: #0f172a;
      --card-bg: #1e293b;
      --border: #334155;
      --text: #f8fafc;
      --primary: #3b82f6;
      --emerald: #10b981;
      --red: #ef4444;
      --yellow: #f59e0b;
    }
    * { box-sizing: border-box; font-family: 'Cairo', sans-serif; }
    body {
      background-color: #f1f5f9;
      color: #1e293b;
      margin: 0;
      padding: 30px;
    }
    .report-container {
      max-width: 1100px;
      margin: 0 auto;
      background: #ffffff;
      padding: 40px;
      border-radius: 16px;
      box-shadow: 0 10px 30px rgba(0,0,0,0.08);
      border: 1px solid #e2e8f0;
    }
    .header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      border-bottom: 3px solid #3b82f6;
      padding-bottom: 20px;
      margin-bottom: 30px;
    }
    .title h1 { margin: 0; font-size: 28px; color: #0f172a; }
    .title p { margin: 6px 0 0; font-size: 15px; color: #64748b; font-weight: 600; }
    .buttons { display: flex; gap: 12px; }
    .btn {
      padding: 10px 22px;
      border: none;
      border-radius: 8px;
      font-size: 14px;
      font-weight: 700;
      cursor: pointer;
      display: flex;
      align-items: center;
      gap: 8px;
      transition: all 0.2s;
    }
    .btn-print { background: #3b82f6; color: #fff; }
    .btn-print:hover { background: #2563eb; }
    .btn-csv { background: #10b981; color: #fff; }
    .btn-csv:hover { background: #059669; }
    .stats-row {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 16px;
      margin-bottom: 30px;
    }
    .stat-card {
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      padding: 16px;
      border-radius: 12px;
      text-align: center;
    }
    .stat-card h3 { margin: 0; font-size: 26px; color: #3b82f6; }
    .stat-card p { margin: 4px 0 0; font-size: 13px; color: #64748b; font-weight: 600; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 20px;
    }
    th, td {
      padding: 12px 14px;
      border: 1px solid #e2e8f0;
      text-align: center;
      font-size: 14px;
    }
    th {
      background: #f8fafc;
      color: #334155;
      font-weight: 700;
    }
    tr:nth-child(even) { background: #f8fafc; }
    .status-badge {
      display: inline-block;
      padding: 3px 10px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: 700;
    }
    .badge-present { background: rgba(16, 185, 129, 0.15); color: #10b981; }
    .badge-late { background: rgba(245, 158, 11, 0.15); color: #f59e0b; }
    .badge-absent { background: rgba(239, 68, 68, 0.15); color: #ef4444; }
    .footer {
      margin-top: 40px;
      padding-top: 20px;
      border-top: 1px solid #e2e8f0;
      display: flex;
      justify-content: space-between;
      color: #64748b;
      font-size: 13px;
    }
    @media print {
      body { background: #ffffff; padding: 0; }
      .report-container { box-shadow: none; border: none; max-width: 100%; padding: 0; }
      .buttons { display: none; }
      table { font-size: 12px; }
      th, td { padding: 8px 6px; }
    }
  </style>
</head>
<body>
  <div class="report-container">
    <div class="header">
      <div class="title">
        <h1>تقرير الحضور والغياب الشهري</h1>
        <p>المنصة الرسمية للأستاذ محسن شاكر - شهر ($monthStr)</p>
      </div>
      <div class="buttons">
        <button class="btn btn-print" onclick="window.print()">🖨️ طباعة / حفظ PDF</button>
        <button class="btn btn-csv" onclick="downloadCSV()">📥 تنزيل إكسيل (CSV)</button>
      </div>
    </div>

    <div class="stats-row">
      <div class="stat-card">
        <h3>${students.length}</h3>
        <p>إجمالي الطلاب</p>
      </div>
      <div class="stat-card">
        <h3>${sessionDates.length}</h3>
        <p>عدد الحصص بالشهر</p>
      </div>
      <div class="stat-card" style="border-color: #10b981;">
        <h3 style="color: #10b981;">${_calculateOverallRate(students, monthRecords, sessionDates.length)}%</h3>
        <p>متوسّط الالتزام الشهري</p>
      </div>
      <div class="stat-card" style="border-color: #ef4444;">
        <h3 style="color: #ef4444;">${_countTotalAbsences(students, monthRecords, sessionDates)}</h3>
        <p>إجمالي حالات الغياب</p>
      </div>
    </div>

    <table>
      <thead>
        <tr>
          <th>م</th>
          <th>اسم الطالب</th>
          <th>الصف الدراسي</th>
          <th>المجموعة</th>
          <th>حاضر</th>
          <th>متأخر</th>
          <th>غائب</th>
          <th>نسبة التواجد</th>
        </tr>
      </thead>
      <tbody>
''');

  int index = 1;
  final csvRows = <List<String>>[
    ['م', 'اسم الطالب', 'الصف الدراسي', 'المجموعة', 'حاضر', 'متأخر', 'غائب', 'نسبة التواجد']
  ];

  for (final student in students) {
    int presentCount = 0;
    int lateCount = 0;
    int absentCount = 0;

    for (final date in sessionDates) {
      final rec = monthRecords.cast<Attendance?>().firstWhere(
            (r) => r?.studentId == student.id && r?.attendanceDate == date,
            orElse: () => null,
          );
      if (rec != null && rec.status == AttendanceStatus.present) {
        presentCount++;
      } else if (rec != null && rec.status == AttendanceStatus.late) {
        lateCount++;
      } else {
        absentCount++;
      }
    }

    // If there are no sessions recorded yet in the month, rate is 100% or N/A
    final int totalSessions = sessionDates.isEmpty ? 1 : sessionDates.length;
    final int rate = ((presentCount + (lateCount * 0.5)) / totalSessions * 100).round().clamp(0, 100);

    final groupName = groups
        .cast<StudyGroup?>()
        .firstWhere((g) => g?.id == student.groupId, orElse: () => null)
        ?.name ?? 'بدون مجموعة';

    buffer.writeln('''
        <tr>
          <td>$index</td>
          <td style="font-weight: bold;">${student.name}</td>
          <td>${student.grade ?? '-'}</td>
          <td>$groupName</td>
          <td><span class="status-badge badge-present">$presentCount</span></td>
          <td><span class="status-badge badge-late">$lateCount</span></td>
          <td><span class="status-badge badge-absent">$absentCount</span></td>
          <td style="font-weight: bold; color: ${rate >= 75 ? '#10b981' : (rate >= 50 ? '#f59e0b' : '#ef4444')};">$rate%</td>
        </tr>
''');

    csvRows.add([
      index.toString(),
      student.name,
      student.grade ?? '-',
      groupName,
      presentCount.toString(),
      lateCount.toString(),
      absentCount.toString(),
      '$rate%'
    ]);

    index++;
  }

  // Convert CSV rows to JSON string for javascript implementation
  final jsonCsv = jsonEncode(csvRows);

  buffer.writeln('''
      </tbody>
    </table>

    <div class="footer">
      <div>تم التصدير من منصة الشاعر في اللغة العربية © ${DateTime.now().year}</div>
      <div>تاريخ التقرير: ${DateTime.now().toString().split('.').first}</div>
    </div>
  </div>

  <script>
    const csvData = $jsonCsv;
    function downloadCSV() {
      let csvContent = "\\uFEFF"; // BOM for UTF-8 Arabic support in Excel
      csvData.forEach(function(rowArray) {
        let row = rowArray.map(item => `"\${item}"`).join(",");
        csvContent += row + "\\r\\n";
      });
      let blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
      let link = document.createElement("a");
      let url = URL.createObjectURL(blob);
      link.setAttribute("href", url);
      link.setAttribute("download", `تقرير_الحضور_الشهري_$monthStr.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    }
  </script>
</body>
</html>
''');

  final blob = html.Blob([buffer.toString().toJS].toJS, html.BlobPropertyBag(type: 'text/html; charset=utf-8'));
  final url = html.URL.createObjectURL(blob);
  html.window.open(url, '_blank');
}

int _calculateOverallRate(List<Student> students, List<Attendance> records, int numSessions) {
  if (students.isEmpty || numSessions == 0) return 100;
  int present = 0;
  int late = 0;
  for (final r in records) {
    if (r.status == AttendanceStatus.present) present++;
    if (r.status == AttendanceStatus.late) late++;
  }
  return ((present + (late * 0.5)) / (students.length * numSessions) * 100).round().clamp(0, 100);
}

int _countTotalAbsences(List<Student> students, List<Attendance> records, List<String> dates) {
  if (students.isEmpty || dates.isEmpty) return 0;
  final totalExpected = students.length * dates.length;
  int recordedPresentOrLate = records.length;
  return (totalExpected - recordedPresentOrLate).clamp(0, 999999);
}
