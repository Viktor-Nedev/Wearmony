import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'features/dev/pipeline_screen.dart';
import 'features/landing/landing_screen.dart';
import 'features/organizer/create_event_screen.dart';
import 'features/participant/join_screen.dart';
import 'features/vendor/vendor_screen.dart';

GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', builder: (context, state) => const LandingScreen()),
        GoRoute(path: '/create', builder: (context, state) => const CreateEventScreen()),
        GoRoute(
          path: '/join',
          builder: (context, state) => JoinScreen(initialCode: state.uri.queryParameters['code']),
        ),
        GoRoute(
          path: '/join/:code',
          builder: (context, state) => JoinScreen(initialCode: state.pathParameters['code']),
        ),
        GoRoute(
          path: '/v/:token',
          builder: (context, state) => VendorScreen(token: state.pathParameters['token']!),
        ),
        if (kDebugMode)
          GoRoute(path: '/dev/pipeline', builder: (context, state) => const PipelineScreen()),
      ],
    );
