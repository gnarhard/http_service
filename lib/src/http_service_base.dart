import 'dart:io' show HttpHeaders, HttpStatus;
import 'package:http/http.dart' as http;

class HttpService extends http.BaseClient {
  String apiNamespace;
  String siteBaseUrl;
  http.Client? client;
  final Function hasConnectivity;
  final Future<String?> Function() getAuthTokenCallback;
  final bool isInDebugMode;
  final int timeoutInMs;
  late final Duration timeout;

  String get noTrailingSlashBaseUrl => siteBaseUrl.endsWith('/')
      ? siteBaseUrl.substring(0, siteBaseUrl.length - 1)
      : siteBaseUrl;

  String get noTrailingSlashNamespace => apiNamespace.endsWith('/')
      ? apiNamespace.substring(0, apiNamespace.length - 1)
      : apiNamespace;

  String get apiUrl {
    return noTrailingSlashNamespace.isEmpty
        ? noTrailingSlashBaseUrl
        : '$noTrailingSlashBaseUrl/$noTrailingSlashNamespace';
  }

  HttpService({
    required this.apiNamespace,
    required this.siteBaseUrl,
    required this.hasConnectivity,
    required this.getAuthTokenCallback,
    this.isInDebugMode = false,
    this.timeoutInMs = 1500,
  }) {
    /// This gets around the annoying http client creation warning when testing.
    client = http.Client();
    timeout = Duration(milliseconds: timeoutInMs);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (isInDebugMode) {
      print('${request.method}: ${request.url}');
    }

    if (!hasConnectivity()) {
      return http.StreamedResponse(
          Stream.fromIterable([[]]), HttpStatus.badGateway);
    }

    final modifiedRequest = request as http.Request;
    modifiedRequest.headers[HttpHeaders.acceptHeader] = 'application/json';

    final token = await getAuthTokenCallback();
    if (token != null) {
      modifiedRequest.headers[HttpHeaders.authorizationHeader] =
          'Bearer $token';
    }

    try {
      return client!.send(modifiedRequest).timeout(timeout);
    } catch (e) {
      if (isInDebugMode) {
        print('HttpService Error: $e');
      }
      return http.StreamedResponse(
          Stream.fromIterable([[]]), HttpStatus.badGateway);
    }
  }
}
