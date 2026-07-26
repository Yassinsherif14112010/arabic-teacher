import 'package:flutter_test/flutter_test.dart';
import 'package:arabic_teacher_flutter/models/student.dart';
import 'package:arabic_teacher_flutter/models/study_group.dart';
import 'package:arabic_teacher_flutter/models/attendance.dart';
import 'package:arabic_teacher_flutter/models/payment.dart';
import 'package:arabic_teacher_flutter/models/grade.dart';
import 'package:arabic_teacher_flutter/models/fee_setting.dart';

void main() {
  // ─── Student ──────────────────────────────────────────────────────────────
  group('Student model', () {
    test('fromMap / toMap round-trip', () {
      final map = {
        'id': 1,
        'name': 'أحمد محمد',
        'phone': '01012345678',
        'parentPhone': '01098765432',
        'barcodeNumber': '123456',
        'grade': 'الصف الأول الثانوي',
        'groupId': 2,
        'feePaid': 1,
        'status': 'active',
      };
      final student = Student.fromMap(map);
      expect(student.id, 1);
      expect(student.name, 'أحمد محمد');
      expect(student.feePaid, isTrue);
      expect(student.status, 'active');

      final roundTrip = Student.fromMap(student.toMap());
      expect(roundTrip.name, student.name);
      expect(roundTrip.feePaid, student.feePaid);
    });

    test('copyWith preserves unchanged fields', () {
      const original = Student(
        id: 5,
        name: 'فاطمة علي',
        barcodeNumber: '654321',
        feePaid: false,
      );
      final updated = original.copyWith(feePaid: true);
      expect(updated.id, 5);
      expect(updated.name, 'فاطمة علي');
      expect(updated.feePaid, isTrue);
    });

    test('feePaid defaults to false', () {
      const s = Student(name: 'طالب', barcodeNumber: '000001');
      expect(s.feePaid, isFalse);
    });

    test('equality by id', () {
      const a = Student(id: 10, name: 'A', barcodeNumber: '1');
      const b = Student(id: 10, name: 'B', barcodeNumber: '2');
      expect(a, equals(b));
    });
  });

  // ─── StudyGroup ───────────────────────────────────────────────────────────
  group('StudyGroup model', () {
    test('fromMap / toMap round-trip', () {
      final map = {
        'id': 3,
        'name': 'سبت وإثنين 4 عصراً',
        'grade': 'الصف الثالث الثانوي',
        'schedule': 'السبت والإثنين 4 م',
        'description': null,
      };
      final group = StudyGroup.fromMap(map);
      expect(group.name, 'سبت وإثنين 4 عصراً');
      expect(group.grade, 'الصف الثالث الثانوي');
      expect(group.schedule, 'السبت والإثنين 4 م');

      final rt = StudyGroup.fromMap(group.toMap());
      expect(rt.name, group.name);
    });
  });

  // ─── Attendance ───────────────────────────────────────────────────────────
  group('Attendance model', () {
    test('fromMap with present status', () {
      final map = {
        'id': 1,
        'studentId': 7,
        'attendanceDate': '2025-01-15',
        'status': 'present',
        'notes': null,
      };
      final a = Attendance.fromMap(map);
      expect(a.status, AttendanceStatus.present);
      expect(a.attendanceDate, '2025-01-15');
    });

    test('AttendanceStatus labels', () {
      expect(AttendanceStatus.present.label, 'حاضر');
      expect(AttendanceStatus.absent.label, 'غائب');
      expect(AttendanceStatus.late.label, 'متأخر');
    });

    test('AttendanceStatusExt.fromString handles unknown', () {
      expect(AttendanceStatusExt.fromString('unknown'), AttendanceStatus.absent);
    });

    test('toMap / fromMap round-trip', () {
      const record = Attendance(
        studentId: 3,
        attendanceDate: '2025-06-01',
        status: AttendanceStatus.late,
      );
      final rt = Attendance.fromMap(record.toMap());
      expect(rt.status, AttendanceStatus.late);
      expect(rt.attendanceDate, '2025-06-01');
    });
  });

  // ─── Payment ──────────────────────────────────────────────────────────────
  group('Payment model', () {
    test('fromMap parses amount as double', () {
      final map = {
        'id': 1,
        'studentId': 2,
        'amount': '500.50',
        'paymentDate': '2025-03-01',
        'paymentMethod': 'cash',
        'month': '2025-03',
        'notes': null,
      };
      final p = Payment.fromMap(map);
      expect(p.amount, closeTo(500.50, 0.001));
      expect(p.paymentMethod, PaymentMethod.cash);
    });

    test('PaymentMethod labels', () {
      expect(PaymentMethod.cash.label, 'نقداً');
      expect(PaymentMethod.transfer.label, 'تحويل بنكي');
      expect(PaymentMethod.check.label, 'شيك');
    });

    test('toMap / fromMap round-trip', () {
      const p = Payment(
        studentId: 5,
        amount: 750.0,
        paymentDate: '2025-04-10',
        paymentMethod: PaymentMethod.transfer,
        month: '2025-04',
      );
      final rt = Payment.fromMap(p.toMap());
      expect(rt.amount, closeTo(750.0, 0.001));
      expect(rt.paymentMethod, PaymentMethod.transfer);
    });
  });

  // ─── Grade ────────────────────────────────────────────────────────────────
  group('Grade model', () {
    test('percentage calculation', () {
      const g = Grade(
        studentId: 1,
        examType: ExamType.daily,
        score: 75,
        maxScore: 100,
        examDate: '2025-05-01',
      );
      expect(g.percentage, closeTo(75.0, 0.001));
      expect(g.isPassing, isTrue);
    });

    test('failing grade', () {
      const g = Grade(
        studentId: 1,
        examType: ExamType.final_,
        score: 40,
        maxScore: 100,
        examDate: '2025-05-01',
      );
      expect(g.isPassing, isFalse);
    });

    test('ExamType labels', () {
      expect(ExamType.daily.label, 'يومي');
      expect(ExamType.monthly.label, 'شهري');
      expect(ExamType.final_.label, 'نهائي');
    });

    test('toMap / fromMap round-trip', () {
      const g = Grade(
        studentId: 2,
        examType: ExamType.monthly,
        score: 88.5,
        maxScore: 100,
        examDate: '2025-06-15',
        subject: 'النحو',
      );
      final rt = Grade.fromMap(g.toMap());
      expect(rt.score, closeTo(88.5, 0.001));
      expect(rt.examType, ExamType.monthly);
      expect(rt.subject, 'النحو');
    });
  });

  // ─── FeeSetting ───────────────────────────────────────────────────────────
  group('FeeSetting model', () {
    test('fromMap / toMap round-trip', () {
      final map = {
        'id': 1,
        'academicYear': '2024-2025',
        'grade': 'الصف الثالث الثانوي',
        'feeAmount': '1500.0',
      };
      final fs = FeeSetting.fromMap(map);
      expect(fs.feeAmount, closeTo(1500.0, 0.001));
      expect(fs.academicYear, '2024-2025');

      final rt = FeeSetting.fromMap(fs.toMap());
      expect(rt.feeAmount, closeTo(1500.0, 0.001));
    });
  });
}
