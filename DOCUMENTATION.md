# Stopwatch App - Documentacao Tecnica

## Visao Geral

Aplicativo Flutter de cronometro com relogio analogico animado, display digital e controles de start/pause/reset. Usa arquitetura em camadas com Riverpod para gerenciamento de estado.

---

## Estrutura de Arquivos

```
lib/
├── presentation/
│   ├── main.dart                    # Ponto de entrada
│   └── views/
│       ├── home_view.dart           # Tela principal (3 widgets)
│       └── about_view.dart          # Tela sobre (2 widgets)
├── data/
│   └── stopwatch_provider.dart      # Providers + servico do cronometro
└── widgets/
    └── animated_stopwatch.dart      # Relogio analogico (widget + painter)

test/
└── widget_test.dart                 # Smoke tests
```

---

## 1. `lib/presentation/main.dart`: Ponto de Entrada

### O que faz
Configura o app inteiro: tema, modo escuro, e injeta o sistema de providers do Riverpod.

> Este arquivo esta em `lib/presentation/`, e nao no `lib/main.dart` padrao. Por isso o app
> precisa ser executado com `flutter run -t lib/presentation/main.dart`.

### Linha por linha

| Linhas | O que faz |
|--------|-----------|
| 6-7 | `ProviderScope` envolve todo o app: e o que permite que qualquer widget acesse os providers do Riverpod |
| 8-9 | `debugShowCheckedModeBanner: false` remove o banner "DEBUG" do canto superior direito |
| 10 | `themeMode: ThemeMode.dark` forca tema escuro como padrao |
| 11-14 | Tema claro: usa `colorSchemeSeed` com roxo `#6C63FF` para gerar toda a paleta Material 3 automaticamente |
| 15-19 | Tema escuro: mesma seed de cor, mas com `Brightness.dark`, e o Material 3 gera tons escuros complementares |
| 21 | `HomeView` e a tela inicial do app |

### Decisao de design
`colorSchemeSeed` em vez de definir cores manualmente: o Material 3 gera ~30 tons harmoniosos (primary, secondary, surface, error, etc.) a partir de uma unica cor.

---

## 2. `lib/data/stopwatch_provider.dart`: Estado e Logica

### O que faz
Contem toda a logica do cronometro e o estado reativo. E o "cerebro" do app.

### Providers (linhas 4-5)

| Provider | Tipo | Valor inicial | Proposito |
|----------|------|---------------|-----------|
| `stopwatchProvider` | `StateProvider<bool>` | `false` | Indica se o cronometro esta rodando |
| `elapsedProvider` | `StateProvider<Duration>` | `Duration.zero` | Tempo decorrido atual |

Qualquer widget que fizer `ref.watch(stopwatchProvider)` vai automaticamente reconstruir quando o valor mudar.

### `stopwatchServiceProvider` (linhas 7-11)

Provider que cria e gerencia o ciclo de vida do `StopwatchService`. O `ref.onDispose` garante que o timer e cancelado se o provider for descartado (ex: hot restart).

### Classe `StopwatchService` (linhas 13-49)

Encapsula o `Stopwatch` nativo do Dart e um `Timer` periodico.

#### Campos

| Campo | Tipo | Proposito |
|-------|------|-----------|
| `_ref` | `Ref` | Referencia ao container do Riverpod para ler/escrever providers |
| `_stopwatch` | `Stopwatch` | Cronometro nativo do Dart (mede tempo real do sistema) |
| `_timer` | `Timer?` | Timer periodico que atualiza o provider a cada 16ms (~60fps) |

#### Metodo `start()` (linhas 20-27)

1. `_stopwatch.start()`: inicia/retoma a medicao de tempo
2. Seta `stopwatchProvider` para `true` (UI muda o botao para pause)
3. `_timer?.cancel()`: cancela timer anterior se existir (previne duplicacao)
4. Cria `Timer.periodic` de 16ms que le `_stopwatch.elapsed` e escreve no `elapsedProvider`

**Por que 16ms?** Equivale a ~60fps. Atualizar mais rapido (1ms) desperdicaria CPU sem beneficio visual, ja que a tela atualiza a 60hz.

