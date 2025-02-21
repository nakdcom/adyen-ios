//
// Copyright (c) 2024 Adyen N.V.
//
// This file is open source and available under the MIT license. See the LICENSE file for more info.
//

import Foundation
import UIKit

/// Simple form item that represent a single UILabel element.
@_spi(AdyenInternal)
public class FormLabelItem: FormItem {
    
    public var isHidden: AdyenObservable<Bool> = AdyenObservable(false)
    
    public var subitems: [FormItem] = []

    public init(text: String, style: TextStyle, identifier: String? = nil) {
        self.identifier = identifier
        self.style = style
        self.text = text
    }

    public var identifier: String?

    /// The style of the label.
    public var style: TextStyle

    /// The text of the label.
    public var text: String

    public func build(with builder: FormItemViewBuilder) -> AnyFormItemView {
        let label = ADYLabel()
        label.text = text
        label.numberOfLines = 0
        label.accessibilityIdentifier = identifier
        label.font = style.font
        label.textColor = style.color
        label.textAlignment = style.textAlignment
        label.backgroundColor = style.backgroundColor
        label.adyen.round(using: style.cornerRounding)
        return label
    }
}

internal class ADYLabel: UILabel, AnyFormItemView {

    public var childItemViews: [AnyFormItemView] { [] }
    
    public func reset() { /* Do nothing */ }
    
}
