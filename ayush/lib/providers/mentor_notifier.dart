import 'package:flutter/material.dart';
import '../models/mentor_type.dart';
import '../services/mentor_service.dart';

class MentorNotifier extends ChangeNotifier {
  MentorType _currentMentor = MentorType.rabbit;

  MentorType get currentMentor => _currentMentor;

  Future<void> initialize() async {
    _currentMentor = await MentorService.loadMentor();
    notifyListeners();
  }

  void updateMentor(MentorType newMentor) {
    _currentMentor = newMentor;
    notifyListeners();
  }
}
