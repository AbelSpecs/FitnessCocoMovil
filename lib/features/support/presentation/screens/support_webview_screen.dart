import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pyrosfitmovil/features/auth/presentation/controllers/auth_provider.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SupportWebViewScreen extends StatefulWidget {
  final String mode;

  const SupportWebViewScreen({
    super.key,
    this.mode = 'ticket',
  });

  @override
  State<SupportWebViewScreen> createState() => _SupportWebViewScreenState();
}

class _SupportWebViewScreenState extends State<SupportWebViewScreen> {
  String get _targetUrl {
    switch (widget.mode) {
      case 'payments':
        return 'https://pyrosfit.com/payments';
      case 'delete':
        return 'https://pyrosfit.com/support?mode=delete';
      default:
        return 'https://pyrosfit.com/support?mode=ticket';
    }
  }

  String get _screenTitle {
    switch (widget.mode) {
      case 'payments':
        return 'Pagos';
      case 'delete':
        return 'Dar de baja mi cuenta';
      default:
        return 'Soporte y Reporte de Bugs';
    }
  }

  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _sessionInjected = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final token = authProvider.token;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF09090B))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted && _hasError) {
              setState(() => _hasError = false);
            }
          },
          onPageFinished: (String url) async {
            if (!mounted) return;

            // Inyectar la sesión en localStorage antes de mostrar la vista
            // para que useAuthStore en la web reconozca al usuario sin pedir login.
            if (!_sessionInjected &&
                user != null &&
                token != null &&
                url.startsWith('https://pyrosfit.com')) {
              _sessionInjected = true;
              final encodedToken = jsonEncode(jsonEncode(token));
              final encodedUser = jsonEncode(jsonEncode(user.toJson()));
              final encodedTargetUrl = jsonEncode(_targetUrl);

              try {
                await _controller.runJavaScript('''
                  localStorage.setItem('pyrosfit_token', $encodedToken);
                  localStorage.setItem('pyrosfit_user', $encodedUser);
                  if (window.location.href !== $encodedTargetUrl) {
                    window.location.replace($encodedTargetUrl);
                  } else {
                    window.location.reload();
                  }
                ''');
                return;
              } catch (_) {
                // Si falla la inyección, mostramos la página igualmente
              }
            }

            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            // Solo mostrar error si corresponde al frame principal
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _hasError = true;
                });
              }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(_targetUrl));
  }

  void _reload() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _controller.loadRequest(Uri.parse(_targetUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF18181B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _screenTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Recargar',
            icon: const Icon(Icons.refresh_rounded, size: 20),
            onPressed: _reload,
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white54,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No se pudo cargar el portal de soporte',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Verifica tu conexión a internet e intenta nuevamente.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reintentar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: const Color(0xFF09090B),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Abriendo portal de soporte...',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

