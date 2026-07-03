library;

export 'src/eco_mode_exceptions.dart'
    show
        EcoModeException,
        EcoModePermissionException,
        EcoModePermissionDeniedException,
        EcoModeActivityNotAttachedException,
        EcoModeStorageException,
        EcoModeGenericException,
        PlatformExceptionToEcoModeException;
export 'src/flutter_eco_mode.dart' show FlutterEcoMode;
export 'src/flutter_eco_mode_platform_interface.dart'
    show DeviceEcoRange, DeviceRange;