#### Metodo `stop()` (linhas 29-35)

1. `_stopwatch.stop()`: pausa a medicao (o valor de `elapsed` congela)
2. Seta `stopwatchProvider` para `false`
3. Cancela o timer e seta para `null`
4. Faz uma ultima escrita do `elapsed` para garantir que a UI mostra o valor exato no momento da pausa

#### Metodo `reset()` (linhas 37-43)

1. `_stopwatch.reset()`: zera o cronometro interno
2. Seta `stopwatchProvider` para `false`
3. Cancela o timer
4. Escreve `Duration.zero` no `elapsedProvider`

#### Metodo `dispose()` (linhas 45-48)

Chamado pelo `ref.onDispose` do provider. Cancela o timer e para o stopwatch. Previne leak de memoria.

### Fluxo de dados

```
Usuario aperta Start
    → service.start()
        → _stopwatch.start()
        → stopwatchProvider = true     → UI mostra botao Pause
        → Timer.periodic(16ms)
            → elapsedProvider = elapsed → UI atualiza display + relogio
```

---

## 3. `lib/presentation/views/home_view.dart`: Tela Principal

### O que faz
Tela principal do app. Composta por 3 widgets: `HomeView`, `TimerDisplay`, e `ButtonRow`.

---

### Widget `HomeView` (linhas 7-70)

`ConsumerWidget`: tipo especial do Riverpod que da acesso a `ref` no `build()`.

#### Providers observados (linhas 12-14)

| Variavel | Provider | Reage a |
|----------|----------|---------|
| `isOn` | `stopwatchProvider` | Mudanca de running/parado |
| `elapsed` | `elapsedProvider` | Cada tick de 16ms |
| `service` | `stopwatchServiceProvider` | Apenas leitura (instancia unica) |

#### Layout (de cima pra baixo)

| Posicao | Widget | Proposito |
|---------|--------|-----------|
| Topo | `Row` com `Text` + `IconButton` | Titulo "Stopwatch" e botao info (abre AboutView) |
| `Spacer(flex: 1)` | - | Empurra o conteudo pra baixo proporcionalmente |
| Centro | `AnimatedStopwatch` | Relogio analogico |
| `SizedBox(height: 32)` | - | Espacamento fixo |
| Centro | `TimerDisplay` | Display digital |
| `Spacer(flex: 2)` | - | Empurra botoes pro fundo (2x mais espaco que o spacer de cima) |
| Fundo | `ButtonRow` dentro de `Padding(bottom: 64)` | Botoes de acao |

#### Navegacao (linhas 36-41)
`Navigator.push` com `MaterialPageRoute`: navegacao padrao do Flutter com animacao de slide da direita.

#### Callbacks dos botoes (linhas 55-63)
- `onStartPause`: chama `service.stop()` se rodando, `service.start()` se parado
- `onReset`: sempre chama `service.reset()`; o service cuida de parar o timer e zerar o estado

---

### Widget `TimerDisplay` (linhas 73-110)

`StatelessWidget` puro: recebe `Duration`, formata, e renderiza.

#### Formatacao (linhas 80-83)

| Variavel | Calculo | Exemplo |
|----------|---------|---------|
| `hours` | `elapsed.inHours` | `01` |
| `minutes` | `elapsed.inMinutes % 60` | `23` |
| `seconds` | `elapsed.inSeconds % 60` | `45` |
| `millis` | `elapsed.inMilliseconds % 1000 ~/ 10` | `67` |

Todos usam `.padLeft(2, '0')` para garantir dois digitos (`5` → `05`).

**`~/ 10` nos milissegundos:** divisao inteira por 10 converte milissegundos (0-999) para centesimos (0-99).

#### Visual
- `HH:MM:SS` em `displayMedium` (fonte grande, peso leve, monospace)
- `.cs` em `headlineMedium` com cor `primary` (roxo), tamanho menor, alinhado pela baseline

---

### Widget `ButtonRow` (linhas 113-180)

`StatelessWidget` que renderiza os botoes de acao.

#### Parametros

