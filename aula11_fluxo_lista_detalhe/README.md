# Aula 11 — Navegação com API e Fluxo Lista-Detalhe 📰

Aplicativo **Flutter** que implementa o padrão **Master-Detail** com consumo
de API REST: um feed de notícias (`ListView.builder`) que abre uma tela de
detalhes com a **passagem do objeto `NoticiaModel` completo pelo construtor**,
**Hero Animation**, **favoritos** e **comentários** carregados por uma segunda
requisição HTTP.

> Projeto independente da Aula 10, criado em `aula11_fluxo_lista_detalhe/`.

---

## Objetivo

Consolidar os conceitos da Aula 11:

- Modelagem completa de `NoticiaModel`;
- Consumo de API REST com o pacote `http` + `dart:convert`;
- Conversão de lista JSON para objetos Dart;
- Verificação de `response.statusCode == 200`;
- Feed resumido renderizado com `ListView.builder`;
- Navegação com `Navigator.push` + `MaterialPageRoute`;
- Passagem do objeto tipado pelo construtor (sem refazer requisição);
- Tela de detalhes com `SingleChildScrollView` + `Column`;
- Tratamento de erros de carregamento (feed, comentários e imagem);
- Desafios: Hero Animation, favoritos e comentários.

---

## Padrão Master-Detail

```
┌─────────────────────┐   Navigator.push +    ┌──────────────────────────┐
│  FeedNoticiasScreen │   MaterialPageRoute   │ DetalheNoticiaScreen     │
│  (lista resumida)   │ ───────────────────►  │ (objeto recebido por     │
│  ListView.builder   │   NoticiaModel completo│  construtor + comentários)│
│                     │ ◄───────────────────  │                          │
│  favoritos (memória)│  Navigator.pop(bool)  │  favoritar / comentários  │
└─────────────────────┘                       └──────────────────────────┘
```

1. O feed carrega as notícias **uma única vez** (`Future` criado no `initState`).
2. Ao tocar em um item, `Navigator.push` abre `DetalheNoticiaScreen` passando a
   instância **completa** de `NoticiaModel` pelo construtor.
3. A tela de detalhes **reutiliza** todos os campos do objeto recebido —
   título, autor, imagem e conteúdo — **sem refazer a requisição da notícia**.
4. Ao voltar, `Navigator.pop(context, favoritada)` devolve o novo estado de
   favorito e o feed atualiza a lista.

---

## Modelo `NoticiaModel`

| Campo              | Origem no JSON    | Regra                                                        |
|--------------------|-------------------|--------------------------------------------------------------|
| `id`               | `id`              | inteiro                                                      |
| `titulo`           | `title`           | string                                                       |
| `resumo`           | `body`            | primeiros **40 caracteres** (com tratamento por comprimento) |
| `conteudoCompleto` | `body`            | corpo integral                                               |
| `autor`            | `userId`          | apresentado como `Autor ID N`                                |
| `urlImagem`        | gerada            | `https://picsum.photos/seed/post_{id}/1200/600`              |
| `dataPublicacao`   | `dataPublicacao`  | opcional; `null` quando a API não fornece (nada é inventado) |

- Construtor com **parâmetros nomeados** e `required`.
- `factory NoticiaModel.fromJson(Map<String, dynamic> json)` defensiva:
  campos ausentes ou inválidos não lançam exceção.
- `NoticiaModel.resumir` nunca gera erro com textos menores que 40 caracteres.

O model de comentários (`ComentarioModel`) segue o mesmo princípio
(`id`, `postId`, `name`, `email`, `body`).

---

## Endpoints utilizados

O roteiro usa `api.servidor/posts` como *placeholder*. Para o aplicativo
funcionar de verdade, foi configurado um **endpoint público compatível** com
os campos esperados:

| Finalidade        | Endpoint                                              |
|-------------------|-------------------------------------------------------|
| Feed de notícias  | `https://jsonplaceholder.typicode.com/posts`          |
| Comentários       | `https://jsonplaceholder.typicode.com/posts/{id}/comments` |

A escolha está documentada também em `lib/services/noticia_service.dart`
(constante `NoticiaService.endpointPadrao`).

### Tratamento de erros no serviço

- `response.statusCode == 200` verificado explicitamente;
- exceções tipadas: `NoticiaRedeException`, `NoticiaHttpException`,
  `NoticiaFormatoException` (todas estendem `NoticiaServiceException`);
- timeout de 15 s (configurável);
- validação de que a resposta é uma lista antes do mapeamento.

O código HTTP fica **fora da interface**, em `lib/services/`.

---

## Imagens de demonstração

A API de demonstração não fornece imagem de capa, então a URL é
**determinística por notícia**:

```
https://picsum.photos/seed/post_{id}/1200/600
```

