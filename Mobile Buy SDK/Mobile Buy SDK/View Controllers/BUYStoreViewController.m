//
//  BUYStoreController.m
//  Mobile Buy SDK
//
//  Created by Joshua Tessier on 2015-02-10.
//  Copyright (c) 2015 Shopify Inc. All rights reserved.
//

@import WebKit;
#import "BUYLineItem.h"
#import "BUYProduct.h"
#import "BUYProductVariant.h"
#import "BUYStoreViewController.h"

@interface BUYStoreViewController () <WKNavigationDelegate, WKScriptMessageHandler>
@end

@implementation BUYStoreViewController {
	NSURL *_url;
	WKWebView *_webView;
	
	UIBarButtonItem *_backButton;
	UIBarButtonItem *_forwardButton;
	
	BOOL _skippingAppCheckout;
	
	NSURLRequest *_checkoutRequest;
}

@dynamic delegate;

- (instancetype)initWithClient:(BUYClient *)client url:(NSURL *)url
{
	self = [super initWithClient:client];
	
	if (self) {
		_url = url;
	}
	
	return self;
}

- (instancetype)initWithClient:(BUYClient *)client
{
	self = [super initWithClient:client];
	
	if (self) {
		_url = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", client.shopDomain]];
	}
	
	return self;
}

- (void)loadView
{
	WKWebViewConfiguration *configuration = [self webViewConfiguration];
	_webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
	_webView.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
	_webView.navigationDelegate = self;
	self.view = _webView;
	
	_backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"back"] style:UIBarButtonItemStylePlain target:_webView action:@selector(goBack)];
	_forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"forward"] style:UIBarButtonItemStylePlain target:_webView action:@selector(goForward)];
	UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareTapped)];

	UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	self.toolbarItems = @[_backButton, flexible, _forwardButton, flexible, shareButton, flexible, flexible, flexible];
}

- (void)viewDidLoad
{
	[super viewDidLoad];
	
	[_webView loadRequest:[NSURLRequest requestWithURL:_url]];
	[self updateButtons];
}

#pragma mark - Button Presses

- (void)updateButtons
{
	_backButton.enabled = [_webView canGoBack];
	_forwardButton.enabled = [_webView canGoForward];
}

- (void)shareTapped
{
	UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[_webView.URL] applicationActivities:nil];
	activityViewController.excludedActivityTypes = @[UIActivityTypeAddToReadingList, UIActivityTypeAssignToContact, UIActivityTypePrint, UIActivityTypeSaveToCameraRoll];
	[self presentViewController:activityViewController animated:YES completion:nil];
}

#pragma mark - Web View Navigation Delegate Methods

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
	NSString *currentUrlString = [[[navigationAction request] URL] absoluteString];
	
	BOOL checkoutLink = [currentUrlString containsString:@"/checkout"] || [currentUrlString containsString:@"/sessions"];
	BOOL thankYouPage = [currentUrlString containsString:@"thank_you"];
	
	if (checkoutLink && thankYouPage == NO) {
		if (_skippingAppCheckout) {
			decisionHandler(WKNavigationActionPolicyAllow);
		}
		else {
			decisionHandler(WKNavigationActionPolicyCancel);
			
			[self presentCheckoutMethodSelectionMenuWithCheckoutRequest:[navigationAction request]];
		}
	}
	else {
		_skippingAppCheckout = NO;
		decisionHandler(WKNavigationActionPolicyAllow);
	}
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
	[self updateButtons];
}

- (void)reloadHomePage
{
	[_webView loadRequest:[NSURLRequest requestWithURL:_url]];
}

#pragma mark - Checkout Methods

- (void)presentCheckoutMethodSelectionMenuWithCheckoutRequest:(NSURLRequest *)request
{
	_checkoutRequest = request;
	
	if ([self.delegate respondsToSelector:@selector(controller:shouldProceedWithCheckoutType:)]) {
		
		[self.delegate controller:self shouldProceedWithCheckoutType:^(BUYCheckoutType type) {
			
			switch (type) {
				case BUYCheckoutTypeNormal:
					[self checkoutWithNormalCheckout];
					break;
					
				case BUYCheckoutTypeApplePay:
					[self checkoutWithApplePay];
					break;
					
				default:
					break;
			}
		}];
	}
	
	else {
		[self checkoutWithNormalCheckout];
	}
}

- (void)getProduct:(NSString *)productId withVariantId:(NSString *)variantId completion:(void (^)(BUYProductVariant *variant, NSError *error))completion;
{
	[self.client getProductById:productId completion:^(BUYProduct *product, NSError *error) {
		BUYProductVariant *selectedVariant = nil;
		
		if (error == nil) {
			for (BUYProductVariant *variant in product.variants) {
				if ([variant.identifier isEqual:@([variantId longLongValue])]) {
					selectedVariant = variant;
					break;
				}
			}
		}
		else {
			NSLog(@"Failed to fetch variant: %@", error);
		}
		
		completion(selectedVariant, error);
	}];
}

#pragma mark - Checkout Selection Delegate Methods

- (void)checkoutWithApplePay
{
	[_webView evaluateJavaScript:@"\
	 var cartRequest = new XMLHttpRequest();\
	 cartRequest.open(\"GET\", \"/cart.json\", false);\
	 cartRequest.onreadystatechange = function() {\
		if (cartRequest.readyState == 4 && cartRequest.status == 200) {\
			window.webkit.messageHandlers.nativeApp.postMessage(JSON.parse(cartRequest.responseText));\
		}\
	 };\
	 cartRequest.send(null);"
			   completionHandler:^(id response, NSError *error) {
		
	}];
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
	NSDictionary *json = message.body;
	NSString *cartToken = json[@"token"];
	
	if (cartToken) {
		[self startCheckoutWithCartToken:cartToken];
	}
	else {
		NSError *error = [NSError errorWithDomain:BUYShopifyError code:BUYShopifyError_CartFetchError userInfo:nil];
		[self.delegate controller:self failedToCreateCheckout:error];
	}
}

- (void)checkoutWithNormalCheckout
{
	_skippingAppCheckout = YES;
	[_webView loadRequest:_checkoutRequest];
}

#pragma mark - Checkout Completion Handling

- (void)checkoutCompleted:(BUYCheckout *)checkout status:(BUYStatus)status
{
	if (status == BUYStatusComplete) {
		[self.client getCheckout:checkout completion:^(BUYCheckout *updatedCheckout, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (updatedCheckout.orderStatusURL) {
					[_webView loadRequest:[NSURLRequest requestWithURL:updatedCheckout.orderStatusURL]];
				}
				else {
					NSLog(@"Couldn't redirect to thank you page: %@ (url: %@)", updatedCheckout, updatedCheckout.orderStatusURL);
				}
			});
		}];
	}
	else {
		NSError *error = [NSError errorWithDomain:BUYShopifyError code:status userInfo:@{@"checkout": checkout}];
		[self.delegate controller:self failedToCompleteCheckout:checkout withError:error];
	}
}

#pragma mark - Web View Configuration

- (WKWebViewConfiguration *)webViewConfiguration
{
	WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
	configuration.userContentController = [self userContentConfiguration];
	configuration.processPool = [self processPool];
	return configuration;
}

- (WKProcessPool *)processPool
{
	static WKProcessPool *pool = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		pool = [[WKProcessPool alloc] init];
	});
	return pool;
}

- (WKUserContentController *)userContentConfiguration
{
	//Register our native bridge
	WKUserContentController *contentController = [WKUserContentController new];
	[contentController addScriptMessageHandler:self name:@"nativeApp"];
	return contentController;
}

@end