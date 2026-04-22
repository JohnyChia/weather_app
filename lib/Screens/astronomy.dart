import 'package:flutter/material.dart';
import 'package:weather_app/Utils/translator.dart';
import 'package:weather_app/models/hourly_data.dart';
import 'solar.dart';
import 'package:fl_chart/fl_chart.dart';

enum AstronomyView { sun, moon }

class AstronomyScreen extends StatefulWidget {
  final String sunrise;
  final String sunset;
  final String noon;
  final String moonPhase;
  final double uvIndex;
  final List<HourlyData>? hourlyUV;

  const AstronomyScreen({
    super.key,
    required this.sunrise,
    required this.sunset,
    required this.noon,
    required this.moonPhase,
    required this.uvIndex,
    this.hourlyUV,
  });

  @override
  State<AstronomyScreen> createState() => _AstronomyScreenState();
}

class _AstronomyScreenState extends State<AstronomyScreen> {
  AstronomyView _selectedView = AstronomyView.sun;

  @override
  Widget build(BuildContext context) {
    final isSunSelected = _selectedView == AstronomyView.sun;

    return Scaffold(
      appBar: AppBar(
        title: const AutoText('Astronomy'),
        backgroundColor: isSunSelected ? Colors.white : const Color(0xFF0C1428),
        foregroundColor: isSunSelected ? Colors.black87 : Colors.white,
        elevation: 0,
      ),
      backgroundColor: isSunSelected ? Colors.white : const Color(0xFF0C1428),
      body: Column(
        children: [
          _buildSelector(),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSelectedView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelector() {
    final isSunSelected = _selectedView == AstronomyView.sun;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: isSunSelected ? Colors.grey.shade200 : Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: .center,
        children: [
          _buildSelectorOption(AstronomyView.sun, 'Sunset/Sunrise'),
          _buildSelectorOption(AstronomyView.moon, 'Moon Phase'),
        ],
      ),
    );
  }

  Widget _buildSelectorOption(AstronomyView view, String title) {
    final isSelected = _selectedView == view;
    final isSunView = _selectedView == AstronomyView.sun;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedView = view;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected
                ? (isSunView ? Colors.white : Colors.blueGrey.shade700)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected && isSunView
                ? [
              const BoxShadow(
                  color: Colors.black, blurRadius: 5, spreadRadius: 1)
            ]
                : [],
          ),
          child: Center(
            child: AutoText(
              title,
              style: TextStyle(
                color: isSunView ? Colors.black87 : Colors.white,
                fontWeight: isSelected ? .bold : .normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedView() {
    switch (_selectedView) {
      case AstronomyView.sun:
        return _buildSunView();
      case AstronomyView.moon:
        return _buildMoonView();
    }
  }

  Widget _buildSunView() {
    DateTime? parseTimeSafeManual(String timeStr) {
      try {
        String cleaned = timeStr.replaceAll(
          RegExp(r'[\u0000-\u0020\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]'),
          '',
        ).toUpperCase();

        final match = RegExp(r'^(\d{1,2}):(\d{2})(AM|PM)$').firstMatch(cleaned);
        if (match == null) return null;

        int hour = int.parse(match.group(1)!);
        int minute = int.parse(match.group(2)!);
        String period = match.group(3)!;

        if (period == 'PM' && hour != 12) hour += 12;
        if (period == 'AM' && hour == 12) hour = 0;

        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, hour, minute);

        return dt;
      } catch (e) {
        throw Exception("Manual Parse Error: $e for '$timeStr'");
      }
    }

    String getDaylightDuration(String sunrise, String sunset) {
      final sunriseTime = parseTimeSafeManual(sunrise);
      final sunsetTime = parseTimeSafeManual(sunset);

      if (sunriseTime != null && sunsetTime != null) {
        var duration = sunsetTime.difference(sunriseTime);
        if (duration.isNegative) {
          duration += const Duration(days: 1);
        }
        final hours = duration.inHours;
        final minutes = duration.inMinutes % 60;
        return '$hours hours $minutes minutes';
      }

      return 'XX hours XX minutes';
    }

    final daylightDuration = getDaylightDuration(widget.sunrise, widget.sunset);

    String uvLevel = '';
    String solarRecommendation = 'No data available';

    final uv = widget.uvIndex;

    if (uv <= 2) {
      uvLevel = 'Low';
      solarRecommendation = 'Not ideal for solar energy';
    } else if (uv <= 5) {
      uvLevel = 'Moderate';
      solarRecommendation = 'Moderate solar performance';
    } else if (uv <= 7) {
      uvLevel = 'High';
      solarRecommendation = 'Good time for solar energy';
    } else if (uv <= 10) {
      uvLevel = 'Very High';
      solarRecommendation = 'Excellent solar energy potential';
    } else {
      uvLevel = 'Extreme';
      solarRecommendation = 'Maximum solar intensity';
    }

    return Column(
      children: [
        _buildSunInfoCard(
          title: 'Sunrise',
          time: widget.sunrise,
          icon: Icons.wb_sunny_outlined,
          gradientColors: [Colors.orange.shade100, Colors.yellow.shade200],
        ),
        const SizedBox(height: 12),
        _buildSunInfoCard(
          title: 'Sunset',
          time: widget.sunset,
          icon: Icons.nightlight_outlined,
          gradientColors: [Colors.purple.shade100, Colors.pink.shade100],
        ),
        const SizedBox(height: 12),
        _buildDaylightCard(
            'DAYLIGHT DURATION', daylightDuration, Icons.hourglass_bottom),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2A47),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              const AutoText(
                'Peak Sun Range',
                style: TextStyle(
                  fontWeight: .bold,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 32,
                          getTitlesWidget: (value, meta) {
                            if ((value - 0.1).abs() < 0.01) {
                              return AutoText(
                                  widget.sunrise,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12
                                  )
                              );
                            }
                            if ((value - 0.5).abs() < 0.01) {
                              return AutoText(widget.noon.isNotEmpty
                                  ? widget.noon
                                  : '--:--',
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12
                                  )
                              );
                            }
                            if ((value - 0.9).abs() < 0.01) {
                              return AutoText(
                                  widget.sunset,
                                  style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12
                                  )
                              );
                            }
                            return const AutoText('');
                          },
                        ),
                      ),
                    ),
                    minX: 0,
                    maxX: 1,
                    minY: 0,
                    maxY: 100,
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0.1, 0),
                          FlSpot(0.5, 100),
                          FlSpot(0.9, 0),
                        ],
                        isCurved: true,
                        barWidth: 3,
                        color: Colors.orange,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>
                  SolarScreen(
                    hourlyUV: widget.hourlyUV,
                    currentUV: widget.uvIndex,
                  )),
            );
          },

          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2A47),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                AutoText(
                  'UV INDEX: ${widget.uvIndex.toStringAsFixed(1)} ($uvLevel)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                AutoText(
                  'Solar Recommendation: $solarRecommendation',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMoonView() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2A47),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          const AutoText(
              'Current Phase',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          AutoText(
            widget.moonPhase.isNotEmpty ? widget.moonPhase : 'Waxing Crescent',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: .bold
            ),
          ),
          const Row(
            children: [
              Icon(
                  Icons.brightness_6_outlined,
                  color: Colors.white70,
                  size: 16),
              SizedBox(width: 4),
            ],
          ),
          const Divider(color: Colors.white24, height: 30),
          Center(
            child: Icon(
                Icons.nightlight_round,
                size: 80,
                color: Colors.yellow.shade100
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunInfoCard({
    required String title,
    required String time,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              AutoText(
                  title.toUpperCase(),
                  style: const TextStyle(
                      fontWeight: .bold, color: Colors.black54)),
            ],
          ),
          AutoText(time.isNotEmpty ? time : '',
              style: const TextStyle(
                  fontSize: 36, fontWeight: .w300, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildDaylightCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.black54),
          const SizedBox(width: 8),

          AutoText(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.black54,
            ),
          ),

          const Spacer(),

          AutoText(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}