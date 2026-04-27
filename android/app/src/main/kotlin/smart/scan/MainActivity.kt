package smart.scan

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    /**
     * The google_mlkit_document_scanner plugin stores a MethodChannel.Result
     * reference when it launches the scanner Activity. If Android kills and
     * recreates the process while the scanner is open (e.g. on low-memory
     * devices or aggressive battery savers), that Result reference is null
     * in the new process, causing a NullPointerException crash on resume.
     *
     * We intercept onActivityResult here and swallow the NPE so Android can
     * finish resuming the activity cleanly. The Dart side will receive no
     * result (null), which your _startScanner already handles gracefully via
     * the null/empty check on result.images.
     */
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        try {
            super.onActivityResult(requestCode, resultCode, data)
        } catch (e: NullPointerException) {
            // Swallow the stale MethodChannel.Result NPE from the ML Kit
            // document scanner after a process-death/recreation cycle.
            // The Dart layer handles the missing result gracefully.
        }
    }
}