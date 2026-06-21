import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/region.dart';

const maxSavedRegions = 10;
const _savedRegionIdsKey = 'saved_region_ids';
const _regionsAssetPath = 'assets/data/regions.json';

class RegionRepository {
  Future<List<Region>> loadAllRegions() async {
    final raw = await rootBundle.loadString(_regionsAssetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Region.fromJson(e as Map<String, dynamic>)).toList();
  }

  List<String> distinctProvinces(List<Region> all) {
    final seen = <String>{};
    final result = <String>[];
    for (final region in all) {
      if (seen.add(region.province)) {
        result.add(region.province);
      }
    }
    return result;
  }

  List<Region> districtsForProvince(List<Region> all, String province) {
    return all.where((r) => r.province == province).toList();
  }

  Future<List<String>> loadSavedRegionIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_savedRegionIdsKey) ?? [];
  }

  Future<void> saveRegionIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_savedRegionIdsKey, ids);
  }
}
