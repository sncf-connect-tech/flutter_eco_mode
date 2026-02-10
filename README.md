[![pub package](https://img.shields.io/pub/v/flutter_eco_mode.svg)](https://pub.dev/packages/flutter_eco_mode)
[![Test](https://github.com/sncf-connect-tech/flutter_eco_mode/actions/workflows/test.yaml/badge.svg)](https://github.com/sncf-connect-tech/flutter_eco_mode/actions/workflows/test.yaml)
[![codecov](https://codecov.io/gh/sncf-connect-tech/flutter_eco_mode/graph/badge.svg?token=6O1cg0mQ2P)](https://codecov.io/gh/sncf-connect-tech/flutter_eco_mode)

# flutter_eco_mode

A Flutter plugin to help implementing custom eco-friendly mode in your mobile app.

According to our recommendations, the plugin determine if a device is:
* a low-end device
* in a battery eco mode

**It will also give you your own rules for your app.**

This plugin is still in reflexion and development. And will only be available for Android and iOS at the moment.

Next this plugin will have the objective to propose solutions to deactivate functionalities of the device to
save energy. For example, disable animations or other nonessential resourceful operations...

## Why this plugin?

We are developing this plugin, to perhaps implementing it on the SNCF Connect application, and offering an
eco-friendly app to our users who have low-end devices to allow them to save the resources of their phone. And
also to offer a less energy-consuming app.

## Features

| Feature                                                  |                 Android                 |                   iOS                   |                Runtime                |                 Event                 |
|:---------------------------------------------------------|:---------------------------------------:|:---------------------------------------:|:-------------------------------------:|:-------------------------------------:|
| Platform Info                                            |                   Yes                   |                   Yes                   |                   X                   |                                       |
| Processor Count                                          |                   Yes                   |                   Yes                   |                   X                   |                                       |
| Total Memory                                             |                   Yes                   |                   Yes                   |                   X                   |                                       |
| Free Memory                                              |                   Yes                   |                   Yes                   |                   X                   |                                       |
| Total Storage                                            |                   Yes                   |                   Yes                   |                   X                   |                                       |
| Free Storage                                             |                   Yes                   |                   Yes                   |                   X                   |                                       |
| <span style="color: #3CB371">**Device Range**</span>     | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">X</span> | <span style="color: #3CB371">X</span> |
| Battery Thermal State                                    |                   Yes                   |                   Yes                   |                   X                   |                                       |
| Battery State                                            |                   Yes                   |                   Yes                   |                   X                   |                   X                   |
| Battery Level                                            |                   Yes                   |                   Yes                   |                   X                   |                   X                   |
| Battery In Low Power Mode                                |                   Yes                   |                   Yes                   |                   X                   |                   X                   |
| <span style="color: #3CB371">**Battery Eco Mode**</span> | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">X</span> | <span style="color: #3CB371">X</span> |
| <span style="color: #007FFF">**Connectivity**</span>     | <span style="color: #007FFF">Yes</span> | <span style="color: #007FFF">No</span>  | <span style="color: #007FFF">X</span> | <span style="color: #007FFF">X</span> |

## Eco Mode

### Device Range
This feature gives the possibility to calculate a score for the device.
The score does NOT represent an ecological performance. 
It's just a score to determine the device's capacities.
It is calculated by combining static information about the device on different OS.
It will return a double between 0 and 1.

Then we can determine the device Eco Range:
- High End
- Mid Range
- Low End

Low-end devices means devices with poor capacities or poor features, usually old devices or low-cost devices.

And finally, you can use the last boolean information **_isLowEndDevice_** to directly know if your device is a low-end device or not.

#### Not really convinced by the Eco Range?

That's why we give you the possibility to calculate your own score by using others features in the plugin.
If you have more than three eco ranges in your custom eco-mode, 
feel free to give the best user eco experience to your final users :)

### Battery Eco Mode

This feature combines different battery information to determine if the device is in **_eco-mode_** or not.
It will return a boolean.

```dart
@override
  Stream<bool?> get isBatteryEcoModeStream => CombineLatestStream.list([
        _isNotEnoughBatteryStream(),
        lowPowerModeEventStream.withInitialValue(isBatteryInLowPowerMode()),
      ]).map((event) => event.any((element) => element)).asBroadcastStream();

  Stream<bool> _isNotEnoughBatteryStream() => CombineLatestStream.list([
        batteryLevelEventStream.map((event) => event.isNotEnough),
        batteryStateEventStream.map((event) => event.isDischarging),
      ]).map((event) => event.every((element) => element)).asBroadcastStream();
``` 

## Connectivity 

### /!\ Only available for Android at the moment

This feature can help you to observe the network, know if the device is connected to the internet, 
or just want to adapt your app to the network state.

We have created a class **_Connectivity_** which contains basic information about the network.

And you can use directly the methode **_hasEnoughNetwork_** which follows these rules in the code

```dart
extension on Connectivity {
  bool? get isEnough => type == ConnectivityType.unknown
      ? null
      : (_isMobileEnoughNetwork || _isWifiEnoughNetwork || type == ConnectivityType.ethernet);

  bool get _isMobileEnoughNetwork =>
      [ConnectivityType.mobile5g, ConnectivityType.mobile4g, ConnectivityType.mobile3g].contains(type);

  bool get _isWifiEnoughNetwork =>
      ConnectivityType.wifi == type && wifiSignalStrength != null ? wifiSignalStrength! >= minWifiSignalStrength : false;
}
```

### How does it work ?

* First, we retrieve the type of network via native access.
* Then, if we have Wifi identified we catch the signal strength.
* And finally, we build and return the object Connectivity.

At this moment, you can ask your self. Is it really reliable ? Is there a better way ?

Probably the better thing to do is to make your own speed test in your app. 
You're right, it's more precise, and you can directly define what is a good network fo your purposes.
But you need to ping a server, and it's not really eco-friendly. 
Here we just use the native access, trust directly your device and OS.

## Example

See the `example` directory for a complete sample app using flutter_eco_mode.

## Contribution

We are open to any contributions or suggestions. If you have any questions, please contact us.

## License

Copyright © 2026 SNCF Connect & Tech.
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
