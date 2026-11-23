import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Zemen typography helpers with Ethiopic fallbacks applied via [TextStyle.copyWith].
class AppFonts {
  AppFonts._();

  static List<String> get ethiopicFallbacks => [
        GoogleFonts.notoSansEthiopic().fontFamily ?? 'Noto Sans Ethiopic',
        'Noto Sans Ethiopic',
        'Abyssinica SIL',
        'Nyala',
        'Ebrima',
        'sans-serif',
      ];

  static TextStyle _withFallback(TextStyle style, List<String>? fallback) =>
      style.copyWith(fontFamilyFallback: fallback ?? ethiopicFallbacks);

  static TextStyle outfit({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    List<String>? fontFamilyFallback,
  }) {
    return _withFallback(
      GoogleFonts.outfit(
        textStyle: textStyle,
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
      ),
      fontFamilyFallback,
    );
  }

  static TextStyle fraunces({
    TextStyle? textStyle,
    Color? color,
    Color? backgroundColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? wordSpacing,
    TextBaseline? textBaseline,
    double? height,
    Locale? locale,
    Paint? foreground,
    Paint? background,
    List<Shadow>? shadows,
    List<FontFeature>? fontFeatures,
    TextDecoration? decoration,
    Color? decorationColor,
    TextDecorationStyle? decorationStyle,
    double? decorationThickness,
    List<String>? fontFamilyFallback,
  }) {
    return _withFallback(
      GoogleFonts.fraunces(
        textStyle: textStyle,
        color: color,
        backgroundColor: backgroundColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
        wordSpacing: wordSpacing,
        textBaseline: textBaseline,
        height: height,
        locale: locale,
        foreground: foreground,
        background: background,
        shadows: shadows,
        fontFeatures: fontFeatures,
        decoration: decoration,
        decorationColor: decorationColor,
        decorationStyle: decorationStyle,
        decorationThickness: decorationThickness,
      ),
      fontFamilyFallback,
    );
  }

  static TextStyle ethiopic({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
    double? letterSpacing,
  }) {
    return _withFallback(
      GoogleFonts.notoSansEthiopic(
        textStyle: textStyle,
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
      ),
      ethiopicFallbacks,
    );
  }
}
