import 'package:supabase_flutter/supabase_flutter.dart';

class DbService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> create(String table, Map<String, dynamic> data) async {
    await _client.from(table).insert(data);
  }

  static Future<List<dynamic>> view(String table) async {
    return await _client.from(table).select();
  }

  static Future<void> update(
      String table, String column, dynamic value, Map<String, dynamic> data) async {
    await _client.from(table).update(data).eq(column, value);
  }

  static Future<void> delete(
      String table, String column, dynamic value) async {
    await _client.from(table).delete().eq(column, value);
  }
}