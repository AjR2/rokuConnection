import Foundation
import Network

// Function to discover Roku devices on the local network
func discoverRokuDevices(completion: @escaping ([String]) -> Void) {
    let SSDP_GROUP = "239.255.255.250"
    let SSDP_PORT: UInt16 = 1900

    let MSEARCH_MSG = """
    M-SEARCH * HTTP/1.1\r
    HOST: \(SSDP_GROUP):\(SSDP_PORT)\r
    MAN: "ssdp:discover"\r
    MX: 1\r
    ST: roku:ecp\r
    \r
    """

    var rokuDevices = Set<String>()
    let queue = DispatchQueue(label: "SSDPQueue")
    let group = DispatchGroup()
    group.enter()

    // Create parameters for UDP connection
    let parameters = NWParameters.udp
    parameters.allowLocalEndpointReuse = true

    // Create a multicast group endpoint
    guard let multicastHost = NWEndpoint.Host(SSDP_GROUP),
          let port = NWEndpoint.Port(rawValue: SSDP_PORT) else {
        print("Invalid multicast address or port.")
        completion([])
        return
    }

    // Create a UDP connection
    let connection = NWConnection(host: multicastHost, port: port, using: parameters)

    connection.stateUpdateHandler = { newState in
        switch newState {
        case .ready:
            // Send the M-SEARCH message
            let data = MSEARCH_MSG.data(using: .utf8)!
            connection.send(content: data, completion: .contentProcessed { error in
                if let error = error {
                    print("Error sending data: \(error)")
                    group.leave()
                } else {
                    // Start receiving responses
                    receiveResponses(connection: connection, devices: &rokuDevices, group: group)
                }
            })
        default:
            break
        }
    }

    connection.start(queue: queue)

    // Wait for responses for a specified duration
    group.notify(queue: .main) {
        connection.cancel()
        completion(Array(rokuDevices))
    }
}

// Function to receive responses from devices
func receiveResponses(connection: NWConnection, devices: inout Set<String>, group: DispatchGroup) {
    connection.receiveMessage { (data, context, isComplete, error) in
        if let data = data, let response = String(data: data, encoding: .utf8) {
            if response.contains("roku:ecp") {
                // Extract the IP address from the response
                if let senderIP = extractIPAddress(from: response) {
                    devices.insert(senderIP)
                }
            }
        }

        if let error = error {
            print("Error receiving data: \(error)")
            group.leave()
        } else {
            // Continue receiving
            receiveResponses(connection: connection, devices: &devices, group: group)
        }
    }

    // Set a timeout for the discovery process
    DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
        group.leave()
    }
}

// Helper function to extract IP address from the response
func extractIPAddress(from response: String) -> String? {
    if let locationLine = response.components(separatedBy: "\r\n").first(where: { $0.hasPrefix("LOCATION:") || $0.hasPrefix("Location:") }),
       let url = locationLine.components(separatedBy: " ").last,
       let host = URL(string: url)?.host {
        return host
    }
    return nil
}

// Function to get Roku device information
func getRokuInfo(ip: String) {
    let urlString = "http://\(ip):8060/query/device-info"
    guard let url = URL(string: urlString) else {
        print("Invalid URL for IP: \(ip)")
        return
    }

    let task = URLSession.shared.dataTask(with: url) { data, response, error in
        if let data = data {
            // Parse the XML data
            let parser = XMLParser(data: data)
            let delegate = RokuXMLParserDelegate()
            parser.delegate = delegate
            if parser.parse() {
                delegate.elements.forEach { key, value in
                    print("\(key): \(value)")
                }
            } else {
                print("Failed to parse XML from \(ip)")
            }
        } else {
            print("Failed to get info from Roku device at \(ip)")
        }
    }
    task.resume()
}

// XML Parser Delegate to parse Roku device info
class RokuXMLParserDelegate: NSObject, XMLParserDelegate {
    var elements: [String: String] = [:]
    var currentElementName: String = ""
    var currentElementValue: String = ""

    func parser(_ parser: XMLParser, didStartElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?,
                attributes attributeDict: [String: String] = [:]) {
        currentElementName = elementName
        currentElementValue = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentElementValue += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        elements[currentElementName] = currentElementValue.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// Main execution
discoverRokuDevices { devices in
    if devices.isEmpty {
        print("No Roku devices found.")
    } else {
        print("Found Roku devices:")
        for ip in devices {
            print(" - \(ip)")
            getRokuInfo(ip: ip)
        }
    }
}

// Keep the main run loop alive
RunLoop.main.run()
