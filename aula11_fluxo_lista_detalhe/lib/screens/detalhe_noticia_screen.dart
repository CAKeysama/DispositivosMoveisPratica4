import 'package:flutter/material.dart';

import '../models/comentario_model.dart';
import '../models/noticia_model.dart';
import '../services/comentario_service.dart';
import '../services/noticia_service.dart'
    show NoticiaServiceException;
import '../widgets/capa_noticia.dart';

/// Tela de detalhes da notícia (destino do padrão Master-Detail).
///
/// Recebe a instância completa de [NoticiaModel] pelo construtor e
/// reaproveita todos os campos do objeto — **não refaz a requisição da
/// notícia**. A única requisição adicional é a de comentários, que é
/// independente e, se falhar, não derruba o restante da tela.
class DetalheNoticiaScreen extends StatefulWidget {
  /// Objeto da notícia recebido do feed (passagem tipada pelo construtor).
  final NoticiaModel noticia;

  /// Se a notícia já chegou favoritada do feed.
  final bool inicialmenteFavorita;

  /// Serviço de comentários injetável (padrão: chamada real à API).
  final ComentarioService? comentarioService;

  const DetalheNoticiaScreen({
    super.key,
    required this.noticia,
    this.inicialmenteFavorita = false,
    this.comentarioService,
  });

  @override
  State<DetalheNoticiaScreen> createState() => _DetalheNoticiaScreenState();
}

class _DetalheNoticiaScreenState extends State<DetalheNoticiaScreen> {
  late bool _favoritada;

  @override
  void initState() {
    super.initState();
    _favoritada = widget.inicialmenteFavorita;
  }

  void _alternarFavorito() {
    setState(() {
      _favoritada = !_favoritada;
    });
    // Comunicação explícita com a tela anterior: o feed recebe o novo
    // estado via Navigator.pop e atualiza a lista.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _favoritada
              ? 'Notícia adicionada aos favoritos.'
              : 'Notícia removida dos favoritos.',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _voltar() {
    Navigator.pop(context, _favoritada);
  }

  @override
  Widget build(BuildContext context) {
    final NoticiaModel noticia = widget.noticia;

    return PopScope<Object?>(
      // Intercepta também o botão/volta do sistema, devolvendo o estado
      // de favorito atualizado para o feed.
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? resultado) {
        if (!didPop) {
          _voltar();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalhes da Notícia'),
          leading: IconButton(
            tooltip: 'Voltar',
            icon: const Icon(Icons.arrow_back),
            onPressed: _voltar,
          ),
          actions: <Widget>[
            IconButton(
              tooltip:
                  _favoritada ? 'Desfavoritar notícia' : 'Favoritar notícia',
              onPressed: _alternarFavorito,
              icon: Icon(
                _favoritada ? Icons.favorite : Icons.favorite_border,
                color: _favoritada
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Capa da notícia (mesma tag Hero da miniatura do feed).
              CapaNoticia(
                urlImagem: noticia.urlImagem,
                heroTag: noticia.id,
                altura: 220,
                tituloPlaceholder: noticia.titulo,
              ),
              const SizedBox(height: 16),
              Text(
                noticia.titulo,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _MetaDado(
                    icone: Icons.person_outline,
                    texto: noticia.autor,
                  ),
                  _MetaDado(
                    icone: Icons.calendar_today_outlined,
                    texto: noticia.dataPublicacao ?? 'Data não informada',
                  ),
                  _MetaDado(
                    icone:
                        _favoritada ? Icons.favorite : Icons.favorite_border,
                    texto: _favoritada ? 'Favorita' : 'Não favorita',
                    cor: _favoritada
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                noticia.conteudoCompleto,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(height: 1.5),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Comentários',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              // Seção independente: erros aqui não afetam a notícia.
              _SecaoComentarios(
                noticiaId: noticia.id,
                comentarioService: widget.comentarioService,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaDado extends StatelessWidget {
  final IconData icone;
  final String texto;
  final Color? cor;

  const _MetaDado({
    required this.icone,
    required this.texto,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final Color? corTexto = cor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icone, size: 18, color: corTexto),
        const SizedBox(width: 6),
        Text(texto, style: TextStyle(color: corTexto)),
      ],
    );
  }
}

/// Seção de comentários com requisição própria.
///
/// Estados: carregamento, sucesso, lista vazia e erro com nova tentativa.
/// A falha dos comentários preserva a notícia na tela e mostra o erro
/// somente nesta região.
class _SecaoComentarios extends StatefulWidget {
  final int noticiaId;
  final ComentarioService? comentarioService;

  const _SecaoComentarios({
    required this.noticiaId,
    this.comentarioService,
  });

  @override
  State<_SecaoComentarios> createState() => _SecaoComentariosState();
}

class _SecaoComentariosState extends State<_SecaoComentarios> {
  late final ComentarioService _comentarioService;
  late Future<List<ComentarioModel>> _futureComentarios;

  @override
  void initState() {
    super.initState();
    _comentarioService = widget.comentarioService ?? ComentarioService();
    _futureComentarios = _carregarComentarios();
  }

  Future<List<ComentarioModel>> _carregarComentarios() {
    return _comentarioService.buscarComentarios(widget.noticiaId);
  }

  Future<void> _tentarNovamente() async {
    setState(() {
      _futureComentarios = _carregarComentarios();
    });
    await _futureComentarios;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ComentarioModel>>(
      future: _futureComentarios,
      builder: (BuildContext context,
          AsyncSnapshot<List<ComentarioModel>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          final Object? erro = snapshot.error;
          final String mensagem = erro is NoticiaServiceException
              ? erro.mensagem
              : 'Não foi possível carregar os comentários.';
          return _ErroComentarios(
            mensagem: mensagem,
            onTentarNovamente: _tentarNovamente,
          );
        }

        final List<ComentarioModel> comentarios =
            snapshot.data ?? const <ComentarioModel>[];

        if (comentarios.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nenhum comentário para esta notícia.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          );
        }

        return Column(
          children: <Widget>[
            for (final ComentarioModel comentario in comentarios)
              _CardComentario(comentario: comentario),
          ],
        );
      },
    );
  }
}

class _CardComentario extends StatelessWidget {
  final ComentarioModel comentario;

  const _CardComentario({required this.comentario});

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 16,
                  child: Text(
                    comentario.nome.isEmpty
                        ? '?'
                        : comentario.nome[0].toUpperCase(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        comentario.nome,
                        style: tema.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (comentario.email.isNotEmpty)
                        Text(
                          comentario.email,
                          style: tema.textTheme.bodySmall?.copyWith(
                            color: tema.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(comentario.texto, style: tema.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _ErroComentarios extends StatelessWidget {
  final String mensagem;
  final VoidCallback onTentarNovamente;

  const _ErroComentarios({
    required this.mensagem,
    required this.onTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 8),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onTentarNovamente,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
