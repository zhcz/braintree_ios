@objc(BTMockAnalyticsService) class MockAnalyticsService: BTAnalyticsService {

    @objc var lastFPTIEvent: String?
    @objc var lastFPTIAdditionalData: [AnyHashable : Any]?
    @objc var lastArachneEvent: String?
    @objc var didFlushQueue: Bool = false

    override func sendFPTIEvent(_ eventName: String, with additionalData: [AnyHashable : Any]) {
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
