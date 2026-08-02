// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void printStudentCardImpl(String name, String grade, String barcode) {
  final htmlContent = '''
<!DOCTYPE html>
<html dir="rtl" lang="ar">
<head>
  <meta charset="UTF-8">
  <title>طباعة بطاقة طالب — $name</title>
  <style>
    @import url('https://fonts.googleapis.com/css2?family=Cairo:wght@400;600;700&display=swap');
    body {
      font-family: 'Cairo', sans-serif;
      background-color: #f8fafc;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      margin: 0;
      padding: 20px;
    }
    .card {
      background: #ffffff;
      width: 380px;
      padding: 32px;
      border-radius: 16px;
      border: 2px solid #e2e8f0;
      box-shadow: 0 10px 25px rgba(0,0,0,0.08);
      text-align: center;
    }
    .header {
      border-bottom: 2px dashed #cbd5e1;
      padding-bottom: 16px;
      margin-bottom: 20px;
    }
    .title {
      font-size: 24px;
      font-weight: 700;
      color: #1e293b;
      margin: 0;
    }
    .subtitle {
      font-size: 15px;
      color: #2563eb;
      margin-top: 4px;
      font-weight: 600;
    }
    .info {
      text-align: right;
      margin-bottom: 24px;
      font-size: 17px;
      color: #334155;
      line-height: 2;
    }
    .info strong {
      color: #0f172a;
    }
    .barcode-box {
      background: #ffffff;
      padding: 16px 12px;
      border-radius: 12px;
      border: 2px solid #000;
      display: inline-block;
      margin-bottom: 8px;
    }
    .footer {
      margin-top: 20px;
      font-size: 12px;
      color: #64748b;
    }
    @media print {
      body { background: #ffffff; min-height: auto; padding: 0; }
      .card { box-shadow: none; border: 2px solid #000; margin: 0 auto; width: 100%; max-width: 400px; }
    }
  </style>
  <script src="https://cdn.jsdelivr.net/npm/jsbarcode@3.11.5/dist/JsBarcode.all.min.js"></script>
</head>
<body>
  <div class="card">
    <div class="header">
      <h1 class="title">الشاعر في اللغة العربية</h1>
      <div class="subtitle">أ. محسن شاكر — بطاقة طالب للدخول والمتابعة</div>
    </div>
    <div class="info">
      <div><strong>اسم الطالب:</strong> $name</div>
      <div><strong>الصف الدراسي:</strong> $grade</div>
      <div><strong>رقم الباركود:</strong> $barcode</div>
    </div>
    <div class="barcode-box">
      <svg id="barcode"></svg>
    </div>
    <div class="footer">يرجى إبراز هذه البطاقة عند الدخول لتسجيل الحضور</div>
  </div>
  <script>
    function triggerPrint() {
      try {
        if (typeof JsBarcode !== 'undefined') {
          JsBarcode("#barcode", "$barcode", {
            format: "CODE128",
            width: 2.4,
            height: 75,
            displayValue: true,
            fontSize: 16,
            font: "Cairo",
            fontOptions: "bold",
            margin: 0
          });
          setTimeout(function() { window.print(); }, 500);
        } else {
          setTimeout(triggerPrint, 200);
        }
      } catch(e) {
        console.error(e);
        setTimeout(function() { window.print(); }, 500);
      }
    }
    window.addEventListener('DOMContentLoaded', triggerPrint);
    window.addEventListener('load', triggerPrint);
    setTimeout(triggerPrint, 800); // Fallback trigger
  </script>
</body>
</html>
''';

  final blob = html.Blob([htmlContent], 'text/html; charset=utf-8');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.window.open(url, '_blank');

  // Clean up object URL memory after window opens
  Future.delayed(const Duration(seconds: 30), () {
    html.Url.revokeObjectUrl(url);
  });
}
