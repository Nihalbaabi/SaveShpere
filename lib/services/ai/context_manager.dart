import '../../models/energy_models.dart';
import '../../models/assistant.dart';
import '../../config/assistant_config.dart';

ConversationContext createInitialContext() {
  return ConversationContext(
    lastIntent: null,
    lastTopic: null,
    lastTimeReference: null,
    lastUpdatedTimestamp: DateTime.now().millisecondsSinceEpoch,
    messageCount: 0,
  );
}

bool isContextExpired(ConversationContext context) {
  if (context.messageCount >= AssistantConfig.contextMessageLimit) {
    return true;
  }

  final minutesSinceLastUpdate = (DateTime.now().millisecondsSinceEpoch - context.lastUpdatedTimestamp) / (1000 * 60);
  if (minutesSinceLastUpdate > AssistantConfig.contextExpiryMinutes) {
    return true;
  }

  return false;
}

ConversationContext updateContext(
    ConversationContext context,
    Intent intent,
    String? timeReference) {
  if (isContextExpired(context)) {
    final newContext = createInitialContext();
    newContext.lastIntent = intent;
    newContext.lastTimeReference = timeReference;
    newContext.messageCount = 1;
    return newContext;
  }

  return ConversationContext(
    lastIntent: intent,
    lastTopic: context.lastTopic,
    lastTimeReference: timeReference ?? context.lastTimeReference,
    lastUpdatedTimestamp: DateTime.now().millisecondsSinceEpoch,
    messageCount: context.messageCount + 1,
  );
}
