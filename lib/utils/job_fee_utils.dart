import '../models/app_catalogs.dart';
import '../models/job.dart';

int resolveJobBidFeeKzt({
  required Job job,
  AppCatalogs? catalogs,
  int legacyBidFeeKzt = 0,
}) {
  if (job.bidFeeKzt > 0) {
    return job.bidFeeKzt;
  }

  if (catalogs != null) {
    final categoryFee = catalogs.bidFeeForCategory(job.category);
    if (categoryFee > 0) {
      return categoryFee;
    }
  }

  return legacyBidFeeKzt > 0 ? legacyBidFeeKzt : 0;
}
