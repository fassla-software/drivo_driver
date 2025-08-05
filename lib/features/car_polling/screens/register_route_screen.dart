import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/register_route_controller.dart';
import '../widgets/enhanced_coordinate_widget.dart';
import '../widgets/rest_stop_widget.dart';

class RegisterRouteScreen extends StatefulWidget {
  const RegisterRouteScreen({super.key});

  @override
  State<RegisterRouteScreen> createState() => _RegisterRouteScreenState();
}

class _RegisterRouteScreenState extends State<RegisterRouteScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBarWidget(
        title: 'register_route'.tr,
        showBackButton: true,
      ),
      body: GetBuilder<RegisterRouteController>(
        init: Get.find<RegisterRouteController>(),
        builder: (controller) {
          try {
            return Stack(
              children: [
                // Main content
                Column(
                  children: [
                    // Progress indicator
                    SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: _calculateProgress(controller),
                        backgroundColor: Theme.of(context).dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                            const EdgeInsets.all(Dimensions.paddingSizeDefault),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Card
                            _buildHeaderCard(),
                            const SizedBox(height: Dimensions.paddingSizeLarge),

                            // Route Information Section
                            _buildSectionCard(
                              title: 'route_information'.tr,
                              icon: Icons.route,
                              children: [
                                EnhancedCoordinateWidget(
                                  title: 'starting_point'.tr,
                                  latController: controller.startLatController,
                                  lngController: controller.startLngController,
                                  icon: Icons.play_arrow,
                                  iconColor: Colors.green,
                                ),
                                EnhancedCoordinateWidget(
                                  title: 'destination'.tr,
                                  latController: controller.endLatController,
                                  lngController: controller.endLngController,
                                  icon: Icons.flag,
                                  iconColor: Colors.red,
                                ),
                                _buildEnhancedDateTimeField(
                                  'departure_time'.tr,
                                  controller.startTimeController,
                                  () => _selectDateTime(controller),
                                ),
                              ],
                            ),

                            // Vehicle & Pricing Section
                            _buildSectionCard(
                              title: 'vehicle_and_pricing'.tr,
                              icon: Icons.directions_car,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        'price_per_seat'.tr,
                                        controller.priceController,
                                        TextInputType.number,
                                        icon: Icons.attach_money,
                                      ),
                                    ),
                                    const SizedBox(
                                        width: Dimensions.paddingSizeDefault),
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        'available_seats'.tr,
                                        controller.seatsController,
                                        TextInputType.number,
                                        icon: Icons.airline_seat_recline_normal,
                                      ),
                                    ),
                                  ],
                                ),
                                // _buildEnhancedTextField(
                                //   'vehicle_id'.tr,
                                //   controller.vehicleIdController,
                                //   TextInputType.text,
                                //   icon: Icons.directions_car,
                                //   hint: 'Vehicle identifier',
                                // ),
                              ],
                            ),

                            // Ride Preferences Section
                            _buildSectionCard(
                              title: 'ride_preferences'.tr,
                              icon: Icons.tune,
                              children: [
                                _buildEnhancedDropdown(
                                  'ride_type'.tr,
                                  controller.rideType,
                                  ['work', 'leisure', 'business'],
                                  controller.setRideType,
                                  Icons.work,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        'minimum_age'.tr,
                                        controller.minAgeController,
                                        TextInputType.number,
                                        icon: Icons.person,
                                      ),
                                    ),
                                    const SizedBox(
                                        width: Dimensions.paddingSizeDefault),
                                    Expanded(
                                      child: _buildEnhancedTextField(
                                        'maximum_age'.tr,
                                        controller.maxAgeController,
                                        TextInputType.number,
                                        icon: Icons.person,
                                      ),
                                    ),
                                  ],
                                ),
                                _buildEnhancedDropdown(
                                  'allowed_gender'.tr,
                                  controller.allowedGender,
                                  ['both', 'male', 'female'],
                                  controller.setAllowedGender,
                                  Icons.people,
                                ),
                              ],
                            ),

                            // Vehicle Features Section
                            _buildSectionCard(
                              title: 'vehicle_features'.tr,
                              icon: Icons.featured_play_list,
                              children: [
                                _buildFeatureGrid(controller),
                              ],
                            ),

                            // Rest Stops Section
                            _buildSectionCard(
                              title: 'rest_stops'.tr,
                              icon: Icons.local_gas_station,
                              children: [
                                RestStopWidget(
                                  restStops: controller.restStops,
                                  onAddRestStop: controller.addRestStop,
                                  onRemoveRestStop: controller.removeRestStop,
                                ),
                              ],
                            ),

                            // Submit Button Section (now part of scrollable body)
                            _buildSubmitSection(controller),

                            const SizedBox(height: Dimensions.paddingSizeLarge),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Loading overlay
                if (controller.isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
              ],
            );
          } catch (e) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'An error occurred',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please try again later',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        border: Border.all(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            ),
            child: const Icon(Icons.add_road, color: Colors.white, size: 32),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'create_new_route'.tr,
                  style: textBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(
                  'share_your_journey_with_others'.tr,
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.paddingSizeDefault),
                topRight: Radius.circular(Dimensions.paddingSizeDefault),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
                const SizedBox(width: Dimensions.paddingSizeDefault),
                Text(
                  title,
                  style: textBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Section Content
          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDateTimeField(
    String label,
    TextEditingController controller,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Column(
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
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            child: Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeSmall),
                color: Theme.of(context).cardColor,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: Theme.of(context).hintColor,
                    size: 20,
                  ),
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                  Expanded(
                    child: Text(
                      controller.text.isEmpty
                          ? 'tap_to_select_date_and_time'.tr
                          : controller.text,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: controller.text.isEmpty
                            ? Theme.of(context).hintColor
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedTextField(
    String label,
    TextEditingController controller,
    TextInputType keyboardType, {
    String? hint,
    IconData? icon,
    Widget? suffix,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Column(
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
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeSmall),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeSmall),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeSmall),
                borderSide:
                    BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.all(Dimensions.paddingSizeDefault),
              prefixIcon: icon != null
                  ? Icon(icon, color: Theme.of(context).hintColor)
                  : null,
              suffixIcon: suffix,
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedDropdown(
    String label,
    String currentValue,
    List<String> options,
    Function(String) onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      child: Column(
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
          DropdownButtonFormField<String>(
            value: currentValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeSmall),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeSmall),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeSmall),
                borderSide:
                    BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.all(Dimensions.paddingSizeDefault),
              prefixIcon: Icon(icon, color: Theme.of(context).hintColor),
              filled: true,
              fillColor: Theme.of(context).cardColor,
            ),
            items: options.map((String option) {
              return DropdownMenuItem<String>(
                value: option,
                child: Text(option.tr),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                onChanged(newValue);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(RegisterRouteController controller) {
    final features = [
      {
        'title': 'air_conditioning'.tr,
        'value': controller.isAc,
        'setter': controller.setIsAc,
        'icon': Icons.ac_unit
      },
      {
        'title': 'smoking_allowed'.tr,
        'value': controller.isSmokingAllowed,
        'setter': controller.setIsSmokingAllowed,
        'icon': Icons.smoking_rooms
      },
      {
        'title': 'music_system'.tr,
        'value': controller.hasMusic,
        'setter': controller.setHasMusic,
        'icon': Icons.music_note
      },
      {
        'title': 'screen_entertainment'.tr,
        'value': controller.hasScreenEntertainment,
        'setter': controller.setHasScreenEntertainment,
        'icon': Icons.tv
      },
      {
        'title': 'allow_luggage'.tr,
        'value': controller.allowLuggage,
        'setter': controller.setAllowLuggage,
        'icon': Icons.luggage
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: Dimensions.paddingSizeSmall,
        mainAxisSpacing: Dimensions.paddingSizeSmall,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(
          feature['title'] as String,
          feature['value'] as bool,
          feature['setter'] as Function(bool),
          feature['icon'] as IconData,
        );
      },
    );
  }

  Widget _buildFeatureCard(
      String title, bool value, Function(bool) onChanged, IconData icon) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      child: Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: value
              ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          border: Border.all(
            color: value
                ? Theme.of(context).primaryColor
                : Theme.of(context).dividerColor,
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: value
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).hintColor,
              size: 20,
            ),
            const SizedBox(width: Dimensions.paddingSizeExtraSmall),
            Expanded(
              child: Text(
                title,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: value
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).hintColor,
                  fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              value ? Icons.check_circle : Icons.radio_button_unchecked,
              color: value
                  ? Theme.of(context).primaryColor
                  : Theme.of(context).hintColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  double _calculateProgress(RegisterRouteController controller) {
    double progress = 0.0;

    // Required fields (must be filled)
    int requiredFields = 0;
    int totalRequiredFields = 5;

    if (controller.startLatController.text.isNotEmpty) requiredFields++;
    if (controller.startLngController.text.isNotEmpty) requiredFields++;
    if (controller.endLatController.text.isNotEmpty) requiredFields++;
    if (controller.endLngController.text.isNotEmpty) requiredFields++;
    if (controller.startTimeController.text.isNotEmpty) requiredFields++;

    // Optional fields (bonus points)
    int optionalFields = 0;
    int totalOptionalFields = 4;

    if (controller.priceController.text.isNotEmpty) optionalFields++;
    if (controller.seatsController.text.isNotEmpty) optionalFields++;
    if (controller.minAgeController.text.isNotEmpty) optionalFields++;
    if (controller.maxAgeController.text.isNotEmpty) optionalFields++;

    // Calculate progress: 70% for required fields + 30% for optional fields
    double requiredProgress = requiredFields / totalRequiredFields * 0.7;
    double optionalProgress = optionalFields / totalOptionalFields * 0.3;

    progress = requiredProgress + optionalProgress;

    // Ensure progress doesn't exceed 100%
    return progress.clamp(0.0, 1.0);
  }

  void _selectDateTime(RegisterRouteController controller) async {
    // Show date picker with improved styling
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('en', 'US'), // Ensure consistent locale
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).primaryColor,
                  onPrimary: Colors.white,
                  surface: Theme.of(context).cardColor,
                  onSurface: Theme.of(context).textTheme.bodyLarge?.color,
                ),
            dialogTheme: DialogTheme(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      // Show time picker with improved styling and better UX
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: Theme.of(context).primaryColor,
                    onPrimary: Colors.white,
                    surface: Theme.of(context).cardColor,
                    onSurface: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
              dialogTheme: DialogTheme(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null && mounted) {
        final DateTime selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        controller.startTimeController.text =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDateTime);
        setState(() {});
      }
    }
  }

  Widget _buildSubmitSection(RegisterRouteController controller) {
    return _buildSectionCard(
      title: 'submit_route'.tr,
      icon: Icons.rocket_launch,
      children: [
        // Progress indicator
        Container(
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Text(
                  'ready_to_register_route'.tr,
                  style: textMedium.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
              ),
              Text(
                '${(_calculateProgress(controller) * 100).toInt()}%',
                style: textBold.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        Container(
          margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeLarge),
          child: LinearProgressIndicator(
            value: _calculateProgress(controller),
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
            minHeight: 6,
          ),
        ),

        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // Show dialog with form data before submitting
              _showRouteDataDialog(controller);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeSmall),
              ),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.send, color: Colors.white, size: 24),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Text(
                  'register_route'.tr,
                  style: textMedium.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRouteDataDialog(RegisterRouteController controller) async {
    // Generate polyline automatically before showing dialog
    await controller.generateEncodedPolyline();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Text('confirm_route_data'.tr),
          ],
        ),
        content: SizedBox(
          width: 300,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDataRow('starting_point'.tr,
                    "Lat: ${controller.startLatController.text}, Lng: ${controller.startLngController.text}"),
                _buildDataRow('destination'.tr,
                    "Lat: ${controller.endLatController.text}, Lng: ${controller.endLngController.text}"),
                _buildDataRow(
                    'departure_time'.tr, controller.startTimeController.text),
                _buildDataRow('price_per_seat'.tr,
                    "${controller.priceController.text} EGP"),
                // _buildDataRow(
                //     'vehicle_id'.tr, controller.vehicleIdController.text),
                _buildDataRow(
                    'available_seats'.tr, controller.seatsController.text),
                _buildDataRow('age_range'.tr,
                    "${controller.minAgeController.text} - ${controller.maxAgeController.text}"),
                _buildDataRow('ride_type'.tr, controller.rideType.tr),
                _buildDataRow('allowed_gender'.tr, controller.allowedGender.tr),
                _buildDataRow('features'.tr, _getFeaturesList(controller)),
                _buildDataRow(
                    'rest_stops'.tr, "${controller.restStops.length} stops"),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // Add a small delay to ensure dialog is closed before showing snackbar
              await Future.delayed(const Duration(milliseconds: 300));
              // Call the actual registration method
              controller.registerRoute();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.send, size: 18, color: Colors.white),
                const SizedBox(width: 4),
                Text('register_route'.tr,
                    style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                        color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'not_set'.tr : value,
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color:
                    value.isEmpty ? Theme.of(context).colorScheme.error : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFeaturesList(RegisterRouteController controller) {
    List<String> features = [];
    if (controller.isAc) features.add('air_conditioning'.tr);
    if (controller.isSmokingAllowed) features.add('smoking_allowed'.tr);
    if (controller.hasMusic) features.add('music_system'.tr);
    if (controller.hasScreenEntertainment) {
      features.add('screen_entertainment'.tr);
    }
    if (controller.allowLuggage) features.add('allow_luggage'.tr);

    return features.isEmpty ? 'none'.tr : features.join(', ');
  }
}
