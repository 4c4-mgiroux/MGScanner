MGScanner
=========

MGScanner is a simple bar code scanner that's easy to use and cute. It was written for Swift.

#### Initialize MGScanner

    var scanner: MGScanner = MGScanner()
    scanner.delegate       = self
    scanner.closeImage     = "img.png"  // You can use the packaged cancelButton.png
    scanner.start(self)
    
    
In the previous example, self refers to a UIViewController. You can pass any UIViewController, 
as long as that UIViewController implements the MGScannerDelegate protocol.

---

### QR Codes

By default the QR Code is turned off (since it's mostly a bar code scanner). But if you need QR code support you can turn it on like this:

    scanner.useQR = true
  
---

#### MGScannerDelegate protocol

This protocol only has 1 method. That method is required and is used to send the data back to your application after a code is detected. Here is what is and how to use it

    func scannerDidFinishWithCode(code: String, type: String)
    {
        // code = the bar code detected
        // type = the internal string for the code type (ex: org.gs1.EAN-13)
    }