# Cuidar de Perto

> **Quem você ama, por perto, mesmo de longe.**

Protótipo mobile em **Flutter/Dart** que permite a familiares e cuidadores acompanharem, em segundos, se está tudo bem com idosos que moram sozinhos. Projeto da Global Solution 2026/2 (CitizenTech, FIAP), disciplina **Mobile Application Development**.

Os sensores (IoT), a API e o banco de dados pertencem a outras disciplinas e são **simulados dentro do app** com dados em memória.

## Cidadão beneficiado e ODS

- **Cidadão:** pessoas idosas que moram sozinhas e quem cuida delas à distância (filhos, vizinhos e cuidadores profissionais).
- **ODS 3** - Saúde e Bem-Estar.
- **ODS 10** - Redução das Desigualdades.

## Identidade visual e telas

A interface segue a referência visual turquesa e verde-menta: abertura em degradê, logo coração-casa, telas claras com cartões arredondados, avatares ilustrados, ícones em círculos suaves e navegação inferior com botão central de ações rápidas. Laranja indica atenção e vermelho fica reservado a emergências.

## Telas e funcionalidades

| Nº | Tela | O que faz |
|----|------|-----------|
| 1 | Login e cadastro | Entrada e criação de perfil demonstrativas, com validação de campos |
| 2 | Painel | Saudação, atalhos para idosos/medicamentos/agenda/perfil, resumo do dia e alertas |
| 3 | Meus Idosos | Lista de pessoas acompanhadas e cadastro de novos idosos |
| 4 | Detalhe do idoso | Situação atual e atalhos (Medicamentos, Histórico, Contatos, Simular evento) |
| 5 | Medicamentos | Marcar dose como tomada, progresso do dia, destaque de atraso |
| 6 | Cadastro de medicamento | Formulário validado (nome, dosagem, horário, observações) |
| 7 | Histórico de alertas | Linha do tempo com filtro por nível e ação de resolver |
| 8 | Contatos de emergência | Contato principal, ligação simulada e SAMU 192 |
| 9 | Alerta crítico | Resposta simulada a queda ou botão de pânico |
| 10 | Agenda e central de cuidado | Calendário mensal selecionável, consultas, rotina, hidratação, check-in, humor, diário, recados, equipe, relatório e acessibilidade |
| 11 | Lembretes | Lista de doses pendentes e tela de lembrete com opção para marcar como tomada |
| 12 | Mais e Meu Perfil | Preferências demonstrativas, contatos, alertas, dados do cuidador e saída da conta |

**Capturas de tela:** `[PREENCHER: adicionar imagens em docs/ após rodar no emulador]`

### Fluxo de navegação

`Boas-vindas → Login/Cadastro → Painel → Detalhe → (Medicamentos → Cadastro | Histórico | Contatos | Alerta crítico → Contatos)`. A navegação inferior oferece Início, Idosos, botão central de ações rápidas, Agenda e Mais. Medicamentos, lembretes e alertas também ficam nos atalhos do painel e em Mais.

- O Login abre o Painel com `pushReplacement`; "Sair" faz o caminho inverso após um `AlertDialog`.
- Parâmetros por construtor: `Idoso` (Painel → Detalhe → telas de medicamentos, histórico e contatos), `Alerta` (Detalhe → Alerta crítico), `nomeCuidador` (Login → Painel).
- Valores de retorno com `Navigator.pop`: `Medicamento` (Cadastro → Medicamentos) e `bool` resolvido (Alerta crítico → Detalhe).
- Em toda tela aberta com `await Navigator.push(...)`, ao voltar o app chama `setState()`.

### Regra de risco (calculada, nunca fixa)

| Nível | Condição |
|-------|----------|
| Crítico | Alerta de queda ou pânico em aberto |
| Alto | 6 h ou mais sem movimento, ou 2 ou mais doses atrasadas |
| Médio | 3 h ou mais sem movimento, ou 1 dose atrasada |
| Baixo | Nenhuma das anteriores |

A **hora simulada é fixa em 14:00**: dose não tomada com horário anterior a isso aparece como "Atrasado". O risco crítico não existe nos dados iniciais; aparece ao simular uma queda ou o botão de pânico.

## Como executar

**Requisitos para Android:** Flutter 3.50 ou superior (Dart 3), JDK 17, VS Code ou Android Studio, Android SDK Platforms 35 e 36, Android SDK Build-Tools 36.0.0, NDK 28.2.13676358 e CMake 3.22.1. No Android Studio, instale as plataformas em **Tools → SDK Manager → SDK Platforms** e os demais componentes na aba **SDK Tools**. O SDK/Gradle local (`android/local.properties`, `android/.gradle`, `build/`) não é versionado; cada máquina instala seus próprios componentes.

```bash
git clone https://github.com/VitorGodoi12/CuidardePerto.git
cd cuidar_de_perto

flutter pub get
flutter analyze
flutter test
flutter run
flutter build apk --release
```

O APK de release é gerado em `build/app/outputs/flutter-apk/app-release.apk`.

**Acesso demonstrativo:** crie uma conta na tela de cadastro. As contas e os dados existem apenas durante a execução atual do app; use dados fictícios.

**Roteiro rápido de demonstração:**
1. Login com campos vazios, senha curta e senha errada; depois o login correto.
2. Painel → Dona Maria → Medicamentos: marque doses e veja o contador e a barra mudarem.
3. "Novo medicamento": envie vazio, use horário `25:70`, preencha corretamente.
4. Detalhe → Simular evento → Queda → Ver contatos → Marcar como resolvido.
5. Painel: risco atualizado. Histórico: filtros Todos, Crítico, Alto e Médio.

## Estrutura

