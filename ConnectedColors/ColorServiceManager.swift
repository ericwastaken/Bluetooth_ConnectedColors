//
//  ColorServiceManager.swift
//  ConnectedColors
//
//  Created by Ralf Ebert on 10/02/2017.
//  Copyright © 2017 Example. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol ColorServiceManagerDelegate {
  
  // Add a protocol to communicate the "found" peers has changed
  func foundPeersChanged(manager: ColorServiceManager, peersFound: [String])
  func connectedDevicesChanged(manager: ColorServiceManager, connectedDevices: [String])
  func colorChanged(manager: ColorServiceManager, colorString: String)
  
}

class ColorServiceManager : NSObject {
  
  // Service type must be a unique string, at most 15 characters long
  // and can contain only ASCII lowercase letters, numbers and hyphens.
  private let ColorServiceType = "example-color"
  
  private let myPeerId = MCPeerID(displayName: UIDevice.current.name)
  
  private let serviceAdvertiser: MCNearbyServiceAdvertiser
  private let serviceBrowser: MCNearbyServiceBrowser
  
  // Add two class properties to keep track of the peers we've found
  fileprivate var peerNames: [String] = []
  fileprivate var peerObjects: [MCPeerID] = []
  
  var delegate: ColorServiceManagerDelegate?
  
  lazy var session: MCSession = {
    let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: .required)
    session.delegate = self
    return session
  }()
  
  override init() {
    self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: ColorServiceType)
    self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: ColorServiceType)
    
    super.init()
    
    self.serviceAdvertiser.delegate = self
    self.serviceAdvertiser.startAdvertisingPeer()
    
    self.serviceBrowser.delegate = self
    self.serviceBrowser.startBrowsingForPeers()
  }
  
  func invite(peer peerName: String) {
    NSLog("%@", "peerName: \(peerName)")
    // Find the peerName in peerNames array and if found, invite to connect
    if let indexOfPeer = self.peerNames.index(of: peerName) {
      // Found it, so invite the peer to connect
      let peerToInvite = self.peerObjects[indexOfPeer]
      NSLog("%@", "invitePeer: \(peerToInvite)")
      self.serviceBrowser.invitePeer(peerToInvite, to: self.session, withContext: nil, timeout: 10)
    }
  }
  
  func send(colorName: String) {
    NSLog("%@", "sendColor: \(colorName) to \(session.connectedPeers.count) peers")
    
    if session.connectedPeers.count > 0 {
      do {
        try self.session.send(colorName.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
      }
      catch let error {
        NSLog("%@", "Error for sending: \(error)")
      }
    }
    
  }
  
  deinit {
    self.serviceAdvertiser.stopAdvertisingPeer()
    self.serviceBrowser.stopBrowsingForPeers()
  }
  
}

extension ColorServiceManager: MCNearbyServiceAdvertiserDelegate {
  
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
    NSLog("%@", "didNotStartAdvertisingPeer: \(error)")
  }
  
  func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
    NSLog("%@", "didReceiveInvitationFromPeer \(peerID)")
    invitationHandler(true, self.session)
  }
  
}

extension ColorServiceManager: MCNearbyServiceBrowserDelegate {
  
  func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
    NSLog("%@", "didNotStartBrowsingForPeers: \(error)")
  }
  
  func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
    NSLog("%@", "foundPeer: \(peerID)")
    //NSLog("%@", "invitePeer: \(peerID)")
    
    // Here, we found a peer.
    
    // Let's NOT invite that peer right away. Instead, we keep a list/set of peers we've found.
    //browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    
    // Add the list of found peers
    if !self.peerNames.contains(peerID.displayName) {
      self.peerNames.append(peerID.displayName)
    }
    if !self.peerObjects.contains(peerID) {
      self.peerObjects.append(peerID)
    }
    
    // Fire off our delegate to let implementers know there's been a change in found peers
    self.delegate?.foundPeersChanged(manager: self, peersFound: self.peerNames.sorted())
    
  }
  
  func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    NSLog("%@", "lostPeer: \(peerID)")
    
    // Here, we note that we've lost a peer.
    
    // Of course, we also need to remove peers from the set of found peers when we lose a peer.
    self.peerNames = self.peerNames.filter { (peerName) -> Bool in
      peerName != peerID.displayName
    }
    self.peerObjects = self.peerObjects.filter({ (peerToTest) -> Bool in
      peerToTest != peerID
    })
    
    // Fire off our delegate to let implementers know there's been a change in found peers
    self.delegate?.foundPeersChanged(manager: self, peersFound: self.peerNames.sorted())
  }
  
}

extension ColorServiceManager: MCSessionDelegate {
  
  func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
    NSLog("%@", "peer \(peerID) didChangeState: \(state)")
    self.delegate?.connectedDevicesChanged(manager: self, connectedDevices:
      session.connectedPeers.map{$0.displayName})
  }
  
  func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
    NSLog("%@", "didReceiveData: \(data)")
    let str = String(data: data, encoding: .utf8)!
    self.delegate?.colorChanged(manager: self, colorString: str)
  }
  
  func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    NSLog("%@", "didReceiveStream")
  }
  
  func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    NSLog("%@", "didStartReceivingResourceWithName")
  }
  
  func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    NSLog("%@", "didFinishReceivingResourceWithName")
  }
  
}
