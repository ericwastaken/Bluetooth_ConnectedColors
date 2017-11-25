import UIKit

class ColorSwitchViewController: UIViewController {
  
  @IBOutlet weak var connectionsLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  
  let colorService = ColorServiceManager()
  var foundPeers: [String] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    colorService.delegate = self
    tableView.dataSource = self
    tableView.delegate = self
  }
  
  @IBAction func redTapped() {
    self.change(color: .red)
    colorService.send(colorName: "red")
  }
  
  @IBAction func yellowTapped() {
    self.change(color: .yellow)
    colorService.send(colorName: "yellow")
  }
  
  func change(color : UIColor) {
    UIView.animate(withDuration: 0.2) {
      self.view.backgroundColor = color
    }
  }
  
}

extension ColorSwitchViewController: ColorServiceManagerDelegate {
  
  func foundPeersChanged(manager: ColorServiceManager, peersFound: [String]) {
    // The list of found peers has changed, so we update our tableView
    NSLog("Current list of peers:\n\(peersFound)")
    self.foundPeers = peersFound
    DispatchQueue.main.async {
      self.tableView.reloadData()
    }
  }
  
  func connectedDevicesChanged(manager: ColorServiceManager, connectedDevices: [String]) {
    OperationQueue.main.addOperation {
      self.connectionsLabel.text = "Connections: \(connectedDevices)"
    }
  }
  
  func colorChanged(manager: ColorServiceManager, colorString: String) {
    OperationQueue.main.addOperation {
      switch colorString {
      case "red":
        self.change(color: .red)
      case "yellow":
        self.change(color: .yellow)
      default:
        NSLog("%@", "Unknown color value received: \(colorString)")
      }
    }
  }
  
}

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
