import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Paleta central da identidade visual Cuidar de Perto.
class AppColors {
  AppColors._();

  static const Color primaria = Color(0xFF078F91);
  static const Color primariaEscura = Color(0xFF006F73);
  static const Color turquesa = Color(0xFF20B8B2);
  static const Color menta = Color(0xFFBDEFE3);
  static const Color verdeSuave = Color(0xFFE6F8F4);
  static const Color fundo = Color(0xFFF5FAF9);
  static const Color cartao = Color(0xFFFFFFFF);
  static const Color laranja = Color(0xFFE8833A);
  static const Color laranjaSuave = Color(0xFFFFEDD5);
  static const Color laranjaTexto = Color(0xFF9A3412);
  static const Color texto = Color(0xFF172E32);
  static const Color textoSuave = Color(0xFF62777B);
  static const Color borda = Color(0xFFE2EEEB);
  static const Color neutroSuave = Color(0xFFF0F5F4);

  static const Color riscoBaixo = Color(0xFF16A36A);
  static const Color riscoMedio = Color(0xFFCA8A04);
  static const Color riscoAlto = Color(0xFFEA580C);
  static const Color riscoCritico = Color(0xFFDC2626);

  static const Color sucessoEscuro = Color(0xFF087A58);
  static const Color erroEscuro = Color(0xFFB91C1C);
}

class Espaco {
  Espaco._();
  static const double p = 8;
  static const double m = 16;
  static const double g = 24;
}

class AppTheme {
  AppTheme._();

  static ThemeData get tema {
    const esquema = ColorScheme.light(
      primary: AppColors.primaria,
      onPrimary: Colors.white,
      secondary: AppColors.turquesa,
      onSecondary: AppColors.texto,
      error: AppColors.riscoCritico,
      onError: Colors.white,
      surface: AppColors.cartao,
      onSurface: AppColors.texto,
    );

    final forma = RoundedRectangleBorder(borderRadius: BorderRadius.circular(17));

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: AppColors.fundo,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
      }),
      visualDensity: VisualDensity.standard,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 28, height: 1.12, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: AppColors.texto),
        headlineSmall: TextStyle(fontSize: 23, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -0.35, color: AppColors.texto),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.25, color: AppColors.texto),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.texto),
        bodyLarge: TextStyle(fontSize: 16, color: AppColors.texto),
        bodyMedium: TextStyle(fontSize: 15, height: 1.35, color: AppColors.texto),
        bodySmall: TextStyle(fontSize: 13, color: AppColors.textoSuave),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.texto,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.texto),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaria,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: forma,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primariaEscura,
          minimumSize: const Size(88, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          side: const BorderSide(color: AppColors.primaria, width: 1.2),
          shape: forma,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primariaEscura,
          minimumSize: const Size(64, 44),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
        hintStyle: const TextStyle(fontSize: 15, color: AppColors.textoSuave),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borda)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.borda)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primaria, width: 1.7)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        contentTextStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
        shape: forma,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaria,
        linearTrackColor: AppColors.verdeSuave,
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: AppColors.primaria, width: 1.4),
      ),
    );
  }

  static InputDecoration campo({
    required String rotulo,
    String? dica,
    IconData? icone,
    Widget? sufixo,
  }) {
    OutlineInputBorder bordaCampo(Color cor, double largura) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cor, width: largura),
        );
    return InputDecoration(
      labelText: rotulo,
      hintText: dica,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primariaEscura),
      hintStyle: const TextStyle(fontSize: 15, color: AppColors.textoSuave),
      prefixIcon: icone == null ? null : Icon(icone, color: AppColors.primaria, size: 21),
      suffixIcon: sufixo,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
      border: bordaCampo(AppColors.borda, 1),
      enabledBorder: bordaCampo(AppColors.borda, 1),
      focusedBorder: bordaCampo(AppColors.primaria, 1.8),
      errorBorder: bordaCampo(AppColors.erroEscuro, 1.4),
      focusedErrorBorder: bordaCampo(AppColors.erroEscuro, 1.8),
      errorStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.erroEscuro),
    );
  }
}

/// Campo de formulário no estilo das telas de acesso: ícone à esquerda e
/// rótulo dentro do campo que sobe ao digitar (como na referência visual).
InputDecoration campoAcesso({
  required String rotulo,
  required IconData icone,
  Widget? sufixo,
  String? dica,
}) {
  OutlineInputBorder borda(Color cor, double largura) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: cor, width: largura),
      );
  return InputDecoration(
    labelText: rotulo,
    hintText: dica,
    labelStyle: const TextStyle(fontSize: 15, color: AppColors.textoSuave),
    floatingLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primariaEscura),
    hintStyle: const TextStyle(fontSize: 14, color: AppColors.textoSuave),
    prefixIcon: Icon(icone, color: AppColors.primaria, size: 22),
    suffixIcon: sufixo,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    border: borda(AppColors.borda, 1),
    enabledBorder: borda(AppColors.borda, 1),
    focusedBorder: borda(AppColors.primaria, 1.8),
    errorBorder: borda(AppColors.erroEscuro, 1.4),
    focusedErrorBorder: borda(AppColors.erroEscuro, 1.8),
    errorStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.erroEscuro),
    errorMaxLines: 2,
  );
}

class Cartao extends StatelessWidget {
  const Cartao({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Espaco.m),
    this.corFundo = Colors.white,
    this.corBorda = AppColors.borda,
    this.larguraBorda = 1,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color corFundo;
  final Color corBorda;
  final double larguraBorda;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: corFundo,
      elevation: 1,
      shadowColor: const Color(0x160B5C59),
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(21),
        side: BorderSide(color: corBorda, width: larguraBorda),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class Mensagens {
  Mensagens._();

  static void sucesso(BuildContext context, String texto) =>
      _mostrar(context, texto, AppColors.sucessoEscuro, Icons.check_circle);

  static void erro(BuildContext context, String texto) =>
      _mostrar(context, texto, AppColors.erroEscuro, Icons.error);

  static void info(BuildContext context, String texto) =>
      _mostrar(context, texto, AppColors.primariaEscura, Icons.info);

  static void _mostrar(BuildContext context, String texto, Color cor, IconData icone) {
    final mensageiro = ScaffoldMessenger.of(context);
    mensageiro.hideCurrentSnackBar();
    mensageiro.showSnackBar(
      SnackBar(
        backgroundColor: cor,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icone, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(texto)),
          ],
        ),
      ),
    );
  }
}
