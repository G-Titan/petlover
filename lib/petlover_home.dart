import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum PetType { dog, cat }

enum DogSize { small, medium, large }

enum DurationType { week, month }

enum LeashChoice { buyNew, useWalkers }

class PetBooking {
  String name;
  PetType type;
  DogSize size;
  DurationType duration;
  bool hasLeash;
  LeashChoice leashChoice;

  PetBooking({
    required this.name,
    this.type = PetType.dog,
    this.size = DogSize.small,
    this.duration = DurationType.week,
    this.hasLeash = true,
    this.leashChoice = LeashChoice.buyNew,
  });

  PetBooking copyWith({
    String? name,
    PetType? type,
    DogSize? size,
    DurationType? duration,
    bool? hasLeash,
    LeashChoice? leashChoice,
  }) {
    return PetBooking(
      name: name ?? this.name,
      type: type ?? this.type,
      size: size ?? this.size,
      duration: duration ?? this.duration,
      hasLeash: hasLeash ?? this.hasLeash,
      leashChoice: leashChoice ?? this.leashChoice,
    );
  }
}

class PetLoverHomePage extends StatefulWidget {
  const PetLoverHomePage({super.key});

  @override
  State<PetLoverHomePage> createState() => _PetLoverHomePageState();
}

class _PetLoverHomePageState extends State<PetLoverHomePage> {
  final List<PetBooking> _pets = [
    PetBooking(name: 'Buddy', type: PetType.dog, size: DogSize.medium, duration: DurationType.week),
  ];

  bool _houseWatchEnabled = false;
  int _houseWatchWeeks = 1;

  bool _utilityWatchEnabled = false;
  int _utilityWatchWeeks = 1;

  final _scrollController = ScrollController();
  final _calculatorKey = GlobalKey();

  // Pricing constants
  static const double baseRateWeek = 100.0;
  static const double baseRateMonth = 300.0;
  static const double catBaseRateWeek = 50.0;
  static const double catBaseRateMonth = 200.0;
  static const double leashFee = 150.0;
  static const double houseWatchRate = 150.0; // P150 per week
  static const double utilityWatchRate = 100.0; // P100 per week

  void _addPet(PetType type) {
    setState(() {
      int nextNum = _pets.length + 1;
      _pets.add(
        PetBooking(
          name: type == PetType.dog ? 'Dog #$nextNum' : 'Cat #$nextNum',
          type: type,
          size: DogSize.small,
          duration: DurationType.week,
        ),
      );
    });
  }

  void _removePet(int index) {
    setState(() {
      _pets.removeAt(index);
    });
  }

  void _updatePet(int index, PetBooking updated) {
    setState(() {
      _pets[index] = updated;
    });
  }

