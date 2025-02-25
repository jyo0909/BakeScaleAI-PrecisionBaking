// settings_panel.dart
import 'package:flutter/material.dart';

class SettingsPanel extends StatelessWidget {
  final VoidCallback onClose;
  final String userName;
  final String? profileImageUrl;

  const SettingsPanel({
    Key? key,
    required this.onClose,
    required this.userName,
    this.profileImageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop
          GestureDetector(
            onTap: onClose,
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: profileImageUrl != null
                                ? NetworkImage(profileImageUrl!)
                                : null,
                            child: profileImageUrl == null
                                ? const Icon(Icons.person, size: 30)
                                : null,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Handle view profile
                                  },
                                  child: const Text('View Profile'),
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
                      onTap: () {},
                    ),
                    
                    _buildExpandableCategory(
                      'Preferences',
                      Icons.settings,
                      [
                        _buildSubOption('Notifications', Icons.notifications),
                        _buildSubOption('Appearance', Icons.palette),
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
                        // Handle sign out
                      },
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
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
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
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
      leading: Icon(icon),
      title: Text(title),
      children: subOptions,
    );
  }

  Widget _buildSubOption(String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      onTap: () {
        // Handle sub-option tap
      },
    );
  }
}