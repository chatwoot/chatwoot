// sass.hpp must go before all system headers to get the
// __EXTENSIONS__ fix on Solaris.
#include "sass.hpp"

#include "ast.hpp"
#include "color_maps.hpp"
#include "util_string.hpp"

namespace Sass {

  namespace ColorNames
  {
    const char aliceblue [] = "aliceblue";
    const char antiquewhite [] = "antiquewhite";
    const char cyan [] = "cyan";
    const char aqua [] = "aqua";
    const char aquamarine [] = "aquamarine";
    const char azure [] = "azure";
    const char beige [] = "beige";
    const char bisque [] = "bisque";
    const char black [] = "black";
    const char blanchedalmond [] = "blanchedalmond";
    const char blue [] = "blue";
    const char blueviolet [] = "blueviolet";
    const char brown [] = "brown";
    const char burlywood [] = "burlywood";
    const char cadetblue [] = "cadetblue";
    const char chartreuse [] = "chartreuse";
    const char chocolate [] = "chocolate";
    const char coral [] = "coral";
    const char cornflowerblue [] = "cornflowerblue";
    const char cornsilk [] = "cornsilk";
    const char crimson [] = "crimson";
    const char darkblue [] = "darkblue";
    const char darkcyan [] = "darkcyan";
    const char darkgoldenrod [] = "darkgoldenrod";
    const char darkgray [] = "darkgray";
    const char darkgrey [] = "darkgrey";
    const char darkgreen [] = "darkgreen";
    const char darkkhaki [] = "darkkhaki";
    const char darkmagenta [] = "darkmagenta";
    const char darkolivegreen [] = "darkolivegreen";
    const char darkorange [] = "darkorange";
    const char darkorchid [] = "darkorchid";
    const char darkred [] = "darkred";
    const char darksalmon [] = "darksalmon";
    const char darkseagreen [] = "darkseagreen";
    const char darkslateblue [] = "darkslateblue";
    const char darkslategray [] = "darkslategray";
    const char darkslategrey [] = "darkslategrey";
    const char darkturquoise [] = "darkturquoise";
    const char darkviolet [] = "darkviolet";
    const char deeppink [] = "deeppink";
    const char deepskyblue [] = "deepskyblue";
    const char dimgray [] = "dimgray";
    const char dimgrey [] = "dimgrey";
    const char dodgerblue [] = "dodgerblue";
    const char firebrick [] = "firebrick";
    const char floralwhite [] = "floralwhite";
    const char forestgreen [] = "forestgreen";
    const char magenta [] = "magenta";
    const char fuchsia [] = "fuchsia";
    const char gainsboro [] = "gainsboro";
    const char ghostwhite [] = "ghostwhite";
    const char gold [] = "gold";
    const char goldenrod [] = "goldenrod";
    const char gray [] = "gray";
    const char grey [] = "grey";
    const char green [] = "green";
    const char greenyellow [] = "greenyellow";
    const char honeydew [] = "honeydew";
    const char hotpink [] = "hotpink";
    const char indianred [] = "indianred";
    const char indigo [] = "indigo";
    const char ivory [] = "ivory";
    const char khaki [] = "khaki";
    const char lavender [] = "lavender";
    const char lavenderblush [] = "lavenderblush";
    const char lawngreen [] = "lawngreen";
    const char lemonchiffon [] = "lemonchiffon";
    const char lightblue [] = "lightblue";
    const char lightcoral [] = "lightcoral";
    const char lightcyan [] = "lightcyan";
    const char lightgoldenrodyellow [] = "lightgoldenrodyellow";
    const char lightgray [] = "lightgray";
    const char lightgrey [] = "lightgrey";
    const char lightgreen [] = "lightgreen";
    const char lightpink [] = "lightpink";
    const char lightsalmon [] = "lightsalmon";
    const char lightseagreen [] = "lightseagreen";
    const char lightskyblue [] = "lightskyblue";
    const char lightslategray [] = "lightslategray";
    const char lightslategrey [] = "lightslategrey";
    const char lightsteelblue [] = "lightsteelblue";
    const char lightyellow [] = "lightyellow";
    const char lime [] = "lime";
    const char limegreen [] = "limegreen";
    const char linen [] = "linen";
    const char maroon [] = "maroon";
    const char mediumaquamarine [] = "mediumaquamarine";
    const char mediumblue [] = "mediumblue";
    const char mediumorchid [] = "mediumorchid";
    const char mediumpurple [] = "mediumpurple";
    const char mediumseagreen [] = "mediumseagreen";
    const char mediumslateblue [] = "mediumslateblue";
    const char mediumspringgreen [] = "mediumspringgreen";
    const char mediumturquoise [] = "mediumturquoise";
    const char mediumvioletred [] = "mediumvioletred";
    const char midnightblue [] = "midnightblue";
    const char mintcream [] = "mintcream";
    const char mistyrose [] = "mistyrose";
    const char moccasin [] = "moccasin";
    const char navajowhite [] = "navajowhite";
    const char navy [] = "navy";
    const char oldlace [] = "oldlace";
    const char olive [] = "olive";
    const char olivedrab [] = "olivedrab";
    const char orange [] = "orange";
    const char orangered [] = "orangered";
    const char orchid [] = "orchid";
    const char palegoldenrod [] = "palegoldenrod";
    const char palegreen [] = "palegreen";
    const char paleturquoise [] = "paleturquoise";
    const char palevioletred [] = "palevioletred";
    const char papayawhip [] = "papayawhip";
    const char peachpuff [] = "peachpuff";
    const char peru [] = "peru";
    const char pink [] = "pink";
    const char plum [] = "plum";
    const char powderblue [] = "powderblue";
    const char purple [] = "purple";
    const char red [] = "red";
    const char rosybrown [] = "rosybrown";
    const char royalblue [] = "royalblue";
    const char saddlebrown [] = "saddlebrown";
    const char salmon [] = "salmon";
    const char sandybrown [] = "sandybrown";
    const char seagreen [] = "seagreen";
    const char seashell [] = "seashell";
    const char sienna [] = "sienna";
    const char silver [] = "silver";
    const char skyblue [] = "skyblue";
    const char slateblue [] = "slateblue";
    const char slategray [] = "slategray";
    const char slategrey [] = "slategrey";
    const char snow [] = "snow";
    const char springgreen [] = "springgreen";
    const char steelblue [] = "steelblue";
    const char tan [] = "tan";
    const char teal [] = "teal";
    const char thistle [] = "thistle";
    const char tomato [] = "tomato";
    const char turquoise [] = "turquoise";
    const char violet [] = "violet";
    const char wheat [] = "wheat";
    const char white [] = "white";
    const char whitesmoke [] = "whitesmoke";
    const char yellow [] = "yellow";
    const char yellowgreen [] = "yellowgreen";
    const char rebeccapurple [] = "rebeccapurple";
    const char transparent [] = "transparent";
  }

