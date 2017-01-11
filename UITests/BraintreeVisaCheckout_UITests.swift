import XCTest

class BraintreeVisaCheckout_UITests: XCTestCase {
        
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-EnvironmentSandbox")
        app.launchArguments.append("-TokenizationKey")
        app.launchArguments.append("-Integration:BraintreeDemoVisaCheckoutViewController")
        app.launch()
        sleep(1)
        self.waitForElementToBeHittable(app.buttons["Visa Checkout"])
        sleep(2)
        app.buttons["Visa Checkout"].tap()
        self.waitForElementToAppear(app.staticTexts["FOR TESTING PURPOSES ONLY"])
        loginPageHelper()
    }
    
    func testVisaCheckout_whenClickingBackArrow_cancels() {
        app.navigationBars["VSignInView"].buttons["Cancel"].tap()
        app.alerts.buttons["OK"].tap()
        
        XCTAssertTrue(app.buttons["Cancelled Visa Checkout"].exists)
    }
    
    func testVisaCheckout_whenClickingCrossButton_cancels() {
        app.navigationBars["VSignInView"].buttons["btn cross"].tap()
        app.alerts.buttons["OK"].tap()
        
        XCTAssertTrue(app.buttons["Cancelled Visa Checkout"].exists)
    }
    
    func testVisaCheckout_withSuccess_recievesNonce() {
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.staticTexts["Email or Mobile number"].tap()
        let clearButton = elementsQuery.buttons["Clear"]
        if (clearButton.exists) {
            clearButton.tap()
        }
        let usernameField = elementsQuery.textFields["Username"]
        self.waitForElementToBeHittable(usernameField)
        usernameField.typeText("test@bt.com")
        usernameField.tap()
        let passwordField = elementsQuery.secureTextFields["Password"]
        self.waitForElementToAppear(passwordField)
        passwordField.tap()
        passwordField.typeText("12345678")
        
        app.buttons["Sign In"].tap()
        app.buttons["Continue"].tap()

        self.waitForElementToAppear(app.buttons["Got a nonce. Tap to make a transaction."])
        XCTAssertTrue(app.buttons["Got a nonce. Tap to make a transaction."].exists)
    }
    
    func loginPageHelper() {
        let signInButton = app.otherElements.staticTexts[" Sign In "]
        if (signInButton.exists) {
            signInButton.tap()
            self.waitForElementToAppear(app.links["Don't have a Visa Checkout account?"])
        }
    }
}
