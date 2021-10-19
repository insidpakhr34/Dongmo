//
//  MemoViewController.swift
//  DongMo
//
//  Created by kimdonghyun on 2019/11/01.
//  Copyright © 2019 kimdonghyun. All rights reserved.
//

import UIKit

// 말하기
import AVFoundation

// 듣기
import Speech

// 보기
import Vision
import VisionKit

class MemoViewController: UIViewController, UITextViewDelegate, SFSpeechRecognizerDelegate,VNDocumentCameraViewControllerDelegate {
    
    @IBOutlet weak var myTextView: UITextView!
    @IBOutlet weak var speechText: UIButton!
    
    // 듣기
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "ko-KR"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    // 듣기
    
    // 보기
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    private let textRecognitionWorkQueue = DispatchQueue(label: "MyVisionScannerQueue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

    // blur effect
    private var backView: UIView!
    

    


    override func viewDidLoad() {
        super.viewDidLoad()

        // 말하기
        myTextView.delegate = self
        
        // 듣기
        speechRecognizer?.delegate = self

        // 보기
//        myTextView.isEditable = false
        setupVision()
        
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            myTextView.resignFirstResponder()
            return false
        }
        return true
    }
    
//======
    //말하기
    @IBAction func textToSpeech(_ sender: Any) {
         
         let synthesizer = AVSpeechSynthesizer()
         let utterance = AVSpeechUtterance(string: myTextView.text )
         
         utterance.voice = AVSpeechSynthesisVoice(language: "ko-KR")
         utterance.rate = 0.5
         utterance.pitchMultiplier = 1.0
         utterance.volume = 1
                
        synthesizer.speak(utterance)
     }

    // 듣기
    @IBAction func speechToText(_ sender: Any) {
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            speechText.isEnabled = false
            speechText.setTitle("중단", for: .normal)
        } else {
            startRecording()
            speechText.setTitle("듣기", for: .normal)
        }
    }
    
    // 보기
    @IBAction func btnTakePicture(_ sender: Any) {
        myTextView.text = "영어, 프랑스어, 독일어, 이탈리아어, 간단한 중국어와 스페인어를 볼 수 있습니다!"
        
        let scannerViewController = VNDocumentCameraViewController()
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
//======
    
    // 듣기

     func startRecording() {
         
         if recognitionTask != nil {
             recognitionTask?.cancel()
             recognitionTask = nil
         }
         
         let audioSession = AVAudioSession.sharedInstance()
        
         do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord)
            try audioSession.setMode(AVAudioSession.Mode.measurement)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
         } catch {
             print("audioSession properties weren't set because of an error.")
         }
         
         recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
         
         let inputNode = audioEngine.inputNode
         
         guard let recognitionRequest = recognitionRequest else {
             fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
         }
         
         recognitionRequest.shouldReportPartialResults = true
         
         recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
             
             var isFinal = false
             
             if result != nil {
                 self.myTextView.text = result?.bestTranscription.formattedString
                 isFinal = (result?.isFinal)!
             }
             
             if error != nil || isFinal {
                 self.audioEngine.stop()
                 inputNode.removeTap(onBus: 0)
                 
                 self.recognitionRequest = nil
                 self.recognitionTask = nil
                 
                 self.speechText.isEnabled = true
             }
         })
         
         let recordingFormat = inputNode.outputFormat(forBus: 0)
         inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
             self.recognitionRequest?.append(buffer)
         }
         
         audioEngine.prepare()
         
         do {
             try audioEngine.start()
         } catch {
             print("audioEngine couldn't start because of an error.")
         }
         
         myTextView.text = "아이폰 마이크에 말해주세요! 제가 듣고 메모장에 입력할께요~!"
         
     }
         
     func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
         if available {
             speechText.isEnabled = true
         } else {
             speechText.isEnabled = false
         }
     }
    // 듣기

    // 보기
    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var detectedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                print("text \(topCandidate.string) has confidence \(topCandidate.confidence)")
    
                detectedText += topCandidate.string
                detectedText += "\n"
            }
            
            DispatchQueue.main.async {
                self.myTextView.text = detectedText
                self.myTextView.flashScrollIndicators()
            }
        }

        textRecognitionRequest.recognitionLevel = .accurate
        textRecognitionRequest.recognitionLanguages = ["zh_CN"]
        textRecognitionRequest.customWords = [""]
    }
    
    private func processImage(_ image: UIImage) {
        recognizeTextInImage(image)
    }
    
    private func recognizeTextInImage(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        
        myTextView.text = ""
        textRecognitionWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
                print(error)
            }
        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        let originalImage = scan.imageOfPage(at: 0)
        let newImage = compressedImage(originalImage)
        controller.dismiss(animated: true)
        
        processImage(newImage)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }

    func compressedImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData) else {
                return originalImage
        }
        return reloadedImage
    }
    // 보기
    
}

func textViewShouldReturn(textView: UITextView!) -> Bool {
    
    return true;
}
