import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/models/hourly_data.dart';

class SolarScreen extends StatelessWidget {
  final List<HourlyData>? hourlyUV;

  const SolarScreen(
      {Key? key, this.hourlyUV}
      ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 初始化变量
    String startTime = '--:--';
    String endTime = '--:--';
    int displayScore = 0;
    double scorePercentage = 0;
    String description = '';

    if (hourlyUV != null && hourlyUV!.isNotEmpty) {
      double maxUV =
      hourlyUV!.map((e) => e.uvIndex).reduce((a, b) => a > b ? a : b);
      scorePercentage = (maxUV / 12.0).clamp(0.0, 1.0);
      displayScore = (scorePercentage * 100).toInt();

      // 按时间排序
      hourlyUV!.sort((a, b) {
        DateTime t1 = DateFormat("HH:mm").parse(a.weatherTime);
        DateTime t2 = DateFormat("HH:mm").parse(b.weatherTime);
        return t1.compareTo(t2);
      });

      String startRow = '';
      String endRow = '';
      bool inPeak = false;

      for (var data in hourlyUV!) {
        if (data.uvIndex >= (maxUV * 0.8)) {
          if (!inPeak) {
            startRow = data.weatherTime;
            inPeak = true;
          }
          endRow = data.weatherTime;
        }
      }

      if (startRow.isEmpty) startRow = hourlyUV!.first.weatherTime;
      if (endRow.isEmpty) endRow = hourlyUV!.last.weatherTime;

      String formatTime(String timeStr) {
        try {
          DateTime tempDate = DateFormat("HH:mm").parse(timeStr);
          return DateFormat("h:mm a").format(tempDate);
        } catch (e) {
          return timeStr;
        }
      }

      startTime = formatTime(startRow);
      endTime = formatTime(endRow);

      if (displayScore >= 70) {
        description = "Excellent conditions for solar energy.";
      } else if (displayScore >= 40) {
        description = "Good conditions for solar energy.";
      } else {
        description = "Low solar energy potential currently.";
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Solar Energy'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSolarInfoCard(
              title: 'Peak Period Start',
              time: startTime != '--:--'
                  ? DateFormat('h:mm a').parse(startTime)
                  : null,
              icon: Icons.wb_sunny_outlined,
              gradientColors: [Colors.orange.shade100, Colors.yellow.shade200],
            ),
            const SizedBox(height: 12),
            _buildSolarInfoCard(
              title: 'Peak Period End',
              time: endTime != '--:--'
                  ? DateFormat('h:mm a').parse(endTime)
                  : null,
              icon: Icons.nightlight_outlined,
              gradientColors: [Colors.purple.shade100, Colors.pink.shade100],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2A47),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Solar Energy Score',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 显示太阳能评分
                  Row(
                    children: [
                      Text(
                        '$displayScore%',
                        style:
                        const TextStyle(fontSize: 45, color: Colors.orange),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: scorePercentage,
                              backgroundColor: Colors.white12,
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(10),
                              minHeight: 10,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Time: $startTime - $endTime',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolarInfoCard({
    required String title,
    required DateTime? time,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    final formattedTime =
    time != null ? DateFormat('h:mm a').format(time.toLocal()) : '--:--';
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradientColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 20, color: Colors.black54),
            const SizedBox(width: 8),
            Text(title.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ))
          ]),
          Text(formattedTime,
              style: const TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w300, color: Colors.black87)),
        ],
      ),
    );
  }
}