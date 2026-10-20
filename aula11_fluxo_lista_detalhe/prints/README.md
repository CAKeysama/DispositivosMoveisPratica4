# Prints — capturas reais da execução

Todas as imagens foram capturadas a partir do **aplicativo real em execução**
(Flutter Web em navegador Chromium headless controlado por automação), não de
mockups ou montagens.

Os estados difíceis de capturar foram reproduzidos com **procedimentos de
teste que alteram apenas a condição de rede** observada pelo aplicativo em
execução (resposta atrasada, falha de conexão e lista vazia) — o código do
aplicativo roda exatamente o mesmo de produção.

| Arquivo | Descrição |
|---------|-----------|
| `01_feed_noticias.png` | Feed **carregado** com a lista de notícias da API: cards com miniatura (Hero), título resumido, resumo, autor e indicador de detalhes (`›`). |
| `02_feed_carregando.png` | Estado de **carregamento** do feed: `CircularProgressIndicator` + texto "Carregando notícias..." enquanto a requisição HTTP está em andamento (resposta atrasada pelo procedimento de teste). |
| `03_feed_erro.png` | Estado de **erro** do feed: ícone, mensagem amigável com o código HTTP e botão **"Tentar novamente"** (requisição falhou pelo procedimento de teste). |
| `04_feed_vazio.png` | Estado **vazio** do feed: "Nenhuma notícia encontrada." com botão **"Atualizar"** (API respondeu lista vazia). |
| `05_detalhe_noticia.png` | Tela de **detalhes** após tocar em uma notícia: capa (Hero), título completo, autor, data ("Data não informada" — a API não fornece data), conteúdo integral e início da seção de comentários. |
| `06_detalhe_comentarios.png` | Seção de **comentários carregada**: nome, e-mail e texto de cada comentário da notícia. |
| `07_detalhe_favoritado.png` | Notícia **favoritada**: coração preenchido no AppBar e meta "Favorita" (comunicação de estado ativa). |
| `08_favorito_atualizado_feed.png` | **Feed atualizado** após voltar dos detalhes: coração exibido no card da notícia favoritada (retorno via `Navigator.pop`). |
