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

| Feature                   | Android        | iOS            | Runtime | Event |
|---------------------------|----------------|----------------|---------|-------|
| getPlatformInfo()         | Yes            | Yes            |         |       |
| getBatteryLevel()         | Yes            | Yes            | X       |       |
| getBatteryState()         | No             | Yes            | X       |       |
| isBatteryInLowPowerMode() | Yes            | Yes            | X       |       |
| lowPowerModeEventStream() | Yes            | Yes            | X       | X     |
| getThermalState()         | Yes            | Yes            | X       |       |
| getProcessorCount()       | Yes            | Yes            |         |       |
| getTotalMemory()          | Yes            | Yes            |         |       |
| getFreeMemory()           | Yes            | Yes            | X       |       |
| getTotalStorage()         | Yes            | Yes            |         |       |
| getFreeStorage()          | Yes            | Yes            | X       |       |
| isLowEndDevice()          | Yes            | Yes            | X       |       |



## Example

See the `example` directory for a complete sample app using flutter_eco_mode.


## Contribution

We are open to any contributions or suggestions. If you have any questions, please contact us.

## License

Copyright © 2024 SNCF Connect & Tech.
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

***

_This file has been written on February 22, 2024_.
