import Foundation

class OpenAIClient {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func transcribe(audioFileURL: URL, prompt: String? = nil, language: String? = nil, completion: @escaping (Result<String, Error>) -> Void) {
        let endpoint = "\(baseURL)/audio/transcriptions"

        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(
                domain: "OpenAIClient",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]
            )))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        guard let audioData = try? Data(contentsOf: audioFileURL) else {
            completion(.failure(NSError(
                domain: "OpenAIClient",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to read audio file"]
            )))
            return
        }

        var body = Data()

        // Add model parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"model\"\r\n\r\n".data(using: .utf8)!)
        body.append("whisper-1\r\n".data(using: .utf8)!)

        // Add file parameter
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"audio.wav\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: audio/wav\r\n\r\n".data(using: .utf8)!)
        body.append(audioData)
        body.append("\r\n".data(using: .utf8)!)

        // Add prompt parameter if provided
        if let prompt = prompt, !prompt.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"prompt\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(prompt)\r\n".data(using: .utf8)!)
        }

        // Add language parameter if provided
        if let language = language, !language.isEmpty {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"language\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(language)\r\n".data(using: .utf8)!)
        }

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(
                    domain: "OpenAIClient",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "No data received"]
                )))
                return
            }

            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    // Check for API errors
                    if let errorObj = json["error"] as? [String: Any],
                       let message = errorObj["message"] as? String {
                        completion(.failure(NSError(
                            domain: "OpenAIClient",
                            code: -4,
                            userInfo: [NSLocalizedDescriptionKey: "API Error: \(message)"]
                        )))
                        return
                    }

                    // Extract transcription
                    if let text = json["text"] as? String {
                        completion(.success(text))
                    } else {
                        completion(.failure(NSError(
                            domain: "OpenAIClient",
                            code: -5,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid response format"]
                        )))
                    }
                } else {
                    completion(.failure(NSError(
                        domain: "OpenAIClient",
                        code: -6,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to parse JSON response"]
                    )))
                }
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
    }
}
