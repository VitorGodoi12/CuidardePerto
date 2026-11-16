import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/auth_gate.dart';
import 'services/dados_repository.dart';
import 'services/memory_repositories.dart';
import 'services/perfil_repository.dart';
import 'state/sessao.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sessao = Sessao(
    auth: AuthEmMemoria(),
    perfis: PerfisEmMemoria(),
    dados: DadosEmMemoria(),
  );
  await sessao.iniciar();
  runApp(CuidarDePertoApp(sessao: sessao));
}

class CuidarDePertoApp extends StatelessWidget {
  const CuidarDePertoApp({super.key, required this.sessao});

  final Sessao sessao;

  @override
  Widget build(BuildContext context) {
    return SessaoScope(
      sessao: sessao,
      child: MaterialApp(
        title: 'Cuidar de Perto',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.tema,
        locale: const Locale('pt', 'BR'),
        supportedLocales: const [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const AuthGate(),
      ),
    );
  }
}