  namespace Colors {
    const SourceSpan color_table("[COLOR TABLE]");
    const Color_RGBA aliceblue(color_table, 240, 248, 255, 1);
    const Color_RGBA antiquewhite(color_table, 250, 235, 215, 1);
    const Color_RGBA cyan(color_table, 0, 255, 255, 1);
    const Color_RGBA aqua(color_table, 0, 255, 255, 1);
    const Color_RGBA aquamarine(color_table, 127, 255, 212, 1);
    const Color_RGBA azure(color_table, 240, 255, 255, 1);
    const Color_RGBA beige(color_table, 245, 245, 220, 1);
    const Color_RGBA bisque(color_table, 255, 228, 196, 1);
    const Color_RGBA black(color_table, 0, 0, 0, 1);
    const Color_RGBA blanchedalmond(color_table, 255, 235, 205, 1);
    const Color_RGBA blue(color_table, 0, 0, 255, 1);
    const Color_RGBA blueviolet(color_table, 138, 43, 226, 1);
    const Color_RGBA brown(color_table, 165, 42, 42, 1);
    const Color_RGBA burlywood(color_table, 222, 184, 135, 1);
    const Color_RGBA cadetblue(color_table, 95, 158, 160, 1);
    const Color_RGBA chartreuse(color_table, 127, 255, 0, 1);
    const Color_RGBA chocolate(color_table, 210, 105, 30, 1);
    const Color_RGBA coral(color_table, 255, 127, 80, 1);
    const Color_RGBA cornflowerblue(color_table, 100, 149, 237, 1);
    const Color_RGBA cornsilk(color_table, 255, 248, 220, 1);
    const Color_RGBA crimson(color_table, 220, 20, 60, 1);
    const Color_RGBA darkblue(color_table, 0, 0, 139, 1);
    const Color_RGBA darkcyan(color_table, 0, 139, 139, 1);
    const Color_RGBA darkgoldenrod(color_table, 184, 134, 11, 1);
    const Color_RGBA darkgray(color_table, 169, 169, 169, 1);
    const Color_RGBA darkgrey(color_table, 169, 169, 169, 1);
    const Color_RGBA darkgreen(color_table, 0, 100, 0, 1);
    const Color_RGBA darkkhaki(color_table, 189, 183, 107, 1);
    const Color_RGBA darkmagenta(color_table, 139, 0, 139, 1);
    const Color_RGBA darkolivegreen(color_table, 85, 107, 47, 1);
    const Color_RGBA darkorange(color_table, 255, 140, 0, 1);
    const Color_RGBA darkorchid(color_table, 153, 50, 204, 1);
    const Color_RGBA darkred(color_table, 139, 0, 0, 1);
    const Color_RGBA darksalmon(color_table, 233, 150, 122, 1);
    const Color_RGBA darkseagreen(color_table, 143, 188, 143, 1);
    const Color_RGBA darkslateblue(color_table, 72, 61, 139, 1);
    const Color_RGBA darkslategray(color_table, 47, 79, 79, 1);
    const Color_RGBA darkslategrey(color_table, 47, 79, 79, 1);
    const Color_RGBA darkturquoise(color_table, 0, 206, 209, 1);
    const Color_RGBA darkviolet(color_table, 148, 0, 211, 1);
    const Color_RGBA deeppink(color_table, 255, 20, 147, 1);
    const Color_RGBA deepskyblue(color_table, 0, 191, 255, 1);
    const Color_RGBA dimgray(color_table, 105, 105, 105, 1);
    const Color_RGBA dimgrey(color_table, 105, 105, 105, 1);
    const Color_RGBA dodgerblue(color_table, 30, 144, 255, 1);
    const Color_RGBA firebrick(color_table, 178, 34, 34, 1);
    const Color_RGBA floralwhite(color_table, 255, 250, 240, 1);
    const Color_RGBA forestgreen(color_table, 34, 139, 34, 1);
    const Color_RGBA magenta(color_table, 255, 0, 255, 1);
    const Color_RGBA fuchsia(color_table, 255, 0, 255, 1);
    const Color_RGBA gainsboro(color_table, 220, 220, 220, 1);
    const Color_RGBA ghostwhite(color_table, 248, 248, 255, 1);
    const Color_RGBA gold(color_table, 255, 215, 0, 1);
    const Color_RGBA goldenrod(color_table, 218, 165, 32, 1);
    const Color_RGBA gray(color_table, 128, 128, 128, 1);
    const Color_RGBA grey(color_table, 128, 128, 128, 1);
    const Color_RGBA green(color_table, 0, 128, 0, 1);
    const Color_RGBA greenyellow(color_table, 173, 255, 47, 1);
    const Color_RGBA honeydew(color_table, 240, 255, 240, 1);
    const Color_RGBA hotpink(color_table, 255, 105, 180, 1);
    const Color_RGBA indianred(color_table, 205, 92, 92, 1);
    const Color_RGBA indigo(color_table, 75, 0, 130, 1);
    const Color_RGBA ivory(color_table, 255, 255, 240, 1);
    const Color_RGBA khaki(color_table, 240, 230, 140, 1);
    const Color_RGBA lavender(color_table, 230, 230, 250, 1);
    const Color_RGBA lavenderblush(color_table, 255, 240, 245, 1);
    const Color_RGBA lawngreen(color_table, 124, 252, 0, 1);
    const Color_RGBA lemonchiffon(color_table, 255, 250, 205, 1);
    const Color_RGBA lightblue(color_table, 173, 216, 230, 1);
    const Color_RGBA lightcoral(color_table, 240, 128, 128, 1);
    const Color_RGBA lightcyan(color_table, 224, 255, 255, 1);
    const Color_RGBA lightgoldenrodyellow(color_table, 250, 250, 210, 1);
    const Color_RGBA lightgray(color_table, 211, 211, 211, 1);
    const Color_RGBA lightgrey(color_table, 211, 211, 211, 1);
    const Color_RGBA lightgreen(color_table, 144, 238, 144, 1);
    const Color_RGBA lightpink(color_table, 255, 182, 193, 1);
    const Color_RGBA lightsalmon(color_table, 255, 160, 122, 1);
    const Color_RGBA lightseagreen(color_table, 32, 178, 170, 1);
    const Color_RGBA lightskyblue(color_table, 135, 206, 250, 1);
    const Color_RGBA lightslategray(color_table, 119, 136, 153, 1);
    const Color_RGBA lightslategrey(color_table, 119, 136, 153, 1);
    const Color_RGBA lightsteelblue(color_table, 176, 196, 222, 1);
    const Color_RGBA lightyellow(color_table, 255, 255, 224, 1);
    const Color_RGBA lime(color_table, 0, 255, 0, 1);
    const Color_RGBA limegreen(color_table, 50, 205, 50, 1);
    const Color_RGBA linen(color_table, 250, 240, 230, 1);
    const Color_RGBA maroon(color_table, 128, 0, 0, 1);
    const Color_RGBA mediumaquamarine(color_table, 102, 205, 170, 1);
    const Color_RGBA mediumblue(color_table, 0, 0, 205, 1);
    const Color_RGBA mediumorchid(color_table, 186, 85, 211, 1);
    const Color_RGBA mediumpurple(color_table, 147, 112, 219, 1);
    const Color_RGBA mediumseagreen(color_table, 60, 179, 113, 1);
    const Color_RGBA mediumslateblue(color_table, 123, 104, 238, 1);
    const Color_RGBA mediumspringgreen(color_table, 0, 250, 154, 1);
    const Color_RGBA mediumturquoise(color_table, 72, 209, 204, 1);
    const Color_RGBA mediumvioletred(color_table, 199, 21, 133, 1);
    const Color_RGBA midnightblue(color_table, 25, 25, 112, 1);
    const Color_RGBA mintcream(color_table, 245, 255, 250, 1);
    const Color_RGBA mistyrose(color_table, 255, 228, 225, 1);
    const Color_RGBA moccasin(color_table, 255, 228, 181, 1);
    const Color_RGBA navajowhite(color_table, 255, 222, 173, 1);
    const Color_RGBA navy(color_table, 0, 0, 128, 1);
    const Color_RGBA oldlace(color_table, 253, 245, 230, 1);
    const Color_RGBA olive(color_table, 128, 128, 0, 1);
    const Color_RGBA olivedrab(color_table, 107, 142, 35, 1);
    const Color_RGBA orange(color_table, 255, 165, 0, 1);
    const Color_RGBA orangered(color_table, 255, 69, 0, 1);
    const Color_RGBA orchid(color_table, 218, 112, 214, 1);
    const Color_RGBA palegoldenrod(color_table, 238, 232, 170, 1);
    const Color_RGBA palegreen(color_table, 152, 251, 152, 1);
    const Color_RGBA paleturquoise(color_table, 175, 238, 238, 1);
    const Color_RGBA palevioletred(color_table, 219, 112, 147, 1);
    const Color_RGBA papayawhip(color_table, 255, 239, 213, 1);
    const Color_RGBA peachpuff(color_table, 255, 218, 185, 1);
    const Color_RGBA peru(color_table, 205, 133, 63, 1);
    const Color_RGBA pink(color_table, 255, 192, 203, 1);
    const Color_RGBA plum(color_table, 221, 160, 221, 1);
    const Color_RGBA powderblue(color_table, 176, 224, 230, 1);
    const Color_RGBA purple(color_table, 128, 0, 128, 1);
    const Color_RGBA red(color_table, 255, 0, 0, 1);
    const Color_RGBA rosybrown(color_table, 188, 143, 143, 1);
    const Color_RGBA royalblue(color_table, 65, 105, 225, 1);
    const Color_RGBA saddlebrown(color_table, 139, 69, 19, 1);
    const Color_RGBA salmon(color_table, 250, 128, 114, 1);
    const Color_RGBA sandybrown(color_table, 244, 164, 96, 1);
    const Color_RGBA seagreen(color_table, 46, 139, 87, 1);
    const Color_RGBA seashell(color_table, 255, 245, 238, 1);
    const Color_RGBA sienna(color_table, 160, 82, 45, 1);
    const Color_RGBA silver(color_table, 192, 192, 192, 1);
    const Color_RGBA skyblue(color_table, 135, 206, 235, 1);
    const Color_RGBA slateblue(color_table, 106, 90, 205, 1);
    const Color_RGBA slategray(color_table, 112, 128, 144, 1);
    const Color_RGBA slategrey(color_table, 112, 128, 144, 1);
    const Color_RGBA snow(color_table, 255, 250, 250, 1);
    const Color_RGBA springgreen(color_table, 0, 255, 127, 1);
    const Color_RGBA steelblue(color_table, 70, 130, 180, 1);
    const Color_RGBA tan(color_table, 210, 180, 140, 1);
    const Color_RGBA teal(color_table, 0, 128, 128, 1);
    const Color_RGBA thistle(color_table, 216, 191, 216, 1);
    const Color_RGBA tomato(color_table, 255, 99, 71, 1);
    const Color_RGBA turquoise(color_table, 64, 224, 208, 1);
    const Color_RGBA violet(color_table, 238, 130, 238, 1);
    const Color_RGBA wheat(color_table, 245, 222, 179, 1);
    const Color_RGBA white(color_table, 255, 255, 255, 1);
    const Color_RGBA whitesmoke(color_table, 245, 245, 245, 1);
    const Color_RGBA yellow(color_table, 255, 255, 0, 1);
    const Color_RGBA yellowgreen(color_table, 154, 205, 50, 1);
    const Color_RGBA rebeccapurple(color_table, 102, 51, 153, 1);
    const Color_RGBA transparent(color_table, 0, 0, 0, 0);
  }

