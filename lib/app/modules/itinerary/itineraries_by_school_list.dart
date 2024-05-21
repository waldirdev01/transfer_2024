import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:transfer_2024/app/core/widgets/custom_app_bar.dart';
import 'package:transfer_2024/app/modules/itinerary/widgets/itinerary_card_list.dart';
import 'package:transfer_2024/app/providers/itinerary_provider.dart';

import '../../models/school.dart';

class ItinerariesBySchoolList extends StatelessWidget {
  const ItinerariesBySchoolList({super.key});

  @override
  Widget build(BuildContext context) {
    final school = ModalRoute.of(context)!.settings.arguments as School;

    return Scaffold(
        appBar: const CustomAppBar(
          title: 'Itinerários da escola',
        ),
        body: FutureBuilder(
          future: context
              .watch<ItineraryProvider>()
              .getItinerariesBySchool(school.id!),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
                return const Center(child: CircularProgressIndicator());
              case ConnectionState.waiting:
                return const Center(child: CircularProgressIndicator());
              case ConnectionState.active:
                return const Center(child: CircularProgressIndicator());
              case ConnectionState.done:
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Erro: ${snapshot.error}'),
                  );
                }
                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  final itineraries = snapshot.data!;
                  itineraries.sort((a, b) => a.code.compareTo(b.code));

                  return ListView.builder(
                    itemCount: itineraries.length,
                    itemBuilder: (context, index) {
                      final itinerary = itineraries[index];
                      return ItineraryCardList(
                          itinerary: itinerary, school: school);
                    },
                  );
                }

                return const Center(
                  child: Text(
                    'Nenhum itinerário associado à escola.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
            }
          },
        ));
  }
}
