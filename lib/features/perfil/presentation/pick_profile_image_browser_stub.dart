import 'dart:typed_data';

/// Apenas compilado em plataformas sem `dart:html`; não deve ser chamado se
/// `kIsWeb` estiver correto no chamador.
Future<({Uint8List bytes, String filename})?> pickProfileImageInBrowser() async =>
    null;

/// Sem canvas nativo: devolve os bytes sem alterar.
Future<Uint8List> shrinkProfileImageBytesForWeb(Uint8List raw) async => raw;
