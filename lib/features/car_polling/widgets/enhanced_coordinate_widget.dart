import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../screens/coordinate_picker_screen.dart';

class EnhancedCoordinateWidget extends StatefulWidget {
  final String title;
  final TextEditingController latController;
  final TextEditingController lngController;
  final IconData icon;
  final Color? iconColor;

  const EnhancedCoordinateWidget({
    super.key,
    required this.title,
    required this.latController,
    required this.lngController,
    required this.icon,
    this.iconColor,
  });

  @override
  State<EnhancedCoordinateWidget> createState() =>
      _EnhancedCoordinateWidgetState();
}

class _EnhancedCoordinateWidgetState extends State<EnhancedCoordinateWidget> {
  String? _selectedLocationName;

  void _openMapPicker(BuildContext context) async {
    // Get current coordinates if available
    LatLng? initialPosition;
    try {
      if (widget.latController.text.isNotEmpty &&
          widget.lngController.text.isNotEmpty) {
        initialPosition = LatLng(
          double.parse(widget.latController.text),
          double.parse(widget.lngController.text),
        );
      }
    } catch (e) {
      // Invalid coordinates, use default
    }

    // Open map picker
    final result = await Get.to(() => CoordinatePickerScreen(
          title: widget.title,
          initialPosition: initialPosition,
        ));

    // Update controllers with selected coordinates
    if (result != null && result is Map<String, dynamic>) {
      final LatLng coordinates = result['coordinates'] as LatLng;
      final String? locationName = result['name'] as String?;

      setState(() {
        _selectedLocationName = locationName;
      });

      widget.latController.text = coordinates.latitude.toStringAsFixed(6);
      widget.lngController.text = coordinates.longitude.toStringAsFixed(6);
    }
  }

  void _clearCoordinates() {
    setState(() {
      _selectedLocationName = null;
    });
    widget.latController.clear();
    widget.lngController.clear();
  }

  @override
  Widget build(BuildContext context) {
    bool hasCoordinates = widget.latController.text.isNotEmpty &&
        widget.lngController.text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.paddingSizeSmall),
                topRight: Radius.circular(Dimensions.paddingSizeSmall),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: widget.iconColor ?? Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      if (_selectedLocationName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _selectedLocationName!,
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                // Map picker button
                InkWell(
                  onTap: () => _openMapPicker(context),
                  child: Container(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(
                          Dimensions.paddingSizeExtraSmall),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.map, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          hasCoordinates ? 'change'.tr : 'pick_on_map'.tr,
                          style: textRegular.copyWith(
                            color: Colors.white,
                            fontSize: Dimensions.fontSizeExtraSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Coordinate input fields
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'latitude'.tr,
                        style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      TextField(
                        controller: widget.latController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          // Clear selected location name when manually editing
                          if (_selectedLocationName != null) {
                            setState(() {
                              _selectedLocationName = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '0.000000',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                Dimensions.paddingSizeExtraSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault,
                            vertical: Dimensions.paddingSizeSmall,
                          ),
                          prefixIcon: Icon(
                            Icons.my_location,
                            color: Theme.of(context).hintColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'longitude'.tr,
                        style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      TextField(
                        controller: widget.lngController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (value) {
                          // Clear selected location name when manually editing
                          if (_selectedLocationName != null) {
                            setState(() {
                              _selectedLocationName = null;
                            });
                          }
                        },
                        decoration: InputDecoration(
                          hintText: '0.000000',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                                Dimensions.paddingSizeExtraSmall),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault,
                            vertical: Dimensions.paddingSizeSmall,
                          ),
                          prefixIcon: Icon(
                            Icons.location_on,
                            color: Theme.of(context).hintColor,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick actions (if coordinates are set)
          if (hasCoordinates)
            Container(
              padding: const EdgeInsets.fromLTRB(
                Dimensions.paddingSizeDefault,
                0,
                Dimensions.paddingSizeDefault,
                Dimensions.paddingSizeDefault,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 16,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                  Expanded(
                    child: Text(
                      _selectedLocationName != null
                          ? 'location_selected'.tr
                          : 'coordinates_set'.tr,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Colors.green,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _clearCoordinates,
                    child: Text(
                      'clear'.tr,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
