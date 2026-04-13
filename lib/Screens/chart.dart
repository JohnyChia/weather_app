import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/hourly_data.dart';
import 'weather_screen.dart';

enum ChartView {
  dailyForecast,
  multidaysForecast,
  hourlyForecast,
  hourlyIndexForecast
}

class ChartScreen extends StatefulWidget {
  final List<HourlyData> hourlyData;
  final List<HourlyData> multiDays;

  const ChartScreen({
    super.key,
    required this.hourlyData,
    required this.multiDays,
  });

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  ChartView _selectedView = ChartView.dailyForecast;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Chart'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          _buildSelector(),
          const SizedBox(height: 20),
          Expanded(child: _buildChart()),
        ],
      ),
    );
  }

  // ================= SELECTOR =================
  Widget _buildSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _buildSelectorOption(ChartView.dailyForecast, 'Daily Weather'),
          _buildSelectorOption(ChartView.multidaysForecast, '5 Days'),
          _buildSelectorOption(ChartView.hourlyIndexForecast, 'UV Index'),
        ],
      ),
    );
  }

  Widget _buildSelectorOption(ChartView view, String title) {
    final isSelected = _selectedView == view;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedView = view),
        child: Container(
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= LINE CHART =================
  Widget _buildChart() {
    if (_selectedView == ChartView.multidaysForecast) {
      return _buildMultiDays();
    }

    if (_selectedView == ChartView.hourlyIndexForecast) {
      return _buildUVChart();
    }

    if (widget.hourlyData.isEmpty) {
      return const Center(child: Text("No data", style: TextStyle(color: Colors.black)));
    }

    List<String> xLabels = [];
    List<double> temp = [];
    List<double> hum = [];

    String today = widget.hourlyData.first.weatherDate;

    for (var d in widget.hourlyData) {
      if (d.weatherDate == today) {
        xLabels.add(d.time);
        temp.add(d.temp);
        hum.add(d.humidity.toDouble());
      }
    }

    if (xLabels.isEmpty) {
      return const Center(child: Text("No data", style: TextStyle(color: Colors.black)));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: xLabels.length * 100,
          height: 600,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: xLabels.length.toDouble() - 1,
              minY: 0,
              maxY: 100,

              gridData: FlGridData(
                show: true,
                horizontalInterval: 10,
              ),

              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      int i = value.toInt();
                      if (i < 0 || i >= xLabels.length) {
                        return const SizedBox();
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          xLabels[i],
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: 10,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(
                    temp.length,
                        (i) => FlSpot(i.toDouble(), temp[i]),
                  ),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                ),
                LineChartBarData(
                  spots: List.generate(
                    hum.length,
                        (i) => FlSpot(i.toDouble(), hum[i]),
                  ),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= MULTI DAYS =================
  Widget _buildMultiDays() {
    if (widget.multiDays.isEmpty) {
      return const Center(child: Text("No data"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.multiDays.length,
      itemBuilder: (context, i) {
        final d = widget.multiDays[i];
        final icon = getWeatherIcon(d.condition);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Image.asset(icon, width: 50, height: 50),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.weatherDate, style: const TextStyle(color: Colors.black)),
                  Text("${d.temp.round()}°C", style: const TextStyle(color: Colors.black)),
                  Text("Humidity: ${d.humidity}%", style: const TextStyle(color: Colors.black)),
                  Text(d.condition, style: const TextStyle(color: Colors.black)),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // ================= UV CHART =================
  Widget _buildUVChart() {
    final today = widget.hourlyData.first.weatherDate;
    final data = widget.hourlyData.where((e) => e.weatherDate == today).toList();

    if (data.isEmpty) {
      return const Center(child: Text("No UV data", style: TextStyle(color: Colors.black)));
    }

    final maxUV = data.map((e) => e.uvIndex).reduce((a, b) => a > b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: data.length * 50,
          height: 300,
          child: BarChart(
            BarChartData(
              maxY: maxUV + 2,
              minY: 0,

              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
              ),

              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      int i = value.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox();
                      return Text(
                        data[i].weatherTime,
                        style: const TextStyle(color: Colors.black, fontSize: 10),
                      );
                    },
                  ),
                ),

                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(color: Colors.black),
                      );
                    },
                  ),
                ),
              ),

              barGroups: List.generate(data.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data[i].uvIndex,
                      color: Colors.orange,
                      width: 10,
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}