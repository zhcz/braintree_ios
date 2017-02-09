#import "UnitTests-Swift.h"
#import "BTAnalyticsService.h"
#import "BTKeychain.h"
#import "Braintree-Version.h"
#import "BTFakeHTTP.h"
#import "BTVisaCheckoutClient.h"
#import "BTVisaCheckoutCardNonce.h"
#import <XCTest/XCTest.h>
#import <VisaCheckoutFramework/VisaCheckoutFramework.h>

@interface BTVisaCheckout_Tests : XCTestCase
@property (nonatomic, strong) MockAPIClient *mockClient;
@end

@implementation BTVisaCheckout_Tests

- (void)setUp {
    [super setUp];
    self.mockClient = [[MockAPIClient alloc] initWithAuthorization: @"development_tokenization_key"];
}

- (void)testTokenization_whenConfigurationIsMissingVisaCheckout_callsBackWithError {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{}];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Unsuccessful tokenization"];
    
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    VisaPaymentSummary *visaPaymentSummary = [[VisaPaymentSummary alloc] init];
    
    [client tokenizeVisaPaymentSummary:visaPaymentSummary completion:^(BTVisaCheckoutCardNonce * _Nullable tokenizedVisaCheckoutCard, NSError * _Nullable error) {
        if (tokenizedVisaCheckoutCard) {
            XCTFail();
            return;
        }
        
        XCTAssertEqual(error.domain, BTVisaCheckoutErrorDomain);
        XCTAssertEqual(error.code, BTVisaCheckoutErrorTypeUnsupported);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testTokenization_whenAPIClientIsNil_callsBackWithError {
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    client.apiClient = nil;
    
    VisaPaymentSummary *visaPaymentSummary = [[VisaPaymentSummary alloc] init];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback invoked"];
    [client tokenizeVisaPaymentSummary:visaPaymentSummary completion:^(BTVisaCheckoutCardNonce * _Nullable tokenizedVisaCheckoutCard, NSError * _Nullable error) {
        XCTAssertNil(tokenizedVisaCheckoutCard);
        XCTAssertEqual(error.domain, BTVisaCheckoutErrorDomain);
        XCTAssertEqual(error.code, BTVisaCheckoutErrorTypeIntegration);

        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testTokenization_whenConfigurationFetchErrorOccurs_callsBackWithError {
    self.mockClient.cannedConfigurationResponseError = [[NSError alloc] initWithDomain:@"MyError" code:1 userInfo:nil];
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    VisaPaymentSummary *visaPaymentSummary = [[VisaPaymentSummary alloc] init];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"tokenization error"];
    [client tokenizeVisaPaymentSummary:visaPaymentSummary completion:^(BTVisaCheckoutCardNonce * _Nullable tokenizedVisaCheckoutCard, NSError * _Nullable error) {
        XCTAssertNil(tokenizedVisaCheckoutCard);
        XCTAssertEqual(error.domain, @"MyError");
        XCTAssertEqual(error.code, 1);
        
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void) testTokenization_whenTokenizationErrorOccurs_callsBackWithError {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"visaCheckout": @{}}];
    self.mockClient.cannedHTTPURLResponse = [[NSHTTPURLResponse alloc] initWithURL:[NSURL URLWithString:@"any"] statusCode:503 HTTPVersion:nil headerFields:nil];
    self.mockClient.cannedResponseError = [[NSError alloc]initWithDomain:@"foo" code:100 userInfo:nil];
    
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    VisaPaymentSummary *visaPaymentSummary = [self mockVisaPaymentSummary];
    XCTestExpectation *expectation = [self expectationWithDescription:@"tokenization failure"];
    
    [client tokenizeVisaPaymentSummary:visaPaymentSummary completion:^(BTVisaCheckoutCardNonce * _Nullable tokenizedVisaCheckoutCard, NSError * _Nullable error) {
        if (tokenizedVisaCheckoutCard) {
            XCTFail();
            return;
        }
        
        XCTAssertEqual(error, self.mockClient.cannedResponseError);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void) testTokenization_whenTokenizationFailureOccurs_callsBackWithError {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"visaCheckout": @{}}];
    self.mockClient.cannedConfigurationResponseError = [[NSError alloc] initWithDomain:@"MyError" code:1 userInfo:nil];

    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    VisaPaymentSummary *visaPaymentSummary = [self mockVisaPaymentSummary];
    XCTestExpectation *expectation = [self expectationWithDescription:@"tokenization failure"];

    [client tokenizeVisaPaymentSummary:visaPaymentSummary completion:^(BTVisaCheckoutCardNonce * _Nullable tokenizedVisaCheckoutCard, NSError * _Nullable error) {
        XCTAssertNil(tokenizedVisaCheckoutCard);
        XCTAssertEqual(error.domain, @"MyError");
        XCTAssertEqual(error.code, 1);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];

}

- (void) testTokenization_POSTsPaymentSummaryToTokenizationEndpoint {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"visaCheckout": @{}}];
    self.mockClient.cannedResponseBody = [[BTJSON alloc] initWithValue:@{
                                                                         @"visaCheckoutCards": @{
                                                                                 @"nonce" : @"a-visa-checkout-nonce",
                                                                                 @"description" : @"a description",
                                                                                 @"details" : @{
                                                                                               @"cardType" : @"Visa"
                                                                                               }}
                                                                         }];
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    VisaPaymentSummary *visaPaymentSummary = [self mockVisaPaymentSummary];
    [client tokenizeVisaPaymentSummary:visaPaymentSummary completion:^(__unused BTVisaCheckoutCardNonce * _Nullable tokenizedVisaCheckoutCard, __unused NSError * _Nullable error) {}];
    
    XCTAssertTrue([@"v1/payment_methods/visa_checkout_cards" isEqualToString:self.mockClient.lastPOSTPath]);
    if (!self.mockClient.lastPOSTParameters) {
        XCTFail();
        return;
    };
    
    XCTAssertEqual(self.mockClient.lastPOSTParameters[@"visaCheckoutCard"][@"callId"], @"callId");
    XCTAssertEqual(self.mockClient.lastPOSTParameters[@"visaCheckoutCard"][@"encryptedKey"], @"encKey");
    XCTAssertEqual(self.mockClient.lastPOSTParameters[@"visaCheckoutCard"][@"encryptedPaymentData"], @"encPaymentData");
}

- (void) testTokenization_whenTokenizationSucceeds_callsBackWithTokenizedPayment {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"visaCheckout": @{}}];
    self.mockClient.cannedResponseBody = [[BTJSON alloc] initWithValue:@{
                                                                         @"visaCheckoutCards": @[@{
                                                                                 @"nonce" : @"a-visa-checkout-nonce",
                                                                                 @"description" : @"a description",
                                                                                 @"details" : @{
                                                                                         @"cardType" : @"Visa"
                                                                                         },
                                                                                 @"shippingAddress" : @{
                                                                                         @"firstName": @"shippingAddressFirstName"
                                                                                         },
                                                                                 @"billingAddress" : @{
                                                                                         @"firstName": @"billingAddressFirstName"
                                                                                         },
                                                                                 @"userData" : @{
                                                                                         @"userEmail" : @"userDataEmail"
                                                                                         }}]
                                                                         }];
    
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    VisaPaymentSummary *visaPaymentSummary = [self mockVisaPaymentSummary];
    XCTestExpectation *expectation = [self expectationWithDescription:@"successful tokenization"];
    
    [client tokenizeVisaPaymentSummary:visaPaymentSummary completion:^(BTVisaCheckoutCardNonce * _Nullable tokenizedVisaCheckoutCard, NSError * _Nullable error) {
        XCTAssertNil(error);
        
        XCTAssertTrue([tokenizedVisaCheckoutCard.localizedDescription isEqualToString:@"a description"]);
        XCTAssertTrue([tokenizedVisaCheckoutCard.nonce isEqualToString:@"a-visa-checkout-nonce"]);
        XCTAssertTrue([tokenizedVisaCheckoutCard.type isEqualToString:@"Visa"]);
        XCTAssertTrue([tokenizedVisaCheckoutCard.shippingAddressFirstName isEqualToString:@"shippingAddressFirstName"]);
        XCTAssertTrue([tokenizedVisaCheckoutCard.billingAddressFirstName isEqualToString:@"billingAddressFirstName"]);
        XCTAssertTrue([tokenizedVisaCheckoutCard.userDataEmail isEqualToString:@"userDataEmail"]);

        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void) testMetaParameter_whenTokenizationIsSuccessful_isPOSTedToServer {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"visaCheckout": @{
                                                                                              @"status": @"production"
                                                                                              }}];
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    VisaPaymentSummary *visaPaymentSummary = [self mockVisaPaymentSummary];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Tokenized card"];
    [client tokenizeVisaPaymentSummary:visaPaymentSummary completion:^(__unused BTVisaCheckoutCardNonce * _Nullable tokenizedVisaCheckoutCard, __unused NSError * _Nullable error) {
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
    
    XCTAssertTrue([self.mockClient.lastPOSTParameters[@"_meta"][@"source"] isEqualToString:@"unknown"]);
    XCTAssertTrue([self.mockClient.lastPOSTParameters[@"_meta"][@"integration"] isEqualToString:@"custom"]);
    XCTAssertEqual(self.mockClient.lastPOSTParameters[@"_meta"][@"sessionId"], self.mockClient.metadata.sessionId);
}

- (void)testPopulatePaymentInfo_setsPropertiesFromConfiguration {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"visaCheckout": @{
                                                                                              @"supportedCardTypes": @[
                                                                                                      @"Visa",
                                                                                                      @"MasterCard",
                                                                                                      @"American Express",
                                                                                                      @"Discover",
                                                                                                      @"MysteryCard",
                                                                                                      @"Braintree Express"
                                                                                                      ],
                                                                                              @"apikey": @"apikey",
                                                                                              @"externalClientId": @"externalClientId"
                                                                                              }}];

    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    VisaPaymentInfo *paymentInfo = [[VisaPaymentInfo alloc] init];
    paymentInfo.merchantInfo = [[VisaMerchantInfo alloc] init];
    
    XCTAssertFalse([paymentInfo.merchantInfo.merchantAPIKey isEqualToString:@"apikey"]);
    XCTAssertFalse([paymentInfo.merchantInfo.externalClientId isEqualToString:@"externalClientId"]);
    XCTAssertFalse([paymentInfo.datalevel isEqualToString:@"FULL"]);
//    paymentInfo.acceptedPaymentTypesAndBrands = [configuration.visaCheckoutSupportedNetworks mutableCopy];
    
    NSMutableArray *expectedSupportedNetworks = [NSMutableArray arrayWithObjects:
                                                 @"Visa",
                                                 @"MasterCard",
                                                 @"AMEX",
                                                 @"Discover",
                                                 nil];
    XCTestExpectation *expectation = [self expectationWithDescription:@"Set properties on VisaPaymentInfo"];
    [client populatePaymentInfo:paymentInfo completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([paymentInfo.merchantInfo.merchantAPIKey isEqualToString:@"apikey"]);
        XCTAssertTrue([paymentInfo.merchantInfo.externalClientId isEqualToString:@"externalClientId"]);
        XCTAssertTrue([paymentInfo.datalevel isEqualToString:@"FULL"]);
        XCTAssertTrue([paymentInfo.acceptedPaymentTypesAndBrands isEqualToArray:expectedSupportedNetworks]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testPopulatePaymentInfo_whenNotAVisaPaymentInfo_throwsAnError {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"creditCards": @{
                                                             @"supportedCardTypes": @[
                                                                     @"Visa",
                                                                     @"MasterCard",
                                                                     @"American Express",
                                                                     @"Discover",
                                                                     @"MysteryCard",
                                                                     @"Braintree Express"
                                                                     ]
                                                             },@"visaCheckout": @{
                                                             @"apikey": @"apikey",
                                                             @"externalClientId": @"externalClientId"
                                                             }}];
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    XCTestExpectation *expectation = [self expectationWithDescription:@"populatePaymentInfo should fail"];
    
    [client populatePaymentInfo:@"" completion:^(NSError * _Nullable error) {
        XCTAssertTrue([@"A valid VisaPaymentInfo is required." isEqualToString:error.localizedDescription]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testPopulatePaymentInfo_whenVisaPaymentInfoDoesntHaveAVisaMerchantInfo_throwsAnError {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"creditCards": @{
                                                                                              @"supportedCardTypes": @[
                                                                                                      @"Visa",
                                                                                                      @"MasterCard",
                                                                                                      @"American Express",
                                                                                                      @"Discover",
                                                                                                      @"MysteryCard",
                                                                                                      @"Braintree Express"
                                                                                                      ]
                                                                                              },@"visaCheckout": @{
                                                                                              @"apikey": @"apikey",
                                                                                              @"externalClientId": @"externalClientId"
                                                                                              }}];
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    XCTestExpectation *expectation = [self expectationWithDescription:@"populatePaymentInfo should fail"];
    VisaPaymentInfo *paymentInfo = [[VisaPaymentInfo alloc] init];
    
    [client populatePaymentInfo:paymentInfo completion:^(NSError * _Nullable error) {
        XCTAssertTrue([@"A valid VisaMerchantInfo is required to be set on the VisaPaymentInfo" isEqualToString:error.localizedDescription]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testPopulatePaymentInfo_whenDataLevelIsSet_overwitesToFull {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"creditCards": @{
                                                                                              @"supportedCardTypes": @[
                                                                                                      @"Visa",
                                                                                                      @"MasterCard",
                                                                                                      @"American Express",
                                                                                                      @"Discover",
                                                                                                      @"MysteryCard",
                                                                                                      @"Braintree Express"
                                                                                                      ]
                                                                                              },@"visaCheckout": @{
                                                                                              @"apikey": @"apikey",
                                                                                              @"externalClientId": @"externalClientId"
                                                                                              }}];
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    XCTestExpectation *expectation = [self expectationWithDescription:@"populatePaymentInfo should fail"];
    VisaPaymentInfo *paymentInfo = [[VisaPaymentInfo alloc] init];
    paymentInfo.merchantInfo = [[VisaMerchantInfo alloc] init];
    paymentInfo.datalevel = @"SUMMARY";

    [client populatePaymentInfo:paymentInfo completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([@"FULL" isEqualToString:paymentInfo.datalevel]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testPopulatePaymentInfo_whenApiKeyIsSet_doesNotOverwite {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"creditCards": @{
                                                                                              @"supportedCardTypes": @[
                                                                                                      @"Visa",
                                                                                                      @"MasterCard",
                                                                                                      @"American Express",
                                                                                                      @"Discover",
                                                                                                      @"MysteryCard",
                                                                                                      @"Braintree Express"
                                                                                                      ]
                                                                                              },@"visaCheckout": @{
                                                                                              @"apikey": @"apikey",
                                                                                              @"externalClientId": @"externalClientId"
                                                                                              }}];
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    XCTestExpectation *expectation = [self expectationWithDescription:@"populatePaymentInfo should fail"];
    VisaPaymentInfo *paymentInfo = [[VisaPaymentInfo alloc] init];
    paymentInfo.merchantInfo = [[VisaMerchantInfo alloc] init];
    paymentInfo.merchantInfo.merchantAPIKey = @"merchantSetApiKey";
    
    [client populatePaymentInfo:paymentInfo completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([@"merchantSetApiKey" isEqualToString:paymentInfo.merchantInfo.merchantAPIKey]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testPopulatePaymentInfo_whenExternalClientIdIsSet_doesNotOverwite {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"creditCards": @{
                                                                                              @"supportedCardTypes": @[
                                                                                                      @"Visa",
                                                                                                      @"MasterCard",
                                                                                                      @"American Express",
                                                                                                      @"Discover",
                                                                                                      @"MysteryCard",
                                                                                                      @"Braintree Express"
                                                                                                      ]
                                                                                              },@"visaCheckout": @{
                                                                                              @"apikey": @"apikey",
                                                                                              @"externalClientId": @"externalClientId"
                                                                                              }}];
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    XCTestExpectation *expectation = [self expectationWithDescription:@"populatePaymentInfo should fail"];
    VisaPaymentInfo *paymentInfo = [[VisaPaymentInfo alloc] init];
    paymentInfo.merchantInfo = [[VisaMerchantInfo alloc] init];
    paymentInfo.merchantInfo.externalClientId = @"merchantSetExternalClientId";
    
    [client populatePaymentInfo:paymentInfo completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([@"merchantSetExternalClientId" isEqualToString:paymentInfo.merchantInfo.externalClientId]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testPopulatePaymentInfo_whenSupportedNetworksIsSet_overwiteWithBraintreeSupportedCardTypes {
    self.mockClient.cannedConfigurationResponseBody = [[BTJSON alloc] initWithValue:@{@"visaCheckout": @{
                                                                                              @"supportedCardTypes": @[
                                                                                                      @"Visa",
                                                                                                      @"Braintree Express"
                                                                                                      ],
                                                                                              @"apikey": @"apikey",
                                                                                              @"externalClientId": @"externalClientId"
                                                                                              }}];
    BTVisaCheckoutClient *client = [[BTVisaCheckoutClient alloc] initWithAPIClient:self.mockClient];
    XCTestExpectation *expectation = [self expectationWithDescription:@"populatePaymentInfo should fail"];
    VisaPaymentInfo *paymentInfo = [[VisaPaymentInfo alloc] init];
    paymentInfo.merchantInfo = [[VisaMerchantInfo alloc] init];
    NSMutableArray *expectedNetworks = [NSMutableArray arrayWithObjects:@"Visa", nil];
    paymentInfo.acceptedPaymentTypesAndBrands = [NSMutableArray arrayWithObjects:
                                                 @"Some",
                                                 @"Networks",
                                                 nil];
    [client populatePaymentInfo:paymentInfo completion:^(NSError * _Nullable error) {
        XCTAssertNil(error);
        XCTAssertTrue([expectedNetworks isEqualToArray:paymentInfo.acceptedPaymentTypesAndBrands]);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:2 handler:nil];
}
- (VisaPaymentSummary *) mockVisaPaymentSummary {
    VisaPaymentSummary *visaPaymentSummary = [[VisaPaymentSummary alloc] init];
    visaPaymentSummary.callId = @"callId";
    visaPaymentSummary.encKey = @"encKey";
    visaPaymentSummary.encPaymentData = @"encPaymentData";
    return visaPaymentSummary;
}

@end
