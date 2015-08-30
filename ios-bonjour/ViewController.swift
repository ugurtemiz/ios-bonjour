//
//  ViewController.swift
//  ios-bonjour
//
//  Created by Ugur Temiz on 27/08/15.
//  Copyright (c) 2015 Ugur Temiz. All rights reserved.
//

import CocoaAsyncSocket
import UIKit

enum TAG: Int {
    case header = 1
    case body   = 2
}

class ViewController: UIViewController, NSNetServiceDelegate, NSNetServiceBrowserDelegate, GCDAsyncSocketDelegate {

    var service : NSNetService!
    var socket  : GCDAsyncSocket!
    
    @IBOutlet weak var senderTextField: UITextField!
    @IBOutlet weak var receiverTextField: UITextField!
    
    @IBOutlet weak var sendButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startTalking()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func parseHeader(data: NSData) -> UInt {
        var out: UInt = 0
        data.getBytes(&out, length: sizeof(UInt))
        return out
    }
    
    func handleResponseBody(data: NSData) {
        if let message = NSString(data: data, encoding: NSUTF8StringEncoding) {
            self.receiverTextField.text = message as String
        }
    }
    
    @IBAction func sendText() {
        if let data = self.senderTextField.text.dataUsingEncoding(NSUTF8StringEncoding) {
            var header = data.length
            let headerData = NSData(bytes: &header, length: sizeof(UInt))
            self.socket.writeData(headerData, withTimeout: -1.0, tag: TAG.header.rawValue)
            self.socket.writeData(data, withTimeout: -1.0, tag: TAG.body.rawValue)
        }
    }

    func startTalking () {
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: dispatch_get_main_queue())
        var error : NSError?
        if self.socket.acceptOnPort(0, error: &error){
            self.service = NSNetService(domain: "local.", type: "_ugurtemiz._tcp", name: "Ugur's iPhone", port: Int32(self.socket.localPort))
            self.service.delegate = self
            self.service.publish()
        } else {
            println("Error occured with acceptOnPort. Error \(error)")
        }
    }

    /*
    *  Delegates of NSNetService
    **/
    
    func netServiceDidPublish(sender: NSNetService) {
        println("Bonjour service published. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port)")
    }
    
    func netService(sender: NSNetService, didNotPublish errorDict: [NSObject : AnyObject]) {
        println("Unable to create socket. domain: \(sender.domain), type: \(sender.type), name: \(sender.name), port: \(sender.port), Error \(errorDict)")
    }
    
    /*
    *  END OF Delegates
    **/
    
    /*
    *  Delegates of GCDAsyncSokcket
    **/
    
    func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        println("Did accept new socket")
        self.socket = newSocket
        
        self.socket.readDataToLength(UInt(sizeof(UInt64)), withTimeout: -1.0, tag: 0)
        println("Connected to " + self.service.name)
    }
    
    func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        println("Socket disconnected: error \(err)")
        if self.socket == socket {
            println("Disconnected from " + self.service.name)
        }
    }
    
    func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if data.length == sizeof(UInt) {
            let bodyLength: UInt = self.parseHeader(data)
            sock.readDataToLength(bodyLength, withTimeout: -1, tag: TAG.body.rawValue)
        } else {
            self.handleResponseBody(data)
            sock.readDataToLength(UInt(sizeof(UInt)), withTimeout: -1, tag: TAG.header.rawValue)
        }
    }
    
    func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        println("Write data with tag of \(tag)")
    }

    /*
    *  END OF Delegates
    **/
    
}

