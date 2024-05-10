[![pub package](https://img.shields.io/pub/v/flutter_google_wallet.svg)](https://pub.dev/packages/flutter_eco_mode)
[![Test](https://github.com/sncf-connect-tech/flutter_eco_mode/actions/workflows/test.yaml/badge.svg)](https://github.com/sncf-connect-tech/flutter_eco_mode/actions/workflows/test.yaml)
[![codecov](https://codecov.io/gh/sncf-connect-tech/flutter_eco_mode/graph/badge.svg?token=6O1cg0mQ2P)](https://codecov.io/gh/sncf-connect-tech/flutter_eco_mode)

# flutter_eco_mode

A Flutter plugin to help implementing custom eco-friendly mode in your mobile app. This plugin will tell you if a device
is a low-end device or not according to our recommendations. 
It will also give you brut data to allow you to implement
your own rules for your app.

This plugin is still in reflexion and development. And will only be available for Android and iOS at the moment.

Next this plugin will have the objective to propose solutions to deactivate functionalities of the device to
save energy. For example, disable animations or other nonessential resourceful operations...

## Why this plugin?

We are developing this plugin, to perhaps implementing it on the SNCF Connect application, and offering an
eco-friendly app to our users who have low-end devices to allow them to save the resources of their phone. And
also to offer a less energy-consuming app.

## Features

| Feature                                                                                      |                 Android                 |                   iOS                   |                Runtime                | Event |
|:---------------------------------------------------------------------------------------------|:---------------------------------------:|:---------------------------------------:|:-------------------------------------:|:-----:|
| getPlatformInfo()                                                                            |                   Yes                   |                   Yes                   |                                       |       |
| getBatteryLevel()                                                                            |                   Yes                   |                   Yes                   |                   X                   |       |
| getBatteryState()                                                                            |                   No                    |                   Yes                   |                   X                   |       |
| isBatteryInLowPowerMode()                                                                    |                   Yes                   |                   Yes                   |                   X                   |       |
| lowPowerModeEventStream()                                                                    |                   Yes                   |                   Yes                   |                   X                   |   X   |
| getThermalState()                                                                            |                   Yes                   |                   Yes                   |                   X                   |       |
| getProcessorCount()                                                                          |                   Yes                   |                   Yes                   |                                       |       |
| getTotalMemory()                                                                             |                   Yes                   |                   Yes                   |                                       |       |
| getFreeMemory()                                                                              |                   Yes                   |                   Yes                   |                   X                   |       |
| getTotalStorage()                                                                            |                   Yes                   |                   Yes                   |                                       |       |
| getFreeStorage()                                                                             |                   Yes                   |                   Yes                   |                   X                   |       |
| <span style="color: #3CB371">**isBatteryEcoMode()**</span>                                   | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">X</span> |       |
| <span style="color: #3CB371">**getEcoRange**()</span>                                        | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">Yes</span> | <span style="color: #3CB371">X</span> |       |


## Eco Mode
### Battery Eco Mode

This feature combines different battery information to determine if the device is in **_eco-mode_** or not. 
It will return a boolean.

```
Future.wait([
      _isNotEnoughBattery(),
      _isBatteryLowPowerMode(),
      _isSeriousAtLeastBatteryState(),
    ])
``` 
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

## Example

See the `example` directory for a complete sample app using flutter_eco_mode.


## Contribution

We are open to any contributions or suggestions. If you have any questions, please contact us.

## License

Copyright © 2024 SNCF Connect & Tech.
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

***

_This file has been written on February 22, 2024_.
