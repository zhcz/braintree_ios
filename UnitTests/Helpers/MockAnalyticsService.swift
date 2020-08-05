@objc(BTMockAnalyticsService) class MockAnalyticsService: BTAnalyticsService {

    @objc var lastFPTIEvent: String?
    @objc var lastFPTIAdditionalData: [String : Any]?
    @objc var lastArachneEvent: String?
    @objc var didFlushQueue: Bool = false

    override func sendFPTIEvent(_ eventName: String, with additionalData: [String : Any]) {
        self.lastFPTIEvent = eventName
        self.lastFPTIAdditionalData = additionalData
    }

    override func sendAnalyticsEvent(_ eventName: String) {
        self.lastArachneEvent = eventName
        self.didFlushQueue = false
    }

    override func sendAnalyticsEvent(_ eventName: String, completion completionBlock: ((Error?) -> Void)? = nil) {
        self.lastArachneEvent = eventName
        self.didFlushQueue = true
    }
}
