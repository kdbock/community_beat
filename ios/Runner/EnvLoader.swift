import Foundation

// Read .env file from project root
let envPath = "../../.env"
if let envContent = try? String(contentsOfFile: envPath, encoding: .utf8) {
    for line in envContent.components(separatedBy: "\n") {
        let parts = line.components(separatedBy: "=")
        if parts.count == 2 {
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            ProcessInfo.processInfo.setValue(value, forKey: key)
        }
    }
}
