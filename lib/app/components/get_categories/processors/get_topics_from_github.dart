import 'dart:convert';
import 'dart:io';

import 'package:haskell_is_beautiful/app/entities.dart';
import 'package:haskell_is_beautiful/base/pipelines.dart';
import 'package:recase/recase.dart';

class GetTopicsFromGithub extends AsyncProcessor {
  @override
  Future safeExecute(PipelineContext context) async {
    var categories = await this.getContent();
    if (!context.properties.containsKey("result")) {
      context.properties["result"] = categories;
    } else {
      (context.properties["result"] as List<Category>).addAll(categories);
    }
  }

  Future<List<Category>> getContent() async {
    var files = await getMetadataFiles();
    var map = <Category>[];

    for (var file in files) {
      var json = await getJson(file);
      var key = getName(json);

      map.add(
          Category(json["tabs"], key, getIcon(json), topic: getCategory(json)));
    }

    return map;
  }

  String getIcon(Map<String, dynamic> json) {
    if (json.containsKey("icon")) {
      return json["icon"];
    }

    return "ac_unit";
  }

  Future<Map<String, dynamic>> getJson(String url) async {
    var content = "";
    var uri = Uri.parse(url);

    await new HttpClient()
        .getUrl(uri)
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.transform(new Utf8Decoder()).listen((data) {
              content = data;
            }).asFuture());
    return jsonDecode(content);
  }

  Future<List<String>> getMetadataFiles() async {
    var content = "";
    var uri = Uri.parse(
        "https://api.github.com/repositories/221082746/contents/assets/Topics");

    await new HttpClient()
        .getUrl(uri)
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) =>
            response.transform(new Utf8Decoder()).listen((data) {
              content = data;
            }).asFuture());

    if (content.contains("Not Found")) {
      return [];
    }

    var json = jsonDecode(content);
    if (!(json is List<Map<String, dynamic>>)) {
      return [];
    }

    List<Map<String, dynamic>> jsonFiles = json;
    return jsonFiles
        .map((e) => e.containsKey("download_url") ? e["download_url"] : null)
        .where((element) => element != null)
        .toList();
  }

  String getName(Map<String, dynamic> json) {
    if (json.containsKey("title")) {
      String result = json["title"];
      ReCase rc = new ReCase(result);
      return rc.titleCase;
    }
    return "Interesting code";
  }

  String getCategory(Map<String, dynamic> json) {
    if (json.containsKey("category")) {
      return json["category"];
    }
    return "Other";
  }
}
