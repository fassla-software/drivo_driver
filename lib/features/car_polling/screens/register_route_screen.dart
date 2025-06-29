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
        builder: (controller) {
          return Column(
            children: [
              // Progress indicator
              Container(
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
                  padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
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
                          _buildEnhancedTextField(
                            'departure_time'.tr,
                            controller.startTimeController,
                            TextInputType.datetime,
                            hint: 'YYYY-MM-DD HH:MM:SS',
                            icon: Icons.schedule,
                            suffix: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _selectDateTime(controller),
                            ),
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
                          _buildEnhancedTextField(
                            'vehicle_id'.tr,
                            controller.vehicleIdController,
                            TextInputType.text,
                            icon: Icons.directions_car,
                            hint: 'Vehicle identifier',
                          ),
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

                      const SizedBox(height: Dimensions.paddingSizeLarge),
                    ],
                  ),
                ),
              ),

              // FUCKING PROMINENT SUBMIT BUTTON (Fixed at bottom)
              Container(
                padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Test Button (if main button doesn't work)
                    Container(
                      margin: const EdgeInsets.only(
                          bottom: Dimensions.paddingSizeDefault),
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          print("TEST BUTTON CLICKED!");
                          Get.showSnackbar(GetSnackBar(
                            title: "Test Button",
                            message:
                                "This is a simple test button that definitely works!",
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.blue,
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("TEST BUTTON - CLICK ME FIRST",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),

                    // Progress indicator
                    Container(
                      margin: const EdgeInsets.only(
                          bottom: Dimensions.paddingSizeDefault),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Text(
                            'ready_to_register_route'.tr,
                            style: textMedium.copyWith(
                              color: Theme.of(context).primaryColor,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // SIMPLE WORKING BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 64,
                      child: ElevatedButton(
                        onPressed: () {
                          // Simple immediate action to test button works
                          print("BUTTON CLICKED!");

                          // Show immediate feedback
                          Get.showSnackbar(GetSnackBar(
                            title: "Button Works!",
                            message: "The button is clickable and working",
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green,
                            icon: const Icon(Icons.check_circle,
                                color: Colors.white),
                          ));

                          // Show dialog with form data
                          Get.dialog(
                            AlertDialog(
                              title: const Text("Route Data"),
                              content: SizedBox(
                                width: 300,
                                height: 400,
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "Start Lat: ${controller.startLatController.text}"),
                                      Text(
                                          "Start Lng: ${controller.startLngController.text}"),
                                      Text(
                                          "End Lat: ${controller.endLatController.text}"),
                                      Text(
                                          "End Lng: ${controller.endLngController.text}"),
                                      Text(
                                          "Start Time: ${controller.startTimeController.text}"),
                                      Text(
                                          "Price: ${controller.priceController.text}"),
                                      Text(
                                          "Vehicle ID: ${controller.vehicleIdController.text}"),
                                      Text(
                                          "Seats: ${controller.seatsController.text}"),
                                      Text(
                                          "Min Age: ${controller.minAgeController.text}"),
                                      Text(
                                          "Max Age: ${controller.maxAgeController.text}"),
                                      Text("Ride Type: ${controller.rideType}"),
                                      Text(
                                          "Gender: ${controller.allowedGender}"),
                                      Text("AC: ${controller.isAc}"),
                                      Text(
                                          "Smoking: ${controller.isSmokingAllowed}"),
                                      Text("Music: ${controller.hasMusic}"),
                                      Text(
                                          "Entertainment: ${controller.hasScreenEntertainment}"),
                                      Text(
                                          "Luggage: ${controller.allowLuggage}"),
                                      Text(
                                          "Rest Stops: ${controller.restStops.length}"),
                                      const SizedBox(height: 20),
                                      const Text("This data would be sent to:"),
                                      const Text(
                                          "https://drivoeg.com/api/driver/register-route",
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue)),
                                    ],
                                  ),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Get.back(),
                                  child: const Text("Close"),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Get.back();
                                    // Call the actual registration method
                                    controller.registerRoute();
                                  },
                                  child: const Text("Send to API"),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, // Make it obvious
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.rocket_launch,
                                color: Colors.white, size: 30),
                            SizedBox(width: 12),
                            Text(
                              'CLICK ME - REGISTER ROUTE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
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
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        border:
            Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
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
            color: Colors.black.withOpacity(0.1),
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
              color: Theme.of(context).primaryColor.withOpacity(0.1),
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
              ? Theme.of(context).primaryColor.withOpacity(0.1)
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
    int totalFields = 10;
    int filledFields = 0;

    if (controller.startLatController.text.isNotEmpty) filledFields++;
    if (controller.startLngController.text.isNotEmpty) filledFields++;
    if (controller.endLatController.text.isNotEmpty) filledFields++;
    if (controller.endLngController.text.isNotEmpty) filledFields++;
    if (controller.startTimeController.text.isNotEmpty) filledFields++;
    if (controller.priceController.text.isNotEmpty) filledFields++;
    if (controller.vehicleIdController.text.isNotEmpty) filledFields++;
    if (controller.seatsController.text.isNotEmpty) filledFields++;
    if (controller.minAgeController.text.isNotEmpty) filledFields++;
    if (controller.maxAgeController.text.isNotEmpty) filledFields++;

    progress = filledFields / totalFields;
    return progress;
  }

  void _selectDateTime(RegisterRouteController controller) async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        final DateTime selectedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        controller.startTimeController.text =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(selectedDateTime);
      }
    }
  }
}
