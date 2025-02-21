//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

@_spi(AdyenInternal) import Adyen
import Adyen3DS2
import Foundation

/// Handles the 3D Secure 2 fingerprint and challenge in one call using a `fingerprintSubmitter`.
internal final class ThreeDS2CompactActionHandler: AnyThreeDS2ActionHandler, ComponentWrapper {
    
    internal weak var presentationDelegate: Adyen.PresentationDelegate? {
        didSet {
            coreActionHandler.presentationDelegate = presentationDelegate
        }
    }

    internal var wrappedComponent: Component { coreActionHandler }

    internal let coreActionHandler: AnyThreeDS2CoreActionHandler
    
    /// `threeDSRequestorAppURL` for protocol version 2.2.0 OOB challenges
    internal var threeDSRequestorAppURL: URL? {
        get {
            coreActionHandler.threeDSRequestorAppURL
        }
        
        set {
            coreActionHandler.threeDSRequestorAppURL = newValue
        }
    }

    internal var transaction: AnyADYTransaction? {
        get {
            coreActionHandler.transaction
        }

        set {
            coreActionHandler.transaction = newValue
        }
    }
    
    /// Initializes the 3D Secure 2 action handler.
    ///
    /// - Parameter context: The context object for this component.
    /// - Parameter fingerprintSubmitter: The fingerprint submitter.
    /// - Parameter service: The 3DS2 Service.
    /// - Parameter appearanceConfiguration: The appearance configuration of the 3D Secure 2 challenge UI.
    /// - Parameter delegatedAuthenticationConfiguration: The delegated authentication configuration.
    internal init(
        context: AdyenContext,
        fingerprintSubmitter: AnyThreeDS2FingerprintSubmitter? = nil,
        service: AnyADYService = ADYServiceAdapter(),
        appearanceConfiguration: ADYAppearanceConfiguration = ADYAppearanceConfiguration(),
        coreActionHandler: AnyThreeDS2CoreActionHandler? = nil,
        delegatedAuthenticationConfiguration: ThreeDS2Component.Configuration.DelegatedAuthentication? = nil
    ) {
        self.coreActionHandler = coreActionHandler ?? createDefaultThreeDS2CoreActionHandler(
            context: context,
            appearanceConfiguration: appearanceConfiguration,
            delegatedAuthenticationConfiguration: delegatedAuthenticationConfiguration
        )
        self.fingerprintSubmitter = fingerprintSubmitter ?? ThreeDS2FingerprintSubmitter(apiContext: context.apiContext)
        self.coreActionHandler.service = service
    }

    // MARK: - Fingerprint

    /// Handles the 3D Secure 2 fingerprint action using full flow.
    ///
    /// - Parameter fingerprintAction: The fingerprint action as received from the Checkout API.
    /// - Parameter completionHandler: The completion closure.
    internal func handle(
        _ fingerprintAction: ThreeDS2FingerprintAction,
        completionHandler: @escaping (Result<ThreeDSActionHandlerResult, Error>) -> Void
    ) {
        let event = Analytics.Event(
            component: "\(threeDS2EventName).fingerprint",
            flavor: _isDropIn ? .dropin : .components,
            environment: context.apiContext.environment
        )
        coreActionHandler.handle(fingerprintAction, event: event) { [weak self] result in
            switch result {
            case let .success(encodedFingerprint):
                self?.fingerprintSubmitter.submit(
                    fingerprint: encodedFingerprint,
                    paymentData: fingerprintAction.paymentData,
                    completionHandler: completionHandler
                )
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }

    // MARK: - Challenge

    /// Handles the 3D Secure 2 challenge action.
    ///
    /// - Parameter challengeAction: The challenge action as received from the Checkout API.
    /// - Parameter completionHandler: The completion closure.
    internal func handle(
        _ challengeAction: ThreeDS2ChallengeAction,
        completionHandler: @escaping (Result<ThreeDSActionHandlerResult, Error>) -> Void
    ) {
        let event = Analytics.Event(
            component: "\(threeDS2EventName).challenge",
            flavor: _isDropIn ? .dropin : .components,
            environment: context.apiContext.environment
        )
        coreActionHandler.handle(challengeAction, event: event) { result in
            switch result {
            case let .success(result):
                let additionalDetails = ThreeDS2Details.completed(result)
                completionHandler(.success(.details(additionalDetails)))
            case let .failure(error):
                completionHandler(.failure(error))
            }
        }
    }

    // MARK: - Private

    private let fingerprintSubmitter: AnyThreeDS2FingerprintSubmitter

    private let threeDS2EventName = "3ds2"

}
