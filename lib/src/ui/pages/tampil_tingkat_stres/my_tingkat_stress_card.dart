import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:stress_notificator/src/models/tingkat_stress.dart';
import 'package:stress_notificator/src/infra/health_repository.dart';

class MyTingkatStresCard extends StatefulWidget {
  const MyTingkatStresCard({super.key});

  @override
  _MyTingkatStresCardState createState() => _MyTingkatStresCardState();
}

class _MyTingkatStresCardState extends State<MyTingkatStresCard> {
  List<TingkatStres> _latestData = [];
  List<TingkatStres> _dailyData = [];
  List<TingkatStres> _weeklyData = [];
  List<TingkatStres> _monthlyData = [];
  bool _isLoading = true;
  final HealthRepository _healthRepository = HealthRepository();
  StreamSubscription<Map<String, List<TingkatStres>>>? _streamSubscription;
  String _selectedMode = 'Latest';

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
    _startListeningToStream();
  }

  Future<void> _fetchInitialData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DateTime now = DateTime.now();
      DateTime start;
      DateTime end;

      switch (_selectedMode) {
        case 'Latest':
          start = now.subtract(Duration(
              hours: now.hour, minutes: now.minute, seconds: now.second));
          end = now;
          try {
            final List<TingkatStres> fetchedData = await _healthRepository
                .getTingkatStresHistoryByLatest(start, end);
            _updateData({'latest': fetchedData});
          } catch (e) {
            print('Error fetching data: $e');
          }
          break;
        case 'Today':
          start = DateTime(now.year, now.month, now.day);
          end = DateTime(now.year, now.month, now.day + 1);
          try {
            final List<TingkatStres> fetchedData =
                await _healthRepository.getTingkatStresHistoryByDay(start, end);
            _updateData({'daily': fetchedData});
          } catch (e) {
            print('Error fetching Daily data: $e');
          }
          break;
        case 'Week':
          start = DateTime(now.year, now.month, now.day - now.weekday + 1);
          end = DateTime(now.year, now.month, now.day + (7 - now.weekday));
          try {
            final List<TingkatStres> fetchedData = await _healthRepository
                .getTingkatStresHistoryByWeek(start, end);
            _updateData({'weekly': fetchedData});
          } catch (e) {
            print('Error fetching Weekly data: $e');
          }
          break;
        case 'Month':
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0).add(Duration(days: 1));
          try {
            final List<TingkatStres> fetchedData = await _healthRepository
                .getTingkatStresHistoryByMonth(start, end);
            _updateData({'monthly': fetchedData});
          } catch (e) {
            print('Error fetching Monthly data: $e');
          }
          break;
        default:
          print('Invalid mode selected');
          setState(() {
            _isLoading = false;
          });
      }

      setState(() {
        _isLoading = false;
      });
    } else {
      print('No user is currently logged in.');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startListeningToStream() {
    _streamSubscription =
        _healthRepository.getCachedDataStream().listen((data) {
      if (data.containsKey(_selectedMode.toLowerCase())) {
        setState(() {
          _updateData(data);
        });
      }
    });
  }

  void _updateData(Map<String, List<TingkatStres>> data) {
    print('Mode: $_selectedMode');
    print('Data length: ${data[_selectedMode]?.length ?? 0}');

    switch (_selectedMode) {
      case 'Latest':
        _latestData = _calculateLatestData(data['latest'] ?? []);
        break;
      case 'Today':
        _dailyData = _calculateAveragePer1Hour(data['daily'] ?? []);
        break;
      case 'Week':
        _weeklyData = _calculateAverageForWeek(data['weekly'] ?? []);
        break;
      case 'Month':
        _monthlyData = _calculateAveragePerMonth(data['monthly'] ?? []);
        break;
    }

    print('Data after update: ${_getCurrentData()}');
  }

  List<TingkatStres> _calculateLatestData(List<TingkatStres> data) {
    // Memotong data agar hanya menyimpan 35 data terbaru
    if (data.length > 35) {
      return data.sublist(data.length - 35);
    }
    return data;
  }

  List<TingkatStres> _calculateAveragePer1Hour(List<TingkatStres> data) {
    Map<int, List<double>> oneHourlyData = {};
    for (var entry in data) {
      DateTime dateTime = entry.tanggal;
      int oneHourSlot = dateTime.hour ~/ 1;
      if (!oneHourlyData.containsKey(oneHourSlot)) {
        oneHourlyData[oneHourSlot] = [];
      }
      oneHourlyData[oneHourSlot]!.add(entry.value.toDouble());
    }

    return List.generate(24, (index) {
      List<double> values = oneHourlyData[index] ?? [];
      double average = 0.0;
      if (values.isNotEmpty) {
        average = values.reduce((a, b) => a + b) / values.length;
      }
      return TingkatStres(
        value: average.toInt(),
        tanggal: DateTime(DateTime.now().year, DateTime.now().month,
            DateTime.now().day, index * 1),
      );
    });
  }

  List<TingkatStres> _calculateAverageForWeek(List<TingkatStres> data) {
    DateTime now = DateTime.now();
    Map<int, List<double>> dailyData = {};

    // Hanya mengambil data dari 7 hari terakhir
    List<TingkatStres> last7DaysData = data.where((entry) {
      return entry.tanggal.isAfter(now.subtract(Duration(days: 7)));
    }).toList();

    for (var entry in last7DaysData) {
      int weekday = entry.tanggal.weekday;
      if (!dailyData.containsKey(weekday)) {
        dailyData[weekday] = [];
      }
      dailyData[weekday]!.add(entry.value.toDouble());
    }

    List<TingkatStres> result = [];
    for (int i = 1; i <= 7; i++) {
      List<double> values = dailyData[i] ?? [];
      double average = 0.0;
      if (values.isNotEmpty) {
        average = values.reduce((a, b) => a + b) / values.length;
      }

      DateTime date = now.subtract(Duration(days: now.weekday - i));
      result.add(TingkatStres(
        value: average.toInt(),
        tanggal: date,
      ));
    }

    return result;
  }

  List<TingkatStres> _calculateAveragePerMonth(List<TingkatStres> data) {
    Map<int, List<double>> dailyData = {};

    for (var entry in data) {
      int day = entry.tanggal.day;
      if (!dailyData.containsKey(day)) {
        dailyData[day] = [];
      }
      dailyData[day]!.add(entry.value.toDouble());
    }

    List<TingkatStres> dailyAverages = [];
    double totalSum = 0;
    int count = 0;

    for (int day = 1; day <= DateTime.now().day; day++) {
      List<double> values = dailyData[day] ?? [];
      double average = 0.0;
      if (values.isNotEmpty) {
        average = values.reduce((a, b) => a + b) / values.length;
      }

      if (average > 0) {
        totalSum += average;
        count++;
      }

      DateTime date = DateTime(DateTime.now().year, DateTime.now().month, day);

      dailyAverages.add(TingkatStres(
        value: average.toInt(),
        tanggal: date,
      ));
    }

    if (count > 0) {
      double monthlyAverage = totalSum / count;
      print('Average Stress Level for the Month: $monthlyAverage');
    } else {
      print('No valid stress data for the month.');
    }

    return dailyAverages;
  }

  List<TingkatStres> _getCurrentData() {
    switch (_selectedMode) {
      case 'Latest':
        return _latestData;
      case 'Today':
        return _dailyData;
      case 'Week':
        return _weeklyData;
      case 'Month':
        return _monthlyData;
      default:
        return [];
    }
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Card(
        margin: const EdgeInsets.all(15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: const BorderSide(
            color: Colors.teal,
            width: 2,
          ),
        ),
        color: const Color.fromARGB(255, 219, 225, 255),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tingkat Stres Anda',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedMode,
                    items: ['Latest', 'Today', 'Week', 'Month']
                        .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedMode = newValue!;
                        _fetchInitialData(); // Fetch data again based on the new mode
                      });
                    },
                  ),
                ],
              ),
              const Divider(
                color: Colors.grey,
                height: 25,
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Colors.teal,
                        ),
                      )
                    : _getCurrentData().isEmpty
                        ? const Center(
                            child: Text(
                              'No data available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        : _buildGraph(),
              ),
              const SizedBox(height: 20),
              if (_getCurrentData().isNotEmpty)
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getDisplayedValue(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getDisplayedText(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDisplayedValue() {
    final data = _getCurrentData();
    if (data.isNotEmpty) {
      switch (_selectedMode) {
        case 'Latest':
          return data.last.value
              .toString(); // Menampilkan nilai terakhir untuk mode Latest
        case 'Today':
        case 'Week':
        case 'Month':
          List<double> nonZeroValues = data
              .where((e) => e.value > 0)
              .map((e) => e.value.toDouble())
              .toList();
          if (nonZeroValues.isNotEmpty) {
            double sum = nonZeroValues.reduce((a, b) => a + b);
            double average = sum / nonZeroValues.length;
            return average.toStringAsFixed(
                0); // Mengembalikan nilai rata-rata dengan pembulatan
          }
          return '0';
        default:
          return '0';
      }
    }
    return '0';
  }

  String _getDisplayedText() {
    switch (_selectedMode) {
      case 'Latest':
        return 'Tingkat Stres Terakhir';
      case 'Today':
        return 'Rata-Rata Tingkat Stres Hari Ini';
      case 'Week':
        return 'Rata-Rata Tingkat Stres Minggu Ini';
      case 'Month':
        return 'Rata-Rata Tingkat Stres Bulan Ini';
      default:
        return '';
    }
  }

  Widget _buildGraph() {
    List<TingkatStres> data = _getCurrentData();
    double minX = 0;
    double maxX = (data.length - 1).toDouble();

    // Mengatur minX dan maxX untuk menampilkan data terbaru di sisi kanan
    if (_selectedMode == 'Latest') {
      minX = 0;
      maxX = (data.length - 1).toDouble();
    }

    return Container(
      width: double.infinity,
      height: 300,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width,
            maxWidth: MediaQuery.of(context).size.width * 2,
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 20,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      String time;
                      switch (_selectedMode) {
                        case 'Latest':
                        case 'Today':
                          time =
                              DateFormat('HH:mm').format(data[index].tanggal);
                          break;
                        case 'Week':
                          time = DateFormat('E')
                              .format(data[index].tanggal); // Hari dalam minggu
                          break;
                        case 'Month':
                          time = DateFormat('d')
                              .format(data[index].tanggal); // Hari dalam bulan
                          break;
                        default:
                          time = '';
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          time,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: false,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  bottom: BorderSide(color: Colors.black87),
                  left: BorderSide(color: Colors.black87),
                  right: BorderSide(color: Colors.transparent),
                  top: BorderSide(color: Colors.transparent),
                ),
              ),
              minX: minX,
              maxX: maxX,
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: data
                      .asMap()
                      .entries
                      .map((entry) => FlSpot(
                          entry.key.toDouble(), entry.value.value.toDouble()))
                      .toList(),
                  isCurved: true,
                  color: Colors.teal,
                  barWidth: 3,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.teal.withOpacity(0.3),
                  ),
                  dotData: FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
