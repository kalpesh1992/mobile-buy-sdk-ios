//
//  MERDataProvider.h
//  Merchant
//
//  Created by Joshua Tessier on 2014-09-10.
//  Copyright (c) 2014 Shopify Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MERShop;
@class MERCollection;
@class MERProduct;
@class MERProductVariant;

typedef void (^MERDataShopBlock)(MERShop *shop, NSError *error);
typedef void (^MERDataCollectionListBlock)(NSArray *collections, NSUInteger page, BOOL reachedEnd, NSError *error);
typedef void (^MERDataProductListBlock)(NSArray *products, NSUInteger page, BOOL reachedEnd, NSError *error);
typedef void (^MERDataImagesListBlock)(NSArray *images, NSError *error);

@interface MERDataProvider : NSObject

- (instancetype)initWithShopDomain:(NSString*)shopDomain;

/**
 * The page size for any request. This can range from 1-250.
 */
@property (nonatomic, assign) NSUInteger pageSize;

/**
 * Fetches the shop's metadata (from /meta.json).
 */
- (NSURLSessionDataTask*)fetchShop:(MERDataShopBlock)block;

/**
 * Fetches a single page of collections for the shop by page number. Pages start at 1.
 */
- (NSURLSessionDataTask*)fetchCollectionsPage:(NSUInteger)page completion:(MERDataCollectionListBlock)block;

/**
 * Fetches a single page of products for the shop. Pages start at 1.
 */
- (NSURLSessionDataTask *)fetchProductsPage:(NSUInteger)page completion:(MERDataProductListBlock)block;

/**
 * Fetches a single page of products for the shop.
 */
- (NSURLSessionDataTask*)fetchProductsInCollection:(MERCollection*)collection page:(NSUInteger)page completion:(MERDataProductListBlock)block;

@end