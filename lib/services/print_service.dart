import 'print_service_stub.dart'
    if (dart.library.html) 'print_service_web.dart';

class PrintService {
  static void printStudentCard(String name, String grade, String barcode) {
    printStudentCardImpl(name, grade, barcode);
  }
}
