//
//  ViewController.swift
//  p2pDemo
//
//  Created by Eran Guttentag on 5/4/15.
//  Copyright (c) 2015 gutte. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController {


    var mcBrowser :MCBrowserViewController!
    var mcAdvertiser :MCAdvertiserAssistant!
    var mcSession :MCSession!
    var mcPeerId :MCPeerID!
    var msgs :[String]!
    @IBOutlet weak var table: UITableView!
    @IBOutlet weak var textField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpConnection()
        msgs = [String]()
    }

    override func finalize() {
        NSLog("finalize")
        mcAdvertiser.stop()
        mcSession.disconnect()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSLog("will dissapear")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpConnection(){
        self.mcPeerId = MCPeerID(displayName: UIDevice.currentDevice().name)
        
        mcSession = MCSession(peer: mcPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
        mcSession.delegate = self
        
        mcBrowser = MCBrowserViewController(serviceType: "chatDemoApp", session: mcSession)
        mcBrowser.delegate = self
        
        mcAdvertiser = MCAdvertiserAssistant(serviceType: "chatDemoApp", discoveryInfo: nil, session: mcSession)
    }
    @IBAction func searchForPeers(sender: AnyObject) {
        mcAdvertiser.start()
        presentViewController(mcBrowser, animated: true, completion: nil)
    }
    
    @IBAction func showPeers(sender: AnyObject) {
        NSLog("\(mcSession.connectedPeers.count)")
        for item in mcSession.connectedPeers{
            NSLog("\(item.displayName)")
        }
    }
    @IBAction func sendData(sender: AnyObject) {
        NSLog("sending \(textField.text)")
//        let data = self.textField.text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let data = NSKeyedArchiver.archivedDataWithRootObject(textField.text)
        mcSession.sendData(data, toPeers: mcSession.connectedPeers, withMode: MCSessionSendDataMode.Reliable, error: nil)
    }
}

extension ViewController : UITableViewDataSource {
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return msgs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
        cell.textLabel?.text = msgs[indexPath.row]
        return cell
    }
}

extension ViewController : MCSessionDelegate{
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
//      called when connection created
        NSLog("peer: \(peerID.displayName). state: \(state.rawValue)")
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        // called data received from pper
        NSLog("data received from \(peerID.displayName)")

        dispatch_async(dispatch_get_main_queue()) {
            if let msg = NSKeyedUnarchiver.unarchiveObjectWithData(data!) {
                self.msgs.append("\(msg)")
            } else {
                self.msgs.append("corrupted")
            }
            self.table.reloadData()
        }
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        // called when byte stream
        NSLog("1")
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        // called when received resource from peer
        NSLog("2")
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        // called when finished receiving data from peer
        NSLog("3")
    }
    func session(session: MCSession!, didReceiveCertificate certificate: [AnyObject]!, fromPeer peerID: MCPeerID!, certificateHandler: ((Bool) -> Void)!) {
        //this method should inspect the cerificate, and approve/disapprove connection
        NSLog("certificate from \(peerID.displayName)")
        certificateHandler(true)
    }
}

extension ViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(browserViewController: MCBrowserViewController!) {
        // called when selected peer to connect
        finishSearching(browserViewController)
    }
    
    func browserViewControllerWasCancelled(browserViewController: MCBrowserViewController!) {
        // called when 'cancel' was clicked in peer selection screen
        finishSearching(browserViewController)
    }
    
    func finishSearching(browser :MCBrowserViewController!){
        mcAdvertiser.stop()
        browser.dismissViewControllerAnimated(true, completion: nil)
    }
}