(fonte: [Picsum Photos](https://picsum.photos), serviço público de imagens
aleatórias estáveis por `seed`).

Se a imagem remota falhar, um **placeholder visual local** é exibido
(`errorBuilder` de `Image.network` em `lib/widgets/capa_noticia.dart`) e a
notícia continua 100% legível.

---

## Hero Animation (desafio básico)

- Miniatura do feed e capa dos detalhes envolvidas em `Hero(tag: noticia.id)`.
- A tag é o `id` da notícia — **única por item**, sem conflitos na lista.
- A transição anima a imagem da lista para a capa da tela de detalhes.

## Favoritos (desafio intermediário)

- Botão de coração na tela de detalhes, com estados visuais distintos
  (`favorite` / `favorite_border`) e feedback via `SnackBar`.
- A tela de detalhes devolve o estado com `Navigator.pop(context, true/false)` —
  também quando o usuário volta pelo botão do sistema (`PopScope`).
- O feed **reflete a alteração** ao receber o resultado (coração no card) e
  repassa o estado ao reabrir os detalhes.
- **Decisão**: os favoritos ficam **em memória durante a sessão** (o roteiro
  não exige persistência; nenhuma implementação adicional foi adicionada).

## Comentários (desafio avançado)

- Segunda requisição HTTP em `ComentarioService`, independente da notícia:
  `GET /posts/{id}/comments`.
- Cada comentário exibe **nome**, **e-mail** (quando disponível) e **texto**.
- Estados: carregamento, sucesso, lista vazia, erro e **nova tentativa**.
- Se os comentários falham, **a notícia permanece na tela** e o erro aparece
  somente na região de comentários.

---

## Estrutura de pastas

```
aula11_fluxo_lista_detalhe/
├── lib/
│   ├── main.dart                     # runApp, MaterialApp, Material 3
│   ├── models/
│   │   ├── noticia_model.dart        # NoticiaModel + fromJson/resumir
│   │   └── comentario_model.dart     # ComentarioModel + fromJson
│   ├── services/
│   │   ├── noticia_service.dart      # GET /posts + tratamento de erros
│   │   └── comentario_service.dart   # GET /posts/{id}/comments
│   ├── screens/
│   │   ├── feed_noticias_screen.dart # Feed (ListView.builder + FutureBuilder)
│   │   └── detalhe_noticia_screen.dart # Detalhes + favoritos + comentários
│   └── widgets/
│       └── capa_noticia.dart         # Hero + Image.network com fallback
├── test/
│   ├── helpers/api_fake.dart         # MockClient e dados de teste
│   ├── models/                       # Testes unitários dos models
│   ├── services/                     # Testes unitários dos services
│   └── screens/                      # Testes de widgets (feed e detalhe)
├── prints/                           # Screenshots reais da execução
├── README.md
├── pubspec.yaml
└── .gitignore
```

---

## Instalação

Requisitos: [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.22 ou superior) configurado.

```bash
git clone <url-do-repositorio>
cd aula11_fluxo_lista_detalhe
flutter pub get
```

## Execução

```bash
flutter run                 # emulador/dispositivo conectado
flutter run -d chrome       # no navegador
flutter run -d web-server --web-port=8080
```

O feed carrega automaticamente; toque em uma notícia para abrir os detalhes,
favoritar pelo coração e visualizar os comentários.

## Testes

```bash
flutter test
```

Os testes cobrem:

- Conversão JSON → `NoticiaModel` (incluindo resumo curto sem erro de
  substring, campos ausentes/inválidos e mapeamento completo);
- Serviço HTTP: sucesso, `statusCode != 200`, JSON inválido, lista inválida,
  falha de rede e timeout;
- Feed: carregamento, sucesso (`ListView.builder` + `Card`), estado vazio,
  estado de erro, nova tentativa e atualização;
- Navegação Master-Detail com `Navigator.push`/`MaterialPageRoute` e
  verificação da passagem do objeto `NoticiaModel` completo;
- Conteúdo completo nos detalhes e imagem com fallback local;
- Hero Animation (tags únicas por notícia, mesma tag nas duas telas);
- Favoritar/desfavoritar e retorno ao feed com atualização do favorito;
- Comentários: carregamento, sucesso (nome/e-mail/texto), lista vazia, erro
  isolado na seção, nova tentativa e independência da notícia;
- Nenhuma requisição da notícia é refeita na tela de detalhes.

Os testes usam `MockClient` (`package:http/testing`) e dados de teste —
**não dependem de API pública** para passar.

## Screenshots

As capturas reais da execução estão em [`prints/`](prints/) com descrição em
[`prints/README.md`](prints/README.md):

| Arquivo | Estado |
|---------|--------|
| `01_feed_noticias.png` | Feed carregado com notícias |
| `02_feed_carregando.png` | Estado de carregamento |
| `03_feed_erro.png` | Estado de erro com nova tentativa |
| `04_feed_vazio.png` | Estado vazio |
| `05_detalhe_noticia.png` | Tela de detalhes (capa, autor, título, conteúdo) |
| `06_detalhe_comentarios.png` | Seção de comentários carregada |
| `07_detalhe_favoritado.png` | Notícia favoritada (coração preenchido) |
| `08_favorito_atualizado_feed.png` | Feed atualizado após favoritar |

---

## Limitações

- **Data de publicação**: a API de demonstração (JSONPlaceholder) **não
  fornece** esse campo. O aplicativo **não inventa datas**: quando ausente, a
  tela exibe `Data não informada`. O model aceita `dataPublicacao` opcional
  caso a API passe a fornecer o dado.
- **Imagens**: a API não fornece capa real; as imagens vêm do Picsum Photos,
  determinísticas por id. Falhas de carregamento caem no placeholder local.
- **Favoritos**: mantidos apenas em memória na sessão (sem persistência).
- **Dados da API**: o JSONPlaceholder é uma API de demonstração — os dados
  (títulos/corpos) são fictícios e os ids de autor são numéricos.
- **Execução neste ambiente**: o Android SDK/emulador não está disponível no
  sandbox de execução deste trabalho; o aplicativo foi executado e validado
  como **Flutter Web** em navegador headless real (Chromium), com capturas de
  tela reais dessa execução. Os procedimentos de reprodução de estados
  (carregamento lento, falha e resposta vazia) alteram apenas a **condição de
  rede** observada pelo app em execução — o comportamento do código é o mesmo
  de produção.
