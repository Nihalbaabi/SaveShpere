class AssistantConfig {
  // Logic Thresholds
  static const double confidenceThreshold = 0.4;
  
  static const Map<String, double> anomalyThresholds = {
    'warningRatio': 1.3,
    'alertRatio': 1.6,
  };

  // Bill Rate Definitions (KSEB style logic simplified)
  static const List<Map<String, dynamic>> slabRates = [
    {'limit': 50, 'rate': 3.15},
    {'limit': 100, 'rate': 3.7},
    {'limit': 150, 'rate': 4.8},
    {'limit': 200, 'rate': 6.4},
    {'limit': 250, 'rate': 7.6},
    {'limit': 300, 'rate': 5.8}, // Different logic above 250
    {'limit': double.infinity, 'rate': 8.5},
  ];

  static const double fixedCharges = 100.0;
  static const double dutyPercentage = 0.10;

  // Tone & Personality Rules
  static const Map<String, dynamic> tone = {
    'shortResponses': true,
    'maxWords': 75,
    'currencySymbol': "₹",
  };

  // Controlled Randomness for Responses
  static const Map<String, List<String>> variants = {
    'normalUsage': [
      "Your usage today is well within your normal range.",
      "Today’s power consumption looks completely consistent with your usual patterns.",
      "Everything is running smoothly. No unusual spikes detected today."
    ],
    'unknown': [
      "I'm not sure I understood that. You can ask me about your usage, bill, or energy tips.",
      "Sorry, I didn't get that. Try asking 'What's my expected bill?' or 'How much energy did I use today?'.",
      "I'm still learning! Could you rephrase your question about your power consumption?"
    ],
    'greeting': [
      "Hello! How can I help you with your energy usage today?",
      "Hi there! Ready to check your power consumption?",
      "Greetings! I'm here to help you save energy."
    ],
    'thanks': [
      "You're very welcome!",
      "Happy to help!",
      "Anytime! Let me know if you need anything else."
    ],
    'bye': [
      "Goodbye! Have an energy-efficient day!",
      "Bye! Feel free to ask more questions later.",
      "See you next time!"
    ]
  };

  // Memory Limits
  static const int contextExpiryMinutes = 5;
  static const int contextMessageLimit = 10;
}
