//
//  ViewController.swift
//  MachineLearningImageRecognation
//
//  Created by Dilara Akdeniz on 5.09.2024.
//

import UIKit
import CoreML //Machine Learning için kullanılan framework
import Vision //CoreML ile image recognation için kullanılan bir modül

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var textLabel: UILabel!
    
    var chosenImage = CIImage()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func changeButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        imageView.image = info[.originalImage] as? UIImage
        self.dismiss(animated: true)
        
        if let ciImage = CIImage(image: imageView.image!) { //Core Image tarafından kullanılabilecek bir görsel
            chosenImage = ciImage
        }
        
        
        recognizeImage(image: chosenImage)
    }
    
    func recognizeImage(image: CIImage) {
        
        textLabel.text = "Finding..."
        
        // 1) Request
        
        if let model = try? VNCoreMLModel(for: MobileNetV2().model) { // MobileNetV2 değişkenini kullanarak modeli bşr değişkene atadık
            let request = VNCoreMLRequest(model: model) {(vnrequest, error) in
                
                if let results = vnrequest.results as? [VNClassificationObservation] { //Bu model bize birden fazla sonucu bir Any array içinde döndürür. Bize ilk sonuç lazım yani olma olasılığı en yüksek olan.
                    if results.count > 0 {
                        let topResult = results.first //İlk seçeneği alacağız
                        
                        DispatchQueue.main.async { //Kullanıcının ana ekranında yapılacak asenkron işlemler için kullanıyoruz
                            
                            let confidenceLevel = (topResult?.confidence ?? 0) * 100 //Yüzdelik dilimi göstermek için kullanıyoruz bu kısmı ama confidence 0-1 arasında değer gösterir o yüzden yüzdelik olarak çevirdik
                            let rounded = Int(confidenceLevel * 100) / 100 //Ekstrem double rakamlar çıktığı için yuvarlama yaptık
                            
                            self.textLabel.text = "\(confidenceLevel)% it's \(topResult!.identifier)"
                        }
                    }
                }
            }
            
            // 2) Handler
            let handler = VNImageRequestHandler(ciImage: image)
            DispatchQueue.global(qos: .userInteractive).async {  //DispatchQueue.main.async genel olarak kullanılan ve birden fazla processin birbirlerinin bitmesini beklemeden arka planda çalıştırılması için kullanılır, DispatchQueue.global .userInteractive ise arka planda çalışan process'in prioritysini arttırır ve onun işlenmesini hızlandırır ama çok fazla tercih edilmez.
                do {
                    try handler.perform([request])
                } catch {
                    print("error")
                }
                
                
            }
        }
    }
}

