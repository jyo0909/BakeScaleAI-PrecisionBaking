import 'package:flutter/material.dart';

class SettingsPanel extends StatefulWidget {
  final VoidCallback onClose;
  final String userName;
  final String? profileImageUrl;
  final VoidCallback? onLogout; // Added logout callback

  const SettingsPanel({
    Key? key,
    required this.onClose,
    required this.userName,
    this.profileImageUrl,
    this.onLogout, // Added optional parameter
  }) : super(key: key);

  @override
  _SettingsPanelState createState() => _SettingsPanelState();
}

enum ThemeMode {
  light,
  dark,
  system,
}

class _SettingsPanelState extends State<SettingsPanel> {
  String selectedLanguage = "English"; // Default language
  bool showAccountSettings = false;
  bool showAppearanceSettings = false;
  ThemeMode currentThemeMode = ThemeMode.system; // Default theme mode
  
  // Define green color constants
  final Color primaryGreen = Colors.green; // You can replace with your exact green color
  final Color lightGreen = Colors.green.withOpacity(0.2);

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Select Language"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption("English"),
              _buildLanguageOption("Español (Spanish)"),
              _buildLanguageOption("Français (French)"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: primaryGreen)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: selectedLanguage == language
          ? Icon(Icons.check, color: primaryGreen)
          : null,
      onTap: () {
        setState(() {
          selectedLanguage = language;
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withOpacity(0.5),
            ),
          ),
          // Panel
          Positioned(
            top: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: MediaQuery.of(context).size.width * 0.85,
              constraints: BoxConstraints(
                maxWidth: 400,
                maxHeight: MediaQuery.of(context).size.height,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(-5, 0),
                  ),
                ],
              ),
              child: showAccountSettings 
                  ? _buildAccountSettingsContent()
                  : showAppearanceSettings
                      ? _buildAppearanceSettingsContent()
                      : _buildMainSettingsContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSettingsContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: lightGreen,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: primaryGreen,
                  backgroundImage: widget.profileImageUrl != null
                      ? NetworkImage(widget.profileImageUrl!)
                      : null,
                  child: widget.profileImageUrl == null
                      ? const Icon(Icons.person, size: 30, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName, // Use the username from the widget
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Handle view profile
                        },
                        child: Text('View Profile', style: TextStyle(color: primaryGreen)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Settings Categories
          _buildSettingsCategory(
            'Account Settings',
            Icons.account_circle,
            onTap: () {
              setState(() {
                showAccountSettings = true;
              });
            },
          ),

          _buildExpandableCategory(
            'Preferences',
            Icons.settings,
            [
              _buildSubOption('Notifications', Icons.notifications),
              _buildSubOption('Appearance', Icons.palette, onTap: () {
                setState(() {
                  showAppearanceSettings = true;
                });
              }),
              _buildLanguageOptionTile(),
            ],
          ),

          _buildExpandableCategory(
            'Saved & Bookmarks',
            Icons.bookmark,
            [
              _buildSubOption('Saved Items', Icons.save),
              _buildSubOption('Bookmarked Content', Icons.bookmark_border),
            ],
          ),

          _buildExpandableCategory(
            'Support & Information',
            Icons.help,
            [
              _buildSubOption('Contact Support', Icons.support_agent),
              _buildSubOption('About the App', Icons.info),
            ],
          ),

          const Divider(),

          _buildSettingsCategory(
            'Sign Out',
            Icons.exit_to_app,
            onTap: () {
              if (widget.onLogout != null) {
                widget.onLogout!(); // Use the logout callback if provided
              }
              widget.onClose(); // Close the panel after logout
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettingsContent() {
    return Column(
      children: [
        // App Bar
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              setState(() {
                showAppearanceSettings = false;
              });
            },
          ),
          title: const Text('Appearance', style: TextStyle(color: Colors.white)),
          elevation: 0,
          backgroundColor: primaryGreen,
        ),
        
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Theme',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryGreen,
                    ),
                  ),
                ),
                
                // Light Theme Option
                _buildThemeOption(
                  title: 'Bright',
                  icon: Icons.light_mode,
                  themeMode: ThemeMode.light,
                  description: 'Light background with green accents',
                ),
                
                // Dark Theme Option
                _buildThemeOption(
                  title: 'Dark',
                  icon: Icons.dark_mode,
                  themeMode: ThemeMode.dark,
                  description: 'Dark background with green accents',
                ),
                
