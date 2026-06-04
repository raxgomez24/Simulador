import 'package:flutter/material.dart';
import '../presentation/screens/auth/login_screen.dart';
import '../presentation/screens/home/home_screen.dart';
import '../presentation/screens/projects/projects_list_screen.dart';
import '../presentation/screens/projects/project_detail_screen.dart';
import '../presentation/screens/admin/enhanced_admin_dashboard_screen.dart';
import '../presentation/screens/admin/profiles_management_screen.dart';
import '../presentation/screens/admin/themes_management_screen.dart';
import '../presentation/screens/admin/projects_management_screen.dart';
import '../presentation/screens/projection/projection_dashboard_screen.dart';
import '../presentation/screens/investments/my_investments_screen.dart';
import '../presentation/screens/ranking/ranking_screen.dart';
import '../presentation/screens/profile/profile_screen.dart';
import '../presentation/screens/help/help_screen.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/';
  static const String projects = '/projects';
  static const String projectDetail = '/projects/:id';
  static const String investments = '/investments';
  static const String ranking = '/ranking';
  static const String profile = '/profile';
  static const String admin = '/admin';
  static const String adminEnhanced = '/admin/enhanced';
  static const String profiles = '/admin/profiles';
  static const String themes = '/admin/themes';
  static const String adminProjects = '/admin/projects';
  static const String projection = '/projection';
  static const String help = '/help';
  static const String investmentHistory = '/investment-history';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      home: (context) => const HomeScreen(),
      projects: (context) => const ProjectsListScreen(),
      investments: (context) => const MyInvestmentsScreen(),
      investmentHistory: (context) => const MyInvestmentsScreen(),
      profile: (context) => const ProfileScreen(),
      ranking: (context) => const RankingScreen(),
      admin: (context) => const EnhancedAdminDashboardScreen(),
      adminEnhanced: (context) => const EnhancedAdminDashboardScreen(),
      profiles: (context) => const ProfilesManagementScreen(),
      themes: (context) => const ThemesManagementScreen(),
      adminProjects: (context) => const ProjectsManagementScreen(),
      projection: (context) => const ProjectionDashboardScreen(),
      help: (context) => const HelpScreen(),
    };
  }

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case projectDetail:
        final projectId = settings.arguments as String?;
        if (projectId != null) {
          return MaterialPageRoute(
            builder: (context) => ProjectDetailScreen(projectId: projectId),
          );
        }
        break;
    }
    return null;
  }
}
