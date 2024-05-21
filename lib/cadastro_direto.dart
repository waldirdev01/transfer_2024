import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:transfer_2024/app/models/school.dart';

import 'app/core/widgets/custom_home_card.dart';
import 'app/models/itinerary.dart';
import 'app/models/student.dart';
import 'escolas.dart';
import 'estudantes.dart';
import 'itinerarios.dart';

class CadastroDireto extends StatefulWidget {
  const CadastroDireto({super.key});

  @override
  State<CadastroDireto> createState() => _CadastroDiretoState();
}

class _CadastroDiretoState extends State<CadastroDireto> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String schoolId = 'jxKuqXpdVQL6dbWyCVOC';
  List<Student> estudantesParaItinerario = [];
  List<String> itinerariosId = [
    'kVFLWJsV2imAsvMKzW27',
  ];

  Future<void> createSchool() async {
    for (var school in TODASASESCOLAS) {
      try {
        await firestore
            .collection('schools')
            .doc(school.id)
            .set(school.toJson());
      } on FirebaseException catch (e) {
        throw e.message!;
      }
    }
    print('total de escolas: ${TODASASESCOLAS.length}  ');
  }

  Future<void> createItinerary() async {
    for (var itinerary in TODOSOSITINERARIOS) {
      try {
        await firestore
            .collection('itineraries')
            .doc(itinerary.id)
            .set(itinerary.toJson());
      } on FirebaseException catch (e) {
        throw e.message!;
      }
    }
  }

  Future<void> createStudents() async {
    for (var student in TODOSOSESTUDANTES) {
      try {
        await firestore
            .collection('students')
            .doc(student.id)
            .set(student.toJson());
        estudantesParaItinerario.add(student);
        if (!itinerariosId.contains(student.itineraryId)) {
          itinerariosId.add(student.itineraryId);
        }
      } on FirebaseException catch (e) {
        throw e.message!;
      }
    }
    print('total de estudantes: ${TODOSOSESTUDANTES.length}');
    print(
        'total de estudantes para itinerário: ${estudantesParaItinerario.length}');
    print(']');
    for (var id in itinerariosId) {
      print("'$id',");
    }
    print('[');
  }

  Future<void> gerItineraryByCode(String code) async {
    final snapshot = await firestore
        .collection('itineraries')
        .where('code', isEqualTo: code)
        .get();
    final itineraries =
        snapshot.docs.map((e) => Itinerary.fromJson(e.data())).toList();
    print('total de itinerários: ${itineraries.length}  ');
    itineraries.sort((a, b) => a.code.compareTo(b.code));
    for (var itinerary in itineraries) {
      print('${itinerary.code}, ${itinerary.id}');
    }
  }

  Future<void> deleteStudentsOftItinerary() async {
    final itinerary = await firestore
        .collection('itineraries')
        .doc('kVFLWJsV2imAsvMKzW27')
        .get();
    final schools = await firestore.collection('schools').get();

    var stt = await firestore
        .collection('students')
        .where('itineraryId', isEqualTo: 'kVFLWJsV2imAsvMKzW27')
        .get();
    for (var student in stt.docs) {
      for (var school in schools.docs) {
        var schoolload = School.fromJson(school.data());
        if (schoolload.studentsId!.contains(student.id)) {
          await firestore.collection('schools').doc(school.id).update({
            'studentsId': FieldValue.arrayRemove([student.id])
          });

          await firestore.collection('students').doc(student.id).delete();
        }
      }
    }
  }

  Future<void> verStudentsdoItinerario() async {
    final itinerary = await firestore
        .collection('itineraries')
        .doc('kVFLWJsV2imAsvMKzW27')
        .get();
    final _itinerary = Itinerary.fromJson(itinerary.data()!);
    for (var studentId in _itinerary.studentsId!) {
      firestore.collection('students').doc(studentId).get().then((value) {
        print(value.data());
      });
    }
  }

  Future<void> addStudentsToSchool(String schoolId) async {
    final snapshot = await firestore
        .collection('students')
        .where('schoolId', isEqualTo: schoolId)
        .get();
    final _students =
        snapshot.docs.map((e) => Student.fromJson(e.data())).toList();
    _students.forEach((student) async {
      await firestore.collection('schools').doc(schoolId).update({
        'studentsId': FieldValue.arrayUnion([student.id])
      });
    });
  }

  Future<void> addStudentsToItinerary() async {
    for (var student in estudantesParaItinerario) {
      await firestore
          .collection('itineraries')
          .doc(student.itineraryId)
          .update({
        'studentsId': FieldValue.arrayUnion([student.id])
      });
      await firestore
          .collection('students')
          .doc(student.id)
          .update({'authorized': true});
    }
  }

  Future<void> getItineraries() async {
    final snapshot = await firestore.collection('itineraries').get();
    final itineraries =
        snapshot.docs.map((e) => Itinerary.fromJson(e.data())).toList();
    print('total de itinerários: ${itineraries.length}  ');
    itineraries.sort((a, b) => a.code.compareTo(b.code));
    for (var itinerary in itineraries) {
      print('${itinerary.code}, ${itinerary.id}');
    }
  }

  Future<void> addSchoolToItinerary() async {
    for (var itineraryId in itinerariosId) {
      await firestore.collection('itineraries').doc(itineraryId).update({
        'schoolIds': FieldValue.arrayUnion([schoolId])
      });
      await firestore.collection('schools').doc(schoolId).update({
        'itinerariesId': FieldValue.arrayUnion([itineraryId])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Cadastro Direto'),
        ),
        body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.count(
              crossAxisCount: 2,
              children: [
                CustomHomeCard(
                  icon: Icons.list_alt,
                  text: 'Cadastrar Escola',
                  onTap: () async {
                    await verStudentsdoItinerario();
                    // ignore: use_build_context_synchronously
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            height: 200,
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Escola Cadastrada com Sucesso!'),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Fechar'),
                                  )
                                ],
                              ),
                            ),
                          );
                        });
                  },
                ),
                CustomHomeCard(
                  icon: Icons.search,
                  text: 'Buscar itrineraio pelo código',
                  onTap: () async {
                    gerItineraryByCode('DARCY 1.V.INT');
                  },
                ),
                CustomHomeCard(
                  icon: Icons.route,
                  text: 'Cadastrar Itinerário',
                  onTap: () async {
                    await createItinerary();
                    // ignore: use_build_context_synchronously
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            height: 200,
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                      'Itinerário Cadastrado com Sucesso!'),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Fechar'),
                                  )
                                ],
                              ),
                            ),
                          );
                        });
                  },
                ),
                CustomHomeCard(
                  icon: Icons.list_alt,
                  text: 'Criar Estudantes',
                  onTap: () async {
                    await createStudents();
                    // ignore: use_build_context_synchronously
                    message(context);
                  },
                ),
                CustomHomeCard(
                  icon: Icons.remove_circle,
                  text: 'Deletar Estudantes do itinerário',
                  onTap: () async {
                    await deleteStudentsOftItinerary();
                    // ignore: use_build_context_synchronously
                    message(context);
                  },
                ),
                CustomHomeCard(
                  icon: Icons.list_alt,
                  text: 'Adicionar Estudantes à Escola',
                  onTap: () async {
                    await addStudentsToSchool(schoolId);
                    // ignore: use_build_context_synchronously
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            height: 200,
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                      'Estudantes Adicionados à Escola com Sucesso!'),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Fechar'),
                                  )
                                ],
                              ),
                            ),
                          );
                        });
                  },
                ),
                CustomHomeCard(
                  icon: Icons.list_alt,
                  text: 'Adicionar estudantes aos Itinerários',
                  onTap: () async {
                    await addStudentsToItinerary();
                    // ignore: use_build_context_synchronously
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            height: 200,
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                      'Estudantes sem Itinerário Encontrados!'),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Fechar'),
                                  )
                                ],
                              ),
                            ),
                          );
                        });
                  },
                ),
                CustomHomeCard(
                    icon: Icons.add_road_outlined,
                    text: 'Adicionar escola ao itinerário',
                    onTap: () async {
                      addSchoolToItinerary();
                      // ignore: use_build_context_synchronously
                      showModalBottomSheet(
                          context: context,
                          builder: (context) {
                            return Container(
                              height: 200,
                              color: Colors.white,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                        'Escola Adicionada ao Itinerário com Sucesso!'),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text('Fechar'),
                                    )
                                  ],
                                ),
                              ),
                            );
                          });
                    }),
                CustomHomeCard(
                  icon: Icons.list_alt,
                  text: 'Ver Itinerários',
                  onTap: () async {
                    await getItineraries();
                    // ignore: use_build_context_synchronously
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return Container(
                            height: 200,
                            color: Colors.white,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('Itinerários Encontrados!'),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Fechar'),
                                  )
                                ],
                              ),
                            ),
                          );
                        });
                  },
                ),
              ],
            )));
  }

  message(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        builder: (context) {
          return Container(
            height: 200,
            color: Colors.white,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Estudantes Cadastrados com Sucesso!'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Fechar'),
                  )
                ],
              ),
            ),
          );
        });
  }
}
