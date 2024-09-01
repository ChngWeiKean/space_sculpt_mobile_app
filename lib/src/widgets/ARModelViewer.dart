import 'dart:async';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart';
import '../../colors.dart';

class ARModelViewer extends StatefulWidget {
  final Map<dynamic, dynamic>? furnitureData;
  final String? selectedVariant;

  ARModelViewer({required this.furnitureData, required this.selectedVariant, Key? key}) : super(key: key);

  @override
  _ARModelViewerState createState() => _ARModelViewerState();
}

class _ARModelViewerState extends State<ARModelViewer> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  List<String> nodeImages = [];
  List<ARNode> nodes = [];
  ARNode? selectedNode;
  final Map<int, bool> _isPressedMap = {};
  bool isLoadingModel = true;

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              margin: const EdgeInsets.only(left: 16.0, top: 30.0),
              width: MediaQuery.of(context).size.width,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.cyanAccent),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildImageList(),
                ],
              ),
            ),
          ),
          Align(
            alignment: isLandscape ? FractionalOffset.topRight : FractionalOffset.bottomCenter,
            child: Padding(
              padding: isLandscape ? const EdgeInsets.only(top: 25.0, right: 16.0)
                  : const EdgeInsets.only(bottom: 16.0),
              child: SpeedDial(
                icon: Icons.add,
                direction: isLandscape ? SpeedDialDirection.down : SpeedDialDirection.up,
                backgroundColor: Colors.cyanAccent,
                childPadding: const EdgeInsets.all(5),
                spaceBetweenChildren: 6,
                overlayColor: Colors.black.withOpacity(0.5),
                overlayOpacity: 0.5,
                children: [
                  SpeedDialChild(
                    child: const Icon(Icons.playlist_remove_outlined, color: Colors.white, size: 30),
                    backgroundColor: Colors.redAccent,
                    label: 'Remove Everything',
                    onTap: onRemoveEverything,
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.remove, color: Colors.white, size: 30),
                    backgroundColor: Colors.redAccent,
                    label: 'Remove Selected Model',
                    onTap: () => onRemoveNode(selectedNode!),
                  ),
                ],
              ),
            ),
          ),
          OrientationBuilder(
            builder: (context, orientation) {
              if (orientation == Orientation.portrait) {
                return Align(
                  alignment: Alignment.centerRight,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Upward
                          _buildControlButton(0, Icons.keyboard_double_arrow_up, () => moveNode(Vector3(0.0, 0.02, 0.0))),
                          const SizedBox(height: 12),
                          // Downward
                          _buildControlButton(1, Icons.keyboard_double_arrow_down, () => moveNode(Vector3(0.0, -0.02, 0.0))),
                          const SizedBox(height: 12),
                          // Left
                          _buildControlButton(2, Icons.arrow_back, () => moveNode(Vector3(-0.02, 0.0, 0.0))),
                          const SizedBox(height: 12),
                          // Right
                          _buildControlButton(3, Icons.arrow_forward, () => moveNode(Vector3(0.02, 0.0, 0.0))),
                          const SizedBox(height: 12),
                          // Forward (moving into the screen, Z-axis negative)
                          _buildControlButton(4, Icons.arrow_upward, () => moveNode(Vector3(0.0, 0.0, -0.02))),
                          const SizedBox(height: 12),
                          // Backward (moving out of the screen, Z-axis positive)
                          _buildControlButton(5, Icons.arrow_downward, () => moveNode(Vector3(0.0, 0.0, 0.02))),
                          const SizedBox(height: 12),
                          // Rotation Controls
                          // Rotate left around Y-axis
                          _buildRotationButton(6, Icons.rotate_left_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), -0.1))),
                          const SizedBox(height: 12),
                          // Rotate right around Y-axis
                          _buildRotationButton(7, Icons.rotate_right_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), 0.1))),
                          const SizedBox(height: 12),
                          // Rotate up around X-axis
                          _buildRotationButton(8, Icons.rotate_left_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(1.0, 0.0, 0.0), 0.1)), rotationAngle: 90),
                          const SizedBox(height: 12),
                          // Rotate down around X-axis
                          _buildRotationButton(9, Icons.rotate_right_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(1.0, 0.0, 0.0), -0.1)), rotationAngle: 90),
                        ],
                      ),
                    ),
                  ),
                );
              } else {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          // Upward
                          _buildControlButton(0, Icons.keyboard_double_arrow_up, () => moveNode(Vector3(0.0, 0.02, 0.0))),
                          const SizedBox(width: 12),
                          // Downward
                          _buildControlButton(1, Icons.keyboard_double_arrow_down, () => moveNode(Vector3(0.0, -0.02, 0.0))),
                          const SizedBox(width: 12),
                          // Left
                          _buildControlButton(2, Icons.arrow_back, () => moveNode(Vector3(-0.02, 0.0, 0.0))),
                          const SizedBox(width: 12),
                          // Right
                          _buildControlButton(3, Icons.arrow_forward, () => moveNode(Vector3(0.02, 0.0, 0.0))),
                          const SizedBox(width: 12),
                          // Forward (moving into the screen, Z-axis negative)
                          _buildControlButton(4, Icons.arrow_upward, () => moveNode(Vector3(0.0, 0.0, -0.02))),
                          const SizedBox(width: 12),
                          // Backward (moving out of the screen, Z-axis positive)
                          _buildControlButton(5, Icons.arrow_downward, () => moveNode(Vector3(0.0, 0.0, 0.02))),
                          const SizedBox(width: 12),
                          // Rotation Controls
                          // Rotate left around Y-axis
                          _buildRotationButton(6, Icons.rotate_left_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), -0.1))),
                          const SizedBox(width: 12),
                          // Rotate right around Y-axis
                          _buildRotationButton(7, Icons.rotate_right_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), 0.1))),
                          const SizedBox(width: 12),
                          // Rotate up around X-axis
                          _buildRotationButton(8, Icons.rotate_left_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(1.0, 0.0, 0.0), 0.1)), rotationAngle: 90),
                          const SizedBox(width: 12),
                          // Rotate down around X-axis
                          _buildRotationButton(9, Icons.rotate_right_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(1.0, 0.0, 0.0), -0.1)), rotationAngle: 90),
                        ],
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageList() {
    print("Node Images: $nodeImages");
    return SizedBox(
      height: 60,
      width: MediaQuery.of(context).size.width - 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: nodeImages.length,
        itemBuilder: (context, index) {
          final imageUrl = nodeImages[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              onTap: () {
                // Handle the tap event here
                print("Image tapped: $imageUrl");
              },
              child: Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.secondary,
                    width: 2.0,
                  ),
                ),
                child: Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Timer? timer;
  Widget _buildControlButton(int key, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      onTapDown: (_) => setState(() => _isPressedMap[key] = true),
      onTapUp: (_) => setState(() => _isPressedMap[key] = false),
      onTapCancel: () => setState(() => _isPressedMap[key] = false),
      onLongPress: () {
        setState(() => _isPressedMap[key] = true);
        timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
          onPressed();
        });
      },
      onLongPressEnd: (_) {
        setState(() => _isPressedMap[key] = false);
        timer?.cancel();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isPressedMap[key] == true ? AppColors.secondary : Colors.cyanAccent,
            width: 2.0,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _isPressedMap[key] == true ? AppColors.secondary : Colors.transparent,
              width: 2.0,
            ),
          ),
          child: IconButton(
            icon: Icon(icon, color: _isPressedMap[key] == true ? AppColors.secondary : Colors.cyanAccent),
            onPressed: onPressed,
            iconSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildRotationButton(int key, IconData icon, VoidCallback onPressed, {double rotationAngle = 0.0}) {
    return GestureDetector(
      onTap: onPressed,
      onTapDown: (_) => setState(() => _isPressedMap[key] = true),
      onTapUp: (_) => setState(() => _isPressedMap[key] = false),
      onTapCancel: () => setState(() => _isPressedMap[key] = false),
      onLongPress: () {
        setState(() => _isPressedMap[key] = true);
        timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
          onPressed();
        });
      },
      onLongPressEnd: (_) {
        setState(() => _isPressedMap[key] = false);
        timer?.cancel();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: _isPressedMap[key] == true ? AppColors.secondary : Colors.cyanAccent,
            width: 2.0,
          ),
        ),
        child: Transform.rotate(
          angle: rotationAngle,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _isPressedMap[key] == true ? AppColors.secondary : Colors.transparent,
                width: 2.0,
              ),
            ),
            child: IconButton(
              icon: Icon(icon, color: _isPressedMap[key] == true ? AppColors.secondary : Colors.cyanAccent),
              onPressed: onPressed,
              iconSize: 20,
            ),
          ),
        ),
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
      showWorldOrigin: false,
      handleTaps: true,
      handlePans: true,
      handleRotation: true,
    );

    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;

    this.arObjectManager!.onRotationStart = onRotationStarted;
    this.arObjectManager!.onRotationChange = onRotationChanged;
    this.arObjectManager!.onRotationEnd = onRotationEnded;
  }

  void onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    // Check if there are any hit test results
    if (hitTestResults.isNotEmpty) {
      // Get the first hit test result (the nearest hit)
      ARHitTestResult hitResult = hitTestResults.first;

      // Extract the position and rotation from the hit test result
      Vector3 position = hitResult.worldTransform.getTranslation();
      Quaternion rotation = Quaternion.fromRotation(hitResult.worldTransform.getRotation());

      print('Tapped on a plane or point at position: $position');
      print('Rotation at the tapped point: $rotation');

      // Call a function to add a model at the tapped position
      await _addModelToSceneAtPosition(position, rotation, widget.furnitureData?['variants']);
    }
  }

  Vector4 quaternionToVector4(Quaternion q) {
    return Vector4(q.x, q.y, q.z, q.w);
  }

  Future<void> _addModelToSceneAtPosition(position, rotation, variant) async {
    setState(() {
      isLoadingModel = true;
    });

    Vector4 rotationVector = quaternionToVector4(rotation);

    try {
      final newNode = ARNode(
        type: NodeType.webGLB,
        name: variant[widget.selectedVariant]['color'],
        uri: variant[widget.selectedVariant]['model'],
        scale: Vector3.all(1),
        position: position,
        rotation: rotationVector,
      );

      bool? didAddNode = await arObjectManager!.addNode(newNode);
      if (didAddNode != null && didAddNode) {
        setState(() {
          nodes.add(newNode);
          selectedNode = newNode;
          isLoadingModel = false;
          print('Model added to detected plane successfully');
        });
      } else {
        print('Failed to add model to the plane');
        setState(() {
          isLoadingModel = false;
        });
      }
    } catch (e) {
      print("Error adding model to detected plane: $e");
      setState(() {
        isLoadingModel = false;
      });
    }
  }

  void onRotationStarted(String nodeName) {
    print("Started rotating node $nodeName");
  }

  void onRotationChanged(String nodeName) {
    print("Continued rotating node $nodeName");
  }

  void onRotationEnded(String nodeName, Matrix4 newTransform) {
    print("Ended rotating node $nodeName");

    // Extract the rotation from the Matrix4 transform
    Quaternion rotation = Quaternion.fromRotation(newTransform.getRotation());

    // Pass the Quaternion to rotateNode
    rotateNode(rotation);
  }

  Future<void> onRemoveEverything() async {
    for (var node in nodes) {
      await arObjectManager!.removeNode(node);
    }
    nodes = [];
  }

  Future<void> onRemoveNode(ARNode node) async {
    await arObjectManager!.removeNode(node);
    nodes.remove(node);
  }

  void moveNode(Vector3 offset) {
    if (selectedNode != null) {
      final currentPosition = selectedNode!.position;
      final newPosition = currentPosition + offset;
      selectedNode!.position = newPosition;

      Quaternion rotation;
      if (selectedNode!.rotation is Quaternion) {
        rotation = selectedNode!.rotation as Quaternion;
      } else {
        rotation = Quaternion.fromRotation(selectedNode!.rotation);
      }

      final transform = Matrix4.compose(
        newPosition,
        rotation,
        selectedNode!.scale,
      );

      arObjectManager!.moveNode(selectedNode!.name, transform);
    }
  }

  void rotateNode(Quaternion deltaRotation) {
    if (selectedNode != null) {
      Vector3 currentPosition = selectedNode!.position;
      Quaternion currentRotation = Quaternion.fromRotation(selectedNode!.rotation);
      Vector3 currentScale = selectedNode!.scale;
      print("Current scale: $currentScale");
      // Normalize delta rotation
      Quaternion normalizedDeltaRotation = deltaRotation.normalized();

      // Apply the new rotation
      Quaternion newRotation = normalizedDeltaRotation * currentRotation;

      // Manually enforce the scale
      selectedNode!.transform = Matrix4.compose(currentPosition, newRotation, Vector3.all(1));

      // Move the node with the updated transform
      arObjectManager!.moveNode(selectedNode!.name, selectedNode!.transform);
    }
  }
}
