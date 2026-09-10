/// GET /reporter/earnings — matches ContentEarningModel::summaryForUser(),
/// the same numbers the website's own reporter dashboard shows.
class ReporterEarnings {
  final double pendingAmount;
  final double paidAmount;
  final int totalArticles;

  ReporterEarnings({required this.pendingAmount, required this.paidAmount, required this.totalArticles});

  factory ReporterEarnings.fromJson(Map<String, dynamic> json) => ReporterEarnings(
        pendingAmount: (json['pending_amount'] as num).toDouble(),
        paidAmount: (json['paid_amount'] as num).toDouble(),
        totalArticles: json['total_articles'] as int,
      );
}
