package sncf.connect.tech.flutter_eco_mode

import android.os.Build.VERSION
import org.junit.runner.RunWith
import org.mockito.internal.util.reflection.Whitebox
import org.powermock.core.classloader.annotations.PrepareForTest
import org.powermock.modules.junit4.PowerMockRunner
import kotlin.test.Test

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

@RunWith(PowerMockRunner::class)
@PrepareForTest(VERSION::class)
internal class FlutterEcoModePluginTest {
    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue()  {
        Whitebox.setInternalState(VERSION::class, "SDK_INT", 23)
    }
}
