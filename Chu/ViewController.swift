//
//  ViewController.swift
//  Chu
//
//  Created by Yuya Matsuo on 2020/10/07.
//

import AVFoundation
import UIKit

class ViewController: UIViewController {

  lazy var engine = AVAudioEngine()
  lazy var input = engine.inputNode
  lazy var output = engine.mainMixerNode

  var pitchParameter: AUParameter?

  @IBOutlet weak var slider: UISlider!

  override func viewDidLoad() {
    super.viewDidLoad()

    let manager = AVAudioUnitComponentManager.shared()
    let components = manager.components(
      matching: AudioComponentDescription(
        componentType: kAudioUnitType_Effect,
        componentSubType: 0,
        componentManufacturer: 0,
        componentFlags: 0,
        componentFlagsMask: 0))

    guard let pitchShift = components.filter { $0.name == "AUNewPitch" }.first else {
      print("AUNewPitch not found!")
      return
    }

    AVAudioUnit.instantiate(with: pitchShift.audioComponentDescription, options: []) {
      [weak self] avAudioUnit, error in
      guard let avAudioUnit = avAudioUnit, error == nil else {
        print("Error: \(error)")
        return
      }

      self?.setupAudioEngine(with: avAudioUnit)
    }
  }

  private func setupAudioEngine(with avAudioUnit: AVAudioUnit) {
    engine.attach(avAudioUnit)
    pitchParameter =
      avAudioUnit.auAudioUnit.parameterTree?.allParameters.filter {
        $0.displayName == "Pitch Scale"
      }.first

    let input = engine.inputNode
    let output = engine.mainMixerNode

    engine.connect(input, to: avAudioUnit, format: input.outputFormat(forBus: 0))
    engine.connect(avAudioUnit, to: output, format: input.outputFormat(forBus: 0))

    do {
      try engine.start()
    } catch {
      print("failed to start engine")
      print(error)
    }
  }

  @IBAction func onChangeSlider(_ sender: Any) {
    guard let pitchParameter = pitchParameter else {
      return
    }

    // 0.0 - 1.0 to min - max
    let newValue =
      slider.value * (pitchParameter.maxValue - pitchParameter.minValue) + pitchParameter.minValue
    pitchParameter.setValue(newValue, originator: nil)
  }
}
