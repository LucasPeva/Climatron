import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(TemperatureControlApp());
}

class TemperatureControlApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Climatron',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TemperatureHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TemperatureHomePage extends StatefulWidget {
  @override
  _TemperatureHomePageState createState() => _TemperatureHomePageState();
}

class _TemperatureHomePageState extends State<TemperatureHomePage>
    with SingleTickerProviderStateMixin {
  final String backendUrl = 'http://192.168.18.13:5000'; // IP do backend

  Map<String, dynamic>? latestData;
  List<dynamic> historyData = [];
  List<dynamic> averagesData = [];
  bool isLoadingLatest = false;
  bool isLoadingAverages = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchLatestData();
    fetchHistoryData();
    fetchAveragesData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchLatestData() async {
    setState(() {
      isLoadingLatest = true;
    });
    try {
      final response = await http.get(Uri.parse('$backendUrl/latest'));
      if (response.statusCode == 200) {
        setState(() {
          latestData = json.decode(response.body);
        });
      } else {
        print('Falha ao buscar dados mais recentes: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar dados mais recentes: $e');
    } finally {
      setState(() {
        isLoadingLatest = false;
      });
    }
  }

  Future<void> fetchHistoryData() async {
    try {
      final response = await http.get(Uri.parse('$backendUrl/history'));
      if (response.statusCode == 200) {
        setState(() {
          historyData = json.decode(response.body);
        });
      } else {
        print('Falha ao buscar dados históricos: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar dados históricos: $e');
    }
  }

  // Novo método para obter médias diárias da nova rota "/averages"
  Future<void> fetchAveragesData() async {
    setState(() {
      isLoadingAverages = true;
    });
    try {
      final response = await http.get(Uri.parse('$backendUrl/averages'));
      if (response.statusCode == 200) {
        setState(() {
          averagesData = json.decode(response.body);
        });
      } else {
        print('Falha ao buscar médias diárias: ${response.statusCode}');
      }
    } catch (e) {
      print('Erro ao buscar médias diárias: $e');
    } finally {
      setState(() {
        isLoadingAverages = false;
      });
    }
  }

  // Widget do card de leitura mais recente
  Widget buildLatestReading() {
    if (latestData == null) {
      return Center(
        child: Text('Nenhum dado disponível', style: TextStyle(fontSize: 18)),
      );
    }

    DateTime timestamp = DateTime.parse(latestData!['timestamp']);
    String formattedTime = '${timestamp.toLocal()}'.split('.')[0];

    return Card(
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Leitura Mais Recente',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.red[900],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Data: $formattedTime',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            SizedBox(height: 8),
            Text(
              'Temperatura: ${latestData!['temperature'].toStringAsFixed(2)} °C',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              'Umidade: ${latestData!['humidity'].toStringAsFixed(2)} %',
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  // Widget da lista do histórico
  Widget buildHistoryList() {
    if (historyData.isEmpty) {
      return Center(child: Text('Nenhum dado histórico disponível.'));
    }
    return ListView.separated(
      padding: EdgeInsets.all(8),
      itemCount: historyData.length,
      separatorBuilder: (_, __) => Divider(),
      itemBuilder: (context, index) {
        var item = historyData[index];
        DateTime ts = DateTime.parse(item['timestamp']);
        String tsFormatted = '${ts.toLocal()}'.split('.')[0];
        return ListTile(
          leading: Icon(Icons.thermostat, color: Colors.black45),
          title: Text(
            'Temp: ${item['temperature'].toStringAsFixed(2)} °C, Umidade: ${item['humidity'].toStringAsFixed(2)} %',
          ),
          subtitle: Text('Data: $tsFormatted'),
        );
      },
    );
  }

  // Widget do gráfico
  Widget buildBarChart() {
    if (averagesData.isEmpty) {
      if (isLoadingAverages) {
        return Center(child: CircularProgressIndicator());
      }
      return Center(child: Text('Nenhum dado para exibir.'));
    }

    List<BarChartGroupData> barGroups = [];
    List<String> dayLabels = [];

    for (int i = 0; i < averagesData.length; i++) {
      var entry = averagesData[i];
      String day = entry['date'];
      double avgTemp = (entry['avg_temperature'] as num).toDouble();
      double avgHum = (entry['avg_humidity'] as num).toDouble();

      dayLabels.add(day);

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(toY: avgTemp, color: Colors.redAccent),
            BarChartRodData(toY: avgHum, color: Colors.lightBlueAccent),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          backgroundColor: Colors.grey[200],
          barGroups: barGroups,
          minY: 0,
          maxY: 100,
        ),
      ),
    );
  }

  Future<void> refreshData() async {
    await fetchLatestData();
    await fetchHistoryData();
    await fetchAveragesData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Climatron - FINAL'),
        centerTitle: true,
        bottom: TabBar(
          labelColor: Colors.red,
          indicatorColor: Colors.redAccent,
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.home), text: "Atual"),
            Tab(icon: Icon(Icons.bar_chart), text: "Média Diária"),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: refreshData,
            tooltip: 'Atualizar Dados',
          ),
        ],
      ),
      body: Container(
        child: TabBarView(
          controller: _tabController,
          children: [
            // Aba 0: Dados atuais + lista de histórico
            Column(
              children: [
                SizedBox(height: 12),
                isLoadingLatest
                    ? CircularProgressIndicator()
                    : buildLatestReading(),
                SizedBox(height: 12),
                Text(
                  'Histórico (Últimas 100 leituras)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 8),
                Expanded(child: buildHistoryList()),
              ],
            ),
            // Aba 1: Gráfico de barras com médias diárias vindas da rota /averages
            buildBarChart(),
          ],
        ),
      ),
    );
  }
}
