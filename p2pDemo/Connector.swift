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
        self.mcPeerId = MCPeerID(displayName: UIDevice.currentDevice().name)
        
        mcSession = MCSession(peer: mcPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.None)
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
        mcBrowser.invitePeer(p, toSession: mcSession, withContext: nil, timeout: NSTimeInterval(2000))
    }

    override func finalize() {
        super.finalize()
        mcBrowser.stopBrowsingForPeers()
        mcAdvertiser.stopAdvertisingPeer()
    }
}

extension Connector : MCNearbyServiceBrowserDelegate {
    func browser(browser: MCNearbyServiceBrowser!, didNotStartBrowsingForPeers error: NSError!) {
        NSLog("browser failed \(error.localizedDescription)")
    }
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {
        NSLog("found \(peerID.displayName)")
//        connectPeer(peerID)
    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!) {
        NSLog("lost \(peerID.displayName)")
    }
}

extension Connector : MCNearbyServiceAdvertiserDelegate {
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        NSLog("accepted invitation from \(peerID.displayName)")
        invitationHandler(true, mcSession)
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        NSLog("advertiser failed: \(error.localizedDescription)")
    }
}

extension Connector : MCSessionDelegate{
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        //      called when connection created
        NSLog("peer: \(peerID.description). state: \(state.rawValue)")
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {
        // called data received from peer
        
        dispatch_async(dispatch_get_main_queue()) {
            if let msg: AnyObject? = NSKeyedUnarchiver.unarchiveObjectWithData(data) {
                NSLog("\(peerID.displayName) sent data = \(msg)")
            } else {NSLog("recieved nil data from \(peerID.displayName)")}
        }
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        // called when byte stream
        NSLog("session recieved stream from \(peerID.displayName)")
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        // called when received resource from peer
        NSLog("recieving resource from \(peerID.displayName)")
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        // called when finished receiving data from peer
        NSLog("resource done")
    }
    func session(session: MCSession!, didReceiveCertificate certificate: [AnyObject]!, fromPeer peerID: MCPeerID!, certificateHandler: ((Bool) -> Void)!) {
        //this method should inspect the cerificate, and approve/disapprove connection
        NSLog("recieve certificate from \(peerID.displayName)")
        certificateHandler(true)
    }
}
