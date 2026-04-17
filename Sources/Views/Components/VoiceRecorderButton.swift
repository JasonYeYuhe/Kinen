import SwiftUI
import Speech
import AVFoundation
import OSLog
#if canImport(UIKit)
import UIKit
#endif

private let logger = Logger(subsystem: "com.jasonye.kinen", category: "VoiceRecorder")

/// Real-time speech-to-text button using Apple's SFSpeechRecognizer.
/// All processing happens on-device.
struct VoiceRecorderButton: View {
    @Binding var transcribedText: String
    var onError: ((String) -> Void)?
    @StateObject private var recorder = SpeechRecorder()

    var body: some View {
        Button(action: {
            if recorder.isRecording {
                recorder.stopRecording()
                transcribedText += (transcribedText.isEmpty ? "" : "\n\n") + recorder.transcript
            } else {
                Task { await recorder.startRecording() }
            }
        }) {
            Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .font(.title2)
                .foregroundStyle(recorder.isRecording ? .red : .purple)
                .symbolEffect(.pulse, isActive: recorder.isRecording)
        }
        .buttonStyle(.borderless)
        .help(recorder.isRecording ? String(localized: "voice.a11y.stop") : String(localized: "voice.a11y.start"))
        .accessibilityLabel(recorder.isRecording ? String(localized: "voice.a11y.stop") : String(localized: "voice.a11y.start"))
        .onChange(of: recorder.errorMessage) { _, msg in
            if let msg { onError?(msg) }
        }
        .alert(String(localized: "voice.permission.title"), isPresented: $recorder.showPermissionAlert) {
            Button(String(localized: "general.openSettings")) {
                #if os(macOS)
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
                #else
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                #endif
            }
            Button(String(localized: "general.cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "voice.permission.message"))
        }
    }
}

@MainActor
final class SpeechRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var showPermissionAlert = false
    @Published var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    /// Request microphone + speech permissions and start recording.
    /// Crash-hardened for iPad / iPadOS 26.4 — checks every audio precondition
    /// before touching `AVAudioEngine.inputNode`, which can throw an
    /// uncatchable ObjC NSException when no input route exists.
    func startRecording() async {
        guard !isRecording else { return }
        errorMessage = nil

        // 1. Mic permission (separate from speech recognition)
        #if os(iOS)
        let micGranted: Bool
        if #available(iOS 17.0, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
        guard micGranted else {
            showPermissionAlert = true
            return
        }
        #endif

        // 2. Speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        guard speechStatus == .authorized else {
            showPermissionAlert = true
            return
        }

        beginRecordingSession()
    }

    private func beginRecordingSession() {
        guard let speechRecognizer = SFSpeechRecognizer(), speechRecognizer.isAvailable else {
            logger.error("Speech recognizer not available")
            errorMessage = String(localized: "voice.error.speechUnavailable")
            return
        }

        // 3. Configure AVAudioSession (iOS only — macOS doesn't have AVAudioSession)
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            logger.error("Audio session configuration failed: \(error)")
            errorMessage = String(localized: "voice.error.audioSession")
            return
        }

        // 4. Pre-checks: bail out gracefully if audio input isn't actually available.
        // On iPad without a connected mic, accessing engine.inputNode below throws
        // an uncatchable ObjC NSException. Detecting this early is essential.
        guard let availableInputs = audioSession.availableInputs, !availableInputs.isEmpty else {
            errorMessage = String(localized: "voice.error.noInputDevice")
            return
        }
        guard !audioSession.currentRoute.inputs.isEmpty else {
            errorMessage = String(localized: "voice.error.noInputRoute")
            return
        }
        guard audioSession.sampleRate > 0 else {
            errorMessage = String(localized: "voice.error.noInput")
            return
        }
        #endif

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true

        let engine = AVAudioEngine()
        self.audioEngine = engine

        // 5. Wrap inputNode access in ObjC exception catcher.
        // AVAudioEngine.inputNode can throw an uncatchable ObjC NSException on
        // iPad when no audio input hardware route exists. Swift do-catch cannot
        // intercept NSException, so we bridge through @try/@catch in ObjC.
        let inputNode: AVAudioNode
        do {
            var node: AVAudioNode!
            try ObjCExceptionCatcher.tryExecuting {
                node = engine.inputNode
            }
            inputNode = node
        } catch {
            logger.error("inputNode threw NSException: \(error)")
            errorMessage = String(localized: "voice.error.noInputDevice")
            self.audioEngine = nil
            return
        }

        // 6. Use format: nil so AVAudioEngine picks the native bus format —
        //    avoids format mismatch crashes across different hardware.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: nil) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
            self.recognitionRequest = request
            self.isRecording = true
            self.transcript = ""

            recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
                Task { @MainActor [weak self] in
                    if let result {
                        self?.transcript = result.bestTranscription.formattedString
                    }
                    if error != nil || (result?.isFinal ?? false) {
                        self?.cleanupRecording()
                    }
                }
            }

            logger.info("Recording started (on-device)")
        } catch {
            logger.error("Failed to start audio engine: \(error)")
            errorMessage = error.localizedDescription
            cleanupRecording()
        }
    }

    func stopRecording() {
        recognitionRequest?.endAudio()
        cleanupRecording()
    }

    private func cleanupRecording() {
        if let engine = audioEngine {
            engine.stop()
            // Protect inputNode access during cleanup — same ObjC exception risk as start.
            try? ObjCExceptionCatcher.tryExecuting {
                engine.inputNode.removeTap(onBus: 0)
            }
        }
        audioEngine = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
    }
}
