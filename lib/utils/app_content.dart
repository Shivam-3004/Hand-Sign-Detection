// ═══════════════════════════════════════════════════════════════════════════
// ✏️  EDIT ALL APP CONTENT HERE
// This is the only file you need to touch to update text, steps, terms etc.
// ═══════════════════════════════════════════════════════════════════════════

class AppContent {

  // ── App info ───────────────────────────────────────────────────────────
  static const String appName        = 'GestureAI';
  static const String appVersion     = '1.0.0';
  static const String appDescription =
      'GestureAI is a real-time hand gesture recognition application'
      'powered by TensorFlow and MediaPipe.'
      'It detects and classifies hand gestures using your device camera,'
      'then sends the captured data to an AI backend for instant prediction.';

  static const String teamName       = 'Major Project Team';
  static const String institution    = 'Govt. Polytechnic Dehradun Pitthuwala, Uttarakhand';
  static const String contactEmail   = 'detectionhandsign@gmail.com';
  static const String githubUrl      = 'https://github.com/Shivam-3004/Hand-Sign-Detection';

  // ── Tech stack chips shown on About screen ─────────────────────────────
  static const List<String> techStack = [
    'Flutter', 'Dart', 'Python', 'FastAPI', 'TensorFlow', 'MediaPipe', 'OpenCV'
  ];

  // ── How To Use steps ───────────────────────────────────────────────────
  // Each map needs 'title' and 'body'. Add or remove maps freely.
  static const List<Map<String, String>> howToUseSteps = [
    {
      'title': 'Open the Camera',
      'body':  'Tap "Start Detection" on the home screen. The front '
          'camera opens automatically in mirror mode.',
    },
    {
      'title': 'Show Your Hand',
      'body':  'Hold your hand clearly in front of the camera. Keep '
          'your hand inside the frame and avoid fast movement.',
    },
    {
      'title': 'Capture a Gesture',
      'body':  'Press the shutter button (bottom center). The app takes '
          'a photo and sends it to the AI server for prediction.',
    },
    {
      'title': 'Read the Result',
      'body':  'A result card slides in showing the detected gesture '
          'name and a confidence percentage. Green = high, '
          'orange = medium, red = low confidence.',
    },
    {
      'title': 'Switch Camera',
      'body':  'Tap the flip icon (bottom right) to switch between '
          'front and rear cameras. Flash is only available on '
          'the rear camera.',
    },
    {
      'title': 'Adjust Settings',
      'body':  'Use the Settings tab to change sensitivity, confidence '
          'threshold, notifications, haptics, and the app theme.',
    },
  ];

  // ── Quick tip shown at the bottom of How To Use ───────────────────────
  static const String howToUseTip =
      'For best accuracy, ensure good lighting and hold your hand steady '
      'at a comfortable distance from the camera.';

  // ── Terms & Conditions clauses ────────────────────────────────────────
  static const String termsLastUpdated = 'April 2026';

  static const List<Map<String, String>> termsAndConditions = [
    {
      'heading': '1. Acceptance of Terms',
      'body': 'By using GestureAI, you agree to these terms and conditions. '
          'If you do not agree, please discontinue use of the application.',
    },
    {
      'heading': '2. Camera & Data Usage',
      'body': 'This app requires camera access to capture hand gestures for '
          'real-time recognition. Captured frames are sent only to the '
          'local backend server for processing and are not stored or '
          'shared with any third party.',
    },
    {
      'heading': '3. AI Predictions',
      'body': 'Gesture predictions are generated using TensorFlow and '
          'MediaPipe-based recognition models. Results may not always '
          'be fully accurate and should not be used for safety-critical '
          'or sensitive decisions.',
    },
    {
      'heading': '4. Privacy',
      'body': 'No personal data is collected. Camera frames are processed '
          'in real time and discarded immediately after prediction. '
          'No biometric information is stored.',
    },
    {
      'heading': '5. Intellectual Property',
      'body': 'All source code, UI design, and trained model components '
          'belong to the development team. Unauthorized copying or '
          'distribution is prohibited.',
    },
    {
      'heading': '6. Limitation of Liability',
      'body': 'The developers are not responsible for any direct or '
          'indirect loss resulting from use of this application. '
          'Use the app at your own discretion.',
    },
    {
      'heading': '7. Changes to Terms',
      'body': 'These terms may be updated periodically. Continued use '
          'of the application after changes indicates acceptance '
          'of the revised terms.',
    },
  ];
}