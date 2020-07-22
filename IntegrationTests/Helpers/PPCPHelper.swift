import Foundation

@objc class PPCPHelper : NSObject {

    private static let _sharedInstance = PPCPHelper()

    private override init() {}

    @objc class func sharedInstance() -> PPCPHelper {
        return PPCPHelper._sharedInstance
    }

    @objc func fetchPayPalIDToken(completion: @escaping ((String?, Error?) -> Void)) {
        var components = URLComponents(url: URL(string: "https://ppcp-sample-merchant-sand.herokuapp.com")!, resolvingAgainstBaseURL: false)!
        components.path = "/id-token"
        components.queryItems = [URLQueryItem(name: "countryCode", value: "US")]

        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = "GET"

        URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            guard let data = data, error == nil else {
                completion(nil, error!)
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary
                let uat = json?.value(forKey: "id_token")
                completion(uat as? String, nil)
            } catch (let error) {
                completion(nil, error)
            }
        }.resume()
    }
}
