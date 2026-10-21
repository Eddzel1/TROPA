/// What part of the app the browser actually shows (web only; null elsewhere).
typedef VisibleArea = ({double viewTop, double viewBottom, double visibleTop, double visibleBottom});

VisibleArea? visibleArea() => null;

bool get keyboardDebugRequested => false;
