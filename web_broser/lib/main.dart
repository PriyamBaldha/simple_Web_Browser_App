import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ));
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  double progress = 0;
  String url = "";
  final urlController = TextEditingController();

  final GlobalKey inAppWebViewKey = GlobalKey();

  late PullToRefreshController pullToRefreshController;

  InAppWebViewController? inAppWebViewController;

  final TextEditingController searchController = TextEditingController();

  String searchedText = "";

  List<String> allBookmarks = [];

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
        options: PullToRefreshOptions(color: Colors.blue),
        onRefresh: () async {
          if (Platform.isAndroid) {
            inAppWebViewController!.reload();
          }
          if (Platform.isIOS) {
            inAppWebViewController!.loadUrl(
                urlRequest:
                    URLRequest(url: await inAppWebViewController!.getUrl()));
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Web Broser"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_add_outlined),
            onPressed: () async {
              Uri? uri = await inAppWebViewController!.getUrl();

              allBookmarks.add(uri.toString());
            },
          ),
          IconButton(
            icon: Icon(Icons.bookmarks),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Center(
                          child: Text("All Bookmarks"),
                        ),
                        content: SizedBox(
                          height: 280,
                          width: 300,
                          child: ListView.separated(
                            itemCount: allBookmarks.length,
                            itemBuilder: (context, i) => ListTile(
                              onTap: () async {
                                Navigator.of(context).pop();

                                await inAppWebViewController!.loadUrl(
                                  urlRequest: URLRequest(
                                    url: Uri.parse(allBookmarks[i]),
                                  ),
                                );
                              },
                              title: Text(allBookmarks[i]),
                            ),
                            separatorBuilder: (context, i) => const Divider(
                              indent: 20,
                              endIndent: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(6),
              child: TextField(
                controller: searchController,
                onSubmitted: (val) async {
                  searchedText = val;
                  Uri uri = Uri.parse(searchedText);

                  if (uri.scheme.isEmpty) {
                    uri = Uri.parse(
                        "https://www.google.com/search?q=" + searchedText);
                  }

                  await inAppWebViewController!
                      .loadUrl(urlRequest: URLRequest(url: uri));
                },
                decoration: const InputDecoration(
                  hintText: "search your website...",
                  suffixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          progress < 1
              ? LinearProgressIndicator(
                  value: progress,
                  color: Colors.black,
                )
              : Container(),
          Expanded(
            flex: 15,
            child: InAppWebView(
              initialOptions: options,
              key: inAppWebViewKey,
              initialUrlRequest: URLRequest(
                url: Uri.parse("https://www.google.co.in"),
              ),
              onWebViewCreated: (controller) {
                inAppWebViewController = controller;
              },
              // onLoadStart: (controller, url) {
              //   setState(() {
              //     this.url = url.toString();
              //     urlController.text = this.url;
              //   });
              // },
              onProgressChanged: (controller, progress) async {
                if (progress == 100) {
                  pullToRefreshController.endRefreshing();
                }
                setState(() {
                  this.progress = progress / 100;
                  searchController.text = this.url;
                });
              },
              onLoadStop: (controller, url) async {
                await pullToRefreshController.endRefreshing();

                searchController.text = url.toString();

                setState(
                  () {
                    searchController.text = url.toString();
                  },
                );
              },
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () async {
                  await inAppWebViewController!.loadUrl(
                    urlRequest: URLRequest(
                      url: Uri.parse("https://www.google.co.in"),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.home,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                onPressed: () async {
                  if (await inAppWebViewController!.canGoBack()) {
                    await inAppWebViewController!.goBack();
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                onPressed: () async {
                  await inAppWebViewController!.reload();
                },
                icon: const Icon(
                  Icons.refresh,
                  color: Colors.blue,
                ),
              ),
              IconButton(
                onPressed: () async {
                  if (await inAppWebViewController!.canGoForward()) {
                    await inAppWebViewController!.goForward();
                  }
                },
                icon: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.blue,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
