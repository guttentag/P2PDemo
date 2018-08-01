//
//  Connector.swift
//  p2pDemo
//
//  Created by Eran Guttentag on 5/7/15.
//  Copyright (c) 2015 gutte. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class Connector: UIViewController {
    var mcAdvertiser :MCNearbyServiceAdvertiser!
    var mcSession :MCSession!
    var mcPeerId :MCPeerID!
    var mcBrowser :MCNearbyServiceBrowser!
    
    func setUpConnection(){
        self.mcPeerId = MCPeerID(displayName: UIDevice.current.name)
        
        mcSession = MCSession(peer: mcPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.none)
        mcSession.delegate = self
        
        mcBrowser = MCNearbyServiceBrowser(peer: mcPeerId, serviceType: "chatDemoApp")
        mcBrowser.delegate = self
        
        mcAdvertiser = MCNearbyServiceAdvertiser(peer: mcPeerId, discoveryInfo: nil, serviceType: "chatDemoApp")
        mcAdvertiser.delegate = self
    }
    override func viewDidLoad() {
        setUpConnection()
        mcAdvertiser.startAdvertisingPeer()
        mcBrowser.startBrowsingForPeers()
        NSLog("connector started!")
    }
    
    func connectPeer(p: MCPeerID){
        NSLog("trying to connect \(p.displayName)")
        mcBrowser.invitePeer(p, to: mcSession, withContext: nil, timeout: TimeInterval(2000))
    }

    override func finalize() {
        mcBrowser.stopBrowsingForPeers()
        mcAdvertiser.stopAdvertisingPeer()
    }
}

extension Connector : MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        NSLog("browser failed \(error.localizedDescription)")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        NSLog("found \(peerID.displayName)")
//        connectPeer(peerID)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        NSLog("lost \(peerID.displayName)")
    }
    
}

extension Connector : MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping ((Bool, MCSession?) -> Void)) {
        NSLog("accepted invitation from \(peerID.displayName)")
        invitationHandler(true, mcSession)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        NSLog("advertiser failed: \(error.localizedDescription)")
    }
}

extension Connector : MCSessionDelegate{
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        //      called when connection created
        NSLog("peer: \(peerID.description). state: \(state.rawValue)")
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        // called data received from peer
        
        DispatchQueue.main.async {
            if let msg = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as AnyObject? {
                NSLog("\(peerID.displayName) sent data = \(msg)")
            } else {NSLog("recieved nil data from \(peerID.displayName)")}
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // called when byte stream
        NSLog("session recieved stream from \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // called when received resource from peer
        NSLog("recieving resource from \(peerID.displayName)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // called when finished receiving data from peer
        NSLog("resource done")
    }
    private func session(session: MCSession!, didReceiveCertificate certificate: [AnyObject]!, fromPeer peerID: MCPeerID!, certificateHandler: ((Bool) -> Void)!) {
        //this method should inspect the cerificate, and approve/disapprove connection
        NSLog("recieve certificate from \(peerID.displayName)")
        certificateHandler(true)
    }
}
