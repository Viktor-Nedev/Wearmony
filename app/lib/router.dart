import 'package:go_router/go_router.dart';

import 'features/event/event_shell.dart';
import 'features/inclusion/inclusion_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/organizer/create_event_screen.dart';
import 'features/participant/consent_screen.dart';
import 'features/participant/join_screen.dart';
import 'features/participant/my_data_screen.dart';
import 'features/participant/photo_screen.dart';
import 'features/vendor/vendor_screen.dart';
import 'widgets/session_widgets.dart';

GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SessionGate(child: LandingScreen()),
    ),
    GoRoute(
      path: '/create',
      builder: (context, state) =>
          const SessionGate(child: CreateEventScreen()),
    ),
    GoRoute(
      path: '/join',
      builder: (context, state) => SessionGate(
        child: JoinScreen(initialCode: state.uri.queryParameters['code']),
      ),
    ),
    GoRoute(
      path: '/join/:code',
      builder: (context, state) => SessionGate(
        child: JoinScreen(initialCode: state.pathParameters['code']),
      ),
    ),
    GoRoute(
      path: '/e/:eventId',
      builder: (context, state) => SessionGate(
        child: EventShell(
          eventId: state.pathParameters['eventId']!,
          initialTab: state.uri.queryParameters['tab'],
        ),
      ),
      routes: [
        GoRoute(
          path: 'consent',
          builder: (context, state) => SessionGate(
            child: ConsentScreen(eventId: state.pathParameters['eventId']!),
          ),
        ),
        GoRoute(
          path: 'photo',
          builder: (context, state) => SessionGate(
            child: PhotoScreen(eventId: state.pathParameters['eventId']!),
          ),
        ),
        GoRoute(
          path: 'data',
          builder: (context, state) => SessionGate(
            child: MyDataScreen(eventId: state.pathParameters['eventId']!),
          ),
        ),
      ],
    ),
    // Public pages: no sign-in needed.
    GoRoute(
      path: '/v/:token',
      builder: (context, state) =>
          VendorScreen(token: state.pathParameters['token']!),
    ),
    GoRoute(
      path: '/inclusion',
      builder: (context, state) => const InclusionScreen(),
    ),
  ],
);
