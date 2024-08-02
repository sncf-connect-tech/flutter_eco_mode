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
| <span style="color: #3CB371">**Eco Range**</span>        | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">X</span> | <span style="color: #3CB371">X</span> |
| Battery Thermal State                                    |                   Yes                   |                   Yes                   |                   X                   |                                       |
| Battery State                                            |                   Yes                   |                   Yes                   |                   X                   |                   X                   |
| Battery Level                                            |                   Yes                   |                   Yes                   |                   X                   |                   X                   |
| Battery In Low Power Mode                                |                   Yes                   |                   Yes                   |                   X                   |                   X                   |
| <span style="color: #3CB371">**Battery Eco Mode**</span> | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">X</span> | <span style="color: #3CB371">X</span> |

## Eco Mode

### Eco Range
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

```
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

## Example

See the `example` directory for a complete sample app using flutter_eco_mode.

## Contribution

We are open to any contributions or suggestions. If you have any questions, please contact us.

## License

Copyright © 2024 SNCF Connect & Tech.
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

***

_This file has been written on February 22, 2024_.
