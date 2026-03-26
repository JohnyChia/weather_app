import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/hourly_data.dart';
import 'weather_screen.dart';

enum ChartView { dailyForecast, multidaysForecast, hourlyForecast, hourlyIndexForecast }

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

  Widget _buildSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.grey,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildSelectorOption(ChartView.dailyForecast, 'Daily Weather Forecast'),
          _buildSelectorOption(ChartView.multidaysForecast, 'Multi 5-days Forecast'),
          _buildSelectorOption(ChartView.hourlyIndexForecast, 'Hourly UV Index Forecast'),

        ],
      ),
    );
  }

  Widget _buildSelectorOption(ChartView view, String title) {
    final isSelected = _selectedView == view;
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

  Widget _buildChart() {
    if (_selectedView == ChartView.multidaysForecast) {
      return _buildMultiDaysForecast();
    }

    if (_selectedView == ChartView.hourlyIndexForecast) {
      return _buildDailyUVChart();
    }

    List<String> xLabels = [];
    List<double> temperature = [];
    List<double> humidity = [];

    String today = widget.hourlyData.first.weatherDate;
    for (var data in widget.hourlyData) {
      if (data.weatherDate == today) {
        xLabels.add(data.weatherTime);
        temperature.add(data.temp);
        humidity.add(data.humidity.toDouble());
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: xLabels.length * 100,
        height: 400,
        child: LineChart(
          LineChartData(
            minY: 10,
            maxY: 80,
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index < 0 || index >= xLabels.length) return const SizedBox();
                    return Text(
                      xLabels[index],
                      style: const TextStyle(fontSize: 13, color: Colors.black),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    );
                  },
                ),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    );
                  },
                ),
              ),
            ),

            lineTouchData: LineTouchData(
              enabled: true,
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    int index = spot.spotIndex.toInt();
                    String label = xLabels[index];
                    double temp = temperature[index];
                    double hum = humidity[index];
                    return LineTooltipItem(
                      '$label\nTemperature: $temp°C\nHumidity: $hum%',
                      const TextStyle(color: Colors.black),
                    );
                  }).toList();
                },
              ),
            ),

            lineBarsData: [
              LineChartBarData(
                spots: List.generate(
                  temperature.length,
                      (i) => FlSpot(i.toDouble(), temperature[i]),
                ),
                isCurved: true,
                color: Colors.red,
                barWidth: 4,
              ),
              LineChartBarData(
                spots: List.generate(
                  humidity.length,
                      (i) => FlSpot(i.toDouble(), humidity[i]),
                ),
                isCurved: true,
                color: Colors.blue,
                barWidth: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiDaysForecast() {
    if (widget.multiDays.isEmpty) {
      return const Center(
        child: Text('No data', style: TextStyle(color: Colors.black)),
      );
    }

    final first5Days = widget.multiDays.take(5).toList();

    return SingleChildScrollView(
      child: Column(
        children: first5Days.map((day) {
          final icon = getWeatherIcon(day.condition);

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 16),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Image.asset(
                    icon,
                    width: 50,
                    height: 50
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(day.weatherDate,
                        style: const TextStyle(
                            color: Colors.black
                        )
                    ),
                    Text('${day.temp.round()}°C',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold
                        )
                    ),
                    Text('Humidity: ${day.humidity}%',
                        style: const TextStyle(
                            color: Colors.black
                        )
                    ),
                    Text('Condition: ${day.condition}',
                        style: const TextStyle(
                            color: Colors.black
                        )
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDailyUVChart() {
    final today = widget.hourlyData.first.weatherDate;
    final todayData = widget.hourlyData.where((d) => d.weatherDate == today).toList();

    if (todayData.isEmpty) {
      return const Center(child: Text('No UV data', style: TextStyle(color: Colors.black)));
    }

    final maxUV = todayData.map((d) => d.uvIndex).reduce((a, b) => a > b ? a : b);
    final maxY = (maxUV > 0 ? (maxUV + 1) : 1).toDouble();

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= todayData.length) {
                    return const SizedBox();
                  }
                  return Text(
                    todayData[index].weatherTime,
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(
                    showTitles: false
                )
            ),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(
                    showTitles: false
                )
            ),
          ),
          barGroups: List.generate(todayData.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: todayData[i].uvIndex,
                  color: Colors.orange,
                  width: 12,
                ),
              ],
            );
          }),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }
}