  void _scrollToCalculator() {
    Scrollable.ensureVisible(
      _calculatorKey.currentContext!,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Theme colors
    const Color bgDark = Color(0xFF0F172A);
    const Color cardDark = Color(0xFF1E293B);
    const Color accentOrange = Color(0xFFF97316);
    const Color accentAmber = Color(0xFFF59E0B);
    const Color textPrimary = Color(0xFFF8FAFC);
    const Color textSecondary = Color(0xFF94A3B8);

    // Calculate totals
    double totalBase = 0;
    double totalLeash = 0;
    int leashPurchasedCount = 0;
    int walkerLeashUsedCount = 0;
    bool hadWalkerLeashCoercion = false;

    // We only count dogs for the 1-dog walker leash rule
    int totalDogs = _pets.where((p) => p.type == PetType.dog).length;

    for (var pet in _pets) {
      if (pet.type == PetType.dog) {
        // Dog care rate: P100/week, P300/month
        if (pet.duration == DurationType.week) {
          totalBase += baseRateWeek;
        } else {
          totalBase += baseRateMonth;
        }

        // Dog leash logic
        if (!pet.hasLeash) {
          if (totalDogs == 1) {
            if (pet.leashChoice == LeashChoice.useWalkers) {
              walkerLeashUsedCount++;
            } else {
              leashPurchasedCount++;
            }
            totalLeash += leashFee;
          } else {
            // If multiple dogs, walker leash is not allowed. Force buy
            leashPurchasedCount++;
            totalLeash += leashFee;
            if (pet.leashChoice == LeashChoice.useWalkers) {
              hadWalkerLeashCoercion = true;
            }
          }
        }
      } else {
        // Cat care rates: P50/week, P200/month
        if (pet.duration == DurationType.week) {
          totalBase += catBaseRateWeek;
        } else {
          totalBase += catBaseRateMonth;
        }
      }
    }

    double totalHouseWatch = _houseWatchEnabled ? (houseWatchRate * _houseWatchWeeks) : 0;
    double totalUtilityWatch = _utilityWatchEnabled ? (utilityWatchRate * _utilityWatchWeeks) : 0;
    double grandTotal = totalBase + totalLeash + totalHouseWatch + totalUtilityWatch;

    return Scaffold(
      backgroundColor: bgDark,
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // --- HEADER / HERO SECTION ---
            _buildHeroSection(context, accentOrange, textPrimary, textSecondary, cardDark),

            // --- PRICING TABLES / OVERVIEW ---
            _buildPricingOverview(context, accentOrange, accentAmber, textPrimary, textSecondary, cardDark),

            // --- CALCULATOR & BOOKING FORM ---
            Container(
              key: _calculatorKey,
              padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 20.0),
              child: MaxWidthContainer(
                maxWidth: 1200,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    bool isDesktop = constraints.maxWidth > 900;
                    Widget calculatorContent = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Care & Booking Calculator',
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          color: textPrimary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Customize your pet care package and request add-on services',
                                    style: TextStyle(color: textSecondary, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _addPet(PetType.dog),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: accentOrange,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.pets, size: 20),
                                  label: const Text('Add Dog', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _addPet(PetType.cat),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  icon: const Icon(Icons.pets_outlined, size: 20),
                                  label: const Text('Add Cat', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        if (_pets.isEmpty)
                          _buildEmptyState(accentOrange, textPrimary, textSecondary, cardDark)
                        else
                          isDesktop
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        children: [
                                          ...List.generate(
                                            _pets.length,
                                            (index) => _buildPetCard(
                                              index,
                                              _pets[index],
                                              totalDogs,
                                              accentOrange,
                                              textPrimary,
                                              textSecondary,
                                              cardDark,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          _buildAddonsCard(
                                            accentOrange,
                                            textPrimary,
                                            textSecondary,
                                            cardDark,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 30),
                                    Expanded(
                                      flex: 2,
                                      child: StickySummary(
                                        child: _buildSummaryReceipt(
                                          totalBase: totalBase,
                                          totalLeash: totalLeash,
                                          leashPurchasedCount: leashPurchasedCount,
                                          walkerLeashUsedCount: walkerLeashUsedCount,
                                          hadWalkerLeashCoercion: hadWalkerLeashCoercion,
                                          totalHouseWatch: totalHouseWatch,
                                          totalUtilityWatch: totalUtilityWatch,
                                          grandTotal: grandTotal,
                                          accentOrange: accentOrange,
                                          accentAmber: accentAmber,
                                          textPrimary: textPrimary,
                                          textSecondary: textSecondary,
                                          cardDark: cardDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    ...List.generate(
                                      _pets.length,
                                      (index) => _buildPetCard(
                                        index,
                                        _pets[index],
                                        totalDogs,
                                        accentOrange,
                                        textPrimary,
                                        textSecondary,
                                        cardDark,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    _buildAddonsCard(
                                      accentOrange,
                                      textPrimary,
                                      textSecondary,
                                      cardDark,
                                    ),
                                    const SizedBox(height: 30),
                                    _buildSummaryReceipt(
                                      totalBase: totalBase,
                                      totalLeash: totalLeash,
                                      leashPurchasedCount: leashPurchasedCount,
                                      walkerLeashUsedCount: walkerLeashUsedCount,
                                      hadWalkerLeashCoercion: hadWalkerLeashCoercion,
                                      totalHouseWatch: totalHouseWatch,
                                      totalUtilityWatch: totalUtilityWatch,
                                      grandTotal: grandTotal,
                                      accentOrange: accentOrange,
                                      accentAmber: accentAmber,
                                      textPrimary: textPrimary,
                                      textSecondary: textSecondary,
                                      cardDark: cardDark,
                                    ),
                                  ],
                                ),
                      ],
                    );

                    return calculatorContent;
                  },
                ),
              ),
            ),

            // --- FOOTER ---
            _buildFooter(textSecondary),
          ],
        ),
      ),
    );
  }

  // --- SUB WIDGETS ---

  Widget _buildHeroSection(
    BuildContext context,
    Color accent,
    Color textPrimary,
    Color textSecondary,
    Color cardDark,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF070B19),
            Color(0xFF0F172A),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
      child: MaxWidthContainer(
        maxWidth: 1200,
        child: Column(
          children: [
            // Top Nav
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.pets, color: accent, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'PetLover',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.public, color: accent, size: 16),
                      const SizedBox(width: 6),
                      const Text(
                        'Web & GitHub Pages Ready',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
            // Hero Body
            LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 800;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: accent.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '🐾 PREMIUM PET WALKING & VACATION CARE',
                                  style: TextStyle(
                                    color: accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Taking Care of Your\nFur Babies While You Are Away',
                            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w900,
                                  height: 1.15,
                                  fontSize: isWide ? 48 : 34,
                                ),
                            textAlign: isWide ? TextAlign.left : TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Professional dog walking, cat sitting, and vacation care routines. High reliability, customized pet plans, and premium peace of mind with our inclusive house check options.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 16,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: isWide ? MainAxisAlignment.start : MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                onPressed: _scrollToCalculator,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                  shadowColor: accent.withOpacity(0.4),
                                ),
                                child: const Row(
                                  children: [
                                    Text('Calculate Price Now', style: TextStyle(fontWeight: FontWeight.bold)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton(
                                onPressed: () {
                                  _scrollController.animateTo(
                                    550,
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeOut,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textPrimary,
                                  side: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text('View Services'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (isWide) ...[
                      const SizedBox(width: 40),
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 280,
                                height: 280,
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      accent.withOpacity(0.2),
                                      Colors.transparent,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  color: cardDark,
                                  borderRadius: BorderRadius.circular(40),
                                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 30,
                                      offset: const Offset(0, 15),
                                    )
                                  ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.pets_rounded, size: 80, color: accent),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Happy Pets 🐕🐈',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Safe & Loving Hands',
                                      style: TextStyle(
                                        color: Colors.white38,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingOverview(
    BuildContext context,
    Color accentOrange,
    Color accentAmber,
    Color textPrimary,
    Color textSecondary,
    Color cardDark,
  ) {
    return Container(
      color: const Color(0xFF0B0F19),
      padding: const EdgeInsets.symmetric(vertical: 70.0, horizontal: 20.0),
      width: double.infinity,
      child: MaxWidthContainer(
        maxWidth: 1200,
        child: Column(
          children: [
            Text(
              'Simple & Transparent Pricing',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Flat rates based on pet types, with flexible duration plans.',
              style: TextStyle(color: textSecondary, fontSize: 15),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 45),
            LayoutBuilder(
              builder: (context, constraints) {
                // Determine width based on a 4-column layout for desktop
                double cardWidth;
                if (constraints.maxWidth > 1000) {
                  cardWidth = (constraints.maxWidth - 90) / 4;
                } else if (constraints.maxWidth > 650) {
                  cardWidth = (constraints.maxWidth - 30) / 2;
                } else {
                  cardWidth = constraints.maxWidth;
                }

                return Wrap(
                  spacing: 30,
                  runSpacing: 30,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildTierCard(
                      title: 'Small Dogs',
                      subtitle: 'Under 10kg',
                      weeklyPrice: 'P100',
                      monthlyPrice: 'P300',
                      icon: Icons.cruelty_free,
                      accent: accentAmber,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      cardDark: cardDark,
                      width: cardWidth,
                    ),
                    _buildTierCard(
                      title: 'Medium Dogs',
                      subtitle: '10kg to 25kg',
                      weeklyPrice: 'P100',
                      monthlyPrice: 'P300',
                      icon: Icons.pets,
                      accent: accentOrange,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      cardDark: cardDark,
                      width: cardWidth,
                    ),
                    _buildTierCard(
                      title: 'Large Dogs',
                      subtitle: 'Over 25kg',
                      weeklyPrice: 'P100',
                      monthlyPrice: 'P300',
                      icon: Icons.pets,
                      accent: Colors.deepOrangeAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      cardDark: cardDark,
                      width: cardWidth,
                    ),
                    _buildTierCard(
                      title: 'Cat Care',
                      subtitle: 'Feeding & Litter',
                      weeklyPrice: 'P50',
                      monthlyPrice: 'P200',
                      icon: Icons.pets_outlined,
                      accent: Colors.tealAccent,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      cardDark: cardDark,
                      width: cardWidth,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            // Information Callout (Leash rules + Addons overview)
            Container(
              decoration: BoxDecoration(
                color: cardDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.04)),
              ),
              padding: const EdgeInsets.all(24),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  bool isWide = constraints.maxWidth > 700;
                  return Flex(
                    direction: isWide ? Axis.horizontal : Axis.vertical,
                    crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: accentOrange, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Dog Leash Surcharge Policy',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Owners must supply a leash. If not provided, a P150 charge applies to buy a leash OR use the walker\'s spare leash (walker leash is only available if booking for exactly 1 dog total). Cats do not require a leash.',
                                    style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isWide) const SizedBox(width: 40) else const SizedBox(height: 24),
                      Expanded(
                        flex: isWide ? 1 : 0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.home_outlined, color: accentAmber, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Add-on Sitting Services',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Get peace of mind during vacations. House Watch (P150/week) keeps the property monitored, and Utility Watch (P100/week) checks that water/electricity reserves do not run dry.',
                                    style: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required String title,
    required String subtitle,
    required String weeklyPrice,
    required String monthlyPrice,
    required IconData icon,
    required Color accent,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardDark,
    required double width,
  }) {
    return Container(
      width: width,
      constraints: const BoxConstraints(minWidth: 220),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Weekly Plan', style: TextStyle(color: textSecondary, fontSize: 14)),
              Text(
                weeklyPrice,
                style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Plan', style: TextStyle(color: textSecondary, fontSize: 14)),
              Text(
                monthlyPrice,
                style: TextStyle(color: accent, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    Color accent,
    Color textPrimary,
    Color textSecondary,
    Color cardDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.03)),
      ),
      child: Column(
        children: [
          Icon(Icons.pets_sharp, size: 60, color: textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No Pets Added Yet',
            style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add at least one pet (dog or cat) to calculate your care package cost.',
            style: TextStyle(color: textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _addPet(PetType.dog),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add a Dog'),
              ),
              ElevatedButton.icon(
                onPressed: () => _addPet(PetType.cat),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add a Cat'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildPetCard(
    int index,
    PetBooking pet,
    int totalDogsCount,
    Color accent,
    Color textPrimary,
    Color textSecondary,
    Color cardDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header of Pet item
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: pet.type == PetType.dog ? accent.withOpacity(0.12) : Colors.teal.withOpacity(0.12),
                  radius: 16,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: pet.type == PetType.dog ? accent : Colors.tealAccent, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: pet.name,
                    key: ValueKey('name-${pet.name}-$index'),
                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: pet.type == PetType.dog ? 'Enter dog\'s name' : 'Enter cat\'s name',
                      hintStyle: const TextStyle(color: Colors.white24),
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onFieldSubmitted: (val) {
                      _updatePet(index, pet.copyWith(name: val.trim()));
                    },
                    onChanged: (val) {
                      // Update name state quietly
                      pet.name = val.trim();
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => _removePet(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  tooltip: pet.type == PetType.dog ? 'Remove Dog' : 'Remove Cat',
                ),
              ],
            ),
          ),

          // Body of Pet item
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet type choice chips
                Row(
                  children: [
                    const Text(
                      'Pet Type:',
                      style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Dog 🐕'),
                      selected: pet.type == PetType.dog,
                      selectedColor: accent.withOpacity(0.2),
                      checkmarkColor: accent,
                      labelStyle: TextStyle(
                        color: pet.type == PetType.dog ? Colors.white : Colors.white60,
                        fontWeight: pet.type == PetType.dog ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                        color: pet.type == PetType.dog ? accent : Colors.white10,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          _updatePet(
                            index,
                            pet.copyWith(
                              type: PetType.dog,
                              name: pet.name.startsWith('Cat #') ? 'Dog #${index + 1}' : pet.name,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Cat 🐈'),
                      selected: pet.type == PetType.cat,
                      selectedColor: Colors.teal.withOpacity(0.2),
                      checkmarkColor: Colors.tealAccent,
                      labelStyle: TextStyle(
                        color: pet.type == PetType.cat ? Colors.white : Colors.white60,
                        fontWeight: pet.type == PetType.cat ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      backgroundColor: Colors.transparent,
                      side: BorderSide(
                        color: pet.type == PetType.cat ? Colors.tealAccent : Colors.white10,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          _updatePet(
                            index,
                            pet.copyWith(
                              type: PetType.cat,
                              name: pet.name.startsWith('Dog #') ? 'Cat #${index + 1}' : pet.name,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                LayoutBuilder(
                  builder: (context, petConstraints) {
                    bool isWide = petConstraints.maxWidth > 500;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      children: [
                        // Dog Size / Cat Details
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pet.type == PetType.dog ? 'Dog Size' : 'Cat Care Inclusion',
                                style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: pet.type == PetType.dog
                                    ? DropdownButtonHideUnderline(
                                        child: DropdownButton<DogSize>(
                                          value: pet.size,
                                          dropdownColor: cardDark,
                                          iconEnabledColor: accent,
                                          isExpanded: true,
                                          style: TextStyle(color: textPrimary, fontSize: 14),
                                          onChanged: (val) {
                                            if (val != null) {
                                              _updatePet(index, pet.copyWith(size: val));
                                            }
                                          },
                                          items: const [
                                            DropdownMenuItem(
                                              value: DogSize.small,
                                              child: Text('Small (Under 10kg)'),
                                            ),
                                            DropdownMenuItem(
                                              value: DogSize.medium,
                                              child: Text('Medium (10kg - 25kg)'),
                                            ),
                                            DropdownMenuItem(
                                              value: DogSize.large,
                                              child: Text('Large (Over 25kg)'),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Row(
                                        children: [
                                          const Icon(Icons.check_circle_outline, color: Colors.tealAccent, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Feeding & Litter Box',
                                              style: TextStyle(color: textPrimary, fontSize: 13),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ],
                          ),
                        ),
                        if (isWide) const SizedBox(width: 20) else const SizedBox(height: 16),
                        // Duration Select
                        Expanded(
                          flex: isWide ? 1 : 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Care Duration',
                                style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<DurationType>(
                                    value: pet.duration,
                                    dropdownColor: cardDark,
                                    iconEnabledColor: pet.type == PetType.dog ? accent : Colors.tealAccent,
                                    isExpanded: true,
                                    style: TextStyle(color: textPrimary, fontSize: 14),
                                    onChanged: (val) {
                                      if (val != null) {
                                        _updatePet(index, pet.copyWith(duration: val));
                                      }
                                    },
                                    items: pet.type == PetType.dog
                                        ? const [
                                            DropdownMenuItem(
                                              value: DurationType.week,
                                              child: Text('1 Week (P100)'),
                                            ),
                                            DropdownMenuItem(
                                              value: DurationType.month,
                                              child: Text('1 Month (P300)'),
                                            ),
                                          ]
                                        : const [
                                            DropdownMenuItem(
                                              value: DurationType.week,
                                              child: Text('1 Week (P50)'),
                                            ),
                                            DropdownMenuItem(
                                              value: DurationType.month,
                                              child: Text('1 Month (P200)'),
                                            ),
                                          ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),

                if (pet.type == PetType.dog) ...[
                  const SizedBox(height: 20),
                  // Leash Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Owner owns a leash',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pet.hasLeash ? 'No leash surcharge' : 'Requires leash accommodation (+P150)',
                            style: TextStyle(
                              color: pet.hasLeash ? Colors.green[400] : Colors.amber[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: pet.hasLeash,
                        activeColor: Colors.green,
                        inactiveTrackColor: Colors.white10,
                        onChanged: (val) {
                          _updatePet(index, pet.copyWith(hasLeash: val));
                        },
                      ),
                    ],
                  ),
                  if (!pet.hasLeash) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Leash Provision Option',
                      style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, radioConstraints) {
                        bool isWide = radioConstraints.maxWidth > 400;
                        return Flex(
                          direction: isWide ? Axis.horizontal : Axis.vertical,
                          children: [
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: _buildLeashRadioTile(
                                title: 'Buy New Leash',
                                value: LeashChoice.buyNew,
                                groupValue: pet.leashChoice,
                                onChanged: (val) {
                                  if (val != null) {
                                    _updatePet(index, pet.copyWith(leashChoice: val));
                                  }
                                },
                                cardDark: cardDark,
                              ),
                            ),
                            if (isWide) const SizedBox(width: 12) else const SizedBox(height: 10),
                            Expanded(
                              flex: isWide ? 1 : 0,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _buildLeashRadioTile(
                                    title: 'Use Walker\'s Leash',
                                    value: LeashChoice.useWalkers,
                                    groupValue: pet.leashChoice,
                                    onChanged: totalDogsCount == 1
                                        ? (val) {
                                            if (val != null) {
                                              _updatePet(index, pet.copyWith(leashChoice: val));
                                            }
                                          }
                                        : null,
                                    cardDark: cardDark,
                                    disabled: totalDogsCount > 1,
                                  ),
                                  if (totalDogsCount > 1)
                                    Positioned(
                                      right: 4,
                                      top: -6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber[900],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          '1 Dog Limit',
                                          style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (totalDogsCount > 1 && pet.leashChoice == LeashChoice.useWalkers) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.08),
                          border: Border.all(color: Colors.amber.withOpacity(0.2)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Walker leash is disabled for multi-dog bookings. Purchase rate (+P150) will apply.',
                                style: TextStyle(color: Colors.amber, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLeashRadioTile({
    required String title,
    required LeashChoice value,
    required LeashChoice groupValue,
    required ValueChanged<LeashChoice?>? onChanged,
    required Color cardDark,
    bool disabled = false,
  }) {
    bool isSelected = groupValue == value && !disabled;
    return InkWell(
      onTap: onChanged != null ? () => onChanged(value) : null,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFF97316).withOpacity(0.1)
              : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF97316).withOpacity(0.5)
                : Colors.white.withOpacity(0.06),
          ),
        ),
        child: Opacity(
          opacity: disabled ? 0.4 : 1.0,
          child: Row(
            children: [
              Radio<LeashChoice>(
                value: value,
                groupValue: groupValue,
                activeColor: const Color(0xFFF97316),
                onChanged: onChanged,
              ),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddonsCard(
    Color accent,
    Color textPrimary,
    Color textSecondary,
    Color cardDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_work_outlined, color: accent, size: 22),
              const SizedBox(width: 8),
              Text(
                'Add-On Services (Vacation Sitting)',
                style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 16),

          // House Watch Option
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'House Watch & Security Sitting',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'We keep an eye on your property while you are away • P150/week',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _houseWatchEnabled,
                activeColor: accent,
                onChanged: (val) {
                  setState(() {
                    _houseWatchEnabled = val;
                  });
                },
              ),
            ],
          ),
          if (_houseWatchEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('House Watch Duration:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                IconButton(
                  onPressed: _houseWatchWeeks > 1
                      ? () => setState(() => _houseWatchWeeks--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white60),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_houseWatchWeeks Week${_houseWatchWeeks > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                IconButton(
                  onPressed: _houseWatchWeeks < 12
                      ? () => setState(() => _houseWatchWeeks++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white60),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.06)),
          const SizedBox(height: 16),

          // Utility Watch Option
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Utility watch (Electricity, Water, etc.)',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check that utilities do not run dry or cut off • P100/week',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _utilityWatchEnabled,
                activeColor: accent,
                onChanged: (val) {
                  setState(() {
                    _utilityWatchEnabled = val;
                  });
                },
              ),
            ],
          ),
          if (_utilityWatchEnabled) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Utility Check Duration:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const Spacer(),
                IconButton(
                  onPressed: _utilityWatchWeeks > 1
                      ? () => setState(() => _utilityWatchWeeks--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white60),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_utilityWatchWeeks Week${_utilityWatchWeeks > 1 ? 's' : ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                IconButton(
                  onPressed: _utilityWatchWeeks < 12
                      ? () => setState(() => _utilityWatchWeeks++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline, color: Colors.white60),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildSummaryReceipt({
    required double totalBase,
    required double totalLeash,
    required int leashPurchasedCount,
    required int walkerLeashUsedCount,
    required bool hadWalkerLeashCoercion,
    required double totalHouseWatch,
    required double totalUtilityWatch,
    required double grandTotal,
    required Color accentOrange,
    required Color accentAmber,
    required Color textPrimary,
    required Color textSecondary,
    required Color cardDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: accentOrange, size: 22),
              const SizedBox(width: 8),
              Text(
                'Fare breakdown',
                style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 16),

          // Pet rates list
          ..._pets.asMap().entries.map((entry) {
            int idx = entry.key;
            var pet = entry.value;
            double base;
            String typeLabel;
            String detailLabel;

            if (pet.type == PetType.dog) {
              base = pet.duration == DurationType.week ? baseRateWeek : baseRateMonth;
              typeLabel = 'Dog';
              String sizeLabel = pet.size.name[0].toUpperCase() + pet.size.name.substring(1);
              String durationLabel = pet.duration == DurationType.week ? '1 Week' : '1 Month';
              detailLabel = '$sizeLabel, $durationLabel';
            } else {
              base = pet.duration == DurationType.week ? catBaseRateWeek : catBaseRateMonth;
              typeLabel = 'Cat';
              String durationLabel = pet.duration == DurationType.week ? '1 Week' : '1 Month';
              detailLabel = 'Cat Care, $durationLabel';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${pet.name.isEmpty ? "$typeLabel #${idx + 1}" : pet.name} ($detailLabel)',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  Text(
                    'P${base.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            );
          }),

          if (_pets.isNotEmpty) const SizedBox(height: 6),

          // Leash charges line
          if (totalLeash > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Leash Surcharge',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        if (leashPurchasedCount > 0)
                          Text(
                            '• Bought $leashPurchasedCount leash${leashPurchasedCount > 1 ? "es" : ""} (+P${(leashPurchasedCount * leashFee).toStringAsFixed(0)})',
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                        if (walkerLeashUsedCount > 0)
                          Text(
                            '• Walker leash rented (+P${(walkerLeashUsedCount * leashFee).toStringAsFixed(0)})',
                            style: TextStyle(color: textSecondary, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    'P${totalLeash.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),

          // House watch charges line
          if (_houseWatchEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'House Watch ($_houseWatchWeeks week${_houseWatchWeeks > 1 ? "s" : ""})',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    'P${totalHouseWatch.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),

          // Utility watch charges line
          if (_utilityWatchEnabled)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Utility Watch ($_utilityWatchWeeks week${_utilityWatchWeeks > 1 ? "s" : ""})',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  Text(
                    'P${totalUtilityWatch.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
            ),

          if (hadWalkerLeashCoercion) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: accentAmber, size: 14),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Walker leash option automatically updated to Buy New because you have multiple dogs booked.',
                      style: TextStyle(color: Colors.orange, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),
          Divider(color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 16),

          // Grand Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'P${grandTotal.toStringAsFixed(0)}',
                style: TextStyle(color: accentOrange, fontSize: 24, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Submit booking trigger
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _pets.isEmpty
                  ? null
                  : () {
                      _showBookingDialog(
                        context,
                        grandTotal,
                        totalBase,
                        totalLeash,
                        totalHouseWatch,
                        totalUtilityWatch,
                        leashPurchasedCount,
                        walkerLeashUsedCount,
                        accentOrange,
                        cardDark,
                        textPrimary,
                        textSecondary,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentOrange,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.white10,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Proceed with Booking',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(
    BuildContext context,
    double grandTotal,
    double totalBase,
    double totalLeash,
    double totalHouseWatch,
    double totalUtilityWatch,
    int leashPurchasedCount,
    int walkerLeashUsedCount,
    Color accent,
    Color cardDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    // Generate simple receipt text summary to let them copy or email
    final buffer = StringBuffer();
    buffer.writeln('--- PETLOVER BOOKING RECEIPT ---');
    buffer.writeln('Total Pets: ${_pets.length}');
    for (var i = 0; i < _pets.length; i++) {
      final pet = _pets[i];
      if (pet.type == PetType.dog) {
        final size = pet.size.name[0].toUpperCase() + pet.size.name.substring(1);
        final duration = pet.duration == DurationType.week ? '1 Week' : '1 Month';
        final base = pet.duration == DurationType.week ? baseRateWeek : baseRateMonth;
        buffer.writeln('Pet #${i + 1}: ${pet.name} (Dog - Size: $size, Duration: $duration) - P${base.toStringAsFixed(0)}');
      } else {
        final duration = pet.duration == DurationType.week ? '1 Week' : '1 Month';
        final base = pet.duration == DurationType.week ? catBaseRateWeek : catBaseRateMonth;
        buffer.writeln('Pet #${i + 1}: ${pet.name} (Cat - Cat Care, Duration: $duration) - P${base.toStringAsFixed(0)}');
      }
    }
    if (totalLeash > 0) {
      buffer.writeln('Leash Surcharges: P${totalLeash.toStringAsFixed(0)}');
      if (leashPurchasedCount > 0) {
        buffer.writeln(' - Bought $leashPurchasedCount Leashes');
      }
      if (walkerLeashUsedCount > 0) {
        buffer.writeln(' - Rented Walker Leash');
      }
    }
    if (_houseWatchEnabled) {
      buffer.writeln('House Watch ($_houseWatchWeeks Weeks): P${totalHouseWatch.toStringAsFixed(0)}');
    }
    if (_utilityWatchEnabled) {
      buffer.writeln('Utility Watch ($_utilityWatchWeeks Weeks): P${totalUtilityWatch.toStringAsFixed(0)}');
    }
    buffer.writeln('GRAND TOTAL: P${grandTotal.toStringAsFixed(0)}');
    buffer.writeln('--------------------------------');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardDark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: Colors.white.withOpacity(0.05))),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green[400], size: 26),
              const SizedBox(width: 12),
              const Text('Booking Confirmed!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your booking summary has been prepared. You can click "Email Booking" to send it directly to kevinmanda92@gmail.com, or copy it to send manually.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      buffer.toString(),
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: buffer.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Receipt copied to clipboard!'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Copy Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _launchEmail(buffer.toString());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.email_outlined, size: 16),
              label: const Text('Email Booking', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white54,
              ),
              child: const Text('Dismiss'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchEmail(String receipt) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'kevinmanda92@gmail.com',
      query: _encodeQueryParameters(<String, String>{
        'subject': 'PetLover Booking Request 🐾',
        'body': receipt,
      }),
    );

    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        throw 'Could not launch $emailLaunchUri';
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Widget _buildFooter(Color textSecondary) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF070B19),
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, color: textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'PetLover Dog & Cat Care Solutions',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '© 2026 PetLover. All Rights Reserved. Built with Flutter Web.',
            style: TextStyle(color: textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

// --- UTILITY WIDGETS ---

class MaxWidthContainer extends StatelessWidget {
  final double maxWidth;
  final Widget child;

  const MaxWidthContainer({
    super.key,
    required this.maxWidth,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

class StickySummary extends StatelessWidget {
  final Widget child;

  const StickySummary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
