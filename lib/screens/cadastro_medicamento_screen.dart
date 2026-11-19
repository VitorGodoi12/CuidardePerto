import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/idoso.dart';
import '../models/medicamento.dart';
import '../theme/app_theme.dart';

class CadastroMedicamentoScreen extends StatefulWidget {
  const CadastroMedicamentoScreen({super.key, required this.idoso});

  final Idoso idoso;

  @override
  State<CadastroMedicamentoScreen> createState() => _CadastroMedicamentoScreenState();
}

class _CadastroMedicamentoScreenState extends State<CadastroMedicamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _doseController = TextEditingController();
  final _horarioController = TextEditingController();
  final _observacaoController = TextEditingController();

  AutovalidateMode _modoValidacao = AutovalidateMode.disabled;

  static final RegExp _formatoHorario = RegExp(r'^([01]?\d|2[0-3]):?([0-5]\d)$');

  @override
  void dispose() {
    _nomeController.dispose();
    _doseController.dispose();
    _horarioController.dispose();
    _observacaoController.dispose();
    super.dispose();
  }

  String? _validarNome(String? valor) {
    if ((valor ?? '').trim().length < 2) return 'Informe o nome do medicamento';
    return null;
  }

  String? _validarDose(String? valor) {
    if ((valor ?? '').trim().isEmpty) return 'Informe a dose (ex.: 50 mg)';
    return null;
  }

  String? _validarHorario(String? valor) {
    if (!_formatoHorario.hasMatch((valor ?? '').trim())) return 'Horário inválido. Ex.: 0830 ou 08:30';
    return null;
  }

  String? _validarObservacao(String? valor) {
    if ((valor ?? '').trim().length > 80) return 'Máximo de 80 caracteres';
    return null;
  }

  String _normalizarHorario(String texto) {
    final horario = _formatoHorario.firstMatch(texto.trim())!;
    return '${horario[1]!.padLeft(2, '0')}:${horario[2]}';
  }

  void _salvar() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      setState(() => _modoValidacao = AutovalidateMode.onUserInteraction);
      return;
    }

    final novo = Medicamento(
      nome: _nomeController.text.trim(),
      dose: _doseController.text.trim(),
      horario: _normalizarHorario(_horarioController.text),
      observacao: _observacaoController.text.trim(),
    );

    Mensagens.sucesso(context, 'Medicamento salvo');
    Navigator.pop(context, novo);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo medicamento')),
      body: Form(
        key: _formKey,
        autovalidateMode: _modoValidacao,
        child: ListView(
          padding: const EdgeInsets.all(Espaco.m),
          children: [
            Text('Para: ${widget.idoso.nome}', style: tema.titleMedium),
            const SizedBox(height: 4),
            Text('Campos com * são obrigatórios.', style: tema.bodySmall),
            const SizedBox(height: Espaco.g),
            TextFormField(
              controller: _nomeController,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 18),
              decoration: AppTheme.campo(
                rotulo: 'Nome do medicamento *',
                dica: 'Ex.: Losartana',
                icone: Icons.medication,
              ),
              validator: _validarNome,
            ),
            const SizedBox(height: Espaco.m),
            TextFormField(
              controller: _doseController,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 18),
              decoration: AppTheme.campo(
                rotulo: 'Dosagem *',
                dica: 'Ex.: 50 mg',
                icone: Icons.scale,
              ),
              validator: _validarDose,
            ),
            const SizedBox(height: Espaco.m),
            TextFormField(
              controller: _horarioController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')),
                LengthLimitingTextInputFormatter(5),
              ],
              style: const TextStyle(fontSize: 18),
              decoration: AppTheme.campo(
                rotulo: 'Horário *',
                dica: 'Digite 0830 para salvar 08:30',
                icone: Icons.schedule,
              ),
              validator: _validarHorario,
            ),
            const SizedBox(height: Espaco.m),
            TextFormField(
              controller: _observacaoController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.sentences,
              minLines: 2,
              maxLines: 3,
              style: const TextStyle(fontSize: 18),
              decoration: AppTheme.campo(
                rotulo: 'Observações (opcional)',
                dica: 'Ex.: Tomar com água',
                icone: Icons.notes,
              ),
              validator: _validarObservacao,
            ),
            const SizedBox(height: Espaco.g),
            ElevatedButton.icon(
              onPressed: _salvar,
              icon: const Icon(Icons.save),
              label: const Text('Salvar medicamento'),
            ),
          ],
        ),
      ),
    );
  }
}
