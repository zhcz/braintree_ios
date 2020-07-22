#import <BraintreeCore/BraintreeCore.h>
#import <BraintreeCore/BTAPIClient_Internal.h>
#import "IntegrationTests-Swift.h"
#import <XCTest/XCTest.h>

@interface BTAPIClient_IntegrationTests : XCTestCase
@end

@implementation BTAPIClient_IntegrationTests

- (void)testFetchConfiguration_withTokenizationKey_returnsTheConfiguration {
    BTAPIClient *client = [[BTAPIClient alloc] initWithAuthorization:SANDBOX_TOKENIZATION_KEY];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetch configuration"];
    [client fetchOrReturnRemoteConfiguration:^(BTConfiguration *configuration, NSError *error) {
        XCTAssertEqualObjects([configuration.json[@"merchantId"] asString], @"dcpspy2brwdjr3qn");
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testFetchConfiguration_withClientToken_returnsTheConfiguration {
    BTAPIClient *client = [[BTAPIClient alloc] initWithAuthorization:SANDBOX_CLIENT_TOKEN];

    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetch configuration"];
    [client fetchOrReturnRemoteConfiguration:^(BTConfiguration *configuration, NSError *error) {
        // Note: client token uses a different merchant ID than the merchant whose tokenization key
        // we use in the other test
        XCTAssertEqualObjects([configuration.json[@"merchantId"] asString], @"348pk9cgf3bgyw2b");
        XCTAssertNil(error);
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testFetchConfiguration_withVersionThreeClientToken_returnsTheConfiguration {
    BTAPIClient *client = [[BTAPIClient alloc] initWithAuthorization:SANDBOX_CLIENT_TOKEN_VERSION_3];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetch configuration"];
    [client fetchOrReturnRemoteConfiguration:^(BTConfiguration *configuration, NSError *error) {
        // Note: client token uses a different merchant ID than the merchant whose tokenization key
        // we use in the other test
        XCTAssertEqualObjects([configuration.json[@"merchantId"] asString], @"dcpspy2brwdjr3qn");
        XCTAssertNil(error);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:5 handler:nil];
}

- (void)testFetchConfiguration_withPayPalIDToken_returnsTheConfiguration {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Fetch ID Token from PPCP sample server; then fetch BT config"];

    // NOTE: - This test needs to fetch an active PayPal ID Token
    // Currently, the PP team cannot provide hard-coded PP ID Token test values
    [PPCPHelper.sharedInstance fetchPayPalIDTokenWithCompletion:^(NSString * _Nullable idToken, NSError * _Nullable error) {
        if (error) {
            XCTFail(@"Error fetching a ID Token from https://ppcp-sample-merchant-sand.herokuapp.com");
        }

        BTAPIClient *client = [[BTAPIClient alloc] initWithAuthorization:idToken];

        [client fetchOrReturnRemoteConfiguration:^(BTConfiguration *configuration, NSError *error) {
            XCTAssertEqualObjects([configuration.json[@"merchantId"] asString], @"cfxs3ghzwfk2rhqm");
            XCTAssertEqualObjects([configuration.json[@"environment"] asString], @"sandbox");
            XCTAssertEqualObjects([configuration.json[@"assetsUrl"] asString], @"https://assets.braintreegateway.com");
            XCTAssertNil(error);
            [expectation fulfill];
        }];
    }];

    [self waitForExpectationsWithTimeout:20 handler:nil];
}

@end