                // System Theme Option
                _buildThemeOption(
                  title: 'System Default',
                  icon: Icons.settings_suggest,
                  themeMode: ThemeMode.system,
                  description: 'Follow system theme settings',
                ),
                
                const SizedBox(height: 20),
                
                // Preview Section
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Preview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                
                // Theme Preview
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getPreviewBackgroundColor(),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: primaryGreen,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Theme Preview',
                        style: TextStyle(
                          color: _getPreviewTextColor(),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryGreen,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Button',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getPreviewBackgroundColor() {
    switch (currentThemeMode) {
      case ThemeMode.light:
        return Colors.white;
      case ThemeMode.dark:
        return const Color(0xFF121212); // Dark mode background color
      case ThemeMode.system:
        // Simplified system check - in a real app, would use MediaQuery.platformBrightness
        return Colors.grey.shade200; // Neutral color for system theme preview
    }
  }

  Color _getPreviewTextColor() {
    switch (currentThemeMode) {
      case ThemeMode.light:
        return Colors.black87;
      case ThemeMode.dark:
        return Colors.white;
      case ThemeMode.system:
        return Colors.black87;
    }
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required ThemeMode themeMode,
    required String description,
  }) {
    final bool isSelected = currentThemeMode == themeMode;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? primaryGreen : Colors.grey,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? primaryGreen : Colors.grey.shade800,
        ),
      ),
      subtitle: Text(description),
      trailing: isSelected 
          ? Icon(Icons.check_circle, color: primaryGreen)
          : Icon(Icons.circle_outlined, color: Colors.grey),
      onTap: () {
        setState(() {
          currentThemeMode = themeMode;
          // In a real app, you would apply the theme here
          // Example: Provider.of<ThemeProvider>(context, listen: false).setThemeMode(themeMode);
        });
      },
    );
  }

  Widget _buildAccountSettingsContent() {
    return Column(
      children: [
        // App Bar
        AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              setState(() {
                showAccountSettings = false;
              });
            },
          ),
          title: const Text('Profile', style: TextStyle(color: Colors.white)),
          elevation: 0,
          backgroundColor: primaryGreen, // Use green for AppBar
        ),
        
        Expanded(
          child: Container(
            color: Colors.white, // White background
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Personal Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen, // Green title
                      ),
                    ),
                  ),
                  
                  _buildProfileDetailItem('User Name', widget.userName),
                  
                  _buildProfilePhotoItem(),
                  
                  _buildProfileDetailItem('Location', 'India'),
                  
                  _buildProfileDetailItem('Zip/Postal Code', '530016'),
                  
                  _buildProfileDetailItem('Time Zone', 'India Standard Time (Chennai)'),
                  
                  _buildProfileDetailItem('Email Address', 'cloudbakers@gmail.com'),
                  
                  _buildProfileDetailItem('Units', 'kg, cm, cal, km, ml'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDetailItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200, // Light border
            width: 1
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade800, // Dark text for label
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: primaryGreen, // Green text for values
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePhotoItem() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200, // Light border
            width: 1
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile Photo',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade800, // Dark text for label
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: primaryGreen.withOpacity(0.2), // Light green background
            child: Icon(
              Icons.person,
              color: primaryGreen, // Green icon
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCategory(
    String title,
    IconData icon, {
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : primaryGreen, // Green icons
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.grey.shade800,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildExpandableCategory(
    String title,
    IconData icon,
    List<Widget> subOptions,
  ) {
    return ExpansionTile(
      leading: Icon(icon, color: primaryGreen), // Green icon
      title: Text(title),
      children: subOptions,
      iconColor: primaryGreen, // Green expansion icon
      textColor: primaryGreen, // Green text when expanded
    );
  }

  Widget _buildSubOption(String title, IconData icon, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, size: 22, color: primaryGreen.withOpacity(0.8)), // Green icon with opacity
      title: Text(title),
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      onTap: onTap ?? () {
        // Handle sub-option tap
      },
    );
  }

  Widget _buildLanguageOptionTile() {
    return ListTile(
      leading: Icon(Icons.language, size: 22, color: primaryGreen.withOpacity(0.8)), // Green icon with opacity
      title: const Text("Language"),
      subtitle: Text(selectedLanguage), // Show selected language
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      onTap: _showLanguageDialog,
    );
  }
}