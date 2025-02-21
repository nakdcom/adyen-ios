//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation

/// An issuer list payment method, such as Open Banking.
public struct IssuerListPaymentMethod: PaymentMethod {

    public let type: PaymentMethodType

    public let name: String
    
    public var merchantProvidedDisplayInformation: MerchantCustomDisplayInformation?
    
    /// The available issuers.
    public let issuers: [Issuer]
    
    // MARK: - Coding
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.type = try container.decode(PaymentMethodType.self, forKey: .type)
        self.name = try container.decode(String.self, forKey: .name)

        let detailsContainer = try? container.nestedUnkeyedContainer(forKey: .details)

        if var detailsContainer {
            var issuers = [Issuer]()

            while !detailsContainer.isAtEnd {
                let detailContainer = try detailsContainer.nestedContainer(keyedBy: CodingKeys.Details.self)
                let detailKey = try detailContainer.decode(String.self, forKey: .key)
                guard detailKey == CodingKeys.Details.issuerKey else {
                    continue
                }

                issuers = try detailContainer.decode([Issuer].self, forKey: .items)
            }

            self.issuers = issuers
        } else {
            self.issuers = try container.decode([Issuer].self, forKey: .issuers)
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(issuers, forKey: .issuers)
    }
    
    @_spi(AdyenInternal)
    public func buildComponent(using builder: PaymentComponentBuilder) -> PaymentComponent? {
        builder.build(paymentMethod: self)
    }
    
    private enum CodingKeys: String, CodingKey {
        case type
        case name
        case issuers
        
        case details
        
        enum Details: String, CodingKey {
            case key
            case items
            
            static var issuerKey: String { "issuer" }
        }
    }
    
}
