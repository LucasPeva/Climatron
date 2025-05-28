import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(TemperatureControlApp());
}

class TemperatureControlApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Climatron',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
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

class _TemperatureHomePageState extends State<TemperatureHomePage> {
  final String backendUrl =
      'http://192.168.18.13:5000'; // Replace with your backend IP

  Map<String, dynamic>? latestData;
  List<dynamic> historyData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchLatestData();
    fetchHistoryData();
  }

  Future<void> fetchLatestData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(Uri.parse('$backendUrl/latest'));
      if (response.statusCode == 200) {
        setState(() {
          latestData = json.decode(response.body);
        });
      }
    } catch (e) {
      print('Error fetching latest data: $e');
    } finally {
      setState(() {
        isLoading = false;
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
      }
    } catch (e) {
      print('Erro buscando dados: $e');
    }
  }

  Widget buildLatestReading() {
    if (latestData == null) {
      return Text('Sem dados disponíveis', style: TextStyle(fontSize: 18));
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
              'Última leitura',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
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

  Widget buildHistoryList() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            padding: EdgeInsets.all(8),
            itemCount: historyData.length,
            separatorBuilder: (_, __) => Divider(),
            itemBuilder: (context, index) {
              var item = historyData[index];
              DateTime ts = DateTime.parse(item['timestamp']);
              String tsFormatted = '${ts.toLocal()}'.split('.')[0];
              return ListTile(
                leading: Icon(Icons.thermostat, color: Colors.deepPurple),
                title: Text(
                  'Temperatura: ${item['temperature'].toStringAsFixed(2)} °C, Umidade: ${item['humidity'].toStringAsFixed(2)} %',
                ),
                subtitle: Text('Data: $tsFormatted'),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> refreshData() async {
    await fetchLatestData();
    await fetchHistoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Climatron - Testes'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: refreshData,
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(height: 12),
          isLoading ? CircularProgressIndicator() : buildLatestReading(),
          SizedBox(height: 12),
          Text(
            'Histórico (Últimas 100 leituras)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          SizedBox(height: 8),
          buildHistoryList(),
        ],
      ),
    );
  }
}
