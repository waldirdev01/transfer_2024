import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transfer_2024/app/models/for_payment.dart';
import '../models/extracurricular_activity.dart';
import '../models/itinerary.dart';
import '../models/school.dart';
import '../models/student.dart';

class ForPaymentProvider extends ChangeNotifier {
  final FirebaseFirestore _firebaseFirestore;

  ForPaymentProvider({required FirebaseFirestore firebaseFirestore})
      : _firebaseFirestore = firebaseFirestore;
  ForPayment? _forPayment;

  ForPayment? get forPayment => _forPayment;
  set forPayment(ForPayment? value) {
    _forPayment = value;
    notifyListeners();
  }

  List<ForPayment> _forPayments = [];
  List<ForPayment> get forPayments => _forPayments;
  set forPayments(List<ForPayment> value) {
    _forPayments = value;
    notifyListeners();
  }

  final List<String> _schoolIds = [];
  List<Student> _students = [];
  Future<void> generateForPaymentMonth(
      {required DateTime monthYear,
      required String contract,
      required double valor}) async {
    try {
      _students = await _firebaseFirestore.collection('students').get().then(
          (snapshot) => snapshot.docs
              .map((doc) => Student.fromJson(doc.data()))
              .toList());
      final payments = await _firebaseFirestore
          .collection('forPayment')
          .where('contract', isEqualTo: contract)
          .get();
      final List<ForPayment> forPayments =
          payments.docs.map((e) => ForPayment.fromJson(e.data())).toList();
      final List<String?> paymentIds = forPayments.map((e) => e.id).toList();
      final itinerariesSnapshot = await _firebaseFirestore
          .collection('itineraries')
          .where('contract', isEqualTo: contract)
          .get();

      final ecActivitiesSnapshot = await _firebaseFirestore
          .collection('ecActivities')
          .where('contract', isEqualTo: contract)
          .get();

      List<Itinerary> itineraries = itinerariesSnapshot.docs
          .map((doc) => Itinerary.fromJson(doc.data()))
          .toList();

      List<ExtracurricularActivity> extracurricularActivities =
          ecActivitiesSnapshot.docs
              .map((doc) => ExtracurricularActivity.fromJson(doc.data()))
              .toList();
      for (var itinerary in itineraries) {
        if (paymentIds.contains(itinerary.id)) {
          continue;
        }
        List<String> schoolsName = [];
        Map<String, int> levels = {};
        Set<DateTime> callDays = {};
        Set<DateTime> callDaysReposition = {};
        Map<String, int> residenceTypeCount = {};
        int totalStudentsRural = 0;
        int totalStudentsUrban = 0;

        int schoolTypeRural = 0;
        int schoolTypeUrban = 0;

        for (var studentId in itinerary.studentsId ?? []) {
          final student =
              _students.firstWhere((element) => element.id == studentId);
          if (student.residenceType == 'RURAL') {
            residenceTypeCount['RURAL'] =
                (residenceTypeCount['RURAL'] ?? 0) + 1;
          } else {
            residenceTypeCount['URBANA'] =
                (residenceTypeCount['URBANA'] ?? 0) + 1;
          }

          for (var stt in student.attendance) {
            if (stt.dateTime.year == monthYear.year &&
                stt.dateTime.month == monthYear.month) {
              if (stt.makeUpDay) {
                callDaysReposition.add(DateTime(
                    stt.dateTime.year, stt.dateTime.month, stt.dateTime.day));
              } else {
                callDays.add(DateTime(
                    stt.dateTime.year, stt.dateTime.month, stt.dateTime.day));
              }
            }
          }

          levels[student.level] = (levels[student.level] ?? 0) + 1;
        }

        totalStudentsRural = residenceTypeCount['RURAL'] ?? 0;
        totalStudentsUrban = residenceTypeCount['URBANA'] ?? 0;

        for (var schoolId in itinerary.schoolIds ?? []) {
          final schoolDoc = await _firebaseFirestore
              .collection('schools')
              .doc(schoolId)
              .get();

          if (schoolDoc.exists) {
            School school =
                School.fromJson(schoolDoc.data()!); // Decode JSON data once
            schoolsName.add(school.name); // Use the 'school' object
            if (_schoolIds.contains(schoolId)) {
              continue;
            }
            if (school.type == 'RURAL') {
              schoolTypeRural++;
            } else {
              schoolTypeUrban++;
            }
          } else {
            // Handling cases where no data is found
          }
          _schoolIds.add(schoolId);
        }

        List<String> monitoras = [];
        if (itinerary.appUserId.isEmpty) {
          monitoras.add('Sem monitor');
        } else {
          final monitorDoc = await _firebaseFirestore
              .collection('users')
              .doc(itinerary.appUserId)
              .get();
          monitoras.add(monitorDoc.data()!['name']);
        }

        final forPayment = ForPayment(
          id: itinerary.id,
          itinerarieCode: itinerary.code,
          itinerariesShift: itinerary.shift,
          schoolsName: schoolsName,
          schoolsTypeRuralCount: schoolTypeRural,
          schoolsTypeUrbanCount: schoolTypeUrban,
          trajectory: itinerary.trajectory,
          levels: levels,
          vehiclePlate: itinerary.vehiclePlate,
          kilometer: itinerary.kilometer,
          driverName: itinerary.driverName,
          monitorsId: [itinerary.appUserId],
          contract: contract,
          callDaysCount: callDays.length,
          callDaysRepositionCount: callDaysReposition.length,
          studentsUrban: totalStudentsUrban,
          studentsRural: totalStudentsRural,
          quantityOfBus: 1,
          dateOfEvent: monthYear,
          valor: valor,
          monitorsName: monitoras,
        );

        await createForPayment(forPayment: forPayment);
      }

      if (extracurricularActivities.isEmpty) {
        return;
      }
      for (var ecActivity in extracurricularActivities) {
        if (paymentIds.contains(ecActivity.id)) {
          continue;
        }
        if (ecActivity.dateOfEvent.year == monthYear.year &&
            ecActivity.dateOfEvent.month == monthYear.month) {
          final schoolDoc = await _firebaseFirestore
              .collection('schools')
              .doc(ecActivity.schoolId)
              .get();
          String schoolName = School.fromJson(schoolDoc.data()!).name;
          Map<String, int> levels = {};
          String itinerariesShift = '';
          Map<String, int> residenceTypeCount = {};
          int totalStudentsRural = 0;
          int totalStudentsUrban = 0;
          int schoolTypeRural = 0;
          int schoolTypeUrban = 0;

          if (_schoolIds.contains(ecActivity.schoolId)) {
          } else {
            if (School.fromJson(schoolDoc.data()!).type == 'RURAL') {
              schoolTypeRural++;
            } else {
              schoolTypeUrban++;
            }
            _schoolIds.add(ecActivity.schoolId);
          }

          if (ecActivity.leaveMorning.isNotEmpty) {
            itinerariesShift = 'MATUTINO';
          } else if (ecActivity.leaveAfternoon.isNotEmpty &&
              ecActivity.leaveMorning.isEmpty) {
            itinerariesShift = 'VESPERTINO';
          } else if (ecActivity.leaveNight.isNotEmpty &&
              ecActivity.leaveAfternoon.isEmpty) {
            itinerariesShift = 'NOTURNO';
          }

          for (var student in ecActivity.students) {
            levels[student.level] = (levels[student.level] ?? 0) + 1;
            if (student.typeResidence == 'RURAL') {
              residenceTypeCount['RURAL'] =
                  (residenceTypeCount['RURAL'] ?? 0) + 1;
            } else {
              residenceTypeCount['URBANA'] =
                  (residenceTypeCount['URBANA'] ?? 0) + 1;
            }
          }

          totalStudentsRural = residenceTypeCount['RURAL'] ?? 0;
          totalStudentsUrban = residenceTypeCount['URBANA'] ?? 0;
          List<String> monitoras = [];
          if (ecActivity.monitorsId.isEmpty) {
            monitoras.add('Sem monitor');
          } else {
            for (var monitorId in ecActivity.monitorsId) {
              final monitorDoc = await _firebaseFirestore
                  .collection('users')
                  .doc(monitorId)
                  .get();
              monitoras.add(monitorDoc.data()!['name']);
            }
          }

          final forPayment = ForPayment(
            id: ecActivity.id,
            itinerarieCode: 'Atividade Extracurricular',
            itinerariesShift: itinerariesShift,
            schoolsName: [schoolName],
            schoolsTypeRuralCount: schoolTypeRural,
            schoolsTypeUrbanCount: schoolTypeUrban,
            trajectory: ecActivity.local,
            levels: levels,
            vehiclePlate: ecActivity.busPlate,
            kilometer: ecActivity.kilometerOfBus,
            driverName: ecActivity.busDriver,
            monitorsId: ecActivity.monitorsId,
            contract: ecActivity.contract,
            callDaysCount: 0,
            callDaysRepositionCount: 1,
            studentsUrban: totalStudentsUrban,
            studentsRural: totalStudentsRural,
            quantityOfBus: ecActivity.quantityOfBus,
            dateOfEvent: ecActivity.dateOfEvent,
            valor: valor,
            monitorsName: monitoras,
          );

          await createForPayment(forPayment: forPayment);
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> createForPayment({required ForPayment forPayment}) async {
    try {
      await _firebaseFirestore
          .collection('forPayment')
          .add(forPayment.toJson());
      notifyListeners();
    } on FirebaseException catch (e) {
      throw e.message!;
    }
  }

  Future<List<ForPayment>> getForPayimentList(
      {required String contract, required DateTime month}) async {
    try {
      List<ForPayment> regular = [];
      List<ForPayment> ec = [];
      final snapshot = await _firebaseFirestore
          .collection('forPayment')
          .where('contract', isEqualTo: contract)
          .get();
      _forPayments =
          snapshot.docs.map((e) => ForPayment.fromJson(e.data())).toList();
      for (var forPayment in _forPayments) {
        if (forPayment.itinerarieCode == 'Atividade Extracurricular') {
          ec.add(forPayment);
        } else {
          regular.add(forPayment);
        }
      }
      _forPayments = regular + ec;

      notifyListeners();
      return _forPayments;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> deleteToPayment(ForPayment forPayiment) async {
    await _firebaseFirestore
        .collection('forPayment')
        .doc(forPayiment.id)
        .delete();
    notifyListeners();
  }

  Future<void> clearForPayment() async {
    _firebaseFirestore.collection('forPayment').get().then((snapshot) {
      for (DocumentSnapshot ds in snapshot.docs) {
        ds.reference.delete();
      }
    });
    _forPayments = [];
    notifyListeners();
  }
}
