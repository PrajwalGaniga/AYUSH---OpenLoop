import 'package:flutter/material.dart';
import '../models/mentor_type.dart';
import '../services/mentor_service.dart';
import '../services/mentor_messages.dart';
import '../widgets/mentor_widget.dart';
import 'package:provider/provider.dart';
import '../providers/mentor_notifier.dart';

mixin MentorGuidanceMixin<T extends StatefulWidget> on State<T> {
  Future<void> showMentorGuidanceIfFirstVisit({
    required String screenKey,
    required MentorType mentor,
    required String context,
    Map<String, dynamic> data = const {},
  }) async {
    final isFirst = await MentorService.isFirstVisit(screenKey);
    if (!isFirst) return;

    if (!mounted) return;

    final message = MentorMessages.get(
      mentor: mentor,
      context: context,
      data: data,
    );

    if (message.isEmpty) return;

    await showModalBottomSheet(
      context: this.context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PopScope(
          canPop: false, // Prevent back button dismissal
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MentorWidget(
                  mentor: mentor,
                  message: message,
                  dismissible: false,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mentor.accentColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> showMentorExplanation({
    required BuildContext context,
    required String contextKey,
    Map<String, dynamic> data = const {},
  }) async {
    if (!mounted) return;
    
    // Attempt to get the mentor, or default to rabbit if not found in context
    MentorType mentor;
    try {
      mentor = Provider.of<MentorNotifier>(context, listen: false).currentMentor;
    } catch (e) {
      mentor = MentorType.rabbit;
    }

    final message = MentorMessages.get(
      mentor: mentor,
      context: contextKey,
      data: data,
    );

    if (message.isEmpty) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MentorWidget(
                mentor: mentor,
                message: message,
                dismissible: true,
                onDismiss: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      },
    );
  }
}
