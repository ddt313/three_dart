import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter_gl/flutter_gl.dart';
import 'package:three_dart/three_dart.dart' as THREE;
import 'package:three_dart_jsm/three_dart_jsm.dart' as THREE_JSM;

class webgl_loader_gltf extends StatefulWidget {
  String fileName;
  webgl_loader_gltf({Key? key, required this.fileName}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<webgl_loader_gltf> {
  late FlutterGlPlugin three3dRender;
  THREE.WebGLRenderer? renderer;

  int? fboId;
  late double width;
  late double height;

  Size? screenSize;

  late THREE.Scene scene;
  late THREE.Camera camera;
  late THREE.Mesh mesh;

  double dpr = 1.0;

  var AMOUNT = 4;

  bool verbose = true;
  bool disposed = false;

  late THREE.Object3D object;

  late THREE.Texture texture;
  late THREE.TextureLoader textureLoader;
  final GlobalKey<THREE_JSM.DomLikeListenableState> _globalKey = GlobalKey<THREE_JSM.DomLikeListenableState>();
  late THREE_JSM.OrbitControls controls;
  THREE.WebGLRenderTarget? renderTarget;

  dynamic sourceTexture;

  @override
  void initState() {
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    width = screenSize!.width;
    height = screenSize!.height;

    three3dRender = FlutterGlPlugin();

    Map<String, dynamic> _options = {
      "antialias": true,
      "alpha": false,
      "width": width.toInt(),
      "height": height.toInt(),
      "dpr": dpr,
      'precision': 'highp'
    };

    await three3dRender.initialize(options: _options);

    setState(() {});

    // TODO web wait dom ok!!!
    Future.delayed(const Duration(milliseconds: 100), () async {
      await three3dRender.prepareContext();

      initScene();
    });
  }

  initSize(BuildContext context) {
    if (screenSize != null) {
      return;
    }

    final mqd = MediaQuery.of(context);

    screenSize = mqd.size;
    dpr = mqd.devicePixelRatio;

    initPlatformState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
      ),
      body: Builder(
        builder: (BuildContext context) {
          initSize(context);
          return _build(context);
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Text("render"),
        onPressed: () {
          render();
        },
      ),
    );
  }

  Widget _build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: THREE_JSM.DomLikeListenable(
        key: _globalKey,
        builder: (BuildContext context) {
          return Container(
            width: width,
            height: height,
            color: Theme.of(context).canvasColor,
            child: Builder(builder: (BuildContext context) {
              if (kIsWeb) {
                return three3dRender.isInitialized
                    ? HtmlElementView(
                        viewType:
                            three3dRender.textureId!.toString())
                    : Container();
              } else {
                return three3dRender.isInitialized
                    ? Texture(textureId: three3dRender.textureId!)
                    : Container();
              }
            })
          );
        }),
    );
  }

  render() {
    int _t = DateTime.now().millisecondsSinceEpoch;

    final _gl = three3dRender.gl;

    renderer!.render(scene, camera);

    int _t1 = DateTime.now().millisecondsSinceEpoch;

    if (verbose) {
      print("render cost: ${_t1 - _t} ");
      print(renderer!.info.memory);
      print(renderer!.info.render);
    }

    // 重要 更新纹理之前一定要调用 确保gl程序执行完毕
    _gl.flush();
    controls.update();
    if (verbose) print(" render: sourceTexture: $sourceTexture ");

    if (!kIsWeb) {
      three3dRender.updateTexture(sourceTexture);
    }
  }

  initRenderer() {
    Map<String, dynamic> _options = {
      "width": width,
      "height": height,
      "gl": three3dRender.gl,
      "antialias": true,
      "canvas": three3dRender.element
    };

    if(!kIsWeb){
      _options['logarithmicDepthBuffer'] = true;
    }

    renderer = THREE.WebGLRenderer(_options);
    renderer!.setPixelRatio(dpr);
    renderer!.setSize(width, height, false);
    renderer!.shadowMap.enabled = true;

    // renderer!.toneMapping = THREE.ACESFilmicToneMapping;
    // renderer!.toneMappingExposure = 1;
    // renderer!.outputEncoding = THREE.sRGBEncoding;

    if (!kIsWeb) {
      var pars = THREE.WebGLRenderTargetOptions({"format": THREE.RGBAFormat,"samples": 4});
      renderTarget = THREE.WebGLRenderTarget((width * dpr).toInt(), (height * dpr).toInt(), pars);
      renderTarget!.samples = 4;
      renderer!.setRenderTarget(renderTarget);
      sourceTexture = renderer!.getRenderTargetGLTexture(renderTarget!);
    }
    else {
      renderTarget = null;
    }
  }

  void initScene() async{
    await initPage();
    initRenderer();
    animate();
  }

  initPage() async {
    scene = THREE.Scene();

    camera = THREE.PerspectiveCamera(45, width / height, 0.25, 20);
    camera.position.set( - 0, 0, 2.7 );
    camera.lookAt(scene.position);

    THREE_JSM.OrbitControls _controls = THREE_JSM.OrbitControls(camera, _globalKey);
    controls = _controls;

    THREE_JSM.RGBELoader _loader = THREE_JSM.RGBELoader(null);
    _loader.setPath('assets/textures/equirectangular/');
    var _hdrTexture = await _loader.loadAsync('royal_esplanade_1k.hdr');
    _hdrTexture.mapping = THREE.EquirectangularReflectionMapping;

    scene.background = _hdrTexture;
    scene.environment = _hdrTexture;

    scene.add( THREE.AmbientLight( 0xffffff ) );

    THREE_JSM.GLTFLoader loader = THREE_JSM.GLTFLoader(null)
        .setPath('assets/models/gltf/DamagedHelmet/glTF/');

    var result = await loader.loadAsync('DamagedHelmet.gltf');

    print(" gltf load sucess result: $result  ");

    object = result["scene"];

    // var geometry = new THREE.PlaneGeometry(2, 2);
    // var material = new THREE.MeshBasicMaterial();

    // object.traverse( ( child ) {
    //   if ( child is THREE.Mesh ) {
    //     material.map = child.material.map;
    //   }
    // } );

    // var mesh = new THREE.Mesh(geometry, material);
    // scene.add(mesh);

    // object.traverse( ( child ) {
    //   if ( child.isMesh ) {
    // child.material.map = texture;
    //   }
    // } );



    scene.add(object);
    textureLoader = THREE.TextureLoader(null);
    // scene.overrideMaterial = new THREE.MeshBasicMaterial();
  }

  animate() {
    if (!mounted || disposed) {
      return;
    }

    render();

    Future.delayed(Duration(milliseconds: 40), () {
      animate();
    });
  }
  @override
  void dispose() {
    
    print(" dispose ............. ");
    disposed = true;
    THREE.loading = {};
    controls.clearListeners();
    three3dRender.dispose();
    print(" dispose finish ");
    super.dispose();
  }
}
