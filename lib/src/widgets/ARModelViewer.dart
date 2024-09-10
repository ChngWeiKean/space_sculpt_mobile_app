import 'dart:async';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:firebase_database/firebase_database.dart';
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
  final _dbRef = FirebaseDatabase.instance.ref();
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  List<String> nodeImages = [];
  List<ARNode> nodes = [];
  ARNode? selectedNode;
  String? selectedVariant;
  Map<dynamic, dynamic> selectedFurniture = {};
  final Map<int, bool> _isPressedMap = {};
  bool isLoadingModel = true;
  final List<Map<dynamic, dynamic>> _furnitureList = [];
  final List<Map<dynamic, dynamic>> _subcategoryList = [];
  final List<String> _variantList = [];

  @override
  void initState() {
    super.initState();
    _fetchSubcategories();
  }

  Future<void> _fetchSubcategories() async {
    final subcategorySnapshot = await _dbRef.child('subcategories').get();
    if (subcategorySnapshot.value != null) {
      final subcategoryData = subcategorySnapshot.value as Map<dynamic, dynamic>;
      subcategoryData?.forEach((key, value) {
        value['id'] = key;
        _subcategoryList.add(value);
      });
    }

    await _fetchFurniture();
  }

  Future<void> _fetchFurniture() async {
    final furnitureSnapshot = await _dbRef.child('furniture').get();
    if (furnitureSnapshot.value != null) {
      final furnitureData = furnitureSnapshot.value as Map<dynamic, dynamic>;
      furnitureData?.forEach((key, value) async {
        final subcategoryName = _subcategoryList.firstWhere((element) => element['id'] == value['subcategory'])['name'];
        value['subcategoryName'] = subcategoryName;

        final variants = (value['variants'] as Map<dynamic, dynamic>?)?.values.toList() ?? [];
        final variantKeys = (value['variants'] as Map<dynamic, dynamic>?)?.keys.toList() ?? [];

        // add variant keys to each variant data
        for (var i = 0; i < variantKeys.length; i++) {
          variants[i]['key'] = variantKeys[i];
        }

        value['mainImage'] = variants.isNotEmpty
            ? variants.firstWhere(
                (variant) => int.parse(variant['inventory'].toString()) > 0,
            orElse: () => variants.first)['image']
            : null;
        value['selectedVariant'] = variants.isNotEmpty
            ? variants.firstWhere(
                (variant) => int.parse(variant['inventory'].toString()) > 0,
            orElse: () => variants.first)['color']
            : null;
        value['order_length'] = (value['orders']?.toList())?.length ?? 0;

        if (value['ratings'] != null && value['ratings'] is List) {
          List ratingsList = value['ratings'];
          value['ratingCount'] = ratingsList.length;
          double totalRatings = 0.0;

          for (var rating in ratingsList) {
            if (rating['rating'] != null) {
              totalRatings += double.parse(rating['rating'].toString());
            }
          }

          if (value['ratingCount'] > 0) {
            value['averageRatings'] = totalRatings / value['ratingCount'];
          }
        }

        value['id'] = key;
        _furnitureList.add(value);
      });
    }
  }

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
                childPadding: const EdgeInsets.all(10),
                spaceBetweenChildren: 6,
                overlayColor: Colors.black.withOpacity(0.5),
                overlayOpacity: 0.5,
                children: [
                  SpeedDialChild(
                    child: const Icon(Icons.playlist_remove_outlined, color: Colors.white, size: 20),
                    backgroundColor: Colors.redAccent,
                    label: 'Remove Everything',
                    onTap: onRemoveEverything,
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.remove, color: Colors.white, size: 20),
                    backgroundColor: Colors.redAccent,
                    label: 'Remove Selected',
                    onTap: () => onRemoveNode(selectedNode!),
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                    backgroundColor: Colors.cyanAccent,
                    label: 'Add Model',
                    onTap: _openCatalogSelectionModal,
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
                          _buildControlButton(0, Icons.keyboard_double_arrow_up, () => moveNode(Vector3(0.0, 0.02, 0.0)), 'Up'),
                          const SizedBox(height: 12),
                          // Downward
                          _buildControlButton(1, Icons.keyboard_double_arrow_down, () => moveNode(Vector3(0.0, -0.02, 0.0)), 'Down'),
                          const SizedBox(height: 12),
                          // Left
                          _buildControlButton(2, Icons.arrow_back, () => moveNode(Vector3(-0.02, 0.0, 0.0)), 'Left'),
                          const SizedBox(height: 12),
                          // Right
                          _buildControlButton(3, Icons.arrow_forward, () => moveNode(Vector3(0.02, 0.0, 0.0)), 'Right'),
                          const SizedBox(height: 12),
                          // Forward (moving into the screen, Z-axis negative)
                          _buildControlButton(4, Icons.arrow_upward, () => moveNode(Vector3(0.0, 0.0, -0.02)), 'Forward'),
                          const SizedBox(height: 12),
                          // Backward (moving out of the screen, Z-axis positive)
                          _buildControlButton(5, Icons.arrow_downward, () => moveNode(Vector3(0.0, 0.0, 0.02)), 'Backward'),
                          const SizedBox(height: 12),
                          // Rotation Controls
                          // Rotate left around Y-axis
                          _buildRotationButton(6, Icons.rotate_left_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), -0.1)), 'Rotate Left'),
                          const SizedBox(height: 12),
                          // Rotate right around Y-axis
                          _buildRotationButton(7, Icons.rotate_right_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), 0.1)), 'Rotate Right'),
                          const SizedBox(height: 12),
                          // Rotate up around X-axis
                          _buildRotationButton(8, Icons.rotate_left_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(1.0, 0.0, 0.0), 0.1)), 'Rotate Up', rotationAngle: 90),
                          const SizedBox(height: 12),
                          // Rotate down around X-axis
                          _buildRotationButton(9, Icons.rotate_right_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(1.0, 0.0, 0.0), -0.1)), 'Rotate Down', rotationAngle: 90),
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
                          _buildControlButton(0, Icons.keyboard_double_arrow_up, () => moveNode(Vector3(0.0, 0.02, 0.0)), 'Up'),
                          const SizedBox(width: 12),
                          // Downward
                          _buildControlButton(1, Icons.keyboard_double_arrow_down, () => moveNode(Vector3(0.0, -0.02, 0.0)), 'Down'),
                          const SizedBox(width: 12),
                          // Left
                          _buildControlButton(2, Icons.arrow_back, () => moveNode(Vector3(-0.02, 0.0, 0.0)), 'Left'),
                          const SizedBox(width: 12),
                          // Right
                          _buildControlButton(3, Icons.arrow_forward, () => moveNode(Vector3(0.02, 0.0, 0.0)), 'Right'),
                          const SizedBox(width: 12),
                          // Forward (moving into the screen, Z-axis negative)
                          _buildControlButton(4, Icons.arrow_upward, () => moveNode(Vector3(0.0, 0.0, -0.02)), 'Forward'),
                          const SizedBox(width: 12),
                          // Backward (moving out of the screen, Z-axis positive)
                          _buildControlButton(5, Icons.arrow_downward, () => moveNode(Vector3(0.0, 0.0, 0.02)), 'Backward'),
                          const SizedBox(width: 12),
                          // Rotation Controls
                          // Rotate left around Y-axis
                          _buildRotationButton(6, Icons.rotate_left_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), -0.1)), 'Rotate Left'),
                          const SizedBox(width: 12),
                          // Rotate right around Y-axis
                          _buildRotationButton(7, Icons.rotate_right_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(0.0, 1.0, 0.0), 0.1)), 'Rotate Right'),
                          const SizedBox(width: 12),
                          // Rotate up around X-axis
                          _buildRotationButton(8, Icons.rotate_left_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(1.0, 0.0, 0.0), 0.1)), 'Rotate Up', rotationAngle: 90),
                          const SizedBox(width: 12),
                          // Rotate down around X-axis
                          _buildRotationButton(9, Icons.rotate_right_outlined, () => rotateNode(Quaternion.axisAngle(Vector3(1.0, 0.0, 0.0), -0.1)), 'Rotate Down', rotationAngle: 90),
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
                // Set the selected node to the node at the given index
                setState(() {
                  selectedNode = nodes[index];
                });
              },
              child: Container(
                width: 60,
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: selectedNode == nodes[index] ? AppColors.secondary : Colors.transparent,
                    width: 4.0,
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
  Widget _buildControlButton(int key, IconData icon, VoidCallback onPressed, String label) {
    return Column(
      children: [
        GestureDetector(
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
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.cyanAccent)),
      ],
    );
  }

  Widget _buildRotationButton(int key, IconData icon, VoidCallback onPressed, String label, {double rotationAngle = 0.0}) {
    return Column(
      children: [
        GestureDetector(
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
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.cyanAccent)),
      ],
    );
  }

  Widget _buildFurnitureCard(Map<dynamic, dynamic> data) {
    double price = 0.0;
    try {
      price = double.parse(data['price'].toString());
      if ((int.parse(data['discount'])) > 0) {
        price = price - (price * (int.parse(data['discount']) / 100));
      }
    } catch (e) {
      print('Error parsing cost: $e');
    }

    bool isSelected = selectedFurniture != null && selectedFurniture == data;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFurniture = data;
        });
        _showVariantDialog(context, data['variants']);
      },
      child: SizedBox(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.transparent, // Add border if selected
              width: 2.0,
            ),
            borderRadius: BorderRadius.circular(8), // Optional: for rounded corners
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: 100,
                child: data['mainImage'] != null
                    ? Image.network(data['mainImage'], height: 90, fit: BoxFit.contain)
                    : const Center(child: Text('No Image')),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.center,
                child: Text(
                  data['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 15,
                    fontFamily: 'Poppins_Bold',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Align(
                alignment: Alignment.center,
                child: Text(
                  'RM ${price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontFamily: 'Poppins_Medium',
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVariantDialog(BuildContext context, dynamic variants) {
    // Ensure that the variants are in a list format
    List<Map<dynamic, dynamic>> variantList;

    // Check if variants is a Map and convert to List
    if (variants is Map) {
      variantList = variants.values.toList().cast<Map<dynamic, dynamic>>();
    } else if (variants is List) {
      variantList = variants.cast<Map<dynamic, dynamic>>();
    } else {
      throw Exception('Unsupported data type for variants');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(0)),
          ),
          title: const Text("Select Furniture Color", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: variantList.map<Widget>((variant) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedVariant = variant['key'];
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.network(
                            variant['image'],
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 5),
                          Text(variant['color'] ?? 'Unknown'),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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

    selectedVariant = widget.selectedVariant;
    selectedFurniture = widget.furnitureData!;
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
      await _addModelToSceneAtPosition(position, rotation, selectedFurniture?['variants']);
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
      if (nodes.isNotEmpty) {
        for (var node in nodes) {
          if (node.uri == variant[selectedVariant]['model']) {
            setState(() {
              isLoadingModel = false;
            });
            return;
          }
        }
      }

      final newNode = ARNode(
        type: NodeType.webGLB,
        name: variant[selectedVariant]['color'],
        uri: variant[selectedVariant]['model'],
        scale: Vector3.all(1),
        position: position,
        rotation: rotationVector,
      );

      bool? didAddNode = await arObjectManager!.addNode(newNode);
      if (didAddNode != null && didAddNode) {
        setState(() {
          nodes.add(newNode);
          nodeImages.add(variant[selectedVariant]['image']);
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

  void _openCatalogSelectionModal() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
          ),
        ),
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  height: MediaQuery.of(context).size.height,
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const Text(
                        'Select a model',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _furnitureList.isEmpty ?
                            const Center(child: CircularProgressIndicator())
                            : GridView.builder(
                          padding: const EdgeInsets.all(0.0),
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 cards per row
                            crossAxisSpacing: 8.0,
                            mainAxisSpacing: 8.0,
                            childAspectRatio: 0.7,
                          ),
                          itemCount: _furnitureList.length,
                          itemBuilder: (context, index) {
                            return _buildFurnitureCard(_furnitureList[index]);
                          },
                        )
                      ),
                    ],
                  ),
                );
              }
          );
        }
      );
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
