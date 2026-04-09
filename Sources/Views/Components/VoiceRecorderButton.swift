import SwiftUI
import Speech
import AVFoundation
import OSLog

private let logger = Logger(subsystem: "com.jasonye.kinen", category: "VoiceRecorder")

/// Real-time speech-to-text button using Apple's SFSpeechRecognizer.
/// All processing happens on-device.
struct VoiceRecorderButton: View {
    @Binding var transcribedText: String
    @StateObject private var recorder = SpeechRecorder()

    var body: some View {
        Button(action: {
            if recorder.isRecording {
                recorder.stopRecording()
                transcribedText += (transcribedText.isEmpty ? "" : "\n\n") + recorder.transcript
            } else {
                recorder.startRecording()
            }
        }) {
            Image(systemName: recorder.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .font(.title2)
                .foregroundStyle(recorder.isRecording ? .red : .purple)
                .symbolEffect(.pulse, isActive: recorder.isRecording)
        }
        .buttonStyle(.borderless)
        .help(recorder.isRecording ? "Stop recording" : "Start voice input")
        .alert("Microphone Access Required", isPresented: $recorder.showPermissionAlert) {
            Button("Open Settings") {
                #if os(macOS)
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
                #else
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                #endif
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Kinen needs microphone access for voice journaling. All speech recognition happens on your device.")
        }
    }
}

@MainActor
final class SpeechRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var showPermissionAlert = false

    private var audioEngine: AVAudioEngine?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?

    func startRecording() {
        // Check permissions
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self else { return }
                switch status {
                case .authorized:
                    self.beginRecordingSession()
                default:
                    self.showPermissionAlert = true
                }
            }
        }
    }

    private func beginRecordingSession() {
        let speechRecognizer = SFSpeechRecognizer()
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            logger.error("Speech recognizer not available")
            return
        }

        // Request on-device recognition for privacy
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true

        let audioEngine = AVAudioEngine()
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
            self.audioEngine = audioEngine
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
            cleanupRecording()
        }
    }

    func stopRecording() {
        recognitionRequest?.endAudio()
        cleanupRecording()
    }

    private func cleanupRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
    }
}
