//
//  CHKCheckout.h
//  Merchant
//
//  Created by Joshua Tessier on 2014-09-10.
//  Copyright (c) 2014 Shopify Inc. All rights reserved.
//

@import Foundation;

#import "MERObject.h"
#import "CHKSerializable.h"

@class CHKCreditCard;
@class CHKAddress;
@class CHKShippingRate;
@class CHKCart;

/**
 * The checkout object. This is the main object that you will interact with when creating orders on Shopify.
 * Your responsibility as a developer is to have the user fill out as much information as necessary on the Checkout.
 *
 * Do not create checkouts directly. You should use the CHKDataProvider to transform a CHKCart into a CHKCheckout.
 */
@interface CHKCheckout : MERObject <CHKSerializable>

- (instancetype)initWithCart:(CHKCart *)cark;

@property (nonatomic, copy) NSString *email;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy) NSNumber *orderId;
@property (nonatomic, strong) NSNumber *requiresShipping;
@property (nonatomic, strong) NSNumber *taxesIncluded;
@property (nonatomic, copy) NSString *currency;
@property (nonatomic, strong) NSDecimalNumber *subtotalPrice;
@property (nonatomic, strong) NSDecimalNumber *totalTax;
@property (nonatomic, strong) NSDecimalNumber *totalPrice;

@property (nonatomic, strong) NSString *paymentSessionId;
@property (nonatomic, strong) NSURL *paymentURL;
@property (nonatomic, strong) NSNumber *reservationTime;
@property (nonatomic, strong) NSNumber *reservationTimeLeft;

@property (nonatomic, readonly, copy) NSArray *lineItems;
@property (nonatomic, readonly, copy) NSArray *taxLines;

@property (nonatomic, strong) CHKAddress *billingAddress;
@property (nonatomic, strong) CHKAddress *shippingAddress;

@property (nonatomic, strong) CHKShippingRate *shippingRate;

@end

/**
 * CHKTaxLine represents a single tax line on a checkout. Use this to display an itemized list of taxes that they are being charged for.
 */
@interface CHKTaxLine : MERObject

@property (nonatomic, strong) NSDecimalNumber *price;
@property (nonatomic, strong) NSDecimalNumber *rate;
@property (nonatomic, copy) NSString *title;

@end

/**
 * A CHKAddress can represent either a shipping or billing address on an order. This will be associated with the customer upon completion.
 */
@interface CHKAddress : MERObject <CHKSerializable>

@property (nonatomic, copy) NSString *address1;
@property (nonatomic, copy) NSString *address2;
@property (nonatomic, copy) NSString *city;
@property (nonatomic, copy) NSString *company;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSString *phone;

@property (nonatomic, copy) NSString *country;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, copy) NSString *province;
@property (nonatomic, copy) NSString *provinceCode;
@property (nonatomic, copy) NSString *zip;

@end

/**
 * CHKShippingRate represents the amount that the merchant is charging the customer for shipping to the specified address.
 */
@interface CHKShippingRate : MERObject

@property (nonatomic, strong) NSDecimalNumber *price;
@property (nonatomic, copy) NSString *title;

@end