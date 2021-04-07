import 'dart:math';

double faderMin = -6;
double faderMax = 6;

double dbToPercentage(double db) {
  return exp((db * ln10) / 20);
}

double percentageToDb(double percentage) {
  return 20 * (log(percentage) / ln10);
}

double percentageToSliderValue(double percentage) {
  double offset = faderMin * -1;
  double relativeMax = faderMax + offset;
  double currentDb = double.parse(percentageToDb(percentage).toStringAsFixed(1));
  double shiftedDb = currentDb + offset;
  return (shiftedDb / relativeMax);
}

double sliderValueToPercentage(double sliderValue) {
  double offset = faderMin * -1;
  double relativeMax = faderMax + offset;
  double shiftedDb = sliderValue * relativeMax;
  double currentDb = shiftedDb - offset;
  return dbToPercentage(currentDb);
}