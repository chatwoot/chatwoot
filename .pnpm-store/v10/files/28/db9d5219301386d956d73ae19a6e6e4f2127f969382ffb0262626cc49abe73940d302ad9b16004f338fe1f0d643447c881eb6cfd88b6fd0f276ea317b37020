import type { Color } from '@csstools/color-helpers';
import type { ComponentValue } from '@csstools/css-parser-algorithms';
import { ColorNotation } from './color-notation';
import { TokenDimension, TokenNumber, TokenPercentage } from '@csstools/css-tokenizer';
export type ColorData = {
    colorNotation: ColorNotation;
    channels: Color;
    alpha: number | ComponentValue;
    syntaxFlags: Set<SyntaxFlag>;
};
export declare enum SyntaxFlag {
    ColorKeyword = "color-keyword",
    HasAlpha = "has-alpha",
    HasDimensionValues = "has-dimension-values",
    HasNoneKeywords = "has-none-keywords",
    HasNumberValues = "has-number-values",
    HasPercentageAlpha = "has-percentage-alpha",
    HasPercentageValues = "has-percentage-values",
    HasVariableAlpha = "has-variable-alpha",
    Hex = "hex",
    LegacyHSL = "legacy-hsl",
    LegacyRGB = "legacy-rgb",
    NamedColor = "named-color",
    RelativeColorSyntax = "relative-color-syntax",
    ColorMix = "color-mix"
}
export declare function colorData_to_XYZ_D50(colorData: ColorData): ColorData;
export declare function colorDataTo(colorData: ColorData, toNotation: ColorNotation): ColorData;
export declare function convertPowerlessComponentsToMissingComponents(a: Color, colorNotation: ColorNotation): Color;
export declare function fillInMissingComponents(a: Color, b: Color): Color;
export declare function normalizeRelativeColorDataChannels(x: ColorData): Map<string, TokenNumber | TokenPercentage | TokenDimension>;
export declare function noneToZeroInRelativeColorDataChannels(x: Map<string, TokenNumber | TokenPercentage | TokenDimension>): Map<string, TokenNumber | TokenPercentage | TokenDimension>;
export declare function colorDataFitsRGB_Gamut(x: ColorData): boolean;
