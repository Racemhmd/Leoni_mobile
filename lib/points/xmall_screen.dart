import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class XmallScreen extends StatefulWidget {
  const XmallScreen({super.key});

  @override
  State<XmallScreen> createState() => _XmallScreenState();
}

class _XmallScreenState extends State<XmallScreen> {
  final _apiService = ApiService(); // Use singleton or provider
  bool _isLoading = false;
  int _balance = 0;
  
  // Rate: 10 Points = 1 TND
  static const double _conversionRate = 0.1;

  final List<Map<String, dynamic>> _rewards = [
    {
      'id': 1,
      'name': 'Shopping Voucher 10 TND',
      'price': 100, // Points
      'image': 'assets/images/voucher10.png', // Placeholder
      'description': 'Valid for all partners'
    },
    {
      'id': 2,
      'name': 'Shopping Voucher 20 TND',
      'price': 200,
      'image': 'assets/images/voucher20.png',
      'description': 'Valid for all partners'
    },
     {
      'id': 3,
      'name': 'Shopping Voucher 50 TND',
      'price': 500,
      'image': 'assets/images/voucher50.png',
      'description': 'Valid for all partners'
    },
    {
      'id': 4,
      'name': 'Cinema Ticket',
      'price': 150,
      'image': 'assets/images/cinema.png',
      'description': 'Standard Entry'
    },
    {
      'id': 5,
      'name': 'Coffee Break Pack',
      'price': 50,
      'image': 'assets/images/coffee.png',
      'description': 'Coffee + Pastry'
    },
     {
      'id': 6,
      'name': 'Wellness Day Pass',
      'price': 800,
      'image': 'assets/images/spa.png',
      'description': 'Access to Spa/Gym'
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.get('/points/balance');
      if (mounted) {
        setState(() {
          _balance = res['points'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Error fetching balance: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _redeem(Map<String, dynamic> item) async {
    if (_balance < item['price']) {
      _showSnack('Insufficient points!', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Redemption', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Purchase "${item['name']}" for ${item['price']} Points?\n\nThis will deduct from your balance.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF003366), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiService.post('/points/xmall', {
        'points': item['price'],
        'description': 'Redeemed: ${item['name']}',
      });
      _showSnack('Redemption successful! Enjoy your reward.');
      _fetchBalance(); // Refresh balance
    } catch (e) {
      _showSnack('Transaction failed: $e', isError: true);
    } finally {
       if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg), 
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        title: Text('XMALL Rewards', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF003366),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildBalanceInfo(),
          Expanded(
            child: _isLoading && _balance == 0 
              ? const Center(child: CircularProgressIndicator()) 
              : _buildRewardsGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo() {
    final moneyValue = (_balance * _conversionRate).toStringAsFixed(1);
    
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF003366),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          Text('Your Balance', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$_balance', style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Text('pts', style: GoogleFonts.poppins(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wallet, color: Colors.greenAccent, size: 18),
                const SizedBox(width: 8),
                Text('Value: $moneyValue TND', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildRewardsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _rewards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (context, index) {
        final item = _rewards[index];
        final canAfford = _balance >= item['price'];
        
        return Card(
          elevation: 4,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    image: const DecorationImage(
                        // Uses placeholder icon if asset logic not fully setup, or assume assets exist
                        image: AssetImage('assets/images/placeholder_reward.png'),
                        fit: BoxFit.cover,
                    ) 
                  ),
                  child: Center(child: Icon(Icons.card_giftcard, size: 40, color: Colors.grey.shade400)),
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['description'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(fontSize: 10, color: Colors.grey),
                          ),
                        ],
                      ),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item['price']} pts',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF003366),
                                fontSize: 13
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              style: IconButton.styleFrom(
                                backgroundColor: canAfford ? Colors.orangeAccent : Colors.grey.shade300,
                              ),
                              icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                              onPressed: canAfford ? () => _redeem(item) : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideY(begin: 0.1, end: 0);
      },
    );
  }
}
