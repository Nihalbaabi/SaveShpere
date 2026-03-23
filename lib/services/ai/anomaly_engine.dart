import '../../models/energy_models.dart';
import '../../models/assistant.dart';
import '../../config/assistant_config.dart';

Severity detectAnomaly(EnergyMetrics data) {
  if (data.weeklyAverageKwh <= 0.1) return Severity.normal;

  final ratio = data.todayUsageKwh / data.weeklyAverageKwh;

  if (ratio >= (AssistantConfig.anomalyThresholds['alertRatio'] ?? 1.6)) {
    return Severity.alert;
  }

  if (ratio >= (AssistantConfig.anomalyThresholds['warningRatio'] ?? 1.3)) {
    return Severity.warning;
  }

  if (data.currentPowerKw > 4.0) {
    return Severity.warning;
  }

  return Severity.normal;
}
