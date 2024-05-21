import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transfer_2024/app/providers/student_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/ui/ap_ui_config.dart';
import '../../core/widgets/custom_app_bar.dart';
import '../../models/student.dart';
import '../../providers/itinerary_provider.dart';

class StudentsForAuthorize extends StatefulWidget {
  const StudentsForAuthorize({super.key});

  @override
  State<StudentsForAuthorize> createState() => _StudentsForAuthorizeState();
}

class _StudentsForAuthorizeState extends State<StudentsForAuthorize> {
  // Lista de estudantes filtrados (mantida para referência, mas não mais para controle de seleção)
  List<Student> filteredStudents = [];

  // Mudança: Map para controlar a seleção de cada estudante
  Map<String, bool> selectedStudents = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Alunos nos itinerários para autorizar',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                height: MediaQuery.of(context).size.height * 0.9,
                child: FutureBuilder<List<Student>>(
                  initialData: const [],
                  future: context
                      .read<StudentProvider>()
                      .getStudentsNotAuthorized(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Erro: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                          child: Text('Nenhum estudante para inserir.',
                              style: TextStyle(fontSize: 18)));
                    }

                    final students = snapshot.data!;

                    // Inicializa o estado de seleção para cada estudante se ainda não estiver definido
                    for (var student in students) {
                      selectedStudents.putIfAbsent(student.id!, () => false);
                    }

                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        return _studentCard(student);
                      },
                    );
                  },
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppUiConfig.themeCustom.primaryColor,
        onPressed: () {
          // Processa apenas os estudantes selecionados
          for (var student in filteredStudents) {
            context.read<ItineraryProvider>().addStudentToItineraryByAdmin(
                itineraryId: student.itineraryId, student: student);
          }
          Navigator.of(context).pop();
        },
        child: const Icon(Icons.save, color: Colors.white),
      ),
    );
  }

  Card _studentCard(Student student) {
    if (student.imageUrl!.isEmpty) {
      return Card(
        color: getColorByAbsences(student.countAbsences()),
        child: ListTile(
          title: Column(
            children: [
              const Text(
                'O termo já foi aprovado.',
                style: TextStyle(color: Colors.red),
              ),
              Text(
                student.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          subtitle: Text(
            'CPF: ${student.cpf}\nFaltas: ${student.countAbsences()}',
            style: const TextStyle(fontSize: 16),
          ),
          trailing: Checkbox(
            value: selectedStudents[student.id],
            onChanged: (bool? value) {
              setState(() {
                selectedStudents[student.id!] = value!;
                // Atualiza a lista de estudantes filtrados com base na seleção
                if (value) {
                  filteredStudents.add(student);
                } else {
                  filteredStudents.removeWhere((s) => s.id == student.id);
                }
              });
            },
          ),
        ),
      );
    }
    return Card(
      color: getColorByAbsences(student.countAbsences()),
      child: ListTile(
        title: Column(
          children: [
            if (!kIsWeb) // Se não for web, tenta carregar a imagem.
              Image.network(
                student.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return const Text(
                    'Erro ao carregar imagem',
                    style: TextStyle(color: Colors.red),
                  );
                },
              )
            else // Se for web, mostra o link.
              InkWell(
                onTap: () => launchUrl(Uri.parse(student.imageUrl!)),
                child: const Text(
                  'Clique aqui para ver a imagem',
                  style: TextStyle(
                      color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            Text(
              student.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        subtitle: Text(
          'CPF: ${student.cpf}\nFaltas: ${student.countAbsences()}',
          style: const TextStyle(fontSize: 16),
        ),
        trailing: Checkbox(
          value: selectedStudents[student.id],
          onChanged: (bool? value) {
            setState(() {
              selectedStudents[student.id!] = value!;
              // Atualiza a lista de estudantes filtrados com base na seleção
              if (value) {
                filteredStudents.add(student);
              } else {
                filteredStudents.removeWhere((s) => s.id == student.id);
              }
            });
          },
        ),
      ),
    );
  }
}
