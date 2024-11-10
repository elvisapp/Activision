import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart'; // Paquete syncfusion para gráficos
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ActiVision',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark, // Oscurecer el tema
      ),
      home: AssetInputScreen(),
      debugShowCheckedModeBanner: false, // Quitar el banner de depuración
    );
  }
}

class AssetInputScreen extends StatefulWidget {
  const AssetInputScreen({Key? key}) : super(key: key);

  @override
  _AssetInputScreenState createState() => _AssetInputScreenState();
}

class _AssetInputScreenState extends State<AssetInputScreen> {
  final TextEditingController _controller = TextEditingController();
  String _assetInfo = '';
  final String _apiKey =
      'de961aab575e6717a452904dee5a3701'; // Reemplaza con tu clave API de Marketstack
  List<ChartSampleData> _chartData = [];

  // Función para buscar la información del activo
  void _fetchAssetInfo(String assetName) async {
    try {
      final response = await http.get(Uri.parse(
          'https://api.marketstack.com/v1/eod?access_key=$_apiKey&symbols=$assetName'));
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        if (responseData != null &&
            responseData['data'] != null &&
            responseData['data'].isNotEmpty) {
          final quote = responseData['data'][0];
          final trend = _calculateTrend(responseData['data']);
          final economicCalendar = await _fetchEconomicCalendar(assetName);
          setState(() {
            _assetInfo = 'Asset: $assetName\n'
                'Open: ${quote['open'] ?? 'N/A'}\n'
                'High: ${quote['high'] ?? 'N/A'}\n'
                'Low: ${quote['low'] ?? 'N/A'}\n'
                'Price: ${quote['close'] ?? 'N/A'}';
            _assetInfo +=
                '\n\nResumen Geopolítico: Este activo está influenciado por eventos geopolíticos globales, como tensiones internacionales y políticas comerciales. Tendencia a 5 días: $trend\n'
                'Análisis Económico: $economicCalendar';
            // Generar datos del gráfico
            _chartData = _generateChartData(responseData['data']);
          });
        } else {
          setState(() {
            _assetInfo = 'No data available for $assetName';
          });
        }
      } else {
        setState(() {
          _assetInfo = 'Error fetching data for $assetName';
        });
      }
    } catch (e) {
      setState(() {
        _assetInfo = 'Error: ${e.toString()}';
      });
    }
  }

  // Función para calcular la tendencia
  String _calculateTrend(List<dynamic> data) {
    double startPrice = data.first['close'];
    double endPrice = data.last['close'];
    if (endPrice > startPrice) {
      return 'Al alza';
    } else if (endPrice < startPrice) {
      return 'A la baja';
    } else {
      return 'Estable';
    }
  }

  // Función para obtener el calendario económico
  Future<String> _fetchEconomicCalendar(String assetName) async {
    try {
      final response = await http.get(Uri.parse(
          'https://data.forexfactory.com/calendar.json?font=s&uid=&hash=&资产管理公司=$assetName'));
      if (response.statusCode == 200) {
        return 'Eventos recientes incluyen anuncios de políticas y datos económicos importantes que podrían influir en el precio del activo.';
      } else {
        return 'Error fetching economic calendar data';
      }
    } catch (e) {
      return 'Error: ${e.toString()}';
    }
  }

  // Función para generar datos del gráfico de velas
  List<ChartSampleData> _generateChartData(List<dynamic> data) {
    List<ChartSampleData> chartData = [];
    for (var entry in data) {
      chartData.add(ChartSampleData(
          x: DateTime.parse(entry['date']),
          open: entry['open'],
          high: entry['high'],
          low: entry['low'],
          close: entry['close']));
    }
    return chartData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black, // Fondo negro en AppBar
        title: Center(
          // Centrar el título
          child: const Text('ActiVision'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Nombre del Activo',
                labelStyle: const TextStyle(
                    color: Colors.amberAccent), // Texto en amarillo
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amberAccent),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amberAccent),
                ),
              ),
              style: const TextStyle(
                  color: Colors.amberAccent), // Texto del input en amarillo
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amberAccent, // Botón amarillo
                foregroundColor: Colors.black, // Texto negro en el botón
              ),
              onPressed: () {
                _fetchAssetInfo(_controller.text);
              },
              child: const Text('Buscar'),
            ),
            const SizedBox(height: 20),
            Text(
              _assetInfo,
              style: const TextStyle(
                  color: Colors.amberAccent), // Texto en amarillo oro
            ),
            Expanded(
              child: SfCartesianChart(
                backgroundColor: Colors.black, // Fondo negro del gráfico
                primaryXAxis: DateTimeAxis(
                  labelStyle: const TextStyle(
                      color: Colors.amberAccent), // Ejes en amarillo oro
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: const TextStyle(
                      color: Colors.amberAccent), // Ejes en amarillo oro
                ),
                series: <CandleSeries>[
                  CandleSeries<ChartSampleData, DateTime>(
                    dataSource: _chartData,
                    xValueMapper: (ChartSampleData data, _) => data.x,
                    lowValueMapper: (ChartSampleData data, _) => data.low,
                    highValueMapper: (ChartSampleData data, _) => data.high,
                    openValueMapper: (ChartSampleData data, _) => data.open,
                    closeValueMapper: (ChartSampleData data, _) => data.close,
                    bullColor: Colors.green, // Velas verdes para subidas
                    bearColor: Colors.red, // Velas rojas para bajadas
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Clase modelo para los datos del gráfico
class ChartSampleData {
  final DateTime x;
  final double open;
  final double high;
  final double low;
  final double close;

  ChartSampleData({
    required this.x,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}
