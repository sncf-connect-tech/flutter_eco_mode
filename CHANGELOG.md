# 1.0.0

> First stable release: connectivity state on iOS, safer error handling and internal cleanup

- **FEAT**: Implement connectivity state (network type, Wifi signal strength) on iOS.
- **FEAT**: Support multiple active listeners for connectivity events on iOS.
- **FEAT**: Migrate iOS side to Swift Package Manager.
- **FIX**: Change plugin interface to remove nullable return values.
- **FIX**: Better error handling — `PlatformException`s are now consistently converted into typed `EcoModeException`s across the API.
- **FIX**: `EcoModeException` and its subclasses no longer extend `PlatformException`; they are now standalone, sealed exception types (`code`/`message`/`details`) for a clearer, non-ambiguous error contract.
- **FIX**: `hasEnoughNetwork()` now rethrows native errors instead of silently returning `null`, for consistency with the rest of the API.
- **FIX**: Fix deadlock issue on iOS event channels.
- **FIX**: Simplify event channels implementation using Pigeon.
- **CHORE**: Replace the hand-rolled `CombineLatestStream` implementation with the `rxdart` package.
- **CHORE**: Add CI job for Android build and tests, upgrade AGP.
- **CHORE**: Add lefthook pre-commit hooks.

## 0.1.0


> Add feature connectivity for Android devices

- **FEAT**: Add feature connectivity for Android devices.

## 0.0.4

> Fix unsupported event type on streaming battery state between Flutter and iOS

- **FIX**: Fix unsupported event type on streaming battery state between Flutter and iOS.

## 0.0.3

> Rename ecoRange deviceRange

- **FEAT**: Rename ecoRange deviceRange.

## 0.0.2

> Add Eco Mode Stream   

- **FEAT**: Add eco mode stream `isBatteryEcoModeStream`.

## 0.0.1

> Initial release   

- **FEAT**: Add method to get the level of the battery `getBatteryLevel()`.
- **FEAT**: Add method that return the state of the battery `getBatterySatte()`.
- **FEAT**: Add method to check if the device is in low power mode `isBatteryInLowPowerMode()`.
- **FEAT**: Add method to get a stream of low power mode events `lowPowerModeEventStream()`.
- **FEAT**: Add method to get the current thermal state of the device `getThermalState()`.
- **FEAT**: Add method to get the number of processors `getProcessorCount()`.
- **FEAT**: Add method to get the total memory of the device `getTotalMemory()`.
- **FEAT**: Add method to get the available memory `getFreeMemory()`.
- **FEAT**: Add method to get the total storage capacity of the device `getTotalStorage()`.
- **FEAT**: Add method to get the available storage `getFreeStorage()`.
- **FEAT**: Add method to check if the device is a low-end device `isLowEndDevice()`.
- **FEAT**: Add method to get info of the device `getPlatformInfo()`.
