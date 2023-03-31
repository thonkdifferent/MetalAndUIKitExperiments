//
//  Utility.swift
//  UIKitMadness
//
//  Created by Bogdan Petru on 31.03.2023.
//

import Foundation
import simd
@propertyWrapper
struct Rounded {
    private(set) var value: Decimal = 0.0
    let rule: NSDecimalNumber.RoundingMode
    let scale: Int

    var wrappedValue: Decimal {
        get { value }
        set { value = roundedDecimal(value:newValue,scale: scale, mode: rule) }
    }

    private func roundedDecimal(value:Decimal, scale: Int = 0, mode: NSDecimalNumber.RoundingMode) -> Decimal {
        var result = Decimal()
        var valueToChange = value
        NSDecimalRound(&result, &valueToChange, scale, mode)
        return result
    }
}

struct Utility{
    static func switchSecondTerm(_ x: Float, _ vmax: Float) -> Int
    {
        let mainBody : Int = Int(ceil(cos(x*Float.pi/2)))
        print(mainBody)
        let correction: Int = Int(floor(x/2))
        print(correction)
        return mainBody+correction
    }
    static func normalize(_ x: Float, to vmax: Float) -> Float
    {
        let normalisedOnZeroTwoX : Float = x/(vmax/2)
        let switchTerm: Int = switchSecondTerm(normalisedOnZeroTwoX, vmax)
        let firstTerm: Float = Float(2-switchTerm)
        let distance: Float = firstTerm-normalisedOnZeroTwoX
        let resultPreTrim: Float = (firstTerm-distance-1)*Float(100.rounded(.toNearestOrEven))
        return resultPreTrim/100
    }
    func orthographicProjection(left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) -> matrix_float4x4 {
        let ral = right + left
        let rsl = right - left
        let tab = top + bottom
        let tsb = top - bottom
        let fan = far + near
        let fsn = far - near
        
        return matrix_float4x4(columns:(simd_float4(rsl / tsb, 0.0, 0.0, 0.0),
                                          simd_float4(0.0, 2.0 / tsb, 0.0, 0.0),
                                          simd_float4(0.0, 0.0, -2.0 / fsn, 0.0),
                                          simd_float4(-ral / rsl, -tab / tsb, -fan / fsn, 1.0)))
    }
}
