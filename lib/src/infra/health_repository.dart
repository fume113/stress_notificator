import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stress_notificator/src/models/tingkat_stress.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HealthRepository {
  final String databaseUrl =
      'https://stress-notificator-default-rtdb.asia-southeast1.firebasedatabase.app/data_stress.json';
  final String userDataUrl =
      'https://stress-notificator-default-rtdb.asia-southeast1.firebasedatabase.app/user_data';
  final String storageKey = 'tingkat_stres_data';

  Future<void> _saveDataLocally(Map<String, List<TingkatStres>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = json.encode({
      'latest': data['latest']?.map((e) => e.toJson()).toList(),
      'daily': data['daily']?.map((e) => e.toJson()).toList(),
      'weekly': data['weekly']?.map((e) => e.toJson()).toList(),
      'monthly': data['monthly']?.map((e) => e.toJson()).toList(),
    });
    await prefs.setString(storageKey, jsonData);
  }

  Stream<Map<String, List<TingkatStres>>> getCachedDataStream() async* {
    while (true) {
      final data = await getCachedData();
      yield data;
      await Future.delayed(Duration(seconds: 5));
    }
  }

  Future<Map<String, List<TingkatStres>>> getCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(storageKey);
    if (jsonString != null) {
      final data = json.decode(jsonString) as Map<String, dynamic>;
      return {
        'latest': _parseTingkatStresList(data['latest']),
        'daily': _parseTingkatStresList(data['daily']),
        'weekly': _parseTingkatStresList(data['weekly']),
        'monthly': _parseTingkatStresList(data['monthly']),
      };
    }
    return {};
  }

  List<TingkatStres> _parseTingkatStresList(dynamic jsonList) {
    if (jsonList is List) {
      return jsonList.map((json) => TingkatStres.fromJson(json)).toList();
    }
    return [];
  }

  Future<void> cacheData(Map<String, List<TingkatStres>> data) async {
    await _saveDataLocally(data);
  }

  Stream<Map<String, List<TingkatStres>>> getTingkatStresStream(
      {Duration interval = const Duration(minutes: 5)}) async* {
    while (true) {
      TingkatStres? tingkatStres = await getLatestTingkatStres();
      if (tingkatStres != null) {
        await _sendTingkatStresToDatabase(tingkatStres);

        final now = DateTime.now();
        DateTime start = now.subtract(Duration(days: 1));
        DateTime end = now;

        List<TingkatStres> latestHistory =
            await getTingkatStresHistoryByLatest(start, end);
        List<TingkatStres> dayHistory =
            await getTingkatStresHistoryByDay(start, end);
        List<TingkatStres> weekHistory =
            await getTingkatStresHistoryByWeek(start, end);
        List<TingkatStres> monthHistory =
            await getTingkatStresHistoryByMonth(start, end);

        final data = {
          'latest': latestHistory,
          'daily': dayHistory,
          'weekly': weekHistory,
          'monthly': monthHistory,
        };
        await _saveDataLocally(data); // Save data to local storage
        yield data;
      }
      await Future.delayed(interval);
    }
  }

  Future<TingkatStres?> getLatestTingkatStres() async {
    try {
      final response = await http.get(Uri.parse(databaseUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic>) {
          return _parseLatestTingkatStres(data);
        } else {
          print('Data is not in the expected format.');
        }
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
    return null;
  }

  TingkatStres? _parseLatestTingkatStres(Map<String, dynamic> data) {
    try {
      if (data.isNotEmpty) {
        final latestDataKey = data.keys.last;
        final latestDataJson = data[latestDataKey];
        if (latestDataJson is Map<String, dynamic>) {
          return TingkatStres.fromJson(latestDataJson);
        } else {
          print('Latest data is not in the expected format.');
        }
      } else {
        print('No data available.');
      }
    } catch (e) {
      print('Error parsing data: $e');
    }
    return null;
  }

  Future<void> _sendTingkatStresToDatabase(TingkatStres tingkatStres) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final emailKey = user.email!.replaceAll('.', ',');
      final url = '$userDataUrl/$emailKey.json';

      try {
        final response = await http.get(Uri.parse(url));

        Map<String, dynamic> data = {};
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData is Map<String, dynamic>) {
            data = responseData;
          } else if (responseData is List) {
            for (var i = 0; i < responseData.length; i++) {
              data[i.toString()] = responseData[i];
            }
          }

          int nextIndex = data.isEmpty
              ? 1
              : data.keys
                      .map((k) => int.tryParse(k) ?? 0)
                      .reduce((a, b) => a > b ? a : b) +
                  1;

          final now = DateTime.now();
          final formattedDate =
              "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          final formattedTime =
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

          data[nextIndex.toString()] = {
            'value': tingkatStres.value,
            'Tanggal': formattedDate,
            'Jam': formattedTime
          };

          final updateResponse = await http.put(Uri.parse(url),
              body: json.encode(data),
              headers: {"Content-Type": "application/json"});

          if (updateResponse.statusCode == 200) {
            print('Data successfully sent to the database');
          } else {
            print('Failed to update data: ${updateResponse.statusCode}');
          }
        } else {
          print('Failed to load user data: ${response.statusCode}');
        }
      } catch (e) {
        print('Error sending data to the database: $e');
      }
    }
  }

  Future<List<TingkatStres>> getTingkatStresHistoryByLatest(
      DateTime startDate, DateTime endDate) async {
    return _getTingkatStresHistory(startDate, endDate);
  }

  Future<List<TingkatStres>> getTingkatStresHistoryByDay(
      DateTime startDate, DateTime endDate) async {
    return _getTingkatStresHistory(startDate, endDate);
  }

  Future<List<TingkatStres>> getTingkatStresHistoryByWeek(
      DateTime startDate, DateTime endDate) async {
    return _getTingkatStresHistory(startDate, endDate);
  }

  Future<List<TingkatStres>> getTingkatStresHistoryByMonth(
      DateTime startDate, DateTime endDate) async {
    return _getTingkatStresHistory(startDate, endDate);
  }

  Future<List<TingkatStres>> _getTingkatStresHistory(
      DateTime startDate, DateTime endDate) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final emailKey = user.email!.replaceAll('.', ',');
      final url = '$userDataUrl/$emailKey.json';

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null) {
            List<TingkatStres> history = [];
            data.forEach((key, value) {
              if (value is Map<String, dynamic>) {
                TingkatStres stress = TingkatStres.fromJson(value);
                if (stress.tanggal.isAfter(startDate) &&
                    stress.tanggal.isBefore(endDate)) {
                  history.add(stress);
                }
              }
            });
            return history;
          }
        } else {
          print('Failed to load data: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching data: $e');
      }
    }
    return [];
  }
}
