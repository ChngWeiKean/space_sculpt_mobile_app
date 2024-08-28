// import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
// import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
// import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
// import 'package:ar_flutter_plugin/datatypes/node_types.dart';
// import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
// import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
// import 'package:ar_flutter_plugin/models/ar_anchor.dart';
// import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
// import 'package:ar_flutter_plugin/models/ar_node.dart';
// import 'package:flutter/material.dart';
// import 'package:vector_math/vector_math_64.dart';
//
// class ARModelViewer extends StatefulWidget {
//   final String modelUrl; // URL to the .glTF model in Firebase Storage
//
//   ARModelViewer({required this.modelUrl, Key? key}) : super(key: key);
//
//   @override
//   _ARModelViewerState createState() => _ARModelViewerState();
// }
//
// class _ARModelViewerState extends State<ARModelViewer> {
//   ARSessionManager? arSessionManager;
//   ARObjectManager? arObjectManager;
//   ARAnchorManager? arAnchorManager;
//   List<ARNode> nodes = [];
//   List<ARAnchor> anchors = [];
//   DateTime? touchStartTime;
//   String? touchedNodeName;
//   final Duration longPressDuration = Duration(milliseconds: 1000);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('AR Model Viewer'),
//       ),
//       body: Stack(
//         children: [
//           ARView(
//             onARViewCreated: onARViewCreated,
//             planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
//           ),
//           Align(
//             alignment: FractionalOffset.bottomCenter,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 ElevatedButton(
//                   onPressed: onRemoveEverything,
//                   child: Text("Remove Everything"),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void onARViewCreated(
//       ARSessionManager arSessionManager,
//       ARObjectManager arObjectManager,
//       ARAnchorManager arAnchorManager,
//       ARLocationManager arLocationManager) {
//     this.arSessionManager = arSessionManager;
//     this.arObjectManager = arObjectManager;
//     this.arAnchorManager = arAnchorManager;
//
//     this.arSessionManager!.onInitialize(
//       showFeaturePoints: false,
//       showPlanes: true,
//       customPlaneTexturePath: "Images/triangle.png",
//       showWorldOrigin: true,
//       handlePans: true,
//       handleRotation: true,
//     );
//     this.arObjectManager!.onInitialize();
//
//     this.arObjectManager!.onPanStart = onPanStarted;
//     this.arObjectManager!.onPanChange = onPanChanged;
//     this.arObjectManager!.onPanEnd = onPanEnded;
//     this.arObjectManager!.onRotationStart = onRotationStarted;
//     this.arObjectManager!.onRotationChange = onRotationChanged;
//     this.arObjectManager!.onRotationEnd = onRotationEnded;
//
//     this.arObjectManager!.onLongPress = onLongPressed;
//     this.arObjectManager!.onTouchStart = onTouchStart;
//     this.arObjectManager!.onTouchEnd = onTouchEnd;
//     this.arObjectManager!.onTouchMove = onTouchMove;
//
//     _addModelToScene();
//   }
//
//   Future<void> _addModelToScene() async {
//     try {
//       final newNode = ARNode(
//         type: NodeType.webGLB, // Adjust as needed
//         uri: widget.modelUrl,
//         scale: Vector3(0.2, 0.2, 0.2),
//         position: Vector3(0.0, 0.0, 0.0),
//         rotation: Vector4(1.0, 0.0, 0.0, 0.0),
//       );
//
//       bool? didAddNode = await arObjectManager!.addNode(newNode);
//       if (didAddNode != null && didAddNode) {
//         nodes.add(newNode);
//       }
//     } catch (e) {
//       print("Error adding model to scene: $e");
//     }
//   }
//
//   Future<void> onRemoveEverything() async {
//     nodes.forEach((node) {
//       arObjectManager!.removeNode(node);
//     });
//     anchors.forEach((anchor) {
//       arAnchorManager!.removeAnchor(anchor);
//     });
//     anchors = [];
//     nodes = [];
//   }
//
//   void onTouchStart(String nodeName) {
//     touchStartTime = DateTime.now();
//     touchedNodeName = nodeName;
//     print("Touch started on node $nodeName");
//   }
//
//   void onTouchMove(String nodeName) {
//     if (touchedNodeName == nodeName && touchStartTime != null) {
//       final currentTime = DateTime.now();
//       final touchDuration = currentTime.difference(touchStartTime!);
//
//       if (touchDuration > longPressDuration) {
//         // If the touch has been held long enough, consider it a long press
//         onLongPressed(nodeName);
//         touchStartTime = null; // Reset the timer
//       }
//     }
//   }
//
//   void onTouchEnd(String nodeName) {
//     if (touchedNodeName == nodeName && touchStartTime != null) {
//       final currentTime = DateTime.now();
//       final touchDuration = currentTime.difference(touchStartTime!);
//
//       if (touchDuration <= longPressDuration) {
//         // If the touch is released before the long press duration, consider it a pan
//         onPanEnded(nodeName, Matrix4.identity()); // Pass the actual transform if needed
//       }
//
//       touchStartTime = null; // Reset the timer
//       touchedNodeName = null;
//     }
//   }
//
//   void onLongPressed(String nodeName) {
//     print("Long pressed node $nodeName");
//
//     final pannedNode = nodes.firstWhere((element) => element.name == nodeName);
//
//     // Apply the long press effect
//     const double scaleFactor = 1.2; // Scale up by 20%
//     const double floatOffset = 0.1; // Float height offset
//
//     // Create a new transform with scaled and floated position
//     Matrix4 newTransform = Matrix4.compose(
//       pannedNode.position * scaleFactor,
//       pannedNode.rotation as Quaternion,
//       Vector3(scaleFactor, scaleFactor, scaleFactor),
//     )..setTranslation(Vector3(
//         pannedNode.position.x,
//         pannedNode.position.y + floatOffset,
//         pannedNode.position.z));
//
//     arObjectManager!.moveNode(nodeName, newTransform);
//   }
//
//   onPanStarted(String nodeName) {
//     print("Started panning node $nodeName");
//   }
//
//   onPanChanged(String nodeName, Matrix4 newTransform) {
//     print("Panning node $nodeName");
//
//     final pannedNode = nodes.firstWhere((element) => element.name == nodeName);
//     Vector3 translation = newTransform.getTranslation();
//     pannedNode.position = translation;
//
//     arObjectManager!.moveNode(nodeName, newTransform);
//   }
//
//   onPanEnded(String nodeName, Matrix4 newTransform) {
//     print("Ended panning node $nodeName");
//   }
//
//   onRotationStarted(String nodeName) {
//     print("Started rotating node $nodeName");
//   }
//
//   onRotationChanged(String nodeName) {
//     print("Continued rotating node $nodeName");
//   }
//
//   onRotationEnded(String nodeName, Matrix4 newTransform) {
//     print("Ended rotating node $nodeName");
//     final rotatedNode = nodes.firstWhere((element) => element.name == nodeName);
//   }
// }