  static const auto* const colors_to_names = new std::unordered_map<int, const char*> {
    { 240 * 0x10000 + 248 * 0x100 + 255, ColorNames::aliceblue },
    { 250 * 0x10000 + 235 * 0x100 + 215, ColorNames::antiquewhite },
    {   0 * 0x10000 + 255 * 0x100 + 255, ColorNames::cyan },
    { 127 * 0x10000 + 255 * 0x100 + 212, ColorNames::aquamarine },
    { 240 * 0x10000 + 255 * 0x100 + 255, ColorNames::azure },
    { 245 * 0x10000 + 245 * 0x100 + 220, ColorNames::beige },
    { 255 * 0x10000 + 228 * 0x100 + 196, ColorNames::bisque },
    {   0 * 0x10000 +   0 * 0x100 +   0, ColorNames::black },
    { 255 * 0x10000 + 235 * 0x100 + 205, ColorNames::blanchedalmond },
    {   0 * 0x10000 +   0 * 0x100 + 255, ColorNames::blue },
    { 138 * 0x10000 +  43 * 0x100 + 226, ColorNames::blueviolet },
    { 165 * 0x10000 +  42 * 0x100 +  42, ColorNames::brown },
    { 222 * 0x10000 + 184 * 0x100 + 135, ColorNames::burlywood },
    {  95 * 0x10000 + 158 * 0x100 + 160, ColorNames::cadetblue },
    { 127 * 0x10000 + 255 * 0x100 +   0, ColorNames::chartreuse },
    { 210 * 0x10000 + 105 * 0x100 +  30, ColorNames::chocolate },
    { 255 * 0x10000 + 127 * 0x100 +  80, ColorNames::coral },
    { 100 * 0x10000 + 149 * 0x100 + 237, ColorNames::cornflowerblue },
    { 255 * 0x10000 + 248 * 0x100 + 220, ColorNames::cornsilk },
    { 220 * 0x10000 +  20 * 0x100 +  60, ColorNames::crimson },
    {   0 * 0x10000 +   0 * 0x100 + 139, ColorNames::darkblue },
    {   0 * 0x10000 + 139 * 0x100 + 139, ColorNames::darkcyan },
    { 184 * 0x10000 + 134 * 0x100 +  11, ColorNames::darkgoldenrod },
    { 169 * 0x10000 + 169 * 0x100 + 169, ColorNames::darkgray },
    {   0 * 0x10000 + 100 * 0x100 +   0, ColorNames::darkgreen },
    { 189 * 0x10000 + 183 * 0x100 + 107, ColorNames::darkkhaki },
    { 139 * 0x10000 +   0 * 0x100 + 139, ColorNames::darkmagenta },
    {  85 * 0x10000 + 107 * 0x100 +  47, ColorNames::darkolivegreen },
    { 255 * 0x10000 + 140 * 0x100 +   0, ColorNames::darkorange },
    { 153 * 0x10000 +  50 * 0x100 + 204, ColorNames::darkorchid },
    { 139 * 0x10000 +   0 * 0x100 +   0, ColorNames::darkred },
    { 233 * 0x10000 + 150 * 0x100 + 122, ColorNames::darksalmon },
    { 143 * 0x10000 + 188 * 0x100 + 143, ColorNames::darkseagreen },
    {  72 * 0x10000 +  61 * 0x100 + 139, ColorNames::darkslateblue },
    {  47 * 0x10000 +  79 * 0x100 +  79, ColorNames::darkslategray },
    {   0 * 0x10000 + 206 * 0x100 + 209, ColorNames::darkturquoise },
    { 148 * 0x10000 +   0 * 0x100 + 211, ColorNames::darkviolet },
    { 255 * 0x10000 +  20 * 0x100 + 147, ColorNames::deeppink },
    {   0 * 0x10000 + 191 * 0x100 + 255, ColorNames::deepskyblue },
    { 105 * 0x10000 + 105 * 0x100 + 105, ColorNames::dimgray },
    {  30 * 0x10000 + 144 * 0x100 + 255, ColorNames::dodgerblue },
    { 178 * 0x10000 +  34 * 0x100 +  34, ColorNames::firebrick },
    { 255 * 0x10000 + 250 * 0x100 + 240, ColorNames::floralwhite },
    {  34 * 0x10000 + 139 * 0x100 +  34, ColorNames::forestgreen },
    { 255 * 0x10000 +   0 * 0x100 + 255, ColorNames::magenta },
    { 220 * 0x10000 + 220 * 0x100 + 220, ColorNames::gainsboro },
    { 248 * 0x10000 + 248 * 0x100 + 255, ColorNames::ghostwhite },
    { 255 * 0x10000 + 215 * 0x100 +   0, ColorNames::gold },
    { 218 * 0x10000 + 165 * 0x100 +  32, ColorNames::goldenrod },
    { 128 * 0x10000 + 128 * 0x100 + 128, ColorNames::gray },
    {   0 * 0x10000 + 128 * 0x100 +   0, ColorNames::green },
    { 173 * 0x10000 + 255 * 0x100 +  47, ColorNames::greenyellow },
    { 240 * 0x10000 + 255 * 0x100 + 240, ColorNames::honeydew },
    { 255 * 0x10000 + 105 * 0x100 + 180, ColorNames::hotpink },
    { 205 * 0x10000 +  92 * 0x100 +  92, ColorNames::indianred },
    {  75 * 0x10000 +   0 * 0x100 + 130, ColorNames::indigo },
    { 255 * 0x10000 + 255 * 0x100 + 240, ColorNames::ivory },
    { 240 * 0x10000 + 230 * 0x100 + 140, ColorNames::khaki },
    { 230 * 0x10000 + 230 * 0x100 + 250, ColorNames::lavender },
    { 255 * 0x10000 + 240 * 0x100 + 245, ColorNames::lavenderblush },
    { 124 * 0x10000 + 252 * 0x100 +   0, ColorNames::lawngreen },
    { 255 * 0x10000 + 250 * 0x100 + 205, ColorNames::lemonchiffon },
    { 173 * 0x10000 + 216 * 0x100 + 230, ColorNames::lightblue },
    { 240 * 0x10000 + 128 * 0x100 + 128, ColorNames::lightcoral },
    { 224 * 0x10000 + 255 * 0x100 + 255, ColorNames::lightcyan },
    { 250 * 0x10000 + 250 * 0x100 + 210, ColorNames::lightgoldenrodyellow },
    { 211 * 0x10000 + 211 * 0x100 + 211, ColorNames::lightgray },
    { 144 * 0x10000 + 238 * 0x100 + 144, ColorNames::lightgreen },
    { 255 * 0x10000 + 182 * 0x100 + 193, ColorNames::lightpink },
    { 255 * 0x10000 + 160 * 0x100 + 122, ColorNames::lightsalmon },
    {  32 * 0x10000 + 178 * 0x100 + 170, ColorNames::lightseagreen },
    { 135 * 0x10000 + 206 * 0x100 + 250, ColorNames::lightskyblue },
    { 119 * 0x10000 + 136 * 0x100 + 153, ColorNames::lightslategray },
    { 176 * 0x10000 + 196 * 0x100 + 222, ColorNames::lightsteelblue },
    { 255 * 0x10000 + 255 * 0x100 + 224, ColorNames::lightyellow },
    {   0 * 0x10000 + 255 * 0x100 +   0, ColorNames::lime },
    {  50 * 0x10000 + 205 * 0x100 +  50, ColorNames::limegreen },
    { 250 * 0x10000 + 240 * 0x100 + 230, ColorNames::linen },
    { 128 * 0x10000 +   0 * 0x100 +   0, ColorNames::maroon },
    { 102 * 0x10000 + 205 * 0x100 + 170, ColorNames::mediumaquamarine },
    {   0 * 0x10000 +   0 * 0x100 + 205, ColorNames::mediumblue },
    { 186 * 0x10000 +  85 * 0x100 + 211, ColorNames::mediumorchid },
    { 147 * 0x10000 + 112 * 0x100 + 219, ColorNames::mediumpurple },
    {  60 * 0x10000 + 179 * 0x100 + 113, ColorNames::mediumseagreen },
    { 123 * 0x10000 + 104 * 0x100 + 238, ColorNames::mediumslateblue },
    {   0 * 0x10000 + 250 * 0x100 + 154, ColorNames::mediumspringgreen },
    {  72 * 0x10000 + 209 * 0x100 + 204, ColorNames::mediumturquoise },
    { 199 * 0x10000 +  21 * 0x100 + 133, ColorNames::mediumvioletred },
    {  25 * 0x10000 +  25 * 0x100 + 112, ColorNames::midnightblue },
    { 245 * 0x10000 + 255 * 0x100 + 250, ColorNames::mintcream },
    { 255 * 0x10000 + 228 * 0x100 + 225, ColorNames::mistyrose },
    { 255 * 0x10000 + 228 * 0x100 + 181, ColorNames::moccasin },
    { 255 * 0x10000 + 222 * 0x100 + 173, ColorNames::navajowhite },
    {   0 * 0x10000 +   0 * 0x100 + 128, ColorNames::navy },
    { 253 * 0x10000 + 245 * 0x100 + 230, ColorNames::oldlace },
    { 128 * 0x10000 + 128 * 0x100 +   0, ColorNames::olive },
    { 107 * 0x10000 + 142 * 0x100 +  35, ColorNames::olivedrab },
    { 255 * 0x10000 + 165 * 0x100 +   0, ColorNames::orange },
    { 255 * 0x10000 +  69 * 0x100 +   0, ColorNames::orangered },
    { 218 * 0x10000 + 112 * 0x100 + 214, ColorNames::orchid },
    { 238 * 0x10000 + 232 * 0x100 + 170, ColorNames::palegoldenrod },
    { 152 * 0x10000 + 251 * 0x100 + 152, ColorNames::palegreen },
    { 175 * 0x10000 + 238 * 0x100 + 238, ColorNames::paleturquoise },
    { 219 * 0x10000 + 112 * 0x100 + 147, ColorNames::palevioletred },
    { 255 * 0x10000 + 239 * 0x100 + 213, ColorNames::papayawhip },
    { 255 * 0x10000 + 218 * 0x100 + 185, ColorNames::peachpuff },
    { 205 * 0x10000 + 133 * 0x100 +  63, ColorNames::peru },
    { 255 * 0x10000 + 192 * 0x100 + 203, ColorNames::pink },
    { 221 * 0x10000 + 160 * 0x100 + 221, ColorNames::plum },
    { 176 * 0x10000 + 224 * 0x100 + 230, ColorNames::powderblue },
    { 128 * 0x10000 +   0 * 0x100 + 128, ColorNames::purple },
    { 255 * 0x10000 +   0 * 0x100 +   0, ColorNames::red },
    { 188 * 0x10000 + 143 * 0x100 + 143, ColorNames::rosybrown },
    {  65 * 0x10000 + 105 * 0x100 + 225, ColorNames::royalblue },
    { 139 * 0x10000 +  69 * 0x100 +  19, ColorNames::saddlebrown },
    { 250 * 0x10000 + 128 * 0x100 + 114, ColorNames::salmon },
    { 244 * 0x10000 + 164 * 0x100 +  96, ColorNames::sandybrown },
    {  46 * 0x10000 + 139 * 0x100 +  87, ColorNames::seagreen },
    { 255 * 0x10000 + 245 * 0x100 + 238, ColorNames::seashell },
    { 160 * 0x10000 +  82 * 0x100 +  45, ColorNames::sienna },
    { 192 * 0x10000 + 192 * 0x100 + 192, ColorNames::silver },
    { 135 * 0x10000 + 206 * 0x100 + 235, ColorNames::skyblue },
    { 106 * 0x10000 +  90 * 0x100 + 205, ColorNames::slateblue },
    { 112 * 0x10000 + 128 * 0x100 + 144, ColorNames::slategray },
    { 255 * 0x10000 + 250 * 0x100 + 250, ColorNames::snow },
    {   0 * 0x10000 + 255 * 0x100 + 127, ColorNames::springgreen },
    {  70 * 0x10000 + 130 * 0x100 + 180, ColorNames::steelblue },
    { 210 * 0x10000 + 180 * 0x100 + 140, ColorNames::tan },
    {   0 * 0x10000 + 128 * 0x100 + 128, ColorNames::teal },
    { 216 * 0x10000 + 191 * 0x100 + 216, ColorNames::thistle },
    { 255 * 0x10000 +  99 * 0x100 +  71, ColorNames::tomato },
    {  64 * 0x10000 + 224 * 0x100 + 208, ColorNames::turquoise },
    { 238 * 0x10000 + 130 * 0x100 + 238, ColorNames::violet },
    { 245 * 0x10000 + 222 * 0x100 + 179, ColorNames::wheat },
    { 255 * 0x10000 + 255 * 0x100 + 255, ColorNames::white },
    { 245 * 0x10000 + 245 * 0x100 + 245, ColorNames::whitesmoke },
    { 255 * 0x10000 + 255 * 0x100 +   0, ColorNames::yellow },
    { 154 * 0x10000 + 205 * 0x100 +  50, ColorNames::yellowgreen },
    { 102 * 0x10000 +  51 * 0x100 + 153, ColorNames::rebeccapurple }
  };

