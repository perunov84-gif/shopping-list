import '../pigeons/flutter_rustore_pay_api.dart';

/// Состояние подтверждения выдачи товара.
///
/// [pending] - товар оплачен, но выдача ещё не подтверждена разработчиком;
/// [acknowledged] - выдача товара подтверждена;
/// [unknown] - состояние подтверждения неизвестно.
enum AcknowledgementState {
  pending,
  acknowledged,
  unknown,
}

AcknowledgementState mapFlutterAcknowledgementStateToAcknowledgementState(
    FlutterAcknowledgementState? flutterAcknowledgementState) {
  return switch (flutterAcknowledgementState) {
    FlutterAcknowledgementState.pending => AcknowledgementState.pending,
    FlutterAcknowledgementState.acknowledged =>
      AcknowledgementState.acknowledged,
    FlutterAcknowledgementState.unknown => AcknowledgementState.unknown,
    null => AcknowledgementState.unknown,
  };
}

FlutterAcknowledgementState
    mapAcknowledgementStateToFlutterAcknowledgementState(
        AcknowledgementState acknowledgementState) {
  return switch (acknowledgementState) {
    AcknowledgementState.pending => FlutterAcknowledgementState.pending,
    AcknowledgementState.acknowledged =>
      FlutterAcknowledgementState.acknowledged,
    AcknowledgementState.unknown => FlutterAcknowledgementState.unknown,
  };
}
