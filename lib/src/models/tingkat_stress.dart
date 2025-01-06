import 'package:intl/intl.dart';

class TingkatStres {
  final int value;
  final DateTime tanggal;

  TingkatStres({
    required this.value,
    required this.tanggal,
  });

  factory TingkatStres.fromJson(Map<String, dynamic> json) {
    DateTime? tanggal;

    try {
      if (json['Tanggal'] != null && json['Jam'] != null) {
        tanggal = DateFormat('yyyy-MM-dd HH:mm:ss')
            .parse('${json['Tanggal']} ${json['Jam']}');
      } else {
        print('Missing Tanggal or Jam in JSON data: $json');
      }
    } catch (e) {
      print('Error parsing date and time: $e');
    }

    return TingkatStres(
      value: json['value']?.toInt() ?? 0,
      tanggal: tanggal ??
          DateTime.now(), // Default to current date and time if parsing fails
    );
  }

  Map<String, dynamic> toJson() {
    final formattedDate = DateFormat('yyyy-MM-dd').format(tanggal);
    final formattedTime = DateFormat('HH:mm:ss').format(tanggal);

    return {
      'value': value,
      'Tanggal': formattedDate,
      'Jam': formattedTime,
    };
  }
}