  static const auto *const names_to_colors = new std::unordered_map<sass::string, const Color_RGBA*>
  {
    { ColorNames::aliceblue, &Colors::aliceblue },
    { ColorNames::antiquewhite, &Colors::antiquewhite },
    { ColorNames::cyan, &Colors::cyan },
    { ColorNames::aqua, &Colors::aqua },
    { ColorNames::aquamarine, &Colors::aquamarine },
    { ColorNames::azure, &Colors::azure },
    { ColorNames::beige, &Colors::beige },
    { ColorNames::bisque, &Colors::bisque },
    { ColorNames::black, &Colors::black },
    { ColorNames::blanchedalmond, &Colors::blanchedalmond },
    { ColorNames::blue, &Colors::blue },
    { ColorNames::blueviolet, &Colors::blueviolet },
    { ColorNames::brown, &Colors::brown },
    { ColorNames::burlywood, &Colors::burlywood },
    { ColorNames::cadetblue, &Colors::cadetblue },
    { ColorNames::chartreuse, &Colors::chartreuse },
    { ColorNames::chocolate, &Colors::chocolate },
    { ColorNames::coral, &Colors::coral },
    { ColorNames::cornflowerblue, &Colors::cornflowerblue },
    { ColorNames::cornsilk, &Colors::cornsilk },
    { ColorNames::crimson, &Colors::crimson },
    { ColorNames::darkblue, &Colors::darkblue },
    { ColorNames::darkcyan, &Colors::darkcyan },
    { ColorNames::darkgoldenrod, &Colors::darkgoldenrod },
    { ColorNames::darkgray, &Colors::darkgray },
    { ColorNames::darkgrey, &Colors::darkgrey },
    { ColorNames::darkgreen, &Colors::darkgreen },
    { ColorNames::darkkhaki, &Colors::darkkhaki },
    { ColorNames::darkmagenta, &Colors::darkmagenta },
    { ColorNames::darkolivegreen, &Colors::darkolivegreen },
    { ColorNames::darkorange, &Colors::darkorange },
    { ColorNames::darkorchid, &Colors::darkorchid },
    { ColorNames::darkred, &Colors::darkred },
    { ColorNames::darksalmon, &Colors::darksalmon },
    { ColorNames::darkseagreen, &Colors::darkseagreen },
    { ColorNames::darkslateblue, &Colors::darkslateblue },
    { ColorNames::darkslategray, &Colors::darkslategray },
    { ColorNames::darkslategrey, &Colors::darkslategrey },
    { ColorNames::darkturquoise, &Colors::darkturquoise },
    { ColorNames::darkviolet, &Colors::darkviolet },
    { ColorNames::deeppink, &Colors::deeppink },
    { ColorNames::deepskyblue, &Colors::deepskyblue },
    { ColorNames::dimgray, &Colors::dimgray },
    { ColorNames::dimgrey, &Colors::dimgrey },
    { ColorNames::dodgerblue, &Colors::dodgerblue },
    { ColorNames::firebrick, &Colors::firebrick },
    { ColorNames::floralwhite, &Colors::floralwhite },
    { ColorNames::forestgreen, &Colors::forestgreen },
    { ColorNames::magenta, &Colors::magenta },
    { ColorNames::fuchsia, &Colors::fuchsia },
    { ColorNames::gainsboro, &Colors::gainsboro },
    { ColorNames::ghostwhite, &Colors::ghostwhite },
    { ColorNames::gold, &Colors::gold },
    { ColorNames::goldenrod, &Colors::goldenrod },
    { ColorNames::gray, &Colors::gray },
    { ColorNames::grey, &Colors::grey },
    { ColorNames::green, &Colors::green },
    { ColorNames::greenyellow, &Colors::greenyellow },
    { ColorNames::honeydew, &Colors::honeydew },
    { ColorNames::hotpink, &Colors::hotpink },
    { ColorNames::indianred, &Colors::indianred },
    { ColorNames::indigo, &Colors::indigo },
    { ColorNames::ivory, &Colors::ivory },
    { ColorNames::khaki, &Colors::khaki },
    { ColorNames::lavender, &Colors::lavender },
    { ColorNames::lavenderblush, &Colors::lavenderblush },
    { ColorNames::lawngreen, &Colors::lawngreen },
    { ColorNames::lemonchiffon, &Colors::lemonchiffon },
    { ColorNames::lightblue, &Colors::lightblue },
    { ColorNames::lightcoral, &Colors::lightcoral },
    { ColorNames::lightcyan, &Colors::lightcyan },
    { ColorNames::lightgoldenrodyellow, &Colors::lightgoldenrodyellow },
    { ColorNames::lightgray, &Colors::lightgray },
    { ColorNames::lightgrey, &Colors::lightgrey },
    { ColorNames::lightgreen, &Colors::lightgreen },
    { ColorNames::lightpink, &Colors::lightpink },
    { ColorNames::lightsalmon, &Colors::lightsalmon },
    { ColorNames::lightseagreen, &Colors::lightseagreen },
    { ColorNames::lightskyblue, &Colors::lightskyblue },
    { ColorNames::lightslategray, &Colors::lightslategray },
    { ColorNames::lightslategrey, &Colors::lightslategrey },
    { ColorNames::lightsteelblue, &Colors::lightsteelblue },
    { ColorNames::lightyellow, &Colors::lightyellow },
    { ColorNames::lime, &Colors::lime },
    { ColorNames::limegreen, &Colors::limegreen },
    { ColorNames::linen, &Colors::linen },
    { ColorNames::maroon, &Colors::maroon },
    { ColorNames::mediumaquamarine, &Colors::mediumaquamarine },
    { ColorNames::mediumblue, &Colors::mediumblue },
    { ColorNames::mediumorchid, &Colors::mediumorchid },
    { ColorNames::mediumpurple, &Colors::mediumpurple },
    { ColorNames::mediumseagreen, &Colors::mediumseagreen },
    { ColorNames::mediumslateblue, &Colors::mediumslateblue },
    { ColorNames::mediumspringgreen, &Colors::mediumspringgreen },
    { ColorNames::mediumturquoise, &Colors::mediumturquoise },
    { ColorNames::mediumvioletred, &Colors::mediumvioletred },
    { ColorNames::midnightblue, &Colors::midnightblue },
    { ColorNames::mintcream, &Colors::mintcream },
    { ColorNames::mistyrose, &Colors::mistyrose },
    { ColorNames::moccasin, &Colors::moccasin },
    { ColorNames::navajowhite, &Colors::navajowhite },
    { ColorNames::navy, &Colors::navy },
    { ColorNames::oldlace, &Colors::oldlace },
    { ColorNames::olive, &Colors::olive },
    { ColorNames::olivedrab, &Colors::olivedrab },
    { ColorNames::orange, &Colors::orange },
    { ColorNames::orangered, &Colors::orangered },
    { ColorNames::orchid, &Colors::orchid },
    { ColorNames::palegoldenrod, &Colors::palegoldenrod },
    { ColorNames::palegreen, &Colors::palegreen },
    { ColorNames::paleturquoise, &Colors::paleturquoise },
    { ColorNames::palevioletred, &Colors::palevioletred },
    { ColorNames::papayawhip, &Colors::papayawhip },
    { ColorNames::peachpuff, &Colors::peachpuff },
    { ColorNames::peru, &Colors::peru },
    { ColorNames::pink, &Colors::pink },
    { ColorNames::plum, &Colors::plum },
    { ColorNames::powderblue, &Colors::powderblue },
    { ColorNames::purple, &Colors::purple },
    { ColorNames::red, &Colors::red },
    { ColorNames::rosybrown, &Colors::rosybrown },
    { ColorNames::royalblue, &Colors::royalblue },
    { ColorNames::saddlebrown, &Colors::saddlebrown },
    { ColorNames::salmon, &Colors::salmon },
    { ColorNames::sandybrown, &Colors::sandybrown },
    { ColorNames::seagreen, &Colors::seagreen },
    { ColorNames::seashell, &Colors::seashell },
    { ColorNames::sienna, &Colors::sienna },
    { ColorNames::silver, &Colors::silver },
    { ColorNames::skyblue, &Colors::skyblue },
    { ColorNames::slateblue, &Colors::slateblue },
    { ColorNames::slategray, &Colors::slategray },
    { ColorNames::slategrey, &Colors::slategrey },
    { ColorNames::snow, &Colors::snow },
    { ColorNames::springgreen, &Colors::springgreen },
    { ColorNames::steelblue, &Colors::steelblue },
    { ColorNames::tan, &Colors::tan },
    { ColorNames::teal, &Colors::teal },
    { ColorNames::thistle, &Colors::thistle },
    { ColorNames::tomato, &Colors::tomato },
    { ColorNames::turquoise, &Colors::turquoise },
    { ColorNames::violet, &Colors::violet },
    { ColorNames::wheat, &Colors::wheat },
    { ColorNames::white, &Colors::white },
    { ColorNames::whitesmoke, &Colors::whitesmoke },
    { ColorNames::yellow, &Colors::yellow },
    { ColorNames::yellowgreen, &Colors::yellowgreen },
    { ColorNames::rebeccapurple, &Colors::rebeccapurple },
    { ColorNames::transparent, &Colors::transparent }
  };

  const Color_RGBA* name_to_color(const char* key)
  {
    return name_to_color(sass::string(key));
  }

  const Color_RGBA* name_to_color(const sass::string& key)
  {
    // case insensitive lookup.  See #2462
    sass::string lower = key;
    Util::ascii_str_tolower(&lower);

    auto p = names_to_colors->find(lower);
    if (p != names_to_colors->end()) {
      return p->second;
    }
    return nullptr;
  }

  const char* color_to_name(const int key)
  {
    auto p = colors_to_names->find(key);
    if (p != colors_to_names->end()) {
      return p->second;
    }
    return nullptr;
  }

  const char* color_to_name(const double key)
  {
    return color_to_name((int)key);
  }

  const char* color_to_name(const Color_RGBA& c)
  {
    double key = c.r() * 0x10000
               + c.g() * 0x100
               + c.b();
    return color_to_name(key);
  }

}
