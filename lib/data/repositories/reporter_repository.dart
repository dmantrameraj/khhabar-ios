import 'package:dio/dio.dart';

import '../../core/network/api_client.dart';
import '../models/paginated_result.dart';
import '../models/reporter_earnings.dart';
import '../models/reporter_submission.dart';

/// The reporter-only "file a story from the field" feature — mirrors the
/// website's NewsController::store() minus tags/SEO/drafts/gallery (see
/// ReporterApiController on the backend for the full mapping). Every
/// endpoint here 403s for a caller without the `news.create` permission,
/// so this repository is only ever used from UI already gated on
/// AuthUser.role == 'reporter'.
class ReporterRepository {
  final ApiClient _client;

  ReporterRepository(this._client);

  Future<PaginatedResult<ReporterSubmission>> mySubmissions({int page = 1}) async {
    final (data, meta) = await _client.get('reporter/news', query: {'page': page});
    final items = (data as List).map((e) => ReporterSubmission.fromJson(e as Map<String, dynamic>)).toList();
    return PaginatedResult<ReporterSubmission>(
      items: items,
      page: meta['page'] as int? ?? 1,
      perPage: meta['per_page'] as int? ?? items.length,
      total: meta['total'] as int? ?? items.length,
      hasNext: meta['has_next'] as bool? ?? false,
    );
  }

  /// [imagePath] is a local file path (from image_picker) — required,
  /// matching the backend's validation. [extraImagePaths] is 0-2 more
  /// photos the backend splices evenly between paragraphs (see
  /// ReporterApiController::buildContentHtml()) — there's no rich-text
  /// editor on mobile to place them precisely.
  Future<ReporterSubmission> submit({
    required String title,
    required String content,
    required int categoryId,
    required String imagePath,
    List<String> extraImagePaths = const [],
  }) async {
    final file = await MultipartFile.fromFile(imagePath, filename: imagePath.split(RegExp(r'[\\/]')).last);
    final extraFiles = <String, MultipartFile>{};
    for (var i = 0; i < extraImagePaths.length && i < 2; i++) {
      final path = extraImagePaths[i];
      extraFiles['extra_image_${i + 1}'] =
          await MultipartFile.fromFile(path, filename: path.split(RegExp(r'[\\/]')).last);
    }
    final (data, _) = await _client.postMultipart(
      'reporter/news',
      fields: {'title': title, 'content': content, 'category_id': categoryId},
      file: file,
      extraFiles: extraFiles,
    );
    return ReporterSubmission.fromJson(data as Map<String, dynamic>);
  }

  Future<ReporterEarnings> getEarnings() async {
    final (data, _) = await _client.get('reporter/earnings');
    return ReporterEarnings.fromJson(data as Map<String, dynamic>);
  }
}
