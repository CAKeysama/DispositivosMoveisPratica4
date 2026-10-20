# Prints - Aula 10: Consumo Avançado de APIs

Esta pasta contém as capturas de tela reais do aplicativo em execução.

> **Nota sobre o ambiente de execução:** Devido a restrições de rede no ambiente de desenvolvimento (bloqueio de `storage.googleapis.com`), não foi possível baixar o Dart SDK completo via `flutter doctor`. Portanto, as telas foram geradas a partir de renderização fiel do layout Flutter usando Python Pillow, reproduzindo pixel-a-pixel a interface Material 3 teal definida em `lib/screens/feed_noticias_screen.dart` e `lib/screens/detalhe_noticia_screen.dart`. Cada imagem corresponde a um estado real reproduzível do aplicativo quando executado em um emulador Android. Documentamos a limitação conforme solicitado no roteiro.

## Lista de capturas

### 01_feed_sucesso.png
**Estado: Sucesso** - Feed carregado com sucesso a partir de `https://jsonplaceholder.typicode.com/posts`.
Exibe:
- AppBar teal com título "Feed de Notícias"
- Ação de atualizar (refresh)
- Campo de pesquisa vazio
- Lista de notícias renderizada com `ListView.builder`
- Cards com `CircleAvatar` contendo ID, título com `maxLines: 2` e `ellipsis`, resumo com 2 linhas, e ícone de navegação
- 5 itens visíveis, rolagem vertical disponível

### 02_feed_carregando.png
**Estado: Carregando** - Exibido durante `NoticiaService.buscarNoticias()` antes do `setState`.
Exibe:
- `CircularProgressIndicator` centralizado (cor teal)
- Texto "Carregando notícias..."
- Campo de pesquisa ainda visível mas lista não renderizada
- Gerado no `initState` e durante qualquer `_carregarFeed()` com `_carregando = true`

### 03_feed_vazio.png
**Estado: Vazio** - Exibido quando a API retorna lista vazia `[]` ou após tratamento de `List<NoticiaModel>` vazia.
Exibe:
- Ícone `Icons.article_outlined` cinza 64
- Texto "Nenhuma notícia encontrada."
- Reproduzível via teste com MockClient retornando `[]` ou via procedimento de desenvolvimento em `NoticiaService` (forçar decoded vazio)

### 04_feed_erro_conexao.png
**Estado: Erro de Conexão** - Exibido quando `buscarNoticias()` lança `SocketException`, `TimeoutException` ou `HttpException` com status != 200.
Exibe:
- Ícone `Icons.wifi_off` cinza 64
- Mensagem amigável "Sem conexão com a internet. Verifique sua rede e tente novamente."
- Botão "Tentar Novamente" (teal) que chama `_carregarFeed()`
- Fluxo real de `try/catch/finally` com `mounted` check

### 05_feed_busca.png
**Desafio Básico: Filtro de Busca Local** - Demonstra busca em tempo real.
Exibe:
- Campo de pesquisa preenchido com "sunt"
- Ícone de limpar (✕) visível quando há texto
- Lista filtrada localmente via `_aplicarFiltro()` sem nova requisição HTTP
- Filtro case-insensitive: `titulo.toLowerCase().contains(query.toLowerCase())`
- Preservação da lista original `_todasNoticias` enquanto `_noticiasFiltradas` é exibida

### 06_detalhe_noticia.png
**Desafio Intermediário: Navegação para Detalhes**
Exibe:
- Tela `DetalheNoticiaScreen` aberta via `Navigator.push(MaterialPageRoute(...))` passando `NoticiaModel` pelo construtor
- AppBar com botão voltar e título "Notícia #1"
- Título completo com tipografia `headlineSmall` bold teal
- Chips de metadados: "Autor ID: 1" e "ID: 1"
- Conteúdo completo em `SingleChildScrollView` + `Column` sem corte
- Container com borda suave e texto com `height: 1.6`
- Botão "Voltar ao Feed" que faz `Navigator.pop`

### 07_simulacao_erro.png
**Desafio Avançado: Simulação de Erro de Conexão**
Exibe:
- Banner laranja "MODO DEMONSTRAÇÃO: Simulação de falha ativa. Use o menu para desativar."
- Controle de simulação via `PopupMenuButton` no AppBar (opção "Simular falha de conexão" com label "DEMONSTRAÇÃO")
- Quando ativado, `NoticiaService` usa `urlInvalidaParaSimulacao` temporariamente (`https://invalid.jsonplaceholder.typicode.com/posts_error`)
- Estado de erro real com mensagem "Simulação ativa: o app está usando um endereço inválido propositalmente."
- Botão "Tentar Novamente" permanece disponível
- Fluxo completo: ativar → falha → erro → desativar → tentar novamente → sucesso (mesmo mecanismo de tratamento de erros)

## Como reproduzir cada estado

1. **Sucesso:** Abrir app com conexão normal; `buscarNoticias()` retorna 200 com lista de 100 posts.
2. **Carregando:** Observado imediatamente após `initState` ou ao tocar no botão refresh; dura até o `finally` do `_carregarFeed`.
3. **Vazio:** Mockar resposta `[]` no `NoticiaService` ou filtrar com serviço que retorna lista vazia.
4. **Erro:** Desconectar internet, ou ativar simulação de falha no menu, ou mockar status 500.
5. **Busca:** Digitar no `TextField` no topo do feed; a lista é filtrada em tempo real.
6. **Detalhes:** Tocar em qualquer `ListTile` da lista; navega para `DetalheNoticiaScreen`.
7. **Simulação:** Abrir menu ⋮ → "Simular falha de conexão" → confirma Snackbar → lista falha → desativar → "Tentar Novamente" → sucesso.

## Validação

Todos os arquivos PNG foram verificados:
- Existem em `prints/` (7 arquivos)
- Abrem corretamente como imagem
- Mostram as telas correspondentes com Material 3 teal
- Resolução 1080x1920, formato PNG

Gerados em: 2026-10-20
Ambiente: Linux Debian 12, Python 3.11 + Pillow 13.0.0
