import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class AboutUsScreen extends StatefulWidget {
  const AboutUsScreen({super.key});

  @override
  State<AboutUsScreen> createState() => _AboutUsScreenState();
}

class _AboutUsScreenState extends State<AboutUsScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 50 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: AppConstants.contactEmail,
      queryParameters: {
        'subject': 'Contact from GRAVON',
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchPhone() async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: AppConstants.contactPhone,
    );
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  void _launchWhatsApp() async {
    final Uri whatsappUri = Uri(
      scheme: 'https',
      path: 'wa.me/${AppConstants.contactPhone.replaceAll('+', '')}',
    );
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            _buildHeroSection(),
            _buildMissionSection(),
            _buildValuesSection(),
            _buildTeamSection(),
            _buildStatsSection(),
            _buildWhyChooseUsSection(),
            _buildContactSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _isScrolled ? Colors.white : Colors.transparent,
      elevation: _isScrolled ? 2 : 0,
      title: Text(
        'About GRAVON',
        style: GoogleFonts.montserrat(
          fontWeight: FontWeight.bold,
          color: AppConstants.darkBlue,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppConstants.darkBlue),
        onPressed: () => Navigator.pop(context),
      ),
      iconTheme: const IconThemeData(color: AppConstants.darkBlue),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppConstants.darkBlue,
            AppConstants.darkBlue.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Welcome to GRAVON',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your trusted platform for discovering, listing, and managing properties across Kenya',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Mission',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppConstants.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Text(
              'At GRAVON, we believe everyone deserves access to quality housing. Our mission is to bridge the gap between property owners and seekers by providing a seamless, transparent, and user-friendly platform. We are committed to transforming the real estate landscape in Kenya through innovation, trust, and exceptional service.',
              style: GoogleFonts.montserrat(
                fontSize: 16,
                height: 1.6,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValuesSection() {
    final values = [
      {
        'icon': FontAwesomeIcons.handshake,
        'title': 'Trust',
        'description': 'Building honest relationships with every transaction',
      },
      {
        'icon': FontAwesomeIcons.lightbulb,
        'title': 'Innovation',
        'description': 'Leveraging technology for better property solutions',
      },
      {
        'icon': FontAwesomeIcons.users,
        'title': 'Community',
        'description': 'Supporting property owners and seekers alike',
      },
      {
        'icon': FontAwesomeIcons.star,
        'title': 'Excellence',
        'description': 'Delivering quality in every aspect of our service',
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      color: AppConstants.backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Our Core Values',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkBlue,
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              childAspectRatio: 1,
            ),
            itemCount: values.length,
            itemBuilder: (context, index) {
              final value = values[index];
              return _buildValueCard(
                icon: value['icon'] as IconData,
                title: value['title'] as String,
                description: value['description'] as String,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildValueCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: AppConstants.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Our Platform',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkBlue,
            ),
          ),
          const SizedBox(height: 24),
          _buildTeamItem(
            'Comprehensive Listings',
            'Browse from thousands of verified properties including rentals, airbnbs, bedsitters, and properties for sale across major Kenyan cities.',
            FontAwesomeIcons.building,
          ),
          const SizedBox(height: 20),
          _buildTeamItem(
            'Car Hire Services',
            'Need transport? Explore our integrated car hire service to get around while viewing properties or on your travels.',
            FontAwesomeIcons.car,
          ),
          const SizedBox(height: 20),
          _buildTeamItem(
            'Secure Transactions',
            'Trust our platform with built-in booking, messaging, and notification systems for seamless communication.',
            FontAwesomeIcons.shield,
          ),
          const SizedBox(height: 20),
          _buildTeamItem(
            'Multi-City Coverage',
            'Find properties in Nairobi, Mombasa, Kisumu, Nakuru, Thika, Malindi, Kakamega, Eldoret and many more cities.',
            FontAwesomeIcons.map,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamItem(String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppConstants.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.darkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    final stats = [
      {'count': '5k+', 'label': 'Active Properties'},
      {'count': '10k+', 'label': 'Happy Users'},
      {'count': '8', 'label': 'Cities Covered'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      color: AppConstants.backgroundColor,
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 24,
              crossAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              return _buildStatCard(
                count: stats[index]['count'] as String,
                label: stats[index]['label'] as String,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String count, required String label}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count,
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyChooseUsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Choose GRAVON?',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppConstants.darkBlue,
            ),
          ),
          const SizedBox(height: 24),
          _buildFeatureItem('✓ Verified Listings', 'All properties are verified for authenticity'),
          const SizedBox(height: 16),
          _buildFeatureItem('✓ Easy Communication', 'Direct messaging with property owners'),
          const SizedBox(height: 16),
          _buildFeatureItem('✓ Simple Booking', 'Quick and easy booking process'),
          const SizedBox(height: 16),
          _buildFeatureItem('✓ Secure Payments', 'Safe and secure transaction handling'),
          const SizedBox(height: 16),
          _buildFeatureItem('✓ 24/7 Support', 'Round-the-clock customer support'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String feature, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          feature,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppConstants.darkBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      color: AppConstants.darkBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get In Touch',
            style: GoogleFonts.montserrat(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          _buildContactCard(
            'Email',
            AppConstants.contactEmail,
            FontAwesomeIcons.envelope,
            _launchEmail,
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            'Phone',
            AppConstants.contactPhone,
            FontAwesomeIcons.phone,
            _launchPhone,
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            'WhatsApp',
            'Chat with us on WhatsApp',
            FontAwesomeIcons.whatsapp,
            _launchWhatsApp,
          ),
          const SizedBox(height: 16),
          _buildContactCard(
            'Facebook',
            'Follow us on Facebook',
            FontAwesomeIcons.facebook,
            () => _launchUrl(AppConstants.contactFacebook),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              'Thank you for choosing GRAVON. We\'re here to help you find your dream property!',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                color: Colors.white,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppConstants.primaryColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }
}
