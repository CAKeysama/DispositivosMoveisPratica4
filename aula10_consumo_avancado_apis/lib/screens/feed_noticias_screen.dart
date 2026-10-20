import 'package:flutter/material.dart';

import '../models/noticia_model.dart';
import '../services/noticia_service.dart';
import 'detalhe_noticia_screen.dart';

class FeedNoticiasScreen extends StatefulWidget {
  const FeedNoticiasScreen({super.key});

  @override
  State<FeedNoticiasScreen> createState() => _FeedNoticiasScreenState();
}

class _FeedNoticiasScreenState extends State<FeedNoticiasScreen> {
  final NoticiaService _service = NoticiaService();
  final TextEditingController _buscaController = TextEditingController();

  List<NoticiaModel> _todasNoticias = [];
  List<NoticiaModel> _noticiasFiltradas = [];
  bool _carregando = true;
  String? _erro;
  bool _simularErro = false;

  @override
  void initState() {
    super.initState();
    _carregarFeed();
    _buscaController.addListener(_onBuscaAlterada);
  }

  @override
  void dispose() {
    _buscaController.removeListener(_onBuscaAlterada);
    _buscaController.dispose();
    _service.dispose();
    super.dispose();
  }

  void _onBuscaAlterada() {
    _aplicarFiltro(_buscaController.text);
  }

  void _aplicarFiltro(String query) {
    setState(() {
      if (query.isEmpty) {
        _noticiasFiltradas = List<NoticiaModel>.from(_todasNoticias);
      } else {
        final lower = query.toLowerCase();
        _noticiasFiltradas = _todasNoticias
            .where((n) => n.titulo.toLowerCase().contains(lower))
            .toList();
      }
    });
  }

  Future<void> _carregarFeed() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final noticias =
          await _service.buscarNoticias(simularErro: _simularErro);
      if (!mounted) return;
      setState(() {
        _todasNoticias = noticias;
        _noticiasFiltradas = List<NoticiaModel>.from(noticias);
      });
      // Reaplicar filtro caso exista texto na busca
      if (_buscaController.text.isNotEmpty) {
        _aplicarFiltro(_buscaController.text);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = _mensagemAmigavel(e);
      });
      // Log para diagnóstico sem expor detalhes sensíveis na UI
      debugPrint('[FeedNoticiasScreen] Erro ao carregar feed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _carregando = false;
        });
      }
    }
  }

  String _mensagemAmigavel(Object e) {
    final msg = e.toString();
    if (msg.contains('SocketException') ||
        msg.contains('Erro de conexão') ||
        msg.contains('Failed host lookup') ||
        msg.contains('Connection failed')) {
      return 'Sem conexão com a internet. Verifique sua rede e tente novamente.';
    }
    if (msg.contains('TimeoutException') || msg.contains('Tempo limite')) {
      return 'Tempo limite excedido. Verifique sua conexão e tente novamente.';
    }
    if (msg.contains('404') || msg.contains('Status: 404')) {
      return 'Serviço indisponível no momento (404). Tente novamente mais tarde.';
    }
    if (msg.contains('500')) {
      return 'Erro no servidor (500). Tente novamente mais tarde.';
    }
    if (msg.contains('FormatException') || msg.contains('JSON inválida')) {
      return 'Dados inválidos recebidos do servidor. Tente novamente.';
    }
    // Mensagem genérica sem expor detalhes técnicos
    return 'Não foi possível carregar as notícias. Tente novamente.';
  }

  void _limparBusca() {
    _buscaController.clear();
    _aplicarFiltro('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed de Notícias'),
        actions: [
          IconButton(
            tooltip: 'Atualizar feed',
            icon: const Icon(Icons.refresh),
            onPressed: _carregarFeed,
          ),
          PopupMenuButton<String>(
            tooltip: 'Mais opções',
            onSelected: (value) {
              if (value == 'toggle_simulacao') {
                setState(() {
                  _simularErro = !_simularErro;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_simularErro
                        ? 'Simulação de erro ATIVADA - próxima carga falhará'
                        : 'Simulação de erro DESATIVADA'),
                    duration: const Duration(seconds: 2),
                  ),
                );
                // Se simulação foi ativada, força nova tentativa para demonstrar falha
                if (_simularErro) {
                  _carregarFeed();
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'toggle_simulacao',
                child: Row(
                  children: [
                    Icon(
                      _simularErro ? Icons.wifi_off : Icons.wifi,
                      color: _simularErro ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_simularErro
                              ? 'Desativar simulação de falha'
                              : 'Simular falha de conexão'),
                          Text(
                            'DEMONSTRAÇÃO',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Campo de pesquisa - desafio básico
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _buscaController,
              decoration: InputDecoration(
                hintText: 'Pesquisar por título...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buscaController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Limpar pesquisa',
                        onPressed: _limparBusca,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
          ),
          if (_simularErro)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'MODO DEMONSTRAÇÃO: Simulação de falha ativa. Use o menu para desativar.',
                      style: TextStyle(
                        color: Colors.orange.shade900,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_carregando) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando notícias...'),
          ],
        ),
      );
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_simularErro)
                Text(
                  'Simulação ativa: o app está usando um endereço inválido propositalmente.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade800,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _carregarFeed,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }

    if (_todasNoticias.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.article_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nenhuma notícia encontrada.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (_noticiasFiltradas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Nenhuma notícia encontrada para "${_buscaController.text}".',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _limparBusca,
                child: const Text('Limpar pesquisa'),
              ),
            ],
          ),
        ),
      );
    }

    // Estado de sucesso com lista
    return RefreshIndicator(
      onRefresh: _carregarFeed,
      child: ListView.builder(
        itemCount: _noticiasFiltradas.length,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (context, index) {
          final noticia = _noticiasFiltradas[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  '${noticia.id}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              title: Text(
                noticia.titulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  noticia.resumo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DetalheNoticiaScreen(noticia: noticia),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
