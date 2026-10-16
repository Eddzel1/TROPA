{{flutter_js}}
{{flutter_build_config}}

// No serviceWorkerSettings: Flutter's own worker is a self-unregistering stub that would remove
// ours (sw.js, registered in index.html), since both live at scope "/".
_flutter.loader.load();