```
lib/
  main.dart               ponto de entrada e MaterialApp
  theme/app_theme.dart    cores, tipografia, cartão padrão e mensagens
  models/                 idoso, medicamento, alerta, contato
  data/mock_data.dart     dados simulados e hora simulada
  screens/                boas-vindas, login, painel, idosos, medicamentos, agenda, lembretes, alertas e demais fluxos
  widgets/                risco_badge, idoso_card, alerta_card, aparecer
assets/images/            logo, foto de abertura do mockup e avatares
test/widget_test.dart     testes de risco, login, medicamentos e cadastro
```

## Decisões técnicas

- **Somente SDK do Flutter**: sem Provider, Bloc, GetX, `intl` ou `url_launcher` (fora do escopo das aulas). Estado com `StatefulWidget` e `setState()`.
- **Navegação** com `Navigator.push` e `MaterialPageRoute` (rotas nomeadas não são usadas).
- **Acessibilidade:** textos de 16 a 18 sp, botões com no mínimo 48 dp, rótulos permanentes nos campos, ícones sempre com texto, risco indicado por cor, ícone e texto, e animações desligadas quando o sistema pede "reduzir movimento".
- **Cores de risco** preservam os valores oficiais; o texto dos selos usa tons mais escuros do mesmo matiz para garantir contraste.
- O horário do cadastro aceita `8:30` e salva como `08:30`.
- Fundo claro `#F5FAF9`, cartões brancos e identidade turquesa `#078F91` / verde-petróleo `#006F73`.

## Declaração de uso de IA generativa

`[CONFERIR E AJUSTAR conforme o uso real do grupo]`

- **Ferramenta:** Claude (Anthropic).
- **Para quê:** leitura e síntese dos documentos de escopo, geração do código Dart/Flutter, dos testes, deste README e do script que gerou as imagens ilustrativas (logo, ilustração do login e avatares).
- **Revisão:** o grupo revisou o código, executou o app e é responsável por explicá-lo na apresentação.

## Limitações do protótipo

Sem sensores reais, API, banco de dados, notificações, GPS, câmera, login real ou ligações telefônicas. Tudo é simulado e os dados voltam ao estado inicial ao reiniciar o app.

## Integrantes e entrega

- Grupo: `[PREENCHER]`
- Integrantes: `[PREENCHER]`
- Vídeo (YouTube, não listado): `[PREENCHER]`

## Atualização visual e navegação
- Identidade visual com o símbolo coração-casa do projeto (`assets/images/logo.png`).
- Navegação inferior principal: Início, Idosos, botão central de ações rápidas, Agenda e Mais.
- Medicamentos, lembretes, alertas e contatos são acessíveis pelos atalhos da tela inicial, por Mais e pelo detalhe de cada idoso.
- O perfil apresenta os dados demonstrativos do cuidador e a opção de sair.
- Todo o conteúdo continua sendo um protótipo local com dados simulados em memória.


## Central de cuidado (novas funcionalidades)

A navegação principal agora inclui a aba **Agenda**, que abre a Central de cuidado. Nela há recursos demonstrativos para: rotina diária (refeições e atividade), contador de hidratação, check-in diário, registro de humor, agenda de consultas e exames, diário de cuidados, mural de recados, equipe de apoio, plano de emergência, linha do tempo/histórico de alterações, central informativa de notificações, relatório resumido e opções de acessibilidade (texto maior e alto contraste).

### Limitações do protótipo

Os novos registros são mantidos em memória durante a execução do app. Ao encerrar o aplicativo, eles são reiniciados. A equipe de cuidado é uma lista demonstrativa, sem contas individuais, sincronização ou permissões reais. Notificações são avisos internos demonstrativos; não há push em segundo plano. O relatório é um resumo na tela, sem exportação de arquivo. Para persistência, compartilhamento real e notificações do sistema será necessária uma etapa futura com banco de dados/backend e permissões apropriadas.


## Atualização de interface e acompanhamento
- Tela inicial de boas-vindas separada das telas de entrar e cadastrar.
- Login redesenhado sem ilustrações de pessoas.
- Painel inicial com cabeçalho em degradê e indicadores resumidos.
- Cadastro de novas pessoas acompanhadas na área **Idosos**.
- Seletor de pessoa independente nas áreas **Medicamentos** e **Agenda**.
- Títulos de medicamentos e agenda identificam a pessoa selecionada.
- Dados continuam em memória, pois esta versão usa dados simulados e ainda não possui integração com banco de dados.


## Atualização visual implementada

A versão atual aplica o padrão visual da referência nas telas de boas-vindas, login, painel, lista de idosos, medicamentos, agenda, perfil, área Mais e lembretes. O calendário permite navegar entre meses e selecionar dias; a agenda mantém os fluxos demonstrativos de rotina, hidratação, check-in, humor, consultas, diário, recados, equipe, plano de emergência, relatório e acessibilidade. O botão central da navegação abre ações rápidas para cadastrar idosos, acessar medicamentos, abrir a agenda e consultar lembretes.

**Limitações mantidas:** login, cadastros, alertas e lembretes são locais/demonstrativos. Não há backend, sincronização, autenticação real, ligações automáticas, sensores reais nem notificações push/em segundo plano. Os registros não são persistidos após encerrar o aplicativo.


## Autenticação demonstrativa e dados locais

O login e o cadastro são simulados no próprio aplicativo. As contas e os dados ficam em memória e são apagados quando o app é encerrado. Não há autenticação real, sincronização ou persistência. Use dados fictícios e não informe senhas reais.

Na tela de entrar há uma conta de demonstração pronta, com e-mail e senha preenchidos. Também é possível consultar e preencher as credenciais pelo cartão **Acesso de demonstração**. Essa conta inclui um perfil fictício e a pessoa acompanhada Dona Maria; não pertence a um cuidador real.

