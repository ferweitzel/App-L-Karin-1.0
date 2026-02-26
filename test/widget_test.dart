// Test básico para la app Ley Karin - Canal de Denuncias.

import 'package:flutter_test/flutter_test.dart';

import 'package:ley_karin_app/main.dart';

void main() {
  testWidgets('App Ley Karin inicia y muestra el formulario de denuncia',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LeyKarinApp());

    // Verificar que se muestra el título del canal de denuncias
    expect(find.text('Canal de Denuncias Seguro'), findsWidgets);
    expect(find.text('Ley 21.643'), findsWidgets);

    // Verificar que existe el botón Enviar
    expect(find.text('Enviar'), findsOneWidget);

    // Verificar que existe el campo de relato (label)
    expect(find.text('Relato de Hechos'), findsOneWidget);
  });
}
