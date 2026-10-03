{{flutter_js}}
{{flutter_build_config}}

// Same as Flutter's default loader, plus: fade out the HTML splash once the app runs.
_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion: {{flutter_service_worker_version}},
  },
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    const splash = document.getElementById('splash');
    if (splash) {
      splash.classList.add('done');
      setTimeout(() => splash.remove(), 600);
    }
  },
});
