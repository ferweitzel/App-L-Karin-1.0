import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// Para el registro de localización en español
import 'package:intl/date_symbol_data_local.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

void main() async {
  // Aseguramos que los widgets estén inicializados
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializamos las fechas en español para que no de error el DateFormat
  await initializeDateFormatting('es_CL', null);
  runApp(const LeyKarinApp());
}

class LeyKarinApp extends StatelessWidget {
  const LeyKarinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canal de Denuncias Seguro - Ley Karin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF1A237E),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1A237E),
          primary: const Color(0xFF1A237E),
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A237E),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const DenunciaScreen(),
    );
  }
}

class DenunciaScreen extends StatefulWidget {
  const DenunciaScreen({super.key});

  @override
  State<DenunciaScreen> createState() => _DenunciaScreenState();
}

class _DenunciaScreenState extends State<DenunciaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _relatoController = TextEditingController();

  bool _denunciaAnonima = false;
  String? _tipoAcoso;
  bool _aceptaDeclaracion = false;

  final List<String> _tiposAcoso = ['Laboral', 'Sexual', 'Violencia'];

  @override
  void dispose() {
    _nombreController.dispose();
    _relatoController.dispose();
    super.dispose();
  }

  String _generarFolio() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(9999).toString().padLeft(4, '0');
    return 'LK-${timestamp.toString().substring(7)}-$randomNum';
  }

  Future<void> _enviarDenuncia() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_aceptaDeclaracion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe aceptar la declaración bajo fe de juramento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final folio = _generarFolio();
    final fechaHora = DateTime.now();

    try {
      final pdfBytes = await _generarPDF(
        folio: folio,
        fechaHora: fechaHora,
        relato: _relatoController.text,
      );

      if (!mounted) return;

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FolioScreen(
            folio: folio,
            pdfBytes: pdfBytes,
            tipoAcoso: _tipoAcoso ?? '',
            fechaHora: fechaHora,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<Uint8List> _generarPDF({
    required String folio,
    required DateTime fechaHora,
    required String relato,
  }) async {
    final pdf = pw.Document();
    final fechaFormateada = DateFormat(
      'dd/MM/yyyy HH:mm:ss',
      'es_CL',
    ).format(fechaHora);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Comprobante de Denuncia Ley Karin',
              style: pw.TextStyle(
                fontSize: 20,
                color: PdfColors.blue900,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Folio: $folio',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
          ),
          pw.Text('Fecha: $fechaFormateada'),
          pw.Divider(),
          pw.Text(
            'Relato de los hechos:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Text(relato),
        ],
      ),
    );

    return pdf.save();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ley Karin - Canal Seguro')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: !_denunciaAnonima,
              ),
              SwitchListTile(
                title: const Text('Denuncia Anónima'),
                value: _denunciaAnonima,
                onChanged: (v) => setState(() {
                  _denunciaAnonima = v;
                  if (v) _nombreController.clear();
                }),
              ),
              // LÍNEA 205 CORREGIDA:
              DropdownButtonFormField<String>(
                initialValue: _tiposAcoso.contains(_tipoAcoso)
                    ? _tipoAcoso
                    : null,
                items: _tiposAcoso
                    .map(
                      (String t) =>
                          DropdownMenuItem<String>(value: t, child: Text(t)),
                    )
                    .toList(),
                onChanged: (String? v) => setState(() => _tipoAcoso = v),
                decoration: const InputDecoration(
                  labelText: 'Tipo de Acoso',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null ? 'Seleccione un tipo' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _relatoController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Relato de Hechos',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'El relato es obligatorio' : null,
              ),
              CheckboxListTile(
                title: const Text('Declaro la veracidad de los hechos'),
                value: _aceptaDeclaracion,
                onChanged: (v) =>
                    setState(() => _aceptaDeclaracion = v ?? false),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _enviarDenuncia,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('ENVIAR DENUNCIA Y GENERAR PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FolioScreen extends StatelessWidget {
  final String folio;
  final Uint8List pdfBytes;
  final String tipoAcoso;
  final DateTime fechaHora;

  const FolioScreen({
    super.key,
    required this.folio,
    required this.pdfBytes,
    required this.tipoAcoso,
    required this.fechaHora,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            Text(
              'Folio: $folio',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () =>
                  Printing.layoutPdf(onLayout: (format) async => pdfBytes),
              icon: const Icon(Icons.print),
              label: const Text('Imprimir Comprobante'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.of(context).popToRoot(), // Ajustar según navegación
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}

extension on NavigatorState {
  void popToRoot() {}
}
