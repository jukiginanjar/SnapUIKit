//
//  VTClient.m
//  iossdk-gojek
//
//  Created by Akbar Taufiq Herlangga on 3/8/16.
//  Copyright © 2016 Veritrans. All rights reserved.
//

#import "MidtransClient.h"
#import "MidtransConfig.h"
#import "MidtransNetworking.h"
#import "MidtransTrackingManager.h"
#import "MidtransHelper.h"
#import "MidtransPrivateConfig.h"
#import "MidtransCreditCardHelper.h"
#import "Midtrans3DSController.h"
#import "MidtransConstant.h"
#import "MidtransBinResponse.h"
NSString *const GENERATE_TOKEN_URL = @"token";
NSString *const REGISTER_CARD_URL = @"card/register";

@interface MidtransClient ()

@end

@implementation MidtransClient

+ (MidtransClient *)shared {
    static MidtransClient *instance = nil;
    @synchronized(self) {
        if (instance == nil) {
            instance = [[self alloc] init];
        }
    }
    return instance;
}

+ (BOOL)isCard:(MidtransCreditCard *)card eligibleForBins:(NSArray *)bins error:(NSError **)error {
    for (NSString *whiteListedBin in bins) {
        if ([card.number containsString:whiteListedBin]) {
            return YES;
        }
    }
    
    NSDictionary *userInfo = @{NSLocalizedDescriptionKey:NSLocalizedString(@"Your card number is not eligible for promo", nil)};
    *error = [NSError errorWithDomain:MIDTRANS_ERROR_DOMAIN
                                 code:MIDTRANS_ERROR_CODE_INVALID_BIN
                             userInfo:userInfo];
    return NO;
}
- (void)requestCardBINForInstallmentWithCompletion:(void (^_Nullable)(NSArray *_Nullable binResponse, NSError *_Nullable error))completion {
    NSURLSession *session = [NSURLSession sharedSession];
    NSURL *url = [NSURL URLWithString:[PRIVATECONFIG binURL]];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                if (error){
                                                    if(completion) {
                                                        completion(nil,error);
                                                    }
                                                }
                                                else {
                                                    NSArray *json  = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                                                    NSMutableArray *contentData = [NSMutableArray new];
                                                    for (NSDictionary *response in json) {
                                                        MidtransBinResponse *binResponseObject = [[MidtransBinResponse alloc] initWithDictionary:response];
                                                        [contentData addObject:[binResponseObject dictionaryRepresentation]];
                                                    }
                                                    
                                                    if(completion) {
                                                        completion(contentData,nil);
                                                    }
                                                    
                                                }
                                            }];
    [dataTask resume];

}
- (void)generateToken:(MidtransTokenizeRequest *_Nonnull)tokenizeRequest
           completion:(void (^_Nullable)(NSString *_Nullable token, NSError *_Nullable error))completion {
    NSString *URL = [NSString stringWithFormat:@"%@/%@", [PRIVATECONFIG baseUrl], GENERATE_TOKEN_URL];
    
    [[MidtransNetworking shared] getFromURL:URL parameters:[tokenizeRequest dictionaryValue] callback:^(id response, NSError *error) {
        if (error) {
            [[MidtransTrackingManager shared] trackAppFailGenerateToken:nil
                                                         secureProtocol:NO
                                                     withPaymentFeature:0 paymentMethod:@"credit card" value:nil];
            if (completion) completion(nil, error);
        } else {
            NSString *redirectURL = response[@"redirect_url"];
            NSString *token = response[@"token_id"];
            if (redirectURL) {
                [[MidtransTrackingManager shared] trackAppSuccessGenerateToken:token
                                                                secureProtocol:YES
                                                            withPaymentFeature:0
                                                                 paymentMethod:@"credit card" value:nil];
                Midtrans3DSController *secureController = [[Midtrans3DSController alloc] initWithToken:token
                                                                                             secureURL:[NSURL URLWithString:redirectURL]];
                [secureController showWithCompletion:^(NSError *error) {
                    if (error) {
                        if (completion) completion(nil, error);
                    } else {
                        if (completion) completion(token, error);
                    }
                }];
            } else {
                [[MidtransTrackingManager shared] trackAppSuccessGenerateToken:token
                                                                secureProtocol:NO
                                                            withPaymentFeature:0 paymentMethod:@"credit card" value:nil];
                if (completion) completion(token, nil);
            }
        }
    }];
}

- (void)registerCreditCard:(MidtransCreditCard *_Nonnull)creditCard
                completion:(void (^_Nullable)(MidtransMaskedCreditCard *_Nullable maskedCreditCard, NSError *_Nullable error))completion {
    NSError *error = nil;
    if ([creditCard isValidCreditCard:&error] == NO) {
        if (completion) completion(nil, error);
        return;
    }
    NSString *URL = [NSString stringWithFormat:@"%@/%@", [PRIVATECONFIG baseUrl], REGISTER_CARD_URL];
    [[MidtransNetworking shared] getFromURL:URL parameters:[creditCard dictionaryValue] callback:^(id response, NSError *error) {
        if (response) {
            MidtransMaskedCreditCard *maskedCreditCard = [[MidtransMaskedCreditCard alloc] initWithData:response];
            if (completion) completion(maskedCreditCard, error);
        } else {
            if (completion) completion(nil, error);
        }
    }];
}

@end
