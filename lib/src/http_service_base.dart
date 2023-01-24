import 'dart:io' show HttpHeaders, HttpStatus, Platform;

import 'package:http/http.dart' as http;

class HttpService extends http.BaseClient {
  String apiNamespace;
  String apiUrl;
  String publicImgPath;
  String siteUrl;
  http.Client? client;
  final Function hasConnectivity;
  final Function getAuthTokenCallback;

  HttpService({
    required this.apiNamespace,
    required this.apiUrl,
    required this.publicImgPath,
    required this.siteUrl,
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
    if (hasConnectivity()) {
      return http.StreamedResponse(
          Stream.fromIterable([[]]), HttpStatus.serviceUnavailable);
    }

    final incomingRequest = request as http.Request;
    final modifiedRequest =
        http.Request(incomingRequest.method, incomingRequest.url);

    modifiedRequest.headers.addAll(incomingRequest.headers);
    modifiedRequest.headers[HttpHeaders.acceptHeader] = 'application/json';
    modifiedRequest.encoding = incomingRequest.encoding;
    modifiedRequest.bodyBytes = incomingRequest.bodyBytes.toList();

    if (bearerToken != null) {
      modifiedRequest.headers[HttpHeaders.authorizationHeader] =
          'Bearer $bearerToken';
    }

    return client!.send(modifiedRequest);
  }
}
