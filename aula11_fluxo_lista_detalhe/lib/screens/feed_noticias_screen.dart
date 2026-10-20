import 'package:flutter/material.dart';

import '../models/noticia_model.dart';
import '../services/noticia_service.dart';
import '../widgets/capa_noticia.dart';
import 'detalhe_noticia_screen.dart';

/// Tela principal (feed) do Portal de Notícias.
///
/// Padrão Master-Detail: a lista carrega as notícias da API e, ao tocar em
/// um item, abre [DetalheNoticiaScreen] passando o objeto [NoticiaModel]
/// completo pelo construtor, com [Navigator.push] + [MaterialPageRoute].
class FeedNoticiasScreen extends StatefulWidget {
  /// Serviço HTTP injetável (padrão: chamada real à API).
  final NoticiaService? noticiaService;

  /// Estado inicial de favoritos (para testes/restauro de sessão).
  final Set<int>? favoritosIniciais;

  const FeedNoticiasScreen({
    super.key,
    this.noticiaService,
    this.favoritosIniciais,
  });

  @override
  State<FeedNoticiasScreen> createState() => _FeedNoticiasScreenState();
}

class _FeedNoticiasScreenState extends State<FeedNoticiasScreen> {
  late final NoticiaService _noticiaService;

  /// Future criado uma única vez no [initState] (e recriado de forma
  /// explícita em atualizações), evitando requisições repetidas a cada
  /// reconstrução de [build].
  late Future<List<NoticiaModel>> _futureNoticias;

  /// Favoritos mantidos em memória durante a sessão (ver README).
  final Set<int> _favoritos = <int>{};

  @override
  void initState() {
    super.initState();
    _noticiaService = widget.noticiaService ?? NoticiaService();
    _favoritos.addAll(widget.favoritosIniciais ?? const <int>{});
    _futureNoticias = _carregarNoticias();
  }

  Future<List<NoticiaModel>> _carregarNoticias() {
    return _noticiaService.buscarNoticias();
  }

  /// Cria um novo Future de forma explícita (atualizar feed / nova tentativa).
  Future<void> _atualizarFeed() async {
    setState(() {
      _futureNoticias = _carregarNoticias();
    });
    await _futureNoticias;
  }

  Future<void> _abrirDetalhes(NoticiaModel noticia) async {
    // Passagem do objeto completo pelo construtor + retorno tipado com o
    // novo estado de favorito (comunicação explícita detalhe → feed).
    final bool? favoritada = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => DetalheNoticiaScreen(
          noticia: noticia,
          inicialmenteFavorita: _favoritos.contains(noticia.id),
        ),
      ),
    );

    if (!mounted || favoritada == null) {
      return;
    }
    setState(() {
      if (favoritada) {
        _favoritos.add(noticia.id);
      } else {
        _favoritos.remove(noticia.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal de Notícias'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Atualizar notícias',
            icon: const Icon(Icons.refresh),
            onPressed: _atualizarFeed,
          ),
        ],
      ),
      body: FutureBuilder<List<NoticiaModel>>(
        future: _futureNoticias,
        builder: (BuildContext context,
            AsyncSnapshot<List<NoticiaModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _EstadoCarregando();
          }

          if (snapshot.hasError) {
            return _EstadoErro(
              mensagem: _mensagemDeErro(snapshot.error),
              onTentarNovamente: _atualizarFeed,
            );
          }

          final List<NoticiaModel> noticias =
              snapshot.data ?? const <NoticiaModel>[];

          if (noticias.isEmpty) {
            return _EstadoVazio(onAtualizar: _atualizarFeed);
          }

          return RefreshIndicator(
            onRefresh: _atualizarFeed,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              itemCount: noticias.length,
              itemBuilder: (BuildContext context, int index) {
                final NoticiaModel noticia = noticias[index];
                return _CardNoticia(
                  noticia: noticia,
                  favorita: _favoritos.contains(noticia.id),
                  onTap: () => _abrirDetalhes(noticia),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _mensagemDeErro(Object? erro) {
    if (erro is NoticiaServiceException) {
      return erro.mensagem;
    }
    return 'Não foi possível carregar as notícias. Tente novamente.';
  }
}

class _CardNoticia extends StatelessWidget {
  final NoticiaModel noticia;
  final bool favorita;
  final VoidCallback onTap;

  const _CardNoticia({
    required this.noticia,
    required this.favorita,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Miniatura com a mesma tag Hero da capa nos detalhes.
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: CapaNoticia(
                    urlImagem: noticia.urlImagem,
                    heroTag: noticia.id,
                    altura: 92,
                    largura: 92,
                    tituloPlaceholder: noticia.titulo,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      noticia.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      noticia.resumo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tema.textTheme.bodyMedium
                          ?.copyWith(color: tema.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.person_outline,
                          size: 16,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            noticia.autor,
                            overflow: TextOverflow.ellipsis,
                            style: tema.textTheme.bodySmall?.copyWith(
                              color: tema.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (favorita)
                          Icon(
                            Icons.favorite,
                            size: 18,
                            color: tema.colorScheme.error,
                          ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right,
                          color: tema.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoCarregando extends StatelessWidget {
  const _EstadoCarregando();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando notícias...'),
        ],
      ),
    );
  }
}

class _EstadoErro extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentarNovamente;

  const _EstadoErro({
    required this.mensagem,
    required this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onTentarNovamente,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoVazio extends StatelessWidget {
  final VoidCallback onAtualizar;

  const _EstadoVazio({required this.onAtualizar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.newspaper,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma notícia encontrada.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onAtualizar,
              icon: const Icon(Icons.refresh),
              label: const Text('Atualizar'),
            ),
          ],
        ),
      ),
    );
  }
}
