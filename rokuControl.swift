import Foundation

// Replace this with the IP address of your Roku TV
let ROKU_IP = "192.168.1.100"  // Example IP address
let ROKU_PORT = 8060  // Default Roku ECP port

// Base URL for ECP commands
let BASE_URL = "http://\(ROKU_IP):\(ROKU_PORT)"

// Function to send a command to the Roku TV
func sendCommand(command: String, completion: @escaping (Bool) -> Void) {
    let urlString = "\(BASE_URL)/\(command)"
    guard let url = URL(string: urlString) else {
        print("Invalid URL: \(urlString)")
        completion(false)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error sending command: \(command), Error: \(error.localizedDescription)")
            completion(false)
            return
        }

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                print("Successfully sent command: \(command)")
                completion(true)
            } else {
                print("Failed to send command: \(command), Status Code: \(httpResponse.statusCode)")
                completion(false)
            }
        }
    }
    task.resume()
}

// Command functions
func powerOn(completion: @escaping (Bool) -> Void) {
    sendCommand(command: "keypress/PowerOn", completion: completion)
}

func powerOff(completion: @escaping (Bool) -> Void) {
    sendCommand(command: "keypress/PowerOff", completion: completion)
}

func volumeUp(completion: @escaping (Bool) -> Void) {
    sendCommand(command: "keypress/VolumeUp", completion: completion)
}

func volumeDown(completion: @escaping (Bool) -> Void) {
    sendCommand(command: "keypress/VolumeDown", completion: completion)
}

func mute(completion: @escaping (Bool) -> Void) {
    sendCommand(command: "keypress/VolumeMute", completion: completion)
}

func home(completion: @escaping (Bool) -> Void) {
    sendCommand(command: "keypress/Home", completion: completion)
}

func launchApp(appID: Int, completion: @escaping (Bool) -> Void) {
    sendCommand(command: "launch/\(appID)", completion: completion)
}

// Example usage
func exampleUsage() {
    // Go to the home screen
    home { success in
        // Power on the TV
        powerOn { success in
            // Increase volume
            volumeUp { success in
                // Launch Netflix (example app ID)
                launchApp(appID: 12) { success in
                    // Further actions can be added here
                }
            }
        }
    }
}

// Start the example
exampleUsage()

// Keep the main run loop alive to wait for async tasks
RunLoop.main.run()
