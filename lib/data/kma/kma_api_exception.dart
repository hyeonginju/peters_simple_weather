/// Thrown when the KMA API returns a non-success `resultCode` (e.g. NO_DATA
/// because the requested base_time hasn't been published yet).
class KmaApiException implements Exception {
  final String resultCode;
  final String resultMessage;

  const KmaApiException(this.resultCode, this.resultMessage);

  @override
  String toString() => 'KmaApiException($resultCode: $resultMessage)';
}
