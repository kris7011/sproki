import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sproki/services/paywall_service.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _loading = false;
  bool _premium = false;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final p = await PaywallService.instance.getPremiumStatus();
    if (!mounted) return;
    setState(() => _premium = p);
  }

  Future<void> _buy() async {
    setState(() => _loading = true);
    final res = await PaywallService.instance.buyPremium();
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(res.message ??
              (res.success ? 'Køb gennemført' : 'Køb mislykkedes'))),
    );
    await _refreshStatus();
  }

  Future<void> _restore() async {
    setState(() => _loading = true);
    final res = await PaywallService.instance.restorePurchases();
    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(res.message ??
              (res.success ? 'Genskabt' : 'Ingen køb at genskabe'))),
    );
    await _refreshStatus();
  }

  // Debug helper – vises kun i debug builds
  Widget _buildDebugBox() {
    if (!kDebugMode) return const SizedBox.shrink();
    return Card(
      color: Colors.blueGrey[50],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Debug / Stub',
              style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.verified),
              label: const Text('Aktivér Premium (lokalt)'),
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await PaywallService.instance.devSetPremium(true);
                      if (!mounted) return;
                      setState(() => _loading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Premium aktiveret lokalt (debug)')),
                      );
                      await _refreshStatus();
                    },
            ),
            OutlinedButton.icon(
              icon: const Icon(Icons.block),
              label: const Text('Deaktivér Premium (lokalt)'),
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await PaywallService.instance.devSetPremium(false);
                      if (!mounted) return;
                      setState(() => _loading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Premium fjernet lokalt (debug)')),
                      );
                      await _refreshStatus();
                    },
            ),
          ]),
          const SizedBox(height: 6),
          const Text(
            'Tip: Brug dette til at teste hele premium-oplevelsen uden rigtige køb. '
            'I produktion fjernes disse knapper.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Opgrader til Premium'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _premium ? Colors.green[600] : Colors.grey[400],
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _premium ? 'Premium aktiv' : 'Gratis',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          )
        ],
      ),
      body: AbsorbPointer(
        absorbing: _loading,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hvorfor Premium?',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('• Ubegrænsede øvelser'),
                      Text('• Personlige anbefalinger'),
                      Text('• Fremtidige øvelsestyper låses op'),
                    ]),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _buy,
              icon: const Icon(Icons.shopping_bag),
              label: Text(_loading ? 'Behandler…' : 'Køb Premium'),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _restore,
              icon: const Icon(Icons.restore),
              label: const Text('Genskab køb'),
            ),
            const SizedBox(height: 16),
            _buildDebugBox(),
          ],
        ),
      ),
    );
  }
}