| Parametro | Tipo | Uso |
|-----------|------|-----|
| `isOn` | `bool` | Determina icone e cor do botao principal |
| `hasElapsed` | `bool` | Controla visibilidade do botao reset |
| `onStartPause` | `VoidCallback` | Acao do botao principal |
| `onReset` | `VoidCallback` | Acao do botao reset |

#### Layout com Stack (linhas 131-178)

`SizedBox(height: 88)` → `Stack(alignment: center)`:

1. **Botao Reset**: `Align(centerLeft)` com `AnimatedOpacity`:
   - Opacidade 0 quando `hasElapsed == false` (invisivel no inicio)
   - Opacidade 1 quando ha tempo decorrido (aparece com fade de 200ms)
   - `onPressed: null` quando invisivel (impede taps acidentais)
   - `FilledButton.tonal`: estilo secundario do Material 3
   - Circular (`CircleBorder`), 72x72

2. **Botao Start/Pause**: centralizado pelo `Stack`:
   - Verde (primary) quando parado, vermelho (error) quando rodando
   - Icone alterna entre `play_arrow_rounded` e `pause_rounded`
   - Circular, 88x88 (maior que o reset)

---

## 4. `lib/presentation/views/about_view.dart`: Tela Sobre

### O que faz
Pagina informativa com detalhes do app e desenvolvedor.

---

### Widget `AboutView` (linhas 5-90)

`StatelessWidget` com `Scaffold` + `AppBar`.

#### Layout (de cima pra baixo)

| Widget | Conteudo |
|--------|----------|
| `AppBar` | Titulo "About" centralizado, botao voltar automatico |
| `AnimatedStopwatch` | Relogio estatico (elapsed: Duration() = 00:00:00) como decoracao |
| `Text` | "Stopwatch" em `headlineMedium` bold |
| `Text` | "v 2.1" em `bodyLarge` com cor primary |
| `Text` | "Developed by" em cor 60% opacidade (hierarquia visual) |
| `TextButton` | "github.com/azevedo1z" sublinhado, abre o perfil no navegador via `url_launcher` |
| `Row` | Tres `_VersionChip` lado a lado |

#### Metodo `_openGithub` (linhas 77-89)

Abre `https://github.com/azevedo1z` no navegador do sistema via `launchUrl` com
`LaunchMode.externalApplication`. Se o launcher nao conseguir resolver o link, mostra um
`SnackBar` de erro. O `ScaffoldMessengerState` e capturado antes do `await`, porque usar o
`BuildContext` depois de um `await` em `StatelessWidget` e inseguro (nao ha `mounted`).

---

### Widget `_VersionChip` (linhas 92-117)

Widget privado (prefixo `_`): so e usado dentro de `about_view.dart`.

- `Container` com `padding` horizontal/vertical
- `BoxDecoration` com `surfaceContainerHighest` (tom sutil do tema) e cantos arredondados (20px)
- Mostra texto no formato `v1: 07/2023`

---

## 5. `lib/widgets/animated_stopwatch.dart`: Relogio Analogico

### O que faz
Desenha um relogio analogico com mostrador, marcas de minuto, e tres ponteiros que se movem suavemente baseados no tempo decorrido.

---

### Widget `AnimatedStopwatch` (linhas 4-26)

`StatelessWidget`: recebe `Duration elapsed` e passa para o painter junto com as cores do tema.

`SizedBox(260x260)` define o tamanho fixo do relogio. O `CustomPaint` delega todo o desenho para `StopwatchPainter`.

---

### Classe `StopwatchPainter` (linhas 28-130)

`CustomPainter`: desenha diretamente no `Canvas`. Chamado toda vez que `shouldRepaint` retorna `true` (quando `elapsed` muda).

#### Parametros de cor

| Cor | Uso |
|-----|-----|
| `primaryColor` | Ponteiro dos segundos + ponto central |
| `surfaceColor` | Borda do ponto central |
| `onSurfaceColor` | Ponteiros de hora/minuto + marcas maiores |
| `outlineColor` | Anel externo + marcas menores |

#### Desenho: ordem de camadas (de tras pra frente)

**1. Anel externo (linhas 48-52)**
- Circulo com `PaintingStyle.stroke`, largura 3px, opacidade 15%
- `radius = width/2 - 8`, margem de 8px para nao cortar o anel

