import 'package:web/web.dart' as web;

/// What part of the app the browser actually shows, in CSS pixels from the top of the page:
/// the app's own element (`viewTop`..`viewBottom`) and the area the browser shows above the
/// on-screen keyboard (`visibleTop`..`visibleBottom`, from `window.visualViewport`).
typedef VisibleArea = ({double viewTop, double viewBottom, double visibleTop, double visibleBottom});

VisibleArea? visibleArea() {
  final vv = web.window.visualViewport;
  if (vv == null) return null;
  final host = web.document.querySelector('flutter-view') ?? web.document.querySelector('flt-glass-pane');
  final rect = host?.getBoundingClientRect();
  // getBoundingClientRect is relative to the layout viewport; the visual viewport is offset from it.
  return (
    viewTop: rect?.top ?? 0,
    viewBottom: rect?.bottom ?? web.window.innerHeight.toDouble(),
    visibleTop: vv.offsetTop,
    visibleBottom: vv.offsetTop + vv.height,
  );
}

/// Open the site with `?kbdebug=1` to show the keyboard measurements on screen.
bool get keyboardDebugRequested => Uri.base.queryParameters.containsKey('kbdebug');
