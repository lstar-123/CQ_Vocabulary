import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/api/api_client.dart';
import '../core/api/api_constants.dart';
import '../core/constants/app_constants.dart';

class TtsRepository {
  TtsRepository({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<Uint8List> speak(
    String text, {
    String lang = AppConstants.ttsDefaultLang,
  }) async {
    final response = await _dio.get(
      ApiPaths.tts,
      queryParameters: {'text': text, 'lang': lang},
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }
}