import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';

class ARModelViewer extends StatefulWidget {
  final String modelUrl; // URL to the .glTF model in Firebase Storage

  ARModelViewer({required this.modelUrl, Key? key}) : super(key: key);

  @override
  _ARModelViewerState createState() => _ARModelViewerState();
}

class _ARModelViewerState extends State<ARModelViewer> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  List<ARNode> nodes = [];
  ARNode? selectedNode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AR Model Viewer'),
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: onRemoveEverything,
                  child: Text("Remove Everything"),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Upward
                  _buildControlButton(Icons.arrow_upward, () => moveNode(Vector3(0.0, 0.1, 0.0))),
                  SizedBox(height: 16),

                  // Downward
                  _buildControlButton(Icons.arrow_downward, () => moveNode(Vector3(0.0, -0.1, 0.0))),
                  SizedBox(height: 16),

                  // Left
                  _buildControlButton(Icons.arrow_back, () => moveNode(Vector3(-0.1, 0.0, 0.0))),
                  SizedBox(height: 16),

                  // Right
                  _buildControlButton(Icons.arrow_forward, () => moveNode(Vector3(0.1, 0.0, 0.0))),
                  SizedBox(height: 16),

                  // Forward (moving into the screen, Z-axis negative)
                  _buildControlButton(Icons.arrow_circle_up, () => moveNode(Vector3(0.0, 0.0, -0.1))),
                  SizedBox(height: 16),

                  // Backward (moving out of the screen, Z-axis positive)
                  _buildControlButton(Icons.arrow_circle_down, () => moveNode(Vector3(0.0, 0.0, 0.1))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onPressed,
        iconSize: 32,
        padding: EdgeInsets.all(16),
      ),
    );
  }

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager,
      ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;

    this.arSessionManager!.onInitialize(
      showFeaturePoints: false,
      showPlanes: true,
      customPlaneTexturePath: "Images/triangle.png",
      showWorldOrigin: true,
      handleRotation: true,
    );
    this.arObjectManager!.onInitialize();

    this.arObjectManager!.onRotationStart = onRotationStarted;
    this.arObjectManager!.onRotationChange = onRotationChanged;
    this.arObjectManager!.onRotationEnd = onRotationEnded;

    _addModelToScene();
  }

  Future<void> _addModelToScene() async {
    try {
      final newNode = ARNode(
        type: NodeType.webGLB, // Adjust as needed
        uri: widget.modelUrl,
        scale: Vector3(0.2, 0.2, 0.2),
        position: Vector3(0.0, 0.0, 0.0),
        rotation: Vector4(1.0, 0.0, 0.0, 0.0),
      );

      bool? didAddNode = await arObjectManager!.addNode(newNode);
      if (didAddNode != null && didAddNode) {
        nodes.add(newNode);
        selectedNode = newNode; // Set the newly added node as selected
      }
    } catch (e) {
      print("Error adding model to scene: $e");
    }
  }

  onRotationStarted(String nodeName) {
    print("Started rotating node $nodeName");
  }

  onRotationChanged(String nodeName) {
    print("Continued rotating node $nodeName");
  }

  onRotationEnded(String nodeName, Matrix4 newTransform) {
    print("Ended rotating node $nodeName");
    final rotatedNode = nodes.firstWhere((element) => element.name == nodeName);
  }

  Future<void> onRemoveEverything() async {
    nodes.forEach((node) {
      arObjectManager!.removeNode(node);
    });
    nodes = [];
  }

  void moveNode(Vector3 offset) {
    if (selectedNode != null) {
      final currentPosition = selectedNode!.position;
      final newPosition = currentPosition + offset;
      selectedNode!.position = newPosition;

      final transform = Matrix4.compose(
        newPosition,
        selectedNode!.rotation as Quaternion,
        selectedNode!.scale,
      );

      arObjectManager!.moveNode(selectedNode!.name, transform);
    }
  }

}
