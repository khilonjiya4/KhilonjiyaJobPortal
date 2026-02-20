import 'package:supabase_flutter/supabase_flutter.dart';

class SearchService {
  final SupabaseClient _db = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> searchJobs({
    required String keyword,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _db.rpc(
        'search_jobs',
        params: {
          'p_keyword': keyword,
          'p_limit': limit,
          'p_offset': offset,
        },
      );

      final jobs = List<Map<String, dynamic>>.from(response);

      if (jobs.isEmpty) return [];

      final companyIds = jobs
          .map((e) => e['company_id'])
          .where((e) => e != null)
          .toSet()
          .toList();

      if (companyIds.isEmpty) return jobs;

      final companies = await _db
          .from('companies')
          .select('''
            id,
            name,
            logo_url,
            is_verified,
            business_types_master (
              id,
              type_name,
              logo_url
            )
          ''')
          .inFilter('id', companyIds);

      final companyMap = {
        for (var c in companies) c['id']: c,
      };

      for (var job in jobs) {
        final companyId = job['company_id'];
        if (companyMap.containsKey(companyId)) {
          job['companies'] = companyMap[companyId];
        }
      }

      return jobs;
    } catch (e) {
      return [];
    }
  }
}