**2. Preenchimento interno (linhas 54-57)**
- Circulo preenchido com opacidade 3%, leve destaque do fundo

**3. Marcas de minuto (linhas 59-82)**
- Loop de 0 a 59 (60 marcas)
- A cada 5 (`i % 5 == 0`) marca e "major": mais longa (14px vs 6px) e mais grossa (2px vs 1px)
- Angulo: `i * (2pi/60) - pi/2`, onde o `- pi/2` rotaciona para que 0 fique no topo (12h)
- Cada marca e uma linha de `outerPoint` para `innerPoint` ao longo do raio

**4. Calculo dos angulos dos ponteiros (linhas 84-87)**

| Ponteiro | Formula | Ciclo completo |
|----------|---------|----------------|
| Segundos | `(ms % 60000) / 60000 * 2pi` | 60 segundos |
| Minutos | `(ms % 3600000) / 3600000 * 2pi` | 60 minutos |
| Horas | `(ms % 43200000) / 43200000 * 2pi` | 12 horas |

Todos usam `inMilliseconds` (nao `inSeconds`), o que faz os ponteiros moverem suavemente em vez de pular.

**5. Ponteiros (linhas 89-93)**

| Ponteiro | Comprimento | Largura | Cor |
|----------|-------------|---------|-----|
| Hora | 45% do raio | 4px | `onSurface` 35% opacidade |
| Minuto | 65% do raio | 3px | `onSurface` 60% opacidade |
| Segundo | 85% do raio | 1.5px | `primary` (roxo) |

**6. Ponto central (linhas 95-104)**
- Circulo preenchido de 5px com cor primary
- Borda de 2px com cor `surface` (cria efeito de destaque)

#### Metodo `_drawHand` (linhas 107-123)

Desenha um ponteiro com "cauda": a linha se estende 12px alem do centro na direcao oposta, imitando ponteiros reais de relogio.

```
tail (12px atras do centro) ────── center ──────────────── end (comprimento do ponteiro)
```

`StrokeCap.round`: pontas arredondadas.

#### `shouldRepaint` (linhas 127-129)

Retorna `true` apenas quando `elapsed` mudou. Evita redesenho desnecessario quando o widget reconstroi por outros motivos (ex: mudanca de tema).

---

## 6. `test/widget_test.dart`: Testes

### Teste 1: "App renders and shows initial state" (linhas 8-19)

Verifica que o app inicializa corretamente:
- Texto "Stopwatch" aparece (titulo)
- Texto "00:00:00" aparece (display digital zerado)
- Texto ".00" aparece (centesimos zerados)
- Icone `play_arrow_rounded` aparece (botao start)

### Teste 2: "Start button toggles to pause" (linhas 21-32)

Verifica a interacao basica:
1. Toca no icone play
2. `pump()` processa o frame
3. Verifica que o icone mudou para `pause_rounded`

Ambos os testes envolvem o app em `ProviderScope` + `MaterialApp`, que e o minimo necessario para o Riverpod funcionar.

---

## Fluxo Completo do App

```
main.dart
  └── ProviderScope
       └── MaterialApp (tema Material 3, dark mode)
            └── HomeView (ConsumerWidget)
                 ├── observa: stopwatchProvider, elapsedProvider
                 ├── obtem: stopwatchServiceProvider
                 │
                 ├── AnimatedStopwatch ← elapsed
                 │    └── CustomPaint → StopwatchPainter
                 │         └── desenha: anel, marcas, 3 ponteiros, ponto central
                 │
                 ├── TimerDisplay ← elapsed
                 │    └── formata HH:MM:SS.cs com padLeft
                 │
                 └── ButtonRow ← isOn, hasElapsed
                      ├── Start/Pause → service.start() / service.stop()
                      └── Reset → service.reset()

StopwatchService (dentro do provider)
  ├── start() → Stopwatch.start() + Timer.periodic(16ms) → elapsedProvider
  ├── stop()  → Stopwatch.stop()  + Timer.cancel()       → elapsedProvider (ultimo valor)
  └── reset() → Stopwatch.reset() + Timer.cancel()       → Duration.zero
```
