import '../models/mentor_type.dart';

class MentorMessages {
  static String get({
    required MentorType mentor,
    required String context,
    Map<String, dynamic> data = const {},
  }) {
    switch (context) {
      case 'welcome':
        if (mentor == MentorType.rabbit) {
          return "I'm Shashi. I'll guide you quietly. Let's begin.";
        }
        return "Hello, I'm Manda. Take your time — I'll be right here with you.";

      case 'login_greeting_morning':
        if (mentor == MentorType.rabbit) {
          return "Morning. Your data from yesterday is processed. Ready for the day?";
        }
        return "Good morning! I've reviewed how you felt yesterday. Let's make today even better, ready?";

      case 'login_greeting_afternoon':
        if (mentor == MentorType.rabbit) {
          return "Midday check. Have you eaten? Scan your lunch if you haven't.";
        }
        return "Good afternoon! I hope you're taking a break to eat. Don't forget to show me your lunch!";

      case 'login_greeting_evening':
        if (mentor == MentorType.rabbit) {
          return "Evening. Time to wind down. Review your daily radar and prepare for sleep.";
        }
        return "Good evening! You did great today. Let's check your Health Radar and get ready to rest.";

      case 'health_radar_intro':
        if (mentor == MentorType.rabbit) {
          return "This radar shows your 6 vital signals. Tap any axis to explore it.";
        }
        return "Don't worry about all the numbers at once. Each point here is just one part of your story.";

      case 'ojas_explained':
        if (mentor == MentorType.rabbit) {
          return "OJAS is your vitality score. It rises when you sleep well, eat right, and move daily.";
        }
        return "Think of OJAS as how full your inner battery is. We'll keep it charged together.";

      case 'ojas_warning':
        final delta = data['delta'] ?? 0;
        if (mentor == MentorType.rabbit) {
          return "OJAS dropped $delta points. Identify what changed in the last 48 hours.";
        }
        return "Your OJAS dipped $delta points. That's okay — let's figure out what your body needs.";

      case 'ojas_celebrating':
        final delta = data['delta'] ?? 0;
        if (mentor == MentorType.rabbit) {
          return "Up $delta points. Whatever you did — repeat it.";
        }
        return "Look at that! $delta points up. You should feel really good about this.";

      case 'log_prompt':
        if (mentor == MentorType.rabbit) {
          return "Nothing logged today. 60 seconds of honest data changes everything.";
        }
        return "No rush — when you're ready, tap here and we'll log together.";

      case 'prakriti_intro':
        if (mentor == MentorType.rabbit) {
          return "Your Prakriti is your baseline constitution. It never changes. Everything else is measured against it.";
        }
        return "Prakriti is who you are at your core. We use it to understand what works for your body specifically.";

      case 'streak_broken':
        if (mentor == MentorType.rabbit) {
          return "Streak reset. Start again today. Progress isn't linear.";
        }
        return "Streaks break sometimes. What matters is you're here now.";

      case 'explain_ojas_card':
        if (mentor == MentorType.rabbit) {
          return "OJAS measures your core vitality. Keep it above 60 to maintain a strong immune system and clear mind.";
        }
        return "This is your OJAS score! It reflects how well-rested, nourished, and balanced you are right now. Higher is better!";

      case 'explain_daily_checkin':
        if (mentor == MentorType.rabbit) {
          return "Log your sleep, stress, and energy daily. These 3 metrics directly influence your OJAS score.";
        }
        return "Take a moment to check in with yourself. Tracking these small details helps us find patterns in your well-being.";

      case 'explain_dosha_radar':
        if (mentor == MentorType.rabbit) {
          return "This radar visualizes your current Dosha balance. A perfect triangle means perfect health. Watch for spikes.";
        }
        return "Think of this triangle as a snapshot of your energies. We want all three points to stay relatively even so you feel your best.";

      case 'explain_dominant_prakriti':
        if (mentor == MentorType.rabbit) {
          return "Your dominant Dosha defines your physical and mental baseline. Align your diet and habits with this to prevent disease.";
        }
        return "This is your core nature! Knowing your dominant Dosha helps us pick the exact right foods, exercises, and routines for you.";

      case 'explain_health_radar':
        if (mentor == MentorType.rabbit) {
          return "This predictive radar calculates your OJAS trajectory for the next 3 days based on current inputs.";
        }
        return "I look at your vitals today to predict how you'll feel tomorrow. Let's keep that trajectory pointing up!";

      case 'explain_tongue_scan':
        if (mentor == MentorType.rabbit) {
          return "Tongue analysis reveals digestive tract health and toxic build-up (Ama). Scan daily before brushing.";
        }
        return "Your tongue is a mirror to your stomach! A quick picture helps us see if you're digesting food well.";

      case 'explain_eye_scan':
        if (mentor == MentorType.rabbit) {
          return "Sclera analysis detects early signs of liver stress, sleep deprivation, or Pitta imbalance.";
        }
        return "The eyes show how tired you really are. A quick look helps me know if you need more rest or hydration.";

      case 'explain_nadi_pariksha':
        if (mentor == MentorType.rabbit) {
          return "This uses photoplethysmography (PPG) to read your pulse from your fingertip, determining real-time Dosha spikes.";
        }
        return "Place your finger on the camera, and I'll read your pulse just like an Ayurvedic doctor would!";

      case 'explain_food_scan':
        if (mentor == MentorType.rabbit) {
          return "Point your camera at a meal. Our YOLO AI will identify the ingredients and assess Dosha compatibility.";
        }
        return "Show me your plate! I'll tell you what's in it and whether it's the right choice for your body type right now.";

      case 'explain_label_scan':
        if (mentor == MentorType.rabbit) {
          return "OCR scans packaged food labels for hidden sugars, bad oils, or incompatible ingredients.";
        }
        return "Not sure if that snack is healthy? Scan the ingredients list and I'll look out for hidden nasties.";

      case 'explain_ai_recipe':
        if (mentor == MentorType.rabbit) {
          return "Generates personalized recipes using Gemini, strictly adhering to your current Dosha requirements.";
        }
        return "Tell me what ingredients you have, and I'll whip up a recipe that's perfectly balanced for you!";

      case 'explain_yoga':
        if (mentor == MentorType.rabbit) {
          return "Real-time posture correction via MediaPipe. Proper alignment prevents injury and maximizes Prana flow.";
        }
        return "Let's move! The camera will gently guide your posture so you get the most out of every stretch.";

      case 'explain_plant_id':
        if (mentor == MentorType.rabbit) {
          return "On-device TFLite identifies medicinal plants. Useful for foraging or learning local flora.";
        }
        return "Spot a strange leaf? Snap a picture and I'll tell you if it's an Ayurvedic herb!";

      case 'explain_community':
        if (mentor == MentorType.rabbit) {
          return "Geolocated community features. Connect with others nearby growing or foraging Ayurvedic plants.";
        }
        return "Meet neighbors who share your passion for plants and natural health!";

      default:
        return '';
    }
  }
}
