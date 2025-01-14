import 'dart:developer';

import 'package:ensemble/framework/widget/widget.dart';
import 'package:ensemble/widget/webview/webview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ControllerImpl extends ViewController {
  WebViewController? controller;
  ControllerImpl([this.controller]);
  @override
  void loadUrl(String url) {
    controller!.loadUrl(url);
  }
}
class WebViewState extends WidgetState<EnsembleWebView> {
  // WebView won't render on Android if height is 0 initially
  double? calculatedHeight = 1;
  late ControllerImpl _controller;
  UniqueKey key = UniqueKey();
  Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  void initState() {
    _controller = ControllerImpl();

    // Unless we are in stretch mode, we want our WebView to take scrolling priority
    // when it needs to scroll, in case it is wrapped inside the rootView's scrollable.
    // In another word, when we are stretching to fit the content, there is no internal
    // scrollbar on the webview, so no need to grab the scroll gesture.
    if (widget.controller.expanded == true || widget.controller.height != null) {
      gestureRecognizers = {
        Factory(() => EagerGestureRecognizer())
      };
    }

    super.initState();
  }

  @override
  Widget buildWidget(BuildContext context) {
    // WebView's height will be the same as the HTML height
    Widget webView = SizedBox(
        height: widget.controller.height ?? calculatedHeight,
        width: widget.controller.width,
        child: WebView(
            key: key,
            gestureRecognizers: gestureRecognizers,
            initialUrl: widget.controller.url,
            javascriptMode: JavascriptMode.unrestricted,
            onWebViewCreated:  (controller) {
              _controller.controller = controller;
              widget.controller.webViewController = _controller;
            },
            onWebResourceError: (WebResourceError err) {
              setState(() {
                widget.controller.error = "Error loading html content";
              });
            },
            onProgress: (value) {
              setState(() {
                widget.controller.loadingPercent = value;
              });
            },
            onPageFinished: (param) async {
              calculatedHeight = double.parse(
                  await _controller.controller!.runJavascriptReturningResult(
                      "document.documentElement.scrollHeight;"));
              setState(() {
                widget.controller.loadingPercent = 100;
              });

            })
    );

    return Stack(
      alignment: Alignment.topLeft,
      children: [
        webView,
        // loading indicator
        Visibility(
            visible: widget.controller.loadingPercent! > 0 && widget.controller.loadingPercent! < 100 && widget.controller.error == null,
            child: LinearProgressIndicator(
                minHeight: 3,
                value: widget.controller.loadingPercent! / 100.0
            )
        ),
        // error panel
        Visibility(
          visible: widget.controller.error != null,
          child: Center(
              child: Text(widget.controller.error ?? '')
          ),
        ),

      ],
    );

  }

}