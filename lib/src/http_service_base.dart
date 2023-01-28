import 'dart:io' show HttpHeaders, HttpStatus, Platform;

import 'package:http/http.dart' as http;

class HttpService extends http.BaseClient {
  String apiNamespace;
  String siteBaseUrl;
  http.Client? client;
  final Function hasConnectivity;
  final Function getAuthTokenCallback;

  String get noTrailingSlashBaseUrl => siteBaseUrl.endsWith('/')
      ? siteBaseUrl.substring(0, siteBaseUrl.length - 1)
      : siteBaseUrl;

  String get noTrailingSlashNamespace => apiNamespace.endsWith('/')
      ? apiNamespace.substring(0, apiNamespace.length - 1)
      : apiNamespace;

  String get apiUrl => '$noTrailingSlashBaseUrl/$noTrailingSlashNamespace';

  HttpService({
    required this.apiNamespace,
    required this.siteBaseUrl,
    required this.hasConnectivity,
    required this.getAuthTokenCallback,
  }) {
    /// This gets around the annoying http client creation warning when testing.
    client =
        Platform.environment.containsKey('FLUTTER_TEST') ? null : http.Client();
  }

  String? get bearerToken => getAuthTokenCallback();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (!hasConnectivity()) {
      return http.StreamedResponse(
          Stream.fromIterable([[]]), HttpStatus.badGateway);
    }

    final modifiedRequest = request as http.Request;
    modifiedRequest.headers[HttpHeaders.acceptHeader] = 'application/json';

    if (bearerToken != null) {
      modifiedRequest.headers[HttpHeaders.authorizationHeader] =
          'Bearer ${bearerToken!}';
    }

    return client!.send(modifiedRequest);
  }
}
