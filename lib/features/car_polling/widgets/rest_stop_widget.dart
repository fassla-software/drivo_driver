import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../domain/models/rest_stop_model.dart';
import '../screens/coordinate_picker_screen.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RestStopWidget extends StatefulWidget {
  final List<RestStopModel> restStops;
  final Function(RestStopModel) onAddRestStop;
  final Function(int) onRemoveRestStop;

  const RestStopWidget({
    super.key,
    required this.restStops,
    required this.onAddRestStop,
    required this.onRemoveRestStop,
  });

  @override
  State<RestStopWidget> createState() => _RestStopWidgetState();
}

class _RestStopWidgetState extends State<RestStopWidget>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _latController = TextEditingController();
  final TextEditingController _lngController = TextEditingController();
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleForm() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
        _clearForm();
      }
    });
  }

  void _clearForm() {
    _nameController.clear();
    _latController.clear();
    _lngController.clear();
  }

  void _openMapPicker() async {
    LatLng? initialPosition;
    try {
      if (_latController.text.isNotEmpty && _lngController.text.isNotEmpty) {
        initialPosition = LatLng(
          double.parse(_latController.text),
          double.parse(_lngController.text),
        );
      }
    } catch (e) {
      // Invalid coordinates, use default
    }

    final result = await Get.to(() => CoordinatePickerScreen(
          title: 'select_rest_stop_location'.tr,
          initialPosition: initialPosition,
        ));

    if (result != null && result is Map<String, dynamic>) {
      final LatLng coordinates = result['coordinates'] as LatLng;
      final String? locationName = result['name'] as String?;

      _latController.text = coordinates.latitude.toStringAsFixed(6);
      _lngController.text = coordinates.longitude.toStringAsFixed(6);

      // If we got a location name from search, use it as the rest stop name
      if (locationName != null && _nameController.text.isEmpty) {
        _nameController.text = locationName;
      }
    }
  }

  void _addRestStop() {
    if (_nameController.text.isEmpty ||
        _latController.text.isEmpty ||
        _lngController.text.isEmpty) {
      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'please_fill_all_rest_stop_fields'.tr,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      final restStop = RestStopModel(
        name: _nameController.text.trim(),
        lat: double.parse(_latController.text),
        lng: double.parse(_lngController.text),
      );

      widget.onAddRestStop(restStop);
      _clearForm();
      _toggleForm();

      Get.showSnackbar(GetSnackBar(
        title: 'success'.tr,
        message: 'rest_stop_added'.tr,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'invalid_coordinates'.tr,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rest Stops List
        if (widget.restStops.isNotEmpty) ...[
          Text(
            '${widget.restStops.length} ${'rest_stops_added'.tr}',
            style: textMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.restStops.length,
            itemBuilder: (context, index) {
              final restStop = widget.restStops[index];
              return _buildRestStopCard(restStop, index);
            },
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],

        // Add Rest Stop Toggle Button
        InkWell(
          onTap: _toggleForm,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          child: Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: _isExpanded
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
              border: Border.all(
                color: _isExpanded
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).dividerColor,
                width: _isExpanded ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius:
                        BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                  ),
                  child: Icon(
                    _isExpanded ? Icons.remove : Icons.add,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Expanded(
                  child: Text(
                    _isExpanded ? 'cancel_add_stop'.tr : 'add_rest_stop'.tr,
                    style: textMedium.copyWith(
                      fontSize: Dimensions.fontSizeLarge,
                      color: _isExpanded
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                RotationTransition(
                  turns: _expandAnimation,
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Animated Add Rest Stop Form
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child:
              _isExpanded ? _buildAddRestStopForm() : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildRestStopCard(RestStopModel restStop, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Stop Number
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: textBold.copyWith(
                  color: Colors.white,
                  fontSize: Dimensions.fontSizeSmall,
                ),
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),

          // Stop Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restStop.name,
                  style: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 14,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${restStop.lat.toStringAsFixed(4)}, ${restStop.lng.toStringAsFixed(4)}',
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete Button
          InkWell(
            onTap: () => _showDeleteConfirmation(index),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRestStopForm() {
    return Container(
      margin: const EdgeInsets.only(top: Dimensions.paddingSizeDefault),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border:
            Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Header
          Row(
            children: [
              Icon(
                Icons.add_location_alt,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                'add_new_rest_stop'.tr,
                style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Rest Stop Name
          _buildFormField(
            label: 'rest_stop_name'.tr,
            controller: _nameController,
            hint: 'e.g., Gas Station, Coffee Shop',
            icon: Icons.store,
          ),

          // Location Section
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                'location_coordinates'.tr,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _openMapPicker,
                icon: const Icon(Icons.map, size: 16),
                label: Text(
                  'pick_on_map'.tr,
                  style:
                      textRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),

          // Coordinates Row
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  label: 'latitude'.tr,
                  controller: _latController,
                  hint: '0.000000',
                  icon: Icons.my_location,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: _buildFormField(
                  label: 'longitude'.tr,
                  controller: _lngController,
                  hint: '0.000000',
                  icon: Icons.location_on,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),

          const SizedBox(height: Dimensions.paddingSizeLarge),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _clearForm();
                    _toggleForm();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeDefault),
                    side: BorderSide(color: Theme.of(context).dividerColor),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.paddingSizeSmall),
                    ),
                  ),
                  child: Text(
                    'cancel'.tr,
                    style: textMedium.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _addRestStop,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                        vertical: Dimensions.paddingSizeDefault),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(Dimensions.paddingSizeSmall),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_location,
                          color: Colors.white, size: 18),
                      const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                      Text(
                        'add_stop'.tr,
                        style: textMedium.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeExtraSmall),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
              borderSide: BorderSide(color: Theme.of(context).dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
              borderSide:
                  BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            prefixIcon: Icon(icon, color: Theme.of(context).hintColor),
            filled: true,
            fillColor: Theme.of(context).scaffoldBackgroundColor,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeDefault),
      ],
    );
  }

  void _showDeleteConfirmation(int index) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_rest_stop'.tr),
        content: Text('are_you_sure_delete_rest_stop'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              widget.onRemoveRestStop(index);
              Get.back();
              Get.showSnackbar(GetSnackBar(
                title: 'success'.tr,
                message: 'rest_stop_deleted'.tr,
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text('delete'.tr, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
