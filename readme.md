# Readme - ConnectedColors Bluetooth Connected Peers Example

## Summary

This repository is the source code that accompanied the online article called "iOS & Swift Tutorial: Multipeer Connectivity" by Ralf Ebert. The article was published at https://www.ralfebert.de/tutorials/ios-swift-multipeer-connectivity/.

Please refer to the article for information about this sample.

Note, though I am hosting the code in my GitHub account, I am not associated with the author in any way. As the code has "copyright" headers, I have asked for permission to share this code and will update this when I hear back. Anyone using this code should take note of the author's possible ownership of this!

## Branch Information

This branch actually includes modifications not discussed in the article. Specifically, this branch answers a Stack Overflow question:

- **Question:** iOS Swift 3 - Multipleer/Bluetooth
- **URL:** https://stackoverflow.com/questions/42883039/ios-swift-3-multipleer-bluetooth/47483346#47483346
- **Question Summary:** How do i make it so the devices do not automatically connect to each other using bluetooth. I would like for you to be able to click a button which opens a menu in which you can pick devices for bluetooth connection based on names.

This branch changes the code to accomplish the "manual" connection!

## Summary of Changes

First, inside `protocol ColorServiceManagerDelegate {}`:

```swift
    // Add a protocol method to communicate the "found" peers has changed.
    // We will need to implement this in the view and will do so later on!
    func foundPeersChanged(manager: ColorServiceManager, peersFound: [String])
```

Then, inside the main class `class ColorServiceManager : NSObject {}`, let's add 2 properties to keep track of found peers:

```swift
    // Add two class properties to keep track of the peers we've found
    fileprivate var peerNames: [String] = []
    fileprivate var peerObjects: [MCPeerID] = []
```

Next, in `MCNearbyServiceBrowserDelegate` change `foundPeer` and `lostPeer` to keep track of the peers list.

```swift
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
      NSLog("%@", "foundPeer: \(peerID)")
    
      // Here, we found a peer.
        
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
```

Then, you're going to need a way to **connect** to a peer, so in the class `ColorServiceManager`, right after the `init()` method, add a new method:

```swift
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
```

Over in your view controller, you need to implement a tableView and related methods as well as the new method in the delegate. 

Go to Interface Builder and add a Table View to the view, then link it to your view controller as usual:

```swift
    @IBOutlet weak var tableView: UITableView!
```

Make sure you add a prototype cell to the table view in IB. Set the cell to **Style: Basic** and set the **Identifier** to `foundPeerCell`.

Also, add a property to your view controller to back up the tableView:

```swift
    var foundPeers: [String] = []
```

Then, add the following to `extension ColorSwitchViewController: ColorServiceManagerDelegate {}`

```swift
    func foundPeersChanged(manager: ColorServiceManager, peersFound: [String]) {
      // The list of found peers has changed, so we update our tableView
      NSLog("Current list of peers:\n\(peersFound)")
      self.foundPeers = peersFound
      DispatchQueue.main.async {
        self.tableView.reloadData()
      }
    }
```

Finally, add the code needed to manage the tableView:

```swift
    /**
     UITableView Data Source
     */
    extension ColorSwitchViewController: UITableViewDataSource {
      
      func numberOfSections(in tableView: UITableView) -> Int {
        return 1
      }
      
      func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return foundPeers.count
      }
      
      func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "foundPeerCell")!
        cell.textLabel?.text = foundPeers[indexPath.row]
        return cell
      }
      
    }

    /**
     UITableView Delegate
     */
    extension ColorSwitchViewController: UITableViewDelegate {
      
      // handle tap on a row
      func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Send back the invite to the peer.
        colorService.invite(peer: foundPeers[indexPath.row])
        // De-select the row
        tableView.deselectRow(at: indexPath, animated: true)
      }
      
    }
```

Note that the `tableView(tableView:didSelectRowAt)` is where we connect back to the `ColorServiceManager` and invite the peer that the user has tapped.


