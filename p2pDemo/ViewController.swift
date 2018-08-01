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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NSLog("will dissapear")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setUpConnection(){
        self.mcPeerId = MCPeerID(displayName: UIDevice.current.name)
        
        mcSession = MCSession(peer: mcPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        mcSession.delegate = self
        
        mcBrowser = MCBrowserViewController(serviceType: "chatDemoApp", session: mcSession)
        mcBrowser.delegate = self
        
        mcAdvertiser = MCAdvertiserAssistant(serviceType: "chatDemoApp", discoveryInfo: nil, session: mcSession)
    }
    
    @IBAction func searchForPeers(_ sender: AnyObject) {
        mcAdvertiser.start()
        present(mcBrowser, animated: true, completion: nil)
    }
    
    @IBAction func showPeers(_ sender: AnyObject) {
        print("\(mcSession.connectedPeers.count)")
        for item in mcSession.connectedPeers{
            print("\(item.displayName)")
        }
    }
    @IBAction func sendData(_ sender: AnyObject) {
        print("sending \(String(describing: textField.text))")
//        let data = self.textField.text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        do {
        let data = NSKeyedArchiver.archivedData(withRootObject: textField.text!)
        try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
        } catch {
            print("sending \(String(describing: textField.text)) Failed with \(error.localizedDescription)")
        }
    }
}

extension ViewController : UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return msgs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
        cell.textLabel?.text = msgs[indexPath.row]
        return cell
    }
}

extension ViewController : MCSessionDelegate{
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
//      called when connection created
        NSLog("peer: \(peerID.displayName). state: \(state.rawValue)")
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // called data received from pper
        NSLog("data received from \(peerID.displayName)")

        DispatchQueue.main.async {
            if let msg = NSKeyedUnarchiver.unarchiveObject(with: data) {
                self.msgs.append("\(msg)")
            } else {
                self.msgs.append("corrupted")
            }
            self.table.reloadData()
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // called when byte stream
        NSLog("1")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // called when received resource from peer
        NSLog("2")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // called when finished receiving data from peer
        NSLog("3")
    }
    private func session(_ session: MCSession, didReceiveCertificate certificate: [AnyObject], fromPeer peerID: MCPeerID, certificateHandler: ((Bool) -> Void)) {
        //this method should inspect the cerificate, and approve/disapprove connection
        NSLog("certificate from \(peerID.displayName)")
        certificateHandler(true)
    }
}

extension ViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        // called when selected peer to connect
        finishSearching(browserViewController)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        // called when 'cancel' was clicked in peer selection screen
        finishSearching(browserViewController)
    }
    
    func finishSearching(_ browser :MCBrowserViewController!){
        mcAdvertiser.stop()
        browser.dismiss(animated: true, completion: nil)
    }
}
