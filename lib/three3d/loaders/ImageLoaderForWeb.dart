import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

class ImageLoaderLoader {
  // flipY
  // static Future<html.ImageElement> loadImage(url, bool flipY,
  //     {Function? imageDecoder}) {
  //   var completer = Completer<html.ImageElement>();
  //   var imageDom = html.ImageElement();
  //   imageDom.crossOrigin = "";

  //   imageDom.onLoad.listen((e) {
  //     completer.complete(imageDom);
  //   });

  //   if (url is Blob) {
  //     var blob = html.Blob([url.data.buffer], url.options["type"]);
  //     imageDom.src = html.Url.createObjectUrl(blob);
  //   } else {
  //     if (url.startsWith("assets") || url.startsWith("packages")) {
  //       imageDom.src = "assets/" + url;
  //     } 
  //     else {
  //       imageDom.src = url;
  //     }
  //   }

  //   return completer.future;
  // }

  static Future<html.ImageElement> loadImage(dynamic url, bool flipY, {Function? imageDecoder}) {
    var completer = Completer<html.ImageElement>();
    var imageDom = html.ImageElement();
    imageDom.crossOrigin = "";

    imageDom.onLoad.listen((e) {
      completer.complete(imageDom);
    });

    imageDom.onError.listen((e) {
      completer.completeError('Failed to load image: $e');
    });

    try {
      ByteBuffer? buffer;
      String mimeType = 'image/png';

      if (url is Map<String, dynamic>) {
        buffer = url['data']?.buffer as ByteBuffer?;
        mimeType = url['options']?['type'] as String? ?? mimeType;
      } else if (url is String) {
        if (url.startsWith("assets") || url.startsWith("packages")) {
          imageDom.src = "assets/" + url;
          return completer.future;
        } else {
          imageDom.src = url;
          return completer.future;
        }
      } else {
        try {
          dynamic data = url.data;
          if (data is TypedData) {
            buffer = data.buffer;
          } else if (data is List<int>) {
            buffer = Uint8List.fromList(data).buffer;
          }
          
          if (url.options != null && url.options['type'] != null) {
            mimeType = url.options['type'];
          }
        } catch (e) {
          print('Warning: Failed to extract blob data: $e');
        }
      }

      if (buffer != null) {
        var blob = html.Blob([buffer], mimeType);
        var objectUrl = html.Url.createObjectUrl(blob);
        imageDom.src = objectUrl;
      } else {
        throw Exception('Invalid or unsupported image data format');
      }
    } catch (e) {
      completer.completeError('Error processing image: $e');
    }

    return completer.future;
  }
}

extension TypeDataExtension on dynamic {
  ByteBuffer? get buffer {
    if (this is TypedData) {
      return (this as TypedData).buffer;
    } else if (this is List<int>) {
      return Uint8List.fromList(this as List<int>).buffer;
    }
    return null;
  }
}