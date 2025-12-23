#include "prism/encoding.h"

typedef uint32_t pm_unicode_codepoint_t;

#define UNICODE_ALPHA_CODEPOINTS_LENGTH 1450
static const pm_unicode_codepoint_t unicode_alpha_codepoints[UNICODE_ALPHA_CODEPOINTS_LENGTH] = {
    0x100, 0x2C1,
    0x2C6, 0x2D1,
    0x2E0, 0x2E4,
    0x2EC, 0x2EC,
    0x2EE, 0x2EE,
    0x345, 0x345,
    0x370, 0x374,
    0x376, 0x377,
    0x37A, 0x37D,
    0x37F, 0x37F,
    0x386, 0x386,
    0x388, 0x38A,
    0x38C, 0x38C,
    0x38E, 0x3A1,
    0x3A3, 0x3F5,
    0x3F7, 0x481,
    0x48A, 0x52F,
    0x531, 0x556,
    0x559, 0x559,
    0x560, 0x588,
    0x5B0, 0x5BD,
    0x5BF, 0x5BF,
    0x5C1, 0x5C2,
    0x5C4, 0x5C5,
    0x5C7, 0x5C7,
    0x5D0, 0x5EA,
    0x5EF, 0x5F2,
    0x610, 0x61A,
    0x620, 0x657,
    0x659, 0x65F,
    0x66E, 0x6D3,
    0x6D5, 0x6DC,
    0x6E1, 0x6E8,
    0x6ED, 0x6EF,
    0x6FA, 0x6FC,
    0x6FF, 0x6FF,
    0x710, 0x73F,
    0x74D, 0x7B1,
    0x7CA, 0x7EA,
    0x7F4, 0x7F5,
    0x7FA, 0x7FA,
    0x800, 0x817,
    0x81A, 0x82C,
    0x840, 0x858,
    0x860, 0x86A,
    0x870, 0x887,
    0x889, 0x88E,
    0x8A0, 0x8C9,
    0x8D4, 0x8DF,
    0x8E3, 0x8E9,
    0x8F0, 0x93B,
    0x93D, 0x94C,
    0x94E, 0x950,
    0x955, 0x963,
    0x971, 0x983,
    0x985, 0x98C,
    0x98F, 0x990,
    0x993, 0x9A8,
    0x9AA, 0x9B0,
    0x9B2, 0x9B2,
    0x9B6, 0x9B9,
    0x9BD, 0x9C4,
    0x9C7, 0x9C8,
    0x9CB, 0x9CC,
    0x9CE, 0x9CE,
    0x9D7, 0x9D7,
    0x9DC, 0x9DD,
    0x9DF, 0x9E3,
    0x9F0, 0x9F1,
    0x9FC, 0x9FC,
    0xA01, 0xA03,
    0xA05, 0xA0A,
    0xA0F, 0xA10,
    0xA13, 0xA28,
    0xA2A, 0xA30,
    0xA32, 0xA33,
    0xA35, 0xA36,
    0xA38, 0xA39,
    0xA3E, 0xA42,
    0xA47, 0xA48,
    0xA4B, 0xA4C,
    0xA51, 0xA51,
    0xA59, 0xA5C,
    0xA5E, 0xA5E,
    0xA70, 0xA75,
    0xA81, 0xA83,
    0xA85, 0xA8D,
    0xA8F, 0xA91,
    0xA93, 0xAA8,
    0xAAA, 0xAB0,
    0xAB2, 0xAB3,
    0xAB5, 0xAB9,
    0xABD, 0xAC5,
    0xAC7, 0xAC9,
    0xACB, 0xACC,
    0xAD0, 0xAD0,
    0xAE0, 0xAE3,
    0xAF9, 0xAFC,
    0xB01, 0xB03,
    0xB05, 0xB0C,
    0xB0F, 0xB10,
    0xB13, 0xB28,
    0xB2A, 0xB30,
    0xB32, 0xB33,
    0xB35, 0xB39,
    0xB3D, 0xB44,
    0xB47, 0xB48,
    0xB4B, 0xB4C,
    0xB56, 0xB57,
    0xB5C, 0xB5D,
    0xB5F, 0xB63,
    0xB71, 0xB71,
    0xB82, 0xB83,
    0xB85, 0xB8A,
    0xB8E, 0xB90,
    0xB92, 0xB95,
    0xB99, 0xB9A,
    0xB9C, 0xB9C,
    0xB9E, 0xB9F,
    0xBA3, 0xBA4,
    0xBA8, 0xBAA,
    0xBAE, 0xBB9,
    0xBBE, 0xBC2,
    0xBC6, 0xBC8,
    0xBCA, 0xBCC,
    0xBD0, 0xBD0,
    0xBD7, 0xBD7,
    0xC00, 0xC0C,
    0xC0E, 0xC10,
    0xC12, 0xC28,
    0xC2A, 0xC39,
    0xC3D, 0xC44,
    0xC46, 0xC48,
    0xC4A, 0xC4C,
    0xC55, 0xC56,
    0xC58, 0xC5A,
    0xC5D, 0xC5D,
    0xC60, 0xC63,
    0xC80, 0xC83,
    0xC85, 0xC8C,
    0xC8E, 0xC90,
    0xC92, 0xCA8,
    0xCAA, 0xCB3,
    0xCB5, 0xCB9,
    0xCBD, 0xCC4,
    0xCC6, 0xCC8,
    0xCCA, 0xCCC,
    0xCD5, 0xCD6,
    0xCDD, 0xCDE,
    0xCE0, 0xCE3,
    0xCF1, 0xCF3,
    0xD00, 0xD0C,
    0xD0E, 0xD10,
    0xD12, 0xD3A,
    0xD3D, 0xD44,
    0xD46, 0xD48,
    0xD4A, 0xD4C,
    0xD4E, 0xD4E,
    0xD54, 0xD57,
    0xD5F, 0xD63,
    0xD7A, 0xD7F,
    0xD81, 0xD83,
    0xD85, 0xD96,
    0xD9A, 0xDB1,
    0xDB3, 0xDBB,
    0xDBD, 0xDBD,
    0xDC0, 0xDC6,
    0xDCF, 0xDD4,
    0xDD6, 0xDD6,
    0xDD8, 0xDDF,
    0xDF2, 0xDF3,
    0xE01, 0xE3A,
    0xE40, 0xE46,
    0xE4D, 0xE4D,
    0xE81, 0xE82,
    0xE84, 0xE84,
    0xE86, 0xE8A,
    0xE8C, 0xEA3,
    0xEA5, 0xEA5,
    0xEA7, 0xEB9,
    0xEBB, 0xEBD,
    0xEC0, 0xEC4,
    0xEC6, 0xEC6,
    0xECD, 0xECD,
    0xEDC, 0xEDF,
    0xF00, 0xF00,
    0xF40, 0xF47,
    0xF49, 0xF6C,
    0xF71, 0xF83,
    0xF88, 0xF97,
    0xF99, 0xFBC,
    0x1000, 0x1036,
    0x1038, 0x1038,
    0x103B, 0x103F,
    0x1050, 0x108F,
    0x109A, 0x109D,
    0x10A0, 0x10C5,
    0x10C7, 0x10C7,
    0x10CD, 0x10CD,
    0x10D0, 0x10FA,
    0x10FC, 0x1248,
    0x124A, 0x124D,
    0x1250, 0x1256,
    0x1258, 0x1258,
    0x125A, 0x125D,
    0x1260, 0x1288,
    0x128A, 0x128D,
    0x1290, 0x12B0,
    0x12B2, 0x12B5,
    0x12B8, 0x12BE,
    0x12C0, 0x12C0,
    0x12C2, 0x12C5,
    0x12C8, 0x12D6,
    0x12D8, 0x1310,
    0x1312, 0x1315,
    0x1318, 0x135A,
    0x1380, 0x138F,
    0x13A0, 0x13F5,
    0x13F8, 0x13FD,
    0x1401, 0x166C,
    0x166F, 0x167F,
    0x1681, 0x169A,
    0x16A0, 0x16EA,
    0x16EE, 0x16F8,
    0x1700, 0x1713,
    0x171F, 0x1733,
    0x1740, 0x1753,
    0x1760, 0x176C,
    0x176E, 0x1770,
    0x1772, 0x1773,
    0x1780, 0x17B3,
    0x17B6, 0x17C8,
    0x17D7, 0x17D7,
    0x17DC, 0x17DC,
    0x1820, 0x1878,
    0x1880, 0x18AA,
    0x18B0, 0x18F5,
    0x1900, 0x191E,
    0x1920, 0x192B,
    0x1930, 0x1938,
    0x1950, 0x196D,
    0x1970, 0x1974,
    0x1980, 0x19AB,
    0x19B0, 0x19C9,
    0x1A00, 0x1A1B,
    0x1A20, 0x1A5E,
    0x1A61, 0x1A74,
    0x1AA7, 0x1AA7,
    0x1ABF, 0x1AC0,
    0x1ACC, 0x1ACE,
    0x1B00, 0x1B33,
    0x1B35, 0x1B43,
    0x1B45, 0x1B4C,
    0x1B80, 0x1BA9,
    0x1BAC, 0x1BAF,
    0x1BBA, 0x1BE5,
    0x1BE7, 0x1BF1,
    0x1C00, 0x1C36,
    0x1C4D, 0x1C4F,
    0x1C5A, 0x1C7D,
    0x1C80, 0x1C88,
    0x1C90, 0x1CBA,
    0x1CBD, 0x1CBF,
    0x1CE9, 0x1CEC,
    0x1CEE, 0x1CF3,
    0x1CF5, 0x1CF6,
    0x1CFA, 0x1CFA,
    0x1D00, 0x1DBF,
    0x1DE7, 0x1DF4,
    0x1E00, 0x1F15,
    0x1F18, 0x1F1D,
    0x1F20, 0x1F45,
    0x1F48, 0x1F4D,
    0x1F50, 0x1F57,
    0x1F59, 0x1F59,
    0x1F5B, 0x1F5B,
    0x1F5D, 0x1F5D,
    0x1F5F, 0x1F7D,
    0x1F80, 0x1FB4,
    0x1FB6, 0x1FBC,
    0x1FBE, 0x1FBE,
    0x1FC2, 0x1FC4,
    0x1FC6, 0x1FCC,
    0x1FD0, 0x1FD3,
    0x1FD6, 0x1FDB,
    0x1FE0, 0x1FEC,
    0x1FF2, 0x1FF4,
    0x1FF6, 0x1FFC,
    0x2071, 0x2071,
    0x207F, 0x207F,
    0x2090, 0x209C,
    0x2102, 0x2102,
    0x2107, 0x2107,
    0x210A, 0x2113,
    0x2115, 0x2115,
    0x2119, 0x211D,
    0x2124, 0x2124,
    0x2126, 0x2126,
    0x2128, 0x2128,
    0x212A, 0x212D,
    0x212F, 0x2139,
    0x213C, 0x213F,
    0x2145, 0x2149,
    0x214E, 0x214E,
    0x2160, 0x2188,
    0x24B6, 0x24E9,
    0x2C00, 0x2CE4,
    0x2CEB, 0x2CEE,
    0x2CF2, 0x2CF3,
    0x2D00, 0x2D25,
    0x2D27, 0x2D27,
    0x2D2D, 0x2D2D,
    0x2D30, 0x2D67,
    0x2D6F, 0x2D6F,
    0x2D80, 0x2D96,
    0x2DA0, 0x2DA6,
    0x2DA8, 0x2DAE,
    0x2DB0, 0x2DB6,
    0x2DB8, 0x2DBE,
    0x2DC0, 0x2DC6,
    0x2DC8, 0x2DCE,
    0x2DD0, 0x2DD6,
    0x2DD8, 0x2DDE,
    0x2DE0, 0x2DFF,
    0x2E2F, 0x2E2F,
    0x3005, 0x3007,
    0x3021, 0x3029,
    0x3031, 0x3035,
    0x3038, 0x303C,
    0x3041, 0x3096,
    0x309D, 0x309F,
    0x30A1, 0x30FA,
    0x30FC, 0x30FF,
    0x3105, 0x312F,
    0x3131, 0x318E,
    0x31A0, 0x31BF,
    0x31F0, 0x31FF,
    0x3400, 0x4DBF,
    0x4E00, 0xA48C,
    0xA4D0, 0xA4FD,
    0xA500, 0xA60C,
    0xA610, 0xA61F,
    0xA62A, 0xA62B,
    0xA640, 0xA66E,
    0xA674, 0xA67B,
    0xA67F, 0xA6EF,
    0xA717, 0xA71F,
    0xA722, 0xA788,
    0xA78B, 0xA7CA,
    0xA7D0, 0xA7D1,
    0xA7D3, 0xA7D3,
    0xA7D5, 0xA7D9,
    0xA7F2, 0xA805,
    0xA807, 0xA827,
    0xA840, 0xA873,
    0xA880, 0xA8C3,
    0xA8C5, 0xA8C5,
    0xA8F2, 0xA8F7,
    0xA8FB, 0xA8FB,
    0xA8FD, 0xA8FF,
    0xA90A, 0xA92A,
    0xA930, 0xA952,
    0xA960, 0xA97C,
    0xA980, 0xA9B2,
    0xA9B4, 0xA9BF,
    0xA9CF, 0xA9CF,
    0xA9E0, 0xA9EF,
    0xA9FA, 0xA9FE,
    0xAA00, 0xAA36,
    0xAA40, 0xAA4D,
    0xAA60, 0xAA76,
    0xAA7A, 0xAABE,
    0xAAC0, 0xAAC0,
    0xAAC2, 0xAAC2,
    0xAADB, 0xAADD,
    0xAAE0, 0xAAEF,
    0xAAF2, 0xAAF5,
    0xAB01, 0xAB06,
    0xAB09, 0xAB0E,
    0xAB11, 0xAB16,
    0xAB20, 0xAB26,
    0xAB28, 0xAB2E,
    0xAB30, 0xAB5A,
    0xAB5C, 0xAB69,
    0xAB70, 0xABEA,
    0xAC00, 0xD7A3,
    0xD7B0, 0xD7C6,
    0xD7CB, 0xD7FB,
    0xF900, 0xFA6D,
    0xFA70, 0xFAD9,
    0xFB00, 0xFB06,
    0xFB13, 0xFB17,
    0xFB1D, 0xFB28,
    0xFB2A, 0xFB36,
    0xFB38, 0xFB3C,
    0xFB3E, 0xFB3E,
    0xFB40, 0xFB41,
    0xFB43, 0xFB44,
    0xFB46, 0xFBB1,
    0xFBD3, 0xFD3D,
    0xFD50, 0xFD8F,
    0xFD92, 0xFDC7,
    0xFDF0, 0xFDFB,
    0xFE70, 0xFE74,
    0xFE76, 0xFEFC,
    0xFF21, 0xFF3A,
    0xFF41, 0xFF5A,
    0xFF66, 0xFFBE,
    0xFFC2, 0xFFC7,
    0xFFCA, 0xFFCF,
    0xFFD2, 0xFFD7,
    0xFFDA, 0xFFDC,
    0x10000, 0x1000B,
    0x1000D, 0x10026,
    0x10028, 0x1003A,
    0x1003C, 0x1003D,
    0x1003F, 0x1004D,
    0x10050, 0x1005D,
    0x10080, 0x100FA,
    0x10140, 0x10174,
    0x10280, 0x1029C,
    0x102A0, 0x102D0,
    0x10300, 0x1031F,
    0x1032D, 0x1034A,
    0x10350, 0x1037A,
    0x10380, 0x1039D,
    0x103A0, 0x103C3,
    0x103C8, 0x103CF,
    0x103D1, 0x103D5,
    0x10400, 0x1049D,
    0x104B0, 0x104D3,
    0x104D8, 0x104FB,
    0x10500, 0x10527,
    0x10530, 0x10563,
    0x10570, 0x1057A,
    0x1057C, 0x1058A,
    0x1058C, 0x10592,
    0x10594, 0x10595,
    0x10597, 0x105A1,
    0x105A3, 0x105B1,
    0x105B3, 0x105B9,
    0x105BB, 0x105BC,
    0x10600, 0x10736,
    0x10740, 0x10755,
    0x10760, 0x10767,
    0x10780, 0x10785,
    0x10787, 0x107B0,
    0x107B2, 0x107BA,
    0x10800, 0x10805,
    0x10808, 0x10808,
    0x1080A, 0x10835,
    0x10837, 0x10838,
    0x1083C, 0x1083C,
    0x1083F, 0x10855,
    0x10860, 0x10876,
    0x10880, 0x1089E,
    0x108E0, 0x108F2,
    0x108F4, 0x108F5,
    0x10900, 0x10915,
    0x10920, 0x10939,
    0x10980, 0x109B7,
    0x109BE, 0x109BF,
    0x10A00, 0x10A03,
    0x10A05, 0x10A06,
    0x10A0C, 0x10A13,
    0x10A15, 0x10A17,
    0x10A19, 0x10A35,
    0x10A60, 0x10A7C,
    0x10A80, 0x10A9C,
    0x10AC0, 0x10AC7,
    0x10AC9, 0x10AE4,
    0x10B00, 0x10B35,
    0x10B40, 0x10B55,
    0x10B60, 0x10B72,
    0x10B80, 0x10B91,
    0x10C00, 0x10C48,
    0x10C80, 0x10CB2,
    0x10CC0, 0x10CF2,
    0x10D00, 0x10D27,
    0x10E80, 0x10EA9,
    0x10EAB, 0x10EAC,
    0x10EB0, 0x10EB1,
    0x10F00, 0x10F1C,
    0x10F27, 0x10F27,
    0x10F30, 0x10F45,
    0x10F70, 0x10F81,
    0x10FB0, 0x10FC4,
    0x10FE0, 0x10FF6,
    0x11000, 0x11045,
    0x11071, 0x11075,
    0x11080, 0x110B8,
    0x110C2, 0x110C2,
    0x110D0, 0x110E8,
    0x11100, 0x11132,
    0x11144, 0x11147,
    0x11150, 0x11172,
    0x11176, 0x11176,
    0x11180, 0x111BF,
    0x111C1, 0x111C4,
    0x111CE, 0x111CF,
    0x111DA, 0x111DA,
    0x111DC, 0x111DC,
    0x11200, 0x11211,
    0x11213, 0x11234,
    0x11237, 0x11237,
    0x1123E, 0x11241,
    0x11280, 0x11286,
    0x11288, 0x11288,
    0x1128A, 0x1128D,
    0x1128F, 0x1129D,
    0x1129F, 0x112A8,
    0x112B0, 0x112E8,
    0x11300, 0x11303,
    0x11305, 0x1130C,
    0x1130F, 0x11310,
    0x11313, 0x11328,
    0x1132A, 0x11330,
    0x11332, 0x11333,
    0x11335, 0x11339,
    0x1133D, 0x11344,
    0x11347, 0x11348,
    0x1134B, 0x1134C,
    0x11350, 0x11350,
    0x11357, 0x11357,
    0x1135D, 0x11363,
    0x11400, 0x11441,
    0x11443, 0x11445,
    0x11447, 0x1144A,
    0x1145F, 0x11461,
    0x11480, 0x114C1,
    0x114C4, 0x114C5,
    0x114C7, 0x114C7,
    0x11580, 0x115B5,
    0x115B8, 0x115BE,
    0x115D8, 0x115DD,
    0x11600, 0x1163E,
    0x11640, 0x11640,
    0x11644, 0x11644,
    0x11680, 0x116B5,
    0x116B8, 0x116B8,
    0x11700, 0x1171A,
    0x1171D, 0x1172A,
    0x11740, 0x11746,
    0x11800, 0x11838,
    0x118A0, 0x118DF,
    0x118FF, 0x11906,
    0x11909, 0x11909,
    0x1190C, 0x11913,
    0x11915, 0x11916,
    0x11918, 0x11935,
    0x11937, 0x11938,
    0x1193B, 0x1193C,
    0x1193F, 0x11942,
    0x119A0, 0x119A7,
    0x119AA, 0x119D7,
    0x119DA, 0x119DF,
    0x119E1, 0x119E1,
    0x119E3, 0x119E4,
    0x11A00, 0x11A32,
    0x11A35, 0x11A3E,
    0x11A50, 0x11A97,
    0x11A9D, 0x11A9D,
    0x11AB0, 0x11AF8,
    0x11C00, 0x11C08,
    0x11C0A, 0x11C36,
    0x11C38, 0x11C3E,
    0x11C40, 0x11C40,
    0x11C72, 0x11C8F,
    0x11C92, 0x11CA7,
    0x11CA9, 0x11CB6,
    0x11D00, 0x11D06,
    0x11D08, 0x11D09,
    0x11D0B, 0x11D36,
    0x11D3A, 0x11D3A,
    0x11D3C, 0x11D3D,
    0x11D3F, 0x11D41,
    0x11D43, 0x11D43,
    0x11D46, 0x11D47,
    0x11D60, 0x11D65,
    0x11D67, 0x11D68,
    0x11D6A, 0x11D8E,
    0x11D90, 0x11D91,
    0x11D93, 0x11D96,
    0x11D98, 0x11D98,
    0x11EE0, 0x11EF6,
    0x11F00, 0x11F10,
    0x11F12, 0x11F3A,
    0x11F3E, 0x11F40,
    0x11FB0, 0x11FB0,
    0x12000, 0x12399,
    0x12400, 0x1246E,
    0x12480, 0x12543,
    0x12F90, 0x12FF0,
    0x13000, 0x1342F,
    0x13441, 0x13446,
    0x14400, 0x14646,
    0x16800, 0x16A38,
    0x16A40, 0x16A5E,
    0x16A70, 0x16ABE,
    0x16AD0, 0x16AED,
    0x16B00, 0x16B2F,
    0x16B40, 0x16B43,
    0x16B63, 0x16B77,
    0x16B7D, 0x16B8F,
    0x16E40, 0x16E7F,
    0x16F00, 0x16F4A,
    0x16F4F, 0x16F87,
    0x16F8F, 0x16F9F,
    0x16FE0, 0x16FE1,
    0x16FE3, 0x16FE3,
    0x16FF0, 0x16FF1,
    0x17000, 0x187F7,
    0x18800, 0x18CD5,
    0x18D00, 0x18D08,
    0x1AFF0, 0x1AFF3,
    0x1AFF5, 0x1AFFB,
    0x1AFFD, 0x1AFFE,
    0x1B000, 0x1B122,
    0x1B132, 0x1B132,
    0x1B150, 0x1B152,
    0x1B155, 0x1B155,
    0x1B164, 0x1B167,
    0x1B170, 0x1B2FB,
    0x1BC00, 0x1BC6A,
    0x1BC70, 0x1BC7C,
    0x1BC80, 0x1BC88,
    0x1BC90, 0x1BC99,
    0x1BC9E, 0x1BC9E,
    0x1D400, 0x1D454,
    0x1D456, 0x1D49C,
    0x1D49E, 0x1D49F,
    0x1D4A2, 0x1D4A2,
    0x1D4A5, 0x1D4A6,
    0x1D4A9, 0x1D4AC,
    0x1D4AE, 0x1D4B9,
    0x1D4BB, 0x1D4BB,
    0x1D4BD, 0x1D4C3,
    0x1D4C5, 0x1D505,
    0x1D507, 0x1D50A,
    0x1D50D, 0x1D514,
    0x1D516, 0x1D51C,
    0x1D51E, 0x1D539,
    0x1D53B, 0x1D53E,
    0x1D540, 0x1D544,
    0x1D546, 0x1D546,
    0x1D54A, 0x1D550,
    0x1D552, 0x1D6A5,
    0x1D6A8, 0x1D6C0,
    0x1D6C2, 0x1D6DA,
    0x1D6DC, 0x1D6FA,
    0x1D6FC, 0x1D714,
    0x1D716, 0x1D734,
    0x1D736, 0x1D74E,
    0x1D750, 0x1D76E,
    0x1D770, 0x1D788,
    0x1D78A, 0x1D7A8,
    0x1D7AA, 0x1D7C2,
    0x1D7C4, 0x1D7CB,
    0x1DF00, 0x1DF1E,
    0x1DF25, 0x1DF2A,
    0x1E000, 0x1E006,
    0x1E008, 0x1E018,
    0x1E01B, 0x1E021,
    0x1E023, 0x1E024,
    0x1E026, 0x1E02A,
    0x1E030, 0x1E06D,
    0x1E08F, 0x1E08F,
    0x1E100, 0x1E12C,
    0x1E137, 0x1E13D,
    0x1E14E, 0x1E14E,
    0x1E290, 0x1E2AD,
    0x1E2C0, 0x1E2EB,
    0x1E4D0, 0x1E4EB,
    0x1E7E0, 0x1E7E6,
    0x1E7E8, 0x1E7EB,
    0x1E7ED, 0x1E7EE,
    0x1E7F0, 0x1E7FE,
    0x1E800, 0x1E8C4,
    0x1E900, 0x1E943,
    0x1E947, 0x1E947,
    0x1E94B, 0x1E94B,
    0x1EE00, 0x1EE03,
    0x1EE05, 0x1EE1F,
    0x1EE21, 0x1EE22,
    0x1EE24, 0x1EE24,
    0x1EE27, 0x1EE27,
    0x1EE29, 0x1EE32,
    0x1EE34, 0x1EE37,
    0x1EE39, 0x1EE39,
    0x1EE3B, 0x1EE3B,
    0x1EE42, 0x1EE42,
    0x1EE47, 0x1EE47,
    0x1EE49, 0x1EE49,
    0x1EE4B, 0x1EE4B,
    0x1EE4D, 0x1EE4F,
    0x1EE51, 0x1EE52,
    0x1EE54, 0x1EE54,
    0x1EE57, 0x1EE57,
    0x1EE59, 0x1EE59,
    0x1EE5B, 0x1EE5B,
    0x1EE5D, 0x1EE5D,
    0x1EE5F, 0x1EE5F,
    0x1EE61, 0x1EE62,
    0x1EE64, 0x1EE64,
    0x1EE67, 0x1EE6A,
    0x1EE6C, 0x1EE72,
    0x1EE74, 0x1EE77,
    0x1EE79, 0x1EE7C,
    0x1EE7E, 0x1EE7E,
    0x1EE80, 0x1EE89,
    0x1EE8B, 0x1EE9B,
    0x1EEA1, 0x1EEA3,
    0x1EEA5, 0x1EEA9,
    0x1EEAB, 0x1EEBB,
    0x1F130, 0x1F149,
    0x1F150, 0x1F169,
    0x1F170, 0x1F189,
    0x20000, 0x2A6DF,
    0x2A700, 0x2B739,
    0x2B740, 0x2B81D,
    0x2B820, 0x2CEA1,
    0x2CEB0, 0x2EBE0,
    0x2F800, 0x2FA1D,
    0x30000, 0x3134A,
    0x31350, 0x323AF,
};

#define UNICODE_ALNUM_CODEPOINTS_LENGTH 1528
static const pm_unicode_codepoint_t unicode_alnum_codepoints[UNICODE_ALNUM_CODEPOINTS_LENGTH] = {
    0x100, 0x2C1,
    0x2C6, 0x2D1,
    0x2E0, 0x2E4,
    0x2EC, 0x2EC,
    0x2EE, 0x2EE,
    0x345, 0x345,
    0x370, 0x374,
    0x376, 0x377,
    0x37A, 0x37D,
    0x37F, 0x37F,
    0x386, 0x386,
    0x388, 0x38A,
    0x38C, 0x38C,
    0x38E, 0x3A1,
    0x3A3, 0x3F5,
    0x3F7, 0x481,
    0x48A, 0x52F,
    0x531, 0x556,
    0x559, 0x559,
    0x560, 0x588,
    0x5B0, 0x5BD,
    0x5BF, 0x5BF,
    0x5C1, 0x5C2,
    0x5C4, 0x5C5,
    0x5C7, 0x5C7,
    0x5D0, 0x5EA,
    0x5EF, 0x5F2,
    0x610, 0x61A,
    0x620, 0x657,
    0x659, 0x669,
    0x66E, 0x6D3,
    0x6D5, 0x6DC,
    0x6E1, 0x6E8,
    0x6ED, 0x6FC,
    0x6FF, 0x6FF,
    0x710, 0x73F,
    0x74D, 0x7B1,
    0x7C0, 0x7EA,
    0x7F4, 0x7F5,
    0x7FA, 0x7FA,
    0x800, 0x817,
    0x81A, 0x82C,
    0x840, 0x858,
    0x860, 0x86A,
    0x870, 0x887,
    0x889, 0x88E,
    0x8A0, 0x8C9,
    0x8D4, 0x8DF,
    0x8E3, 0x8E9,
    0x8F0, 0x93B,
    0x93D, 0x94C,
    0x94E, 0x950,
    0x955, 0x963,
    0x966, 0x96F,
    0x971, 0x983,
    0x985, 0x98C,
    0x98F, 0x990,
    0x993, 0x9A8,
    0x9AA, 0x9B0,
    0x9B2, 0x9B2,
    0x9B6, 0x9B9,
    0x9BD, 0x9C4,
    0x9C7, 0x9C8,
    0x9CB, 0x9CC,
    0x9CE, 0x9CE,
    0x9D7, 0x9D7,
    0x9DC, 0x9DD,
    0x9DF, 0x9E3,
    0x9E6, 0x9F1,
    0x9FC, 0x9FC,
    0xA01, 0xA03,
    0xA05, 0xA0A,
    0xA0F, 0xA10,
    0xA13, 0xA28,
    0xA2A, 0xA30,
    0xA32, 0xA33,
    0xA35, 0xA36,
    0xA38, 0xA39,
    0xA3E, 0xA42,
    0xA47, 0xA48,
    0xA4B, 0xA4C,
    0xA51, 0xA51,
    0xA59, 0xA5C,
    0xA5E, 0xA5E,
    0xA66, 0xA75,
    0xA81, 0xA83,
    0xA85, 0xA8D,
    0xA8F, 0xA91,
    0xA93, 0xAA8,
    0xAAA, 0xAB0,
    0xAB2, 0xAB3,
    0xAB5, 0xAB9,
    0xABD, 0xAC5,
    0xAC7, 0xAC9,
    0xACB, 0xACC,
    0xAD0, 0xAD0,
    0xAE0, 0xAE3,
    0xAE6, 0xAEF,
    0xAF9, 0xAFC,
    0xB01, 0xB03,
    0xB05, 0xB0C,
    0xB0F, 0xB10,
    0xB13, 0xB28,
    0xB2A, 0xB30,
    0xB32, 0xB33,
    0xB35, 0xB39,
    0xB3D, 0xB44,
    0xB47, 0xB48,
    0xB4B, 0xB4C,
    0xB56, 0xB57,
    0xB5C, 0xB5D,
    0xB5F, 0xB63,
    0xB66, 0xB6F,
    0xB71, 0xB71,
    0xB82, 0xB83,
    0xB85, 0xB8A,
    0xB8E, 0xB90,
    0xB92, 0xB95,
    0xB99, 0xB9A,
    0xB9C, 0xB9C,
    0xB9E, 0xB9F,
    0xBA3, 0xBA4,
    0xBA8, 0xBAA,
    0xBAE, 0xBB9,
    0xBBE, 0xBC2,
    0xBC6, 0xBC8,
    0xBCA, 0xBCC,
    0xBD0, 0xBD0,
    0xBD7, 0xBD7,
    0xBE6, 0xBEF,
    0xC00, 0xC0C,
    0xC0E, 0xC10,
    0xC12, 0xC28,
    0xC2A, 0xC39,
    0xC3D, 0xC44,
    0xC46, 0xC48,
    0xC4A, 0xC4C,
    0xC55, 0xC56,
    0xC58, 0xC5A,
    0xC5D, 0xC5D,
    0xC60, 0xC63,
    0xC66, 0xC6F,
    0xC80, 0xC83,
    0xC85, 0xC8C,
    0xC8E, 0xC90,
    0xC92, 0xCA8,
    0xCAA, 0xCB3,
    0xCB5, 0xCB9,
    0xCBD, 0xCC4,
    0xCC6, 0xCC8,
    0xCCA, 0xCCC,
    0xCD5, 0xCD6,
    0xCDD, 0xCDE,
    0xCE0, 0xCE3,
    0xCE6, 0xCEF,
    0xCF1, 0xCF3,
    0xD00, 0xD0C,
    0xD0E, 0xD10,
    0xD12, 0xD3A,
    0xD3D, 0xD44,
    0xD46, 0xD48,
    0xD4A, 0xD4C,
    0xD4E, 0xD4E,
    0xD54, 0xD57,
    0xD5F, 0xD63,
    0xD66, 0xD6F,
    0xD7A, 0xD7F,
    0xD81, 0xD83,
    0xD85, 0xD96,
    0xD9A, 0xDB1,
    0xDB3, 0xDBB,
    0xDBD, 0xDBD,
    0xDC0, 0xDC6,
    0xDCF, 0xDD4,
    0xDD6, 0xDD6,
    0xDD8, 0xDDF,
    0xDE6, 0xDEF,
    0xDF2, 0xDF3,
    0xE01, 0xE3A,
    0xE40, 0xE46,
    0xE4D, 0xE4D,
    0xE50, 0xE59,
    0xE81, 0xE82,
    0xE84, 0xE84,
    0xE86, 0xE8A,
    0xE8C, 0xEA3,
    0xEA5, 0xEA5,
    0xEA7, 0xEB9,
    0xEBB, 0xEBD,
    0xEC0, 0xEC4,
    0xEC6, 0xEC6,
    0xECD, 0xECD,
    0xED0, 0xED9,
    0xEDC, 0xEDF,
    0xF00, 0xF00,
    0xF20, 0xF29,
    0xF40, 0xF47,
    0xF49, 0xF6C,
    0xF71, 0xF83,
    0xF88, 0xF97,
    0xF99, 0xFBC,
    0x1000, 0x1036,
    0x1038, 0x1038,
    0x103B, 0x1049,
    0x1050, 0x109D,
    0x10A0, 0x10C5,
    0x10C7, 0x10C7,
    0x10CD, 0x10CD,
    0x10D0, 0x10FA,
    0x10FC, 0x1248,
    0x124A, 0x124D,
    0x1250, 0x1256,
    0x1258, 0x1258,
    0x125A, 0x125D,
    0x1260, 0x1288,
    0x128A, 0x128D,
    0x1290, 0x12B0,
    0x12B2, 0x12B5,
    0x12B8, 0x12BE,
    0x12C0, 0x12C0,
    0x12C2, 0x12C5,
    0x12C8, 0x12D6,
    0x12D8, 0x1310,
    0x1312, 0x1315,
    0x1318, 0x135A,
    0x1380, 0x138F,
    0x13A0, 0x13F5,
    0x13F8, 0x13FD,
    0x1401, 0x166C,
    0x166F, 0x167F,
    0x1681, 0x169A,
    0x16A0, 0x16EA,
    0x16EE, 0x16F8,
    0x1700, 0x1713,
    0x171F, 0x1733,
    0x1740, 0x1753,
    0x1760, 0x176C,
    0x176E, 0x1770,
    0x1772, 0x1773,
    0x1780, 0x17B3,
    0x17B6, 0x17C8,
    0x17D7, 0x17D7,
    0x17DC, 0x17DC,
    0x17E0, 0x17E9,
    0x1810, 0x1819,
    0x1820, 0x1878,
    0x1880, 0x18AA,
    0x18B0, 0x18F5,
    0x1900, 0x191E,
    0x1920, 0x192B,
    0x1930, 0x1938,
    0x1946, 0x196D,
    0x1970, 0x1974,
    0x1980, 0x19AB,
    0x19B0, 0x19C9,
    0x19D0, 0x19D9,
    0x1A00, 0x1A1B,
    0x1A20, 0x1A5E,
    0x1A61, 0x1A74,
    0x1A80, 0x1A89,
    0x1A90, 0x1A99,
    0x1AA7, 0x1AA7,
    0x1ABF, 0x1AC0,
    0x1ACC, 0x1ACE,
    0x1B00, 0x1B33,
    0x1B35, 0x1B43,
    0x1B45, 0x1B4C,
    0x1B50, 0x1B59,
    0x1B80, 0x1BA9,
    0x1BAC, 0x1BE5,
    0x1BE7, 0x1BF1,
    0x1C00, 0x1C36,
    0x1C40, 0x1C49,
    0x1C4D, 0x1C7D,
    0x1C80, 0x1C88,
    0x1C90, 0x1CBA,
    0x1CBD, 0x1CBF,
    0x1CE9, 0x1CEC,
    0x1CEE, 0x1CF3,
    0x1CF5, 0x1CF6,
    0x1CFA, 0x1CFA,
    0x1D00, 0x1DBF,
    0x1DE7, 0x1DF4,
    0x1E00, 0x1F15,
    0x1F18, 0x1F1D,
    0x1F20, 0x1F45,
    0x1F48, 0x1F4D,
    0x1F50, 0x1F57,
    0x1F59, 0x1F59,
    0x1F5B, 0x1F5B,
    0x1F5D, 0x1F5D,
    0x1F5F, 0x1F7D,
    0x1F80, 0x1FB4,
    0x1FB6, 0x1FBC,
    0x1FBE, 0x1FBE,
    0x1FC2, 0x1FC4,
    0x1FC6, 0x1FCC,
    0x1FD0, 0x1FD3,
    0x1FD6, 0x1FDB,
    0x1FE0, 0x1FEC,
    0x1FF2, 0x1FF4,
    0x1FF6, 0x1FFC,
    0x2071, 0x2071,
    0x207F, 0x207F,
    0x2090, 0x209C,
    0x2102, 0x2102,
    0x2107, 0x2107,
    0x210A, 0x2113,
    0x2115, 0x2115,
    0x2119, 0x211D,
    0x2124, 0x2124,
    0x2126, 0x2126,
    0x2128, 0x2128,
    0x212A, 0x212D,
    0x212F, 0x2139,
    0x213C, 0x213F,
    0x2145, 0x2149,
    0x214E, 0x214E,
    0x2160, 0x2188,
    0x24B6, 0x24E9,
    0x2C00, 0x2CE4,
    0x2CEB, 0x2CEE,
    0x2CF2, 0x2CF3,
    0x2D00, 0x2D25,
    0x2D27, 0x2D27,
    0x2D2D, 0x2D2D,
    0x2D30, 0x2D67,
    0x2D6F, 0x2D6F,
    0x2D80, 0x2D96,
    0x2DA0, 0x2DA6,
    0x2DA8, 0x2DAE,
    0x2DB0, 0x2DB6,
    0x2DB8, 0x2DBE,
    0x2DC0, 0x2DC6,
    0x2DC8, 0x2DCE,
    0x2DD0, 0x2DD6,
    0x2DD8, 0x2DDE,
    0x2DE0, 0x2DFF,
    0x2E2F, 0x2E2F,
    0x3005, 0x3007,
    0x3021, 0x3029,
    0x3031, 0x3035,
    0x3038, 0x303C,
    0x3041, 0x3096,
    0x309D, 0x309F,
    0x30A1, 0x30FA,
    0x30FC, 0x30FF,
    0x3105, 0x312F,
    0x3131, 0x318E,
    0x31A0, 0x31BF,
    0x31F0, 0x31FF,
    0x3400, 0x4DBF,
    0x4E00, 0xA48C,
    0xA4D0, 0xA4FD,
    0xA500, 0xA60C,
    0xA610, 0xA62B,
    0xA640, 0xA66E,
    0xA674, 0xA67B,
    0xA67F, 0xA6EF,
    0xA717, 0xA71F,
    0xA722, 0xA788,
    0xA78B, 0xA7CA,
    0xA7D0, 0xA7D1,
    0xA7D3, 0xA7D3,
    0xA7D5, 0xA7D9,
    0xA7F2, 0xA805,
    0xA807, 0xA827,
    0xA840, 0xA873,
    0xA880, 0xA8C3,
    0xA8C5, 0xA8C5,
    0xA8D0, 0xA8D9,
    0xA8F2, 0xA8F7,
    0xA8FB, 0xA8FB,
    0xA8FD, 0xA92A,
    0xA930, 0xA952,
    0xA960, 0xA97C,
    0xA980, 0xA9B2,
    0xA9B4, 0xA9BF,
    0xA9CF, 0xA9D9,
    0xA9E0, 0xA9FE,
    0xAA00, 0xAA36,
    0xAA40, 0xAA4D,
    0xAA50, 0xAA59,
    0xAA60, 0xAA76,
    0xAA7A, 0xAABE,
    0xAAC0, 0xAAC0,
    0xAAC2, 0xAAC2,
    0xAADB, 0xAADD,
    0xAAE0, 0xAAEF,
    0xAAF2, 0xAAF5,
    0xAB01, 0xAB06,
    0xAB09, 0xAB0E,
    0xAB11, 0xAB16,
    0xAB20, 0xAB26,
    0xAB28, 0xAB2E,
    0xAB30, 0xAB5A,
    0xAB5C, 0xAB69,
    0xAB70, 0xABEA,
    0xABF0, 0xABF9,
    0xAC00, 0xD7A3,
    0xD7B0, 0xD7C6,
    0xD7CB, 0xD7FB,
    0xF900, 0xFA6D,
    0xFA70, 0xFAD9,
    0xFB00, 0xFB06,
    0xFB13, 0xFB17,
    0xFB1D, 0xFB28,
    0xFB2A, 0xFB36,
    0xFB38, 0xFB3C,
    0xFB3E, 0xFB3E,
    0xFB40, 0xFB41,
    0xFB43, 0xFB44,
    0xFB46, 0xFBB1,
    0xFBD3, 0xFD3D,
    0xFD50, 0xFD8F,
    0xFD92, 0xFDC7,
    0xFDF0, 0xFDFB,
    0xFE70, 0xFE74,
    0xFE76, 0xFEFC,
    0xFF10, 0xFF19,
    0xFF21, 0xFF3A,
    0xFF41, 0xFF5A,
    0xFF66, 0xFFBE,
    0xFFC2, 0xFFC7,
    0xFFCA, 0xFFCF,
    0xFFD2, 0xFFD7,
    0xFFDA, 0xFFDC,
    0x10000, 0x1000B,
    0x1000D, 0x10026,
    0x10028, 0x1003A,
    0x1003C, 0x1003D,
    0x1003F, 0x1004D,
    0x10050, 0x1005D,
    0x10080, 0x100FA,
    0x10140, 0x10174,
    0x10280, 0x1029C,
    0x102A0, 0x102D0,
    0x10300, 0x1031F,
    0x1032D, 0x1034A,
    0x10350, 0x1037A,
    0x10380, 0x1039D,
    0x103A0, 0x103C3,
    0x103C8, 0x103CF,
    0x103D1, 0x103D5,
    0x10400, 0x1049D,
    0x104A0, 0x104A9,
    0x104B0, 0x104D3,
    0x104D8, 0x104FB,
    0x10500, 0x10527,
    0x10530, 0x10563,
    0x10570, 0x1057A,
    0x1057C, 0x1058A,
    0x1058C, 0x10592,
    0x10594, 0x10595,
    0x10597, 0x105A1,
    0x105A3, 0x105B1,
    0x105B3, 0x105B9,
    0x105BB, 0x105BC,
    0x10600, 0x10736,
    0x10740, 0x10755,
    0x10760, 0x10767,
    0x10780, 0x10785,
    0x10787, 0x107B0,
    0x107B2, 0x107BA,
    0x10800, 0x10805,
    0x10808, 0x10808,
    0x1080A, 0x10835,
    0x10837, 0x10838,
    0x1083C, 0x1083C,
    0x1083F, 0x10855,
    0x10860, 0x10876,
    0x10880, 0x1089E,
    0x108E0, 0x108F2,
    0x108F4, 0x108F5,
    0x10900, 0x10915,
    0x10920, 0x10939,
    0x10980, 0x109B7,
    0x109BE, 0x109BF,
    0x10A00, 0x10A03,
    0x10A05, 0x10A06,
    0x10A0C, 0x10A13,
    0x10A15, 0x10A17,
    0x10A19, 0x10A35,
    0x10A60, 0x10A7C,
    0x10A80, 0x10A9C,
    0x10AC0, 0x10AC7,
    0x10AC9, 0x10AE4,
    0x10B00, 0x10B35,
    0x10B40, 0x10B55,
    0x10B60, 0x10B72,
    0x10B80, 0x10B91,
    0x10C00, 0x10C48,
    0x10C80, 0x10CB2,
    0x10CC0, 0x10CF2,
    0x10D00, 0x10D27,
    0x10D30, 0x10D39,
    0x10E80, 0x10EA9,
    0x10EAB, 0x10EAC,
    0x10EB0, 0x10EB1,
    0x10F00, 0x10F1C,
    0x10F27, 0x10F27,
    0x10F30, 0x10F45,
    0x10F70, 0x10F81,
    0x10FB0, 0x10FC4,
    0x10FE0, 0x10FF6,
    0x11000, 0x11045,
    0x11066, 0x1106F,
    0x11071, 0x11075,
    0x11080, 0x110B8,
    0x110C2, 0x110C2,
    0x110D0, 0x110E8,
    0x110F0, 0x110F9,
    0x11100, 0x11132,
    0x11136, 0x1113F,
    0x11144, 0x11147,
    0x11150, 0x11172,
    0x11176, 0x11176,
    0x11180, 0x111BF,
    0x111C1, 0x111C4,
    0x111CE, 0x111DA,
    0x111DC, 0x111DC,
    0x11200, 0x11211,
    0x11213, 0x11234,
    0x11237, 0x11237,
    0x1123E, 0x11241,
    0x11280, 0x11286,
    0x11288, 0x11288,
    0x1128A, 0x1128D,
    0x1128F, 0x1129D,
    0x1129F, 0x112A8,
    0x112B0, 0x112E8,
    0x112F0, 0x112F9,
    0x11300, 0x11303,
    0x11305, 0x1130C,
    0x1130F, 0x11310,
    0x11313, 0x11328,
    0x1132A, 0x11330,
    0x11332, 0x11333,
    0x11335, 0x11339,
    0x1133D, 0x11344,
    0x11347, 0x11348,
    0x1134B, 0x1134C,
    0x11350, 0x11350,
    0x11357, 0x11357,
    0x1135D, 0x11363,
    0x11400, 0x11441,
    0x11443, 0x11445,
    0x11447, 0x1144A,
    0x11450, 0x11459,
    0x1145F, 0x11461,
    0x11480, 0x114C1,
    0x114C4, 0x114C5,
    0x114C7, 0x114C7,
    0x114D0, 0x114D9,
    0x11580, 0x115B5,
    0x115B8, 0x115BE,
    0x115D8, 0x115DD,
    0x11600, 0x1163E,
    0x11640, 0x11640,
    0x11644, 0x11644,
    0x11650, 0x11659,
    0x11680, 0x116B5,
    0x116B8, 0x116B8,
    0x116C0, 0x116C9,
    0x11700, 0x1171A,
    0x1171D, 0x1172A,
    0x11730, 0x11739,
    0x11740, 0x11746,
    0x11800, 0x11838,
    0x118A0, 0x118E9,
    0x118FF, 0x11906,
    0x11909, 0x11909,
    0x1190C, 0x11913,
    0x11915, 0x11916,
    0x11918, 0x11935,
    0x11937, 0x11938,
    0x1193B, 0x1193C,
    0x1193F, 0x11942,
    0x11950, 0x11959,
    0x119A0, 0x119A7,
    0x119AA, 0x119D7,
    0x119DA, 0x119DF,
    0x119E1, 0x119E1,
    0x119E3, 0x119E4,
    0x11A00, 0x11A32,
    0x11A35, 0x11A3E,
    0x11A50, 0x11A97,
    0x11A9D, 0x11A9D,
    0x11AB0, 0x11AF8,
    0x11C00, 0x11C08,
    0x11C0A, 0x11C36,
    0x11C38, 0x11C3E,
    0x11C40, 0x11C40,
    0x11C50, 0x11C59,
    0x11C72, 0x11C8F,
    0x11C92, 0x11CA7,
    0x11CA9, 0x11CB6,
    0x11D00, 0x11D06,
    0x11D08, 0x11D09,
    0x11D0B, 0x11D36,
    0x11D3A, 0x11D3A,
    0x11D3C, 0x11D3D,
    0x11D3F, 0x11D41,
    0x11D43, 0x11D43,
    0x11D46, 0x11D47,
    0x11D50, 0x11D59,
    0x11D60, 0x11D65,
    0x11D67, 0x11D68,
    0x11D6A, 0x11D8E,
    0x11D90, 0x11D91,
    0x11D93, 0x11D96,
    0x11D98, 0x11D98,
    0x11DA0, 0x11DA9,
    0x11EE0, 0x11EF6,
    0x11F00, 0x11F10,
    0x11F12, 0x11F3A,
    0x11F3E, 0x11F40,
    0x11F50, 0x11F59,
    0x11FB0, 0x11FB0,
    0x12000, 0x12399,
    0x12400, 0x1246E,
    0x12480, 0x12543,
    0x12F90, 0x12FF0,
    0x13000, 0x1342F,
    0x13441, 0x13446,
    0x14400, 0x14646,
    0x16800, 0x16A38,
    0x16A40, 0x16A5E,
    0x16A60, 0x16A69,
    0x16A70, 0x16ABE,
    0x16AC0, 0x16AC9,
    0x16AD0, 0x16AED,
    0x16B00, 0x16B2F,
    0x16B40, 0x16B43,
    0x16B50, 0x16B59,
    0x16B63, 0x16B77,
    0x16B7D, 0x16B8F,
    0x16E40, 0x16E7F,
    0x16F00, 0x16F4A,
    0x16F4F, 0x16F87,
    0x16F8F, 0x16F9F,
    0x16FE0, 0x16FE1,
    0x16FE3, 0x16FE3,
    0x16FF0, 0x16FF1,
    0x17000, 0x187F7,
    0x18800, 0x18CD5,
    0x18D00, 0x18D08,
    0x1AFF0, 0x1AFF3,
    0x1AFF5, 0x1AFFB,
    0x1AFFD, 0x1AFFE,
    0x1B000, 0x1B122,
    0x1B132, 0x1B132,
    0x1B150, 0x1B152,
    0x1B155, 0x1B155,
    0x1B164, 0x1B167,
    0x1B170, 0x1B2FB,
    0x1BC00, 0x1BC6A,
    0x1BC70, 0x1BC7C,
    0x1BC80, 0x1BC88,
    0x1BC90, 0x1BC99,
    0x1BC9E, 0x1BC9E,
    0x1D400, 0x1D454,
    0x1D456, 0x1D49C,
    0x1D49E, 0x1D49F,
    0x1D4A2, 0x1D4A2,
    0x1D4A5, 0x1D4A6,
    0x1D4A9, 0x1D4AC,
    0x1D4AE, 0x1D4B9,
    0x1D4BB, 0x1D4BB,
    0x1D4BD, 0x1D4C3,
    0x1D4C5, 0x1D505,
    0x1D507, 0x1D50A,
    0x1D50D, 0x1D514,
    0x1D516, 0x1D51C,
    0x1D51E, 0x1D539,
    0x1D53B, 0x1D53E,
    0x1D540, 0x1D544,
    0x1D546, 0x1D546,
    0x1D54A, 0x1D550,
    0x1D552, 0x1D6A5,
    0x1D6A8, 0x1D6C0,
    0x1D6C2, 0x1D6DA,
    0x1D6DC, 0x1D6FA,
    0x1D6FC, 0x1D714,
    0x1D716, 0x1D734,
    0x1D736, 0x1D74E,
    0x1D750, 0x1D76E,
    0x1D770, 0x1D788,
    0x1D78A, 0x1D7A8,
    0x1D7AA, 0x1D7C2,
    0x1D7C4, 0x1D7CB,
    0x1D7CE, 0x1D7FF,
    0x1DF00, 0x1DF1E,
    0x1DF25, 0x1DF2A,
    0x1E000, 0x1E006,
    0x1E008, 0x1E018,
    0x1E01B, 0x1E021,
    0x1E023, 0x1E024,
    0x1E026, 0x1E02A,
    0x1E030, 0x1E06D,
    0x1E08F, 0x1E08F,
    0x1E100, 0x1E12C,
    0x1E137, 0x1E13D,
    0x1E140, 0x1E149,
    0x1E14E, 0x1E14E,
    0x1E290, 0x1E2AD,
    0x1E2C0, 0x1E2EB,
    0x1E2F0, 0x1E2F9,
    0x1E4D0, 0x1E4EB,
    0x1E4F0, 0x1E4F9,
    0x1E7E0, 0x1E7E6,
    0x1E7E8, 0x1E7EB,
    0x1E7ED, 0x1E7EE,
    0x1E7F0, 0x1E7FE,
    0x1E800, 0x1E8C4,
    0x1E900, 0x1E943,
    0x1E947, 0x1E947,
    0x1E94B, 0x1E94B,
    0x1E950, 0x1E959,
    0x1EE00, 0x1EE03,
    0x1EE05, 0x1EE1F,
    0x1EE21, 0x1EE22,
    0x1EE24, 0x1EE24,
    0x1EE27, 0x1EE27,
    0x1EE29, 0x1EE32,
    0x1EE34, 0x1EE37,
    0x1EE39, 0x1EE39,
    0x1EE3B, 0x1EE3B,
    0x1EE42, 0x1EE42,
    0x1EE47, 0x1EE47,
    0x1EE49, 0x1EE49,
    0x1EE4B, 0x1EE4B,
    0x1EE4D, 0x1EE4F,
    0x1EE51, 0x1EE52,
    0x1EE54, 0x1EE54,
    0x1EE57, 0x1EE57,
    0x1EE59, 0x1EE59,
    0x1EE5B, 0x1EE5B,
    0x1EE5D, 0x1EE5D,
    0x1EE5F, 0x1EE5F,
    0x1EE61, 0x1EE62,
    0x1EE64, 0x1EE64,
    0x1EE67, 0x1EE6A,
    0x1EE6C, 0x1EE72,
    0x1EE74, 0x1EE77,
    0x1EE79, 0x1EE7C,
    0x1EE7E, 0x1EE7E,
    0x1EE80, 0x1EE89,
    0x1EE8B, 0x1EE9B,
    0x1EEA1, 0x1EEA3,
    0x1EEA5, 0x1EEA9,
    0x1EEAB, 0x1EEBB,
    0x1F130, 0x1F149,
    0x1F150, 0x1F169,
    0x1F170, 0x1F189,
    0x1FBF0, 0x1FBF9,
    0x20000, 0x2A6DF,
    0x2A700, 0x2B739,
    0x2B740, 0x2B81D,
    0x2B820, 0x2CEA1,
    0x2CEB0, 0x2EBE0,
    0x2F800, 0x2FA1D,
    0x30000, 0x3134A,
    0x31350, 0x323AF,
};

#define UNICODE_ISUPPER_CODEPOINTS_LENGTH 1302
static const pm_unicode_codepoint_t unicode_isupper_codepoints[UNICODE_ISUPPER_CODEPOINTS_LENGTH] = {
    0x100, 0x100,
    0x102, 0x102,
    0x104, 0x104,
    0x106, 0x106,
    0x108, 0x108,
    0x10A, 0x10A,
    0x10C, 0x10C,
    0x10E, 0x10E,
    0x110, 0x110,
    0x112, 0x112,
    0x114, 0x114,
    0x116, 0x116,
    0x118, 0x118,
    0x11A, 0x11A,
    0x11C, 0x11C,
    0x11E, 0x11E,
    0x120, 0x120,
    0x122, 0x122,
    0x124, 0x124,
    0x126, 0x126,
    0x128, 0x128,
    0x12A, 0x12A,
    0x12C, 0x12C,
    0x12E, 0x12E,
    0x130, 0x130,
    0x132, 0x132,
    0x134, 0x134,
    0x136, 0x136,
    0x139, 0x139,
    0x13B, 0x13B,
    0x13D, 0x13D,
    0x13F, 0x13F,
    0x141, 0x141,
    0x143, 0x143,
    0x145, 0x145,
    0x147, 0x147,
    0x14A, 0x14A,
    0x14C, 0x14C,
    0x14E, 0x14E,
    0x150, 0x150,
    0x152, 0x152,
    0x154, 0x154,
    0x156, 0x156,
    0x158, 0x158,
    0x15A, 0x15A,
    0x15C, 0x15C,
    0x15E, 0x15E,
    0x160, 0x160,
    0x162, 0x162,
    0x164, 0x164,
    0x166, 0x166,
    0x168, 0x168,
    0x16A, 0x16A,
    0x16C, 0x16C,
    0x16E, 0x16E,
    0x170, 0x170,
    0x172, 0x172,
    0x174, 0x174,
    0x176, 0x176,
    0x178, 0x179,
    0x17B, 0x17B,
    0x17D, 0x17D,
    0x181, 0x182,
    0x184, 0x184,
    0x186, 0x187,
    0x189, 0x18B,
    0x18E, 0x191,
    0x193, 0x194,
    0x196, 0x198,
    0x19C, 0x19D,
    0x19F, 0x1A0,
    0x1A2, 0x1A2,
    0x1A4, 0x1A4,
    0x1A6, 0x1A7,
    0x1A9, 0x1A9,
    0x1AC, 0x1AC,
    0x1AE, 0x1AF,
    0x1B1, 0x1B3,
    0x1B5, 0x1B5,
    0x1B7, 0x1B8,
    0x1BC, 0x1BC,
    0x1C4, 0x1C5,
    0x1C7, 0x1C8,
    0x1CA, 0x1CB,
    0x1CD, 0x1CD,
    0x1CF, 0x1CF,
    0x1D1, 0x1D1,
    0x1D3, 0x1D3,
    0x1D5, 0x1D5,
    0x1D7, 0x1D7,
    0x1D9, 0x1D9,
    0x1DB, 0x1DB,
    0x1DE, 0x1DE,
    0x1E0, 0x1E0,
    0x1E2, 0x1E2,
    0x1E4, 0x1E4,
    0x1E6, 0x1E6,
    0x1E8, 0x1E8,
    0x1EA, 0x1EA,
    0x1EC, 0x1EC,
    0x1EE, 0x1EE,
    0x1F1, 0x1F2,
    0x1F4, 0x1F4,
    0x1F6, 0x1F8,
    0x1FA, 0x1FA,
    0x1FC, 0x1FC,
    0x1FE, 0x1FE,
    0x200, 0x200,
    0x202, 0x202,
    0x204, 0x204,
    0x206, 0x206,
    0x208, 0x208,
    0x20A, 0x20A,
    0x20C, 0x20C,
    0x20E, 0x20E,
    0x210, 0x210,
    0x212, 0x212,
    0x214, 0x214,
    0x216, 0x216,
    0x218, 0x218,
    0x21A, 0x21A,
    0x21C, 0x21C,
    0x21E, 0x21E,
    0x220, 0x220,
    0x222, 0x222,
    0x224, 0x224,
    0x226, 0x226,
    0x228, 0x228,
    0x22A, 0x22A,
    0x22C, 0x22C,
    0x22E, 0x22E,
    0x230, 0x230,
    0x232, 0x232,
    0x23A, 0x23B,
    0x23D, 0x23E,
    0x241, 0x241,
    0x243, 0x246,
    0x248, 0x248,
    0x24A, 0x24A,
    0x24C, 0x24C,
    0x24E, 0x24E,
    0x370, 0x370,
    0x372, 0x372,
    0x376, 0x376,
    0x37F, 0x37F,
    0x386, 0x386,
    0x388, 0x38A,
    0x38C, 0x38C,
    0x38E, 0x38F,
    0x391, 0x3A1,
    0x3A3, 0x3AB,
    0x3CF, 0x3CF,
    0x3D2, 0x3D4,
    0x3D8, 0x3D8,
    0x3DA, 0x3DA,
    0x3DC, 0x3DC,
    0x3DE, 0x3DE,
    0x3E0, 0x3E0,
    0x3E2, 0x3E2,
    0x3E4, 0x3E4,
    0x3E6, 0x3E6,
    0x3E8, 0x3E8,
    0x3EA, 0x3EA,
    0x3EC, 0x3EC,
    0x3EE, 0x3EE,
    0x3F4, 0x3F4,
    0x3F7, 0x3F7,
    0x3F9, 0x3FA,
    0x3FD, 0x42F,
    0x460, 0x460,
    0x462, 0x462,
    0x464, 0x464,
    0x466, 0x466,
    0x468, 0x468,
    0x46A, 0x46A,
    0x46C, 0x46C,
    0x46E, 0x46E,
    0x470, 0x470,
    0x472, 0x472,
    0x474, 0x474,
    0x476, 0x476,
    0x478, 0x478,
    0x47A, 0x47A,
    0x47C, 0x47C,
    0x47E, 0x47E,
    0x480, 0x480,
    0x48A, 0x48A,
    0x48C, 0x48C,
    0x48E, 0x48E,
    0x490, 0x490,
    0x492, 0x492,
    0x494, 0x494,
    0x496, 0x496,
    0x498, 0x498,
    0x49A, 0x49A,
    0x49C, 0x49C,
    0x49E, 0x49E,
    0x4A0, 0x4A0,
    0x4A2, 0x4A2,
    0x4A4, 0x4A4,
    0x4A6, 0x4A6,
    0x4A8, 0x4A8,
    0x4AA, 0x4AA,
    0x4AC, 0x4AC,
    0x4AE, 0x4AE,
    0x4B0, 0x4B0,
    0x4B2, 0x4B2,
    0x4B4, 0x4B4,
    0x4B6, 0x4B6,
    0x4B8, 0x4B8,
    0x4BA, 0x4BA,
    0x4BC, 0x4BC,
    0x4BE, 0x4BE,
    0x4C0, 0x4C1,
    0x4C3, 0x4C3,
    0x4C5, 0x4C5,
    0x4C7, 0x4C7,
    0x4C9, 0x4C9,
    0x4CB, 0x4CB,
    0x4CD, 0x4CD,
    0x4D0, 0x4D0,
    0x4D2, 0x4D2,
    0x4D4, 0x4D4,
    0x4D6, 0x4D6,
    0x4D8, 0x4D8,
    0x4DA, 0x4DA,
    0x4DC, 0x4DC,
    0x4DE, 0x4DE,
    0x4E0, 0x4E0,
    0x4E2, 0x4E2,
    0x4E4, 0x4E4,
    0x4E6, 0x4E6,
    0x4E8, 0x4E8,
    0x4EA, 0x4EA,
    0x4EC, 0x4EC,
    0x4EE, 0x4EE,
    0x4F0, 0x4F0,
    0x4F2, 0x4F2,
    0x4F4, 0x4F4,
    0x4F6, 0x4F6,
    0x4F8, 0x4F8,
    0x4FA, 0x4FA,
    0x4FC, 0x4FC,
    0x4FE, 0x4FE,
    0x500, 0x500,
    0x502, 0x502,
    0x504, 0x504,
    0x506, 0x506,
    0x508, 0x508,
    0x50A, 0x50A,
    0x50C, 0x50C,
    0x50E, 0x50E,
    0x510, 0x510,
    0x512, 0x512,
    0x514, 0x514,
    0x516, 0x516,
    0x518, 0x518,
    0x51A, 0x51A,
    0x51C, 0x51C,
    0x51E, 0x51E,
    0x520, 0x520,
    0x522, 0x522,
    0x524, 0x524,
    0x526, 0x526,
    0x528, 0x528,
    0x52A, 0x52A,
    0x52C, 0x52C,
    0x52E, 0x52E,
    0x531, 0x556,
    0x10A0, 0x10C5,
    0x10C7, 0x10C7,
    0x10CD, 0x10CD,
    0x13A0, 0x13F5,
    0x1C90, 0x1CBA,
    0x1CBD, 0x1CBF,
    0x1E00, 0x1E00,
    0x1E02, 0x1E02,
    0x1E04, 0x1E04,
    0x1E06, 0x1E06,
    0x1E08, 0x1E08,
    0x1E0A, 0x1E0A,
    0x1E0C, 0x1E0C,
    0x1E0E, 0x1E0E,
    0x1E10, 0x1E10,
    0x1E12, 0x1E12,
    0x1E14, 0x1E14,
    0x1E16, 0x1E16,
    0x1E18, 0x1E18,
    0x1E1A, 0x1E1A,
    0x1E1C, 0x1E1C,
    0x1E1E, 0x1E1E,
    0x1E20, 0x1E20,
    0x1E22, 0x1E22,
    0x1E24, 0x1E24,
    0x1E26, 0x1E26,
    0x1E28, 0x1E28,
    0x1E2A, 0x1E2A,
    0x1E2C, 0x1E2C,
    0x1E2E, 0x1E2E,
    0x1E30, 0x1E30,
    0x1E32, 0x1E32,
    0x1E34, 0x1E34,
    0x1E36, 0x1E36,
    0x1E38, 0x1E38,
    0x1E3A, 0x1E3A,
    0x1E3C, 0x1E3C,
    0x1E3E, 0x1E3E,
    0x1E40, 0x1E40,
    0x1E42, 0x1E42,
    0x1E44, 0x1E44,
    0x1E46, 0x1E46,
    0x1E48, 0x1E48,
    0x1E4A, 0x1E4A,
    0x1E4C, 0x1E4C,
    0x1E4E, 0x1E4E,
    0x1E50, 0x1E50,
    0x1E52, 0x1E52,
    0x1E54, 0x1E54,
    0x1E56, 0x1E56,
    0x1E58, 0x1E58,
    0x1E5A, 0x1E5A,
    0x1E5C, 0x1E5C,
    0x1E5E, 0x1E5E,
    0x1E60, 0x1E60,
    0x1E62, 0x1E62,
    0x1E64, 0x1E64,
    0x1E66, 0x1E66,
    0x1E68, 0x1E68,
    0x1E6A, 0x1E6A,
    0x1E6C, 0x1E6C,
    0x1E6E, 0x1E6E,
    0x1E70, 0x1E70,
    0x1E72, 0x1E72,
    0x1E74, 0x1E74,
    0x1E76, 0x1E76,
    0x1E78, 0x1E78,
    0x1E7A, 0x1E7A,
    0x1E7C, 0x1E7C,
    0x1E7E, 0x1E7E,
    0x1E80, 0x1E80,
    0x1E82, 0x1E82,
    0x1E84, 0x1E84,
    0x1E86, 0x1E86,
    0x1E88, 0x1E88,
    0x1E8A, 0x1E8A,
    0x1E8C, 0x1E8C,
    0x1E8E, 0x1E8E,
    0x1E90, 0x1E90,
    0x1E92, 0x1E92,
    0x1E94, 0x1E94,
    0x1E9E, 0x1E9E,
    0x1EA0, 0x1EA0,
    0x1EA2, 0x1EA2,
    0x1EA4, 0x1EA4,
    0x1EA6, 0x1EA6,
    0x1EA8, 0x1EA8,
    0x1EAA, 0x1EAA,
    0x1EAC, 0x1EAC,
    0x1EAE, 0x1EAE,
    0x1EB0, 0x1EB0,
    0x1EB2, 0x1EB2,
    0x1EB4, 0x1EB4,
    0x1EB6, 0x1EB6,
    0x1EB8, 0x1EB8,
    0x1EBA, 0x1EBA,
    0x1EBC, 0x1EBC,
    0x1EBE, 0x1EBE,
    0x1EC0, 0x1EC0,
    0x1EC2, 0x1EC2,
    0x1EC4, 0x1EC4,
    0x1EC6, 0x1EC6,
    0x1EC8, 0x1EC8,
    0x1ECA, 0x1ECA,
    0x1ECC, 0x1ECC,
    0x1ECE, 0x1ECE,
    0x1ED0, 0x1ED0,
    0x1ED2, 0x1ED2,
    0x1ED4, 0x1ED4,
    0x1ED6, 0x1ED6,
    0x1ED8, 0x1ED8,
    0x1EDA, 0x1EDA,
    0x1EDC, 0x1EDC,
    0x1EDE, 0x1EDE,
    0x1EE0, 0x1EE0,
    0x1EE2, 0x1EE2,
    0x1EE4, 0x1EE4,
    0x1EE6, 0x1EE6,
    0x1EE8, 0x1EE8,
    0x1EEA, 0x1EEA,
    0x1EEC, 0x1EEC,
    0x1EEE, 0x1EEE,
    0x1EF0, 0x1EF0,
    0x1EF2, 0x1EF2,
    0x1EF4, 0x1EF4,
    0x1EF6, 0x1EF6,
    0x1EF8, 0x1EF8,
    0x1EFA, 0x1EFA,
    0x1EFC, 0x1EFC,
    0x1EFE, 0x1EFE,
    0x1F08, 0x1F0F,
    0x1F18, 0x1F1D,
    0x1F28, 0x1F2F,
    0x1F38, 0x1F3F,
    0x1F48, 0x1F4D,
    0x1F59, 0x1F59,
    0x1F5B, 0x1F5B,
    0x1F5D, 0x1F5D,
    0x1F5F, 0x1F5F,
    0x1F68, 0x1F6F,
    0x1F88, 0x1F8F,
    0x1F98, 0x1F9F,
    0x1FA8, 0x1FAF,
    0x1FB8, 0x1FBC,
    0x1FC8, 0x1FCC,
    0x1FD8, 0x1FDB,
    0x1FE8, 0x1FEC,
    0x1FF8, 0x1FFC,
    0x2102, 0x2102,
    0x2107, 0x2107,
    0x210B, 0x210D,
    0x2110, 0x2112,
    0x2115, 0x2115,
    0x2119, 0x211D,
    0x2124, 0x2124,
    0x2126, 0x2126,
    0x2128, 0x2128,
    0x212A, 0x212D,
    0x2130, 0x2133,
    0x213E, 0x213F,
    0x2145, 0x2145,
    0x2160, 0x216F,
    0x2183, 0x2183,
    0x24B6, 0x24CF,
    0x2C00, 0x2C2F,
    0x2C60, 0x2C60,
    0x2C62, 0x2C64,
    0x2C67, 0x2C67,
    0x2C69, 0x2C69,
    0x2C6B, 0x2C6B,
    0x2C6D, 0x2C70,
    0x2C72, 0x2C72,
    0x2C75, 0x2C75,
    0x2C7E, 0x2C80,
    0x2C82, 0x2C82,
    0x2C84, 0x2C84,
    0x2C86, 0x2C86,
    0x2C88, 0x2C88,
    0x2C8A, 0x2C8A,
    0x2C8C, 0x2C8C,
    0x2C8E, 0x2C8E,
    0x2C90, 0x2C90,
    0x2C92, 0x2C92,
    0x2C94, 0x2C94,
    0x2C96, 0x2C96,
    0x2C98, 0x2C98,
    0x2C9A, 0x2C9A,
    0x2C9C, 0x2C9C,
    0x2C9E, 0x2C9E,
    0x2CA0, 0x2CA0,
    0x2CA2, 0x2CA2,
    0x2CA4, 0x2CA4,
    0x2CA6, 0x2CA6,
    0x2CA8, 0x2CA8,
    0x2CAA, 0x2CAA,
    0x2CAC, 0x2CAC,
    0x2CAE, 0x2CAE,
    0x2CB0, 0x2CB0,
    0x2CB2, 0x2CB2,
    0x2CB4, 0x2CB4,
    0x2CB6, 0x2CB6,
    0x2CB8, 0x2CB8,
    0x2CBA, 0x2CBA,
    0x2CBC, 0x2CBC,
    0x2CBE, 0x2CBE,
    0x2CC0, 0x2CC0,
    0x2CC2, 0x2CC2,
    0x2CC4, 0x2CC4,
    0x2CC6, 0x2CC6,
    0x2CC8, 0x2CC8,
    0x2CCA, 0x2CCA,
    0x2CCC, 0x2CCC,
    0x2CCE, 0x2CCE,
    0x2CD0, 0x2CD0,
    0x2CD2, 0x2CD2,
    0x2CD4, 0x2CD4,
    0x2CD6, 0x2CD6,
    0x2CD8, 0x2CD8,
    0x2CDA, 0x2CDA,
    0x2CDC, 0x2CDC,
    0x2CDE, 0x2CDE,
    0x2CE0, 0x2CE0,
    0x2CE2, 0x2CE2,
    0x2CEB, 0x2CEB,
    0x2CED, 0x2CED,
    0x2CF2, 0x2CF2,
    0xA640, 0xA640,
    0xA642, 0xA642,
    0xA644, 0xA644,
    0xA646, 0xA646,
    0xA648, 0xA648,
    0xA64A, 0xA64A,
    0xA64C, 0xA64C,
    0xA64E, 0xA64E,
    0xA650, 0xA650,
    0xA652, 0xA652,
    0xA654, 0xA654,
    0xA656, 0xA656,
    0xA658, 0xA658,
    0xA65A, 0xA65A,
    0xA65C, 0xA65C,
    0xA65E, 0xA65E,
    0xA660, 0xA660,
    0xA662, 0xA662,
    0xA664, 0xA664,
    0xA666, 0xA666,
    0xA668, 0xA668,
    0xA66A, 0xA66A,
    0xA66C, 0xA66C,
    0xA680, 0xA680,
    0xA682, 0xA682,
    0xA684, 0xA684,
    0xA686, 0xA686,
    0xA688, 0xA688,
    0xA68A, 0xA68A,
    0xA68C, 0xA68C,
    0xA68E, 0xA68E,
    0xA690, 0xA690,
    0xA692, 0xA692,
    0xA694, 0xA694,
    0xA696, 0xA696,
    0xA698, 0xA698,
    0xA69A, 0xA69A,
    0xA722, 0xA722,
    0xA724, 0xA724,
    0xA726, 0xA726,
    0xA728, 0xA728,
    0xA72A, 0xA72A,
    0xA72C, 0xA72C,
    0xA72E, 0xA72E,
    0xA732, 0xA732,
    0xA734, 0xA734,
    0xA736, 0xA736,
    0xA738, 0xA738,
    0xA73A, 0xA73A,
    0xA73C, 0xA73C,
    0xA73E, 0xA73E,
    0xA740, 0xA740,
    0xA742, 0xA742,
    0xA744, 0xA744,
    0xA746, 0xA746,
    0xA748, 0xA748,
    0xA74A, 0xA74A,
    0xA74C, 0xA74C,
    0xA74E, 0xA74E,
    0xA750, 0xA750,
    0xA752, 0xA752,
    0xA754, 0xA754,
    0xA756, 0xA756,
    0xA758, 0xA758,
    0xA75A, 0xA75A,
    0xA75C, 0xA75C,
    0xA75E, 0xA75E,
    0xA760, 0xA760,
    0xA762, 0xA762,
    0xA764, 0xA764,
    0xA766, 0xA766,
    0xA768, 0xA768,
    0xA76A, 0xA76A,
    0xA76C, 0xA76C,
    0xA76E, 0xA76E,
    0xA779, 0xA779,
    0xA77B, 0xA77B,
    0xA77D, 0xA77E,
    0xA780, 0xA780,
    0xA782, 0xA782,
    0xA784, 0xA784,
    0xA786, 0xA786,
    0xA78B, 0xA78B,
    0xA78D, 0xA78D,
    0xA790, 0xA790,
    0xA792, 0xA792,
    0xA796, 0xA796,
    0xA798, 0xA798,
    0xA79A, 0xA79A,
    0xA79C, 0xA79C,
    0xA79E, 0xA79E,
    0xA7A0, 0xA7A0,
    0xA7A2, 0xA7A2,
    0xA7A4, 0xA7A4,
    0xA7A6, 0xA7A6,
    0xA7A8, 0xA7A8,
    0xA7AA, 0xA7AE,
    0xA7B0, 0xA7B4,
    0xA7B6, 0xA7B6,
    0xA7B8, 0xA7B8,
    0xA7BA, 0xA7BA,
    0xA7BC, 0xA7BC,
    0xA7BE, 0xA7BE,
    0xA7C0, 0xA7C0,
    0xA7C2, 0xA7C2,
    0xA7C4, 0xA7C7,
    0xA7C9, 0xA7C9,
    0xA7D0, 0xA7D0,
    0xA7D6, 0xA7D6,
    0xA7D8, 0xA7D8,
    0xA7F5, 0xA7F5,
    0xFF21, 0xFF3A,
    0x10400, 0x10427,
    0x104B0, 0x104D3,
    0x10570, 0x1057A,
    0x1057C, 0x1058A,
    0x1058C, 0x10592,
    0x10594, 0x10595,
    0x10C80, 0x10CB2,
    0x118A0, 0x118BF,
    0x16E40, 0x16E5F,
    0x1D400, 0x1D419,
    0x1D434, 0x1D44D,
    0x1D468, 0x1D481,
    0x1D49C, 0x1D49C,
    0x1D49E, 0x1D49F,
    0x1D4A2, 0x1D4A2,
    0x1D4A5, 0x1D4A6,
    0x1D4A9, 0x1D4AC,
    0x1D4AE, 0x1D4B5,
    0x1D4D0, 0x1D4E9,
    0x1D504, 0x1D505,
    0x1D507, 0x1D50A,
    0x1D50D, 0x1D514,
    0x1D516, 0x1D51C,
    0x1D538, 0x1D539,
    0x1D53B, 0x1D53E,
    0x1D540, 0x1D544,
    0x1D546, 0x1D546,
    0x1D54A, 0x1D550,
    0x1D56C, 0x1D585,
    0x1D5A0, 0x1D5B9,
    0x1D5D4, 0x1D5ED,
    0x1D608, 0x1D621,
    0x1D63C, 0x1D655,
    0x1D670, 0x1D689,
    0x1D6A8, 0x1D6C0,
    0x1D6E2, 0x1D6FA,
    0x1D71C, 0x1D734,
    0x1D756, 0x1D76E,
    0x1D790, 0x1D7A8,
    0x1D7CA, 0x1D7CA,
    0x1E900, 0x1E921,
    0x1F130, 0x1F149,
    0x1F150, 0x1F169,
    0x1F170, 0x1F189,
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding unicode codepoint. Note that
 * this table is different from other encodings where we used a lookup table
 * because the indices of those tables are the byte representations, not the
 * codepoints themselves.
 */
const uint8_t pm_encoding_unicode_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 3, // Fx
};

/**
 * Binary search through the given list of codepoints to see if the given
 * codepoint is in the list.
 */
static bool
pm_unicode_codepoint_match(pm_unicode_codepoint_t codepoint, const pm_unicode_codepoint_t *codepoints, size_t size) {
    size_t start = 0;
    size_t end = size;

    while (start < end) {
        size_t middle = start + (end - start) / 2;
        if ((middle % 2) != 0) middle--;

        if (codepoint >= codepoints[middle] && codepoint <= codepoints[middle + 1]) {
            return true;
        }

        if (codepoint < codepoints[middle]) {
            end = middle;
        } else {
            start = middle + 2;
        }
    }

    return false;
}

/**
 * A state transition table for decoding UTF-8.
 *
 * Copyright (c) 2008-2009 Bjoern Hoehrmann <bjoern@hoehrmann.de>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
static const uint8_t pm_utf_8_dfa[] = {
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 00..1f
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 20..3f
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 40..5f
    0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, // 60..7f
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9, // 80..9f
    7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7, // a0..bf
    8,8,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, // c0..df
    0xa,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x3,0x4,0x3,0x3, // e0..ef
    0xb,0x6,0x6,0x6,0x5,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8,0x8, // f0..ff
    0x0,0x1,0x2,0x3,0x5,0x8,0x7,0x1,0x1,0x1,0x4,0x6,0x1,0x1,0x1,0x1, // s0..s0
    1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1, // s1..s2
    1,2,1,1,1,1,1,2,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1, // s3..s4
    1,2,1,1,1,1,1,1,1,2,1,1,1,1,1,1,1,1,1,1,1,1,1,3,1,3,1,1,1,1,1,1, // s5..s6
    1,3,1,1,1,1,1,3,1,3,1,1,1,1,1,1,1,3,1,1,1,1,1,1,1,1,1,1,1,1,1,1, // s7..s8
};

/**
 * Given a pointer to a string and the number of bytes remaining in the string,
 * decode the next UTF-8 codepoint and return it. The number of bytes consumed
 * is returned in the width out parameter.
 */
static pm_unicode_codepoint_t
pm_utf_8_codepoint(const uint8_t *b, ptrdiff_t n, size_t *width) {
    assert(n >= 0);

    size_t maximum = (n > 4) ? 4 : ((size_t) n);
    uint32_t codepoint;
    uint32_t state = 0;

    for (size_t index = 0; index < maximum; index++) {
        uint32_t byte = b[index];
        uint32_t type = pm_utf_8_dfa[byte];

        codepoint = (state != 0) ?
            (byte & 0x3fu) | (codepoint << 6) :
            (0xffu >> type) & (byte);

        state = pm_utf_8_dfa[256 + (state * 16) + type];
        if (state == 0) {
            *width = index + 1;
            return (pm_unicode_codepoint_t) codepoint;
        }
    }

    *width = 0;
    return 0;
}

/**
 * Return the size of the next character in the UTF-8 encoding.
 */
size_t
pm_encoding_utf_8_char_width(const uint8_t *b, ptrdiff_t n) {
    assert(n >= 0);

    size_t maximum = (n > 4) ? 4 : ((size_t) n);
    uint32_t state = 0;

    for (size_t index = 0; index < maximum; index++) {
        state = pm_utf_8_dfa[256 + (state * 16) + pm_utf_8_dfa[b[index]]];
        if (state == 0) return index + 1;
    }

    return 0;
}

/**
 * Return the size of the next character in the UTF-8 encoding if it is an
 * alphabetical character.
 */
size_t
pm_encoding_utf_8_alpha_char(const uint8_t *b, ptrdiff_t n) {
    if (*b < 0x80) {
        return (pm_encoding_unicode_table[*b] & PRISM_ENCODING_ALPHABETIC_BIT) ? 1 : 0;
    }

    size_t width;
    pm_unicode_codepoint_t codepoint = pm_utf_8_codepoint(b, n, &width);

    if (codepoint <= 0xFF) {
        return (pm_encoding_unicode_table[(uint8_t) codepoint] & PRISM_ENCODING_ALPHABETIC_BIT) ? width : 0;
    } else {
        return pm_unicode_codepoint_match(codepoint, unicode_alpha_codepoints, UNICODE_ALPHA_CODEPOINTS_LENGTH) ? width : 0;
    }
}

/**
 * Return the size of the next character in the UTF-8 encoding if it is an
 * alphanumeric character.
 */
size_t
pm_encoding_utf_8_alnum_char(const uint8_t *b, ptrdiff_t n) {
    if (*b < 0x80) {
        return (pm_encoding_unicode_table[*b] & (PRISM_ENCODING_ALPHANUMERIC_BIT)) ? 1 : 0;
    }

    size_t width;
    pm_unicode_codepoint_t codepoint = pm_utf_8_codepoint(b, n, &width);

    if (codepoint <= 0xFF) {
        return (pm_encoding_unicode_table[(uint8_t) codepoint] & (PRISM_ENCODING_ALPHANUMERIC_BIT)) ? width : 0;
    } else {
        return pm_unicode_codepoint_match(codepoint, unicode_alnum_codepoints, UNICODE_ALNUM_CODEPOINTS_LENGTH) ? width : 0;
    }
}

/**
 * Return true if the next character in the UTF-8 encoding if it is an uppercase
 * character.
 */
bool
pm_encoding_utf_8_isupper_char(const uint8_t *b, ptrdiff_t n) {
    if (*b < 0x80) {
        return (pm_encoding_unicode_table[*b] & PRISM_ENCODING_UPPERCASE_BIT) ? true : false;
    }

    size_t width;
    pm_unicode_codepoint_t codepoint = pm_utf_8_codepoint(b, n, &width);

    if (codepoint <= 0xFF) {
        return (pm_encoding_unicode_table[(uint8_t) codepoint] & PRISM_ENCODING_UPPERCASE_BIT) ? true : false;
    } else {
        return pm_unicode_codepoint_match(codepoint, unicode_isupper_codepoints, UNICODE_ISUPPER_CODEPOINTS_LENGTH) ? true : false;
    }
}

#ifndef PRISM_ENCODING_EXCLUDE_FULL

static pm_unicode_codepoint_t
pm_cesu_8_codepoint(const uint8_t *b, ptrdiff_t n, size_t *width) {
    if (b[0] < 0x80) {
        *width = 1;
        return (pm_unicode_codepoint_t) b[0];
    }

    if (n > 1 && b[0] >= 0xC2 && b[0] <= 0xDF && b[1] >= 0x80 && b[1] <= 0xBF) {
        *width = 2;

        // 110xxxxx 10xxxxxx
        return (pm_unicode_codepoint_t) (((b[0] & 0x1F) << 6) | (b[1] & 0x3F));
    }

    if (n > 5 && b[0] == 0xED && b[1] >= 0xA0 && b[1] <= 0xAF && b[2] >= 0x80 && b[2] <= 0xBF && b[3] == 0xED && b[4] >= 0xB0 && b[4] <= 0xBF && b[5] >= 0x80 && b[5] <= 0xBF) {
        *width = 6;

        // 11101101 1010xxxx 10xxxxxx 11101101 1011xxxx 10xxxxxx
        return (pm_unicode_codepoint_t) (0x10000 + (((b[1] & 0xF) << 16) | ((b[2] & 0x3F) << 10) | ((b[4] & 0xF) << 6) | (b[5] & 0x3F)));
    }

    if (n > 2 && b[0] == 0xED && b[1] >= 0xA0 && b[1] <= 0xBF) {
        *width = 3;

        // 11101101 1010xxxx 10xxxxx
        return (pm_unicode_codepoint_t) (0x10000 + (((b[0] & 0x03) << 16) | ((b[1] & 0x3F) << 10) | (b[2] & 0x3F)));
    }

    if (n > 2 && ((b[0] == 0xE0 && b[1] >= 0xA0) || (b[0] >= 0xE1 && b[0] <= 0xEF && b[1] >= 0x80)) && b[1] <= 0xBF && b[2] >= 0x80 && b[2] <= 0xBF) {
        *width = 3;

        // 1110xxxx 10xxxxxx 10xxxxx
        return (pm_unicode_codepoint_t) (((b[0] & 0xF) << 12) | ((b[1] & 0x3F) << 6) | (b[2] & 0x3F));
    }

    *width = 0;
    return 0;
}

static size_t
pm_encoding_cesu_8_char_width(const uint8_t *b, ptrdiff_t n) {
    size_t width;
    pm_cesu_8_codepoint(b, n, &width);
    return width;
}

static size_t
pm_encoding_cesu_8_alpha_char(const uint8_t *b, ptrdiff_t n) {
    if (*b < 0x80) {
        return (pm_encoding_unicode_table[*b] & PRISM_ENCODING_ALPHABETIC_BIT) ? 1 : 0;
    }

    size_t width;
    pm_unicode_codepoint_t codepoint = pm_cesu_8_codepoint(b, n, &width);

    if (codepoint <= 0xFF) {
        return (pm_encoding_unicode_table[(uint8_t) codepoint] & PRISM_ENCODING_ALPHABETIC_BIT) ? width : 0;
    } else {
        return pm_unicode_codepoint_match(codepoint, unicode_alpha_codepoints, UNICODE_ALPHA_CODEPOINTS_LENGTH) ? width : 0;
    }
}

static size_t
pm_encoding_cesu_8_alnum_char(const uint8_t *b, ptrdiff_t n) {
    if (*b < 0x80) {
        return (pm_encoding_unicode_table[*b] & (PRISM_ENCODING_ALPHANUMERIC_BIT)) ? 1 : 0;
    }

    size_t width;
    pm_unicode_codepoint_t codepoint = pm_cesu_8_codepoint(b, n, &width);

    if (codepoint <= 0xFF) {
        return (pm_encoding_unicode_table[(uint8_t) codepoint] & (PRISM_ENCODING_ALPHANUMERIC_BIT)) ? width : 0;
    } else {
        return pm_unicode_codepoint_match(codepoint, unicode_alnum_codepoints, UNICODE_ALNUM_CODEPOINTS_LENGTH) ? width : 0;
    }
}

static bool
pm_encoding_cesu_8_isupper_char(const uint8_t *b, ptrdiff_t n) {
    if (*b < 0x80) {
        return (pm_encoding_unicode_table[*b] & PRISM_ENCODING_UPPERCASE_BIT) ? true : false;
    }

    size_t width;
    pm_unicode_codepoint_t codepoint = pm_cesu_8_codepoint(b, n, &width);

    if (codepoint <= 0xFF) {
        return (pm_encoding_unicode_table[(uint8_t) codepoint] & PRISM_ENCODING_UPPERCASE_BIT) ? true : false;
    } else {
        return pm_unicode_codepoint_match(codepoint, unicode_isupper_codepoints, UNICODE_ISUPPER_CODEPOINTS_LENGTH) ? true : false;
    }
}

#endif

#undef UNICODE_ALPHA_CODEPOINTS_LENGTH
#undef UNICODE_ALNUM_CODEPOINTS_LENGTH
#undef UNICODE_ISUPPER_CODEPOINTS_LENGTH

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding US-ASCII character.
 */
static const uint8_t pm_encoding_ascii_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

#ifndef PRISM_ENCODING_EXCLUDE_FULL

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding CP850 character.
 */
static const uint8_t pm_encoding_cp850_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding CP852 character.
 */
static const uint8_t pm_encoding_cp852_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding CP855 character.
 */
static const uint8_t pm_encoding_cp855_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding GB1988 character.
 */
static const uint8_t pm_encoding_gb1988_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM437 character.
 */
static const uint8_t pm_encoding_ibm437_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM720 character.
 */
static const uint8_t pm_encoding_ibm720_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM737 character.
 */
static const uint8_t pm_encoding_ibm737_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM775 character.
 */
static const uint8_t pm_encoding_ibm775_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM852 character.
 */
static const uint8_t pm_encoding_ibm852_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM855 character.
 */
static const uint8_t pm_encoding_ibm855_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM857 character.
 */
static const uint8_t pm_encoding_ibm857_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM860 character.
 */
static const uint8_t pm_encoding_ibm860_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM861 character.
 */
static const uint8_t pm_encoding_ibm861_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM862 character.
 */
static const uint8_t pm_encoding_ibm862_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM863 character.
 */
static const uint8_t pm_encoding_ibm863_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM864 character.
 */
static const uint8_t pm_encoding_ibm864_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM865 character.
 */
static const uint8_t pm_encoding_ibm865_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM866 character.
 */
static const uint8_t pm_encoding_ibm866_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding IBM869 character.
 */
static const uint8_t pm_encoding_ibm869_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-1 character.
 */
static const uint8_t pm_encoding_iso_8859_1_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 3, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-2 character.
 */
static const uint8_t pm_encoding_iso_8859_2_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 7, 0, 7, 0, 7, 7, 0, 0, 7, 7, 7, 7, 0, 7, 7, // Ax
    0, 3, 0, 3, 0, 3, 3, 0, 0, 3, 3, 3, 3, 0, 3, 3, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-3 character.
 */
static const uint8_t pm_encoding_iso_8859_3_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 7, 0, 0, 0, 0, 7, 0, 0, 7, 7, 7, 7, 0, 0, 7, // Ax
    0, 3, 0, 0, 0, 3, 3, 0, 0, 3, 3, 3, 3, 0, 0, 3, // Bx
    7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    0, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    0, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-4 character.
 */
static const uint8_t pm_encoding_iso_8859_4_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 7, 3, 7, 0, 7, 7, 0, 0, 7, 7, 7, 7, 0, 7, 0, // Ax
    0, 3, 0, 3, 0, 3, 3, 0, 0, 3, 3, 3, 3, 7, 3, 3, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-5 character.
 */
static const uint8_t pm_encoding_iso_8859_5_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 7, 7, // Ax
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 3, 3, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-6 character.
 */
static const uint8_t pm_encoding_iso_8859_6_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Cx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-7 character.
 */
static const uint8_t pm_encoding_iso_8859_7_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 7, 0, 7, 7, 7, 0, 7, 0, 7, 7, // Bx
    3, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, 3, 3, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-8 character.
 */
static const uint8_t pm_encoding_iso_8859_8_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-9 character.
 */
static const uint8_t pm_encoding_iso_8859_9_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 3, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-10 character.
 */
static const uint8_t pm_encoding_iso_8859_10_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 0, 7, 7, // Ax
    0, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 0, 3, 3, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-11 character.
 */
static const uint8_t pm_encoding_iso_8859_11_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ax
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Bx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Cx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-13 character.
 */
static const uint8_t pm_encoding_iso_8859_13_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 7, 0, 0, 0, 0, 7, // Ax
    0, 0, 0, 0, 0, 3, 0, 0, 3, 0, 3, 0, 0, 0, 0, 3, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-14 character.
 */
static const uint8_t pm_encoding_iso_8859_14_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 7, 3, 0, 7, 3, 7, 0, 7, 0, 7, 3, 7, 0, 0, 7, // Ax
    7, 3, 7, 3, 7, 3, 0, 7, 3, 3, 3, 7, 3, 7, 3, 3, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-15 character.
 */
static const uint8_t pm_encoding_iso_8859_15_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 7, 0, 3, 0, 3, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 7, 3, 0, 0, 3, 0, 3, 0, 7, 3, 7, 0, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 3, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding ISO-8859-16 character.
 */
static const uint8_t pm_encoding_iso_8859_16_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 7, 3, 7, 0, 0, 7, 0, 3, 0, 7, 0, 7, 0, 3, 7, // Ax
    0, 0, 7, 3, 7, 0, 0, 0, 3, 3, 3, 0, 7, 3, 7, 3, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding KOI8-R character.
 */
static const uint8_t pm_encoding_koi8_r_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Cx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Dx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Ex
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding KOI8-U character.
 */
static const uint8_t pm_encoding_koi8_u_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 3, 3, 0, 3, 3, 0, 0, 0, 0, 0, 3, 0, 0, // Ax
    0, 0, 0, 7, 7, 0, 7, 7, 0, 0, 0, 0, 0, 7, 0, 0, // Bx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Cx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Dx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Ex
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding macCentEuro character.
 */
static const uint8_t pm_encoding_mac_cent_euro_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding macCroatian character.
 */
static const uint8_t pm_encoding_mac_croatian_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

 /**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding macCyrillic character.
 */
static const uint8_t pm_encoding_mac_cyrillic_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding macGreek character.
 */
static const uint8_t pm_encoding_mac_greek_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding macIceland character.
 */
static const uint8_t pm_encoding_mac_iceland_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding macRoman character.
 */
static const uint8_t pm_encoding_mac_roman_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding macRomania character.
 */
static const uint8_t pm_encoding_mac_romania_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding macThai character.
 */
static const uint8_t pm_encoding_mac_thai_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding TIS-620 character.
 */
static const uint8_t pm_encoding_tis_620_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ax
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Bx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Cx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding macTurkish character.
 */
static const uint8_t pm_encoding_mac_turkish_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding macUkraine character.
 */
static const uint8_t pm_encoding_mac_ukraine_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding windows-1250 character.
 */
static const uint8_t pm_encoding_windows_1250_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 7, 7, 7, 7, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 3, 3, 3, 3, // 9x
    0, 0, 0, 7, 0, 7, 0, 0, 0, 0, 7, 0, 0, 0, 0, 7, // Ax
    0, 0, 0, 3, 0, 3, 0, 0, 0, 3, 3, 0, 7, 0, 3, 3, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding windows-1251 character.
 */
static const uint8_t pm_encoding_windows_1251_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    7, 7, 0, 3, 0, 0, 0, 0, 0, 0, 7, 0, 7, 7, 7, 7, // 8x
    3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 3, 3, 3, 3, // 9x
    0, 7, 3, 7, 0, 7, 0, 0, 7, 0, 7, 0, 0, 0, 0, 7, // Ax
    0, 0, 7, 3, 3, 3, 0, 0, 3, 0, 3, 0, 3, 7, 3, 3, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding windows-1252 character.
 */
static const uint8_t pm_encoding_windows_1252_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 7, 0, 7, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 3, 0, 3, 7, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 3, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding windows-1253 character.
 */
static const uint8_t pm_encoding_windows_1253_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 3, 7, 0, 7, 7, 7, 0, 7, 0, 7, 7, // Bx
    3, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 3, 3, 3, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding windows-1254 character.
 */
static const uint8_t pm_encoding_windows_1254_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 7, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 3, 0, 0, 7, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 3, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding windows-1255 character.
 */
static const uint8_t pm_encoding_windows_1255_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding windows-1256 character.
 */
static const uint8_t pm_encoding_windows_1256_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Cx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding windows-1257 character.
 */
static const uint8_t pm_encoding_windows_1257_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 7, 0, 7, 0, 0, 0, 0, 7, // Ax
    0, 0, 0, 0, 0, 3, 0, 0, 3, 0, 3, 0, 0, 0, 0, 3, // Bx
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // Cx
    7, 7, 7, 7, 7, 7, 7, 0, 7, 7, 7, 7, 7, 7, 7, 3, // Dx
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // Ex
    3, 3, 3, 3, 3, 3, 3, 0, 3, 3, 3, 3, 3, 3, 3, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding windows-1258 character.
 */
static const uint8_t pm_encoding_windows_1258_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

/**
 * Each element of the following table contains a bitfield that indicates a
 * piece of information about the corresponding windows-874 character.
 */
static const uint8_t pm_encoding_windows_874_table[256] = {
//  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 0x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 1x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 2x
    2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 0, 0, 0, 0, 0, 0, // 3x
    0, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, // 4x
    7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 0, 0, 0, 0, 0, // 5x
    0, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, // 6x
    3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 0, 0, 0, 0, 0, // 7x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 8x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // 9x
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ax
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Bx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Cx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Dx
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Ex
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, // Fx
};

#define PRISM_ENCODING_TABLE(name) \
    static size_t pm_encoding_ ##name ## _alpha_char(const uint8_t *b, PRISM_ATTRIBUTE_UNUSED ptrdiff_t n) {           \
        return (pm_encoding_ ##name ## _table[*b] & PRISM_ENCODING_ALPHABETIC_BIT);           \
    }                                                                                                         \
    static size_t pm_encoding_ ##name ## _alnum_char(const uint8_t *b, PRISM_ATTRIBUTE_UNUSED ptrdiff_t n) {           \
        return (pm_encoding_ ##name ## _table[*b] & PRISM_ENCODING_ALPHANUMERIC_BIT) ? 1 : 0; \
    }                                                                                                         \
    static bool pm_encoding_ ##name ## _isupper_char(const uint8_t *b, PRISM_ATTRIBUTE_UNUSED ptrdiff_t n) {           \
        return (pm_encoding_ ##name ## _table[*b] & PRISM_ENCODING_UPPERCASE_BIT);            \
    }

PRISM_ENCODING_TABLE(cp850)
PRISM_ENCODING_TABLE(cp852)
PRISM_ENCODING_TABLE(cp855)
PRISM_ENCODING_TABLE(gb1988)
PRISM_ENCODING_TABLE(ibm437)
PRISM_ENCODING_TABLE(ibm720)
PRISM_ENCODING_TABLE(ibm737)
PRISM_ENCODING_TABLE(ibm775)
PRISM_ENCODING_TABLE(ibm852)
PRISM_ENCODING_TABLE(ibm855)
PRISM_ENCODING_TABLE(ibm857)
PRISM_ENCODING_TABLE(ibm860)
PRISM_ENCODING_TABLE(ibm861)
PRISM_ENCODING_TABLE(ibm862)
PRISM_ENCODING_TABLE(ibm863)
PRISM_ENCODING_TABLE(ibm864)
PRISM_ENCODING_TABLE(ibm865)
PRISM_ENCODING_TABLE(ibm866)
PRISM_ENCODING_TABLE(ibm869)
PRISM_ENCODING_TABLE(iso_8859_1)
PRISM_ENCODING_TABLE(iso_8859_2)
PRISM_ENCODING_TABLE(iso_8859_3)
PRISM_ENCODING_TABLE(iso_8859_4)
PRISM_ENCODING_TABLE(iso_8859_5)
PRISM_ENCODING_TABLE(iso_8859_6)
PRISM_ENCODING_TABLE(iso_8859_7)
PRISM_ENCODING_TABLE(iso_8859_8)
PRISM_ENCODING_TABLE(iso_8859_9)
PRISM_ENCODING_TABLE(iso_8859_10)
PRISM_ENCODING_TABLE(iso_8859_11)
PRISM_ENCODING_TABLE(iso_8859_13)
PRISM_ENCODING_TABLE(iso_8859_14)
PRISM_ENCODING_TABLE(iso_8859_15)
PRISM_ENCODING_TABLE(iso_8859_16)
PRISM_ENCODING_TABLE(koi8_r)
PRISM_ENCODING_TABLE(koi8_u)
PRISM_ENCODING_TABLE(mac_cent_euro)
PRISM_ENCODING_TABLE(mac_croatian)
PRISM_ENCODING_TABLE(mac_cyrillic)
PRISM_ENCODING_TABLE(mac_greek)
PRISM_ENCODING_TABLE(mac_iceland)
PRISM_ENCODING_TABLE(mac_roman)
PRISM_ENCODING_TABLE(mac_romania)
PRISM_ENCODING_TABLE(mac_thai)
PRISM_ENCODING_TABLE(mac_turkish)
PRISM_ENCODING_TABLE(mac_ukraine)
PRISM_ENCODING_TABLE(tis_620)
PRISM_ENCODING_TABLE(windows_1250)
PRISM_ENCODING_TABLE(windows_1251)
PRISM_ENCODING_TABLE(windows_1252)
PRISM_ENCODING_TABLE(windows_1253)
PRISM_ENCODING_TABLE(windows_1254)
PRISM_ENCODING_TABLE(windows_1255)
PRISM_ENCODING_TABLE(windows_1256)
PRISM_ENCODING_TABLE(windows_1257)
PRISM_ENCODING_TABLE(windows_1258)
PRISM_ENCODING_TABLE(windows_874)

#undef PRISM_ENCODING_TABLE
#endif

/**
 * Returns the size of the next character in the ASCII encoding. This basically
 * means that if the top bit is not set, the character is 1 byte long.
 */
static size_t
pm_encoding_ascii_char_width(const uint8_t *b, PRISM_ATTRIBUTE_UNUSED ptrdiff_t n) {
    return *b < 0x80 ? 1 : 0;
}

/**
 * Return the size of the next character in the ASCII encoding if it is an
 * alphabetical character.
 */
static size_t
pm_encoding_ascii_alpha_char(const uint8_t *b, PRISM_ATTRIBUTE_UNUSED ptrdiff_t n) {
    return (pm_encoding_ascii_table[*b] & PRISM_ENCODING_ALPHABETIC_BIT);
}

/**
 * Certain encodings are equivalent to ASCII below 0x80, so it works for our
 * purposes to have a function here that first checks the bounds and then falls
 * back to checking the ASCII lookup table.
 */
static size_t
pm_encoding_ascii_alpha_char_7bit(const uint8_t *b, ptrdiff_t n) {
    return (*b < 0x80) ? pm_encoding_ascii_alpha_char(b, n) : 0;
}

/**
 * Return the size of the next character in the ASCII encoding if it is an
 * alphanumeric character.
 */
static size_t
pm_encoding_ascii_alnum_char(const uint8_t *b, PRISM_ATTRIBUTE_UNUSED ptrdiff_t n) {
    return (pm_encoding_ascii_table[*b] & PRISM_ENCODING_ALPHANUMERIC_BIT) ? 1 : 0;
}

/**
 * Certain encodings are equivalent to ASCII below 0x80, so it works for our
 * purposes to have a function here that first checks the bounds and then falls
 * back to checking the ASCII lookup table.
 */
static size_t
pm_encoding_ascii_alnum_char_7bit(const uint8_t *b, ptrdiff_t n) {
    return (*b < 0x80) ? pm_encoding_ascii_alnum_char(b, n) : 0;
}

/**
 * Return true if the next character in the ASCII encoding if it is an uppercase
 * character.
 */
static bool
pm_encoding_ascii_isupper_char(const uint8_t *b, PRISM_ATTRIBUTE_UNUSED ptrdiff_t n) {
    return (pm_encoding_ascii_table[*b] & PRISM_ENCODING_UPPERCASE_BIT);
}

/**
 * For a lot of encodings the default is that they are a single byte long no
 * matter what the codepoint, so this function is shared between them.
 */
static size_t
pm_encoding_single_char_width(PRISM_ATTRIBUTE_UNUSED const uint8_t *b, PRISM_ATTRIBUTE_UNUSED ptrdiff_t n) {
    return 1;
}

/**
 * Returns the size of the next character in the EUC-JP encoding, or 0 if a
 * character cannot be decoded from the given bytes.
 */
static size_t
pm_encoding_euc_jp_char_width(const uint8_t *b, ptrdiff_t n) {
    // These are the single byte characters.
    if (*b < 0x80) {
        return 1;
    }

    // These are the double byte characters.
    if ((n > 1) && ((b[0] == 0x8E) || (b[0] >= 0xA1 && b[0] <= 0xFE)) && (b[1] >= 0xA1 && b[1] <= 0xFE)) {
        return 2;
    }

    // These are the triple byte characters.
    if ((n > 2) && (b[0] == 0x8F) && (b[1] >= 0xA1 && b[2] <= 0xFE) && (b[2] >= 0xA1 && b[2] <= 0xFE)) {
        return 3;
    }

    return 0;
}

/**
 * Returns the size of the next character in the EUC-JP encoding if it is an
 * uppercase character.
 */
static bool
pm_encoding_euc_jp_isupper_char(const uint8_t *b, ptrdiff_t n) {
    size_t width = pm_encoding_euc_jp_char_width(b, n);

    if (width == 1) {
        return pm_encoding_ascii_isupper_char(b, n);
    } else if (width == 2) {
        return (
            (b[0] == 0xA3 && b[1] >= 0xC1 && b[1] <= 0xDA) ||
            (b[0] == 0xA6 && b[1] >= 0xA1 && b[1] <= 0xB8) ||
            (b[0] == 0xA7 && b[1] >= 0xA1 && b[1] <= 0xC1)
        );
    } else {
        return false;
    }
}

/**
 * Returns the size of the next character in the Shift_JIS encoding, or 0 if a
 * character cannot be decoded from the given bytes.
 */
static size_t
pm_encoding_shift_jis_char_width(const uint8_t *b, ptrdiff_t n) {
    // These are the single byte characters.
    if (b[0] < 0x80 || (b[0] >= 0xA1 && b[0] <= 0xDF)) {
        return 1;
    }

    // These are the double byte characters.
    if ((n > 1) && ((b[0] >= 0x81 && b[0] <= 0x9F) || (b[0] >= 0xE0 && b[0] <= 0xFC)) && (b[1] >= 0x40 && b[1] <= 0xFC && b[1] != 0x7F)) {
        return 2;
    }

    return 0;
}

/**
 * Returns the size of the next character in the Shift_JIS encoding if it is an
 * alphanumeric character.
 */
static size_t
pm_encoding_shift_jis_alnum_char(const uint8_t *b, ptrdiff_t n) {
    size_t width = pm_encoding_shift_jis_char_width(b, n);
    return width == 1 ? ((b[0] >= 0x80) || pm_encoding_ascii_alnum_char(b, n)) : width;
}

/**
 * Returns the size of the next character in the Shift_JIS encoding if it is an
 * alphabetical character.
 */
static size_t
pm_encoding_shift_jis_alpha_char(const uint8_t *b, ptrdiff_t n) {
    size_t width = pm_encoding_shift_jis_char_width(b, n);
    return width == 1 ? ((b[0] >= 0x80) || pm_encoding_ascii_alpha_char(b, n)) : width;
}

/**
 * Returns the size of the next character in the Shift_JIS encoding if it is an
 * uppercase character.
 */
static bool
pm_encoding_shift_jis_isupper_char(const uint8_t *b, ptrdiff_t n) {
    size_t width = pm_encoding_shift_jis_char_width(b, n);

    if (width == 1) {
        return pm_encoding_ascii_isupper_char(b, n);
    } else if (width == 2) {
        return (
            ((b[0] == 0x82) && (b[1] >= 0x60 && b[1] <= 0x79)) ||
            ((b[0] == 0x83) && (b[1] >= 0x9F && b[1] <= 0xB6)) ||
            ((b[0] == 0x84) && (b[1] >= 0x40 && b[1] <= 0x60))
        );
    } else {
        return width;
    }
}

#ifndef PRISM_ENCODING_EXCLUDE_FULL

/**
 * Certain encodings are equivalent to ASCII below 0x80, so it works for our
 * purposes to have a function here that first checks the bounds and then falls
 * back to checking the ASCII lookup table.
 */
static bool
pm_encoding_ascii_isupper_char_7bit(const uint8_t *b, ptrdiff_t n) {
    return (*b < 0x80) && pm_encoding_ascii_isupper_char(b, n);
}

/**
 * Returns the size of the next character in the Big5 encoding, or 0 if a
 * character cannot be decoded from the given bytes.
 */
static size_t
pm_encoding_big5_char_width(const uint8_t *b, ptrdiff_t n) {
    // These are the single byte characters.
    if (*b < 0x80) {
        return 1;
    }

    // These are the double byte characters.
    if ((n > 1) && (b[0] >= 0xA1 && b[0] <= 0xFE) && ((b[1] >= 0x40 && b[1] <= 0x7E) || (b[1] >= 0xA1 && b[1] <= 0xFE))) {
        return 2;
    }

    return 0;
}

/**
 * Returns the size of the next character in the CP949 encoding, or 0 if a
 * character cannot be decoded from the given bytes.
 */
static size_t
pm_encoding_cp949_char_width(const uint8_t *b, ptrdiff_t n) {
    // These are the single byte characters
    if (*b <= 0x80) {
        return 1;
    }

    // These are the double byte characters
    if ((n > 1) && (b[0] >= 0x81 && b[0] <= 0xFE) && ((b[1] >= 0x41 && b[1] <= 0x5A) || (b[1] >= 0x61 && b[1] <= 0x7A) || (b[1] >= 0x81 && b[1] <= 0xFE))) {
        return 2;
    }

    return 0;
}

/**
 * Returns the size of the next character in the Emacs MULE encoding, or 0 if a
 * character cannot be decoded from the given bytes.
 */
static size_t
pm_encoding_emacs_mule_char_width(const uint8_t *b, ptrdiff_t n) {
    // These are the 1 byte characters.
    if (*b < 0x80) {
        return 1;
    }

    // These are the 2 byte characters.
    if ((n > 1) && (b[0] >= 0x81 && b[0] <= 0x8F) && (b[1] >= 0xA0)) {
        return 2;
    }

    // These are the 3 byte characters.
    if (
        (n > 2) &&
        (
            ((b[0] >= 0x90 && b[0] <= 0x99) && (b[1] >= 0xA0)) ||
            ((b[0] == 0x9A || b[0] == 0x9B) && (b[1] >= 0xE0 && b[1] <= 0xEF))
        ) &&
        (b[2] >= 0xA0)
    ) {
        return 3;
    }

    // These are the 4 byte characters.
    if (
        (n > 3) &&
        (
            ((b[0] == 0x9C) && (b[1] >= 0xF0) && (b[1] <= 0xF4)) ||
            ((b[0] == 0x9D) && (b[1] >= 0xF5) && (b[1] <= 0xFE))
        ) &&
        (b[2] >= 0xA0) && (b[3] >= 0xA0)
    ) {
        return 4;
    }

    return 0;
}

/**
 * Returns the size of the next character in the EUC-KR encoding, or 0 if a
 * character cannot be decoded from the given bytes.
 */
static size_t
pm_encoding_euc_kr_char_width(const uint8_t *b, ptrdiff_t n) {
    // These are the single byte characters.
    if (*b < 0x80) {
        return 1;
    }

    // These are the double byte characters.
    if ((n > 1) && (b[0] >= 0xA1 && b[0] <= 0xFE) && (b[1] >= 0xA1 && b[1] <= 0xFE)) {
        return 2;
    }

    return 0;
}

/**
 * Returns the size of the next character in the EUC-TW encoding, or 0 if a
 * character cannot be decoded from the given bytes.
 */
static size_t
pm_encoding_euc_tw_char_width(const uint8_t *b, ptrdiff_t n) {
    // These are the single byte characters.
    if (*b < 0x80) {
        return 1;
    }

    // These are the double byte characters.
    if ((n > 1) && (b[0] >= 0xA1) && (b[0] <= 0xFE) && (b[1] >= 0xA1) && (b[1] <= 0xFE)) {
        return 2;
    }

    // These are the quadruple byte characters.
    if ((n > 3) && (b[0] == 0x8E) && (b[1] >= 0xA1) && (b[1] <= 0xB0) && (b[2] >= 0xA1) && (b[2] <= 0xFE) && (b[3] >= 0xA1) && (b[3] <= 0xFE)) {
        return 4;
    }

    return 0;
}

/**
 * Returns the size of the next character in the GB18030 encoding, or 0 if a
 * character cannot be decoded from the given bytes.
 */
static size_t
pm_encoding_gb18030_char_width(const uint8_t *b, ptrdiff_t n) {
    // These are the 1 byte characters.
    if (*b < 0x80) {
        return 1;
    }

    // These are the 2 byte characters.
    if ((n > 1) && (b[0] >= 0x81 && b[0] <= 0xFE) && (b[1] >= 0x40 && b[1] <= 0xFE && b[1] != 0x7F)) {
        return 2;
    }

    // These are the 4 byte characters.
    if ((n > 3) && ((b[0] >= 0x81 && b[0] <= 0xFE) && (b[1] >= 0x30 && b[1] <= 0x39) && (b[2] >= 0x81 && b[2] <= 0xFE) && (b[3] >= 0x30 && b[3] <= 0x39))) {
        return 4;
    }

    return 0;
}

/**
 * Returns the size of the next character in the GBK encoding, or 0 if a
 * character cannot be decoded from the given bytes.
 */
static size_t
pm_encoding_gbk_char_width(const uint8_t *b, ptrdiff_t n) {
    // These are the single byte characters.
    if (*b <= 0x80) {
        return 1;
    }

    // These are the double byte characters.
    if (
        (n > 1) &&
        (
            ((b[0] >= 0xA1 && b[0] <= 0xA9) && (b[1] >= 0xA1 && b[1] <= 0xFE)) || // GBK/1
            ((b[0] >= 0xB0 && b[0] <= 0xF7) && (b[1] >= 0xA1 && b[1] <= 0xFE)) || // GBK/2
            ((b[0] >= 0x81 && b[0] <= 0xA0) && (b[1] >= 0x40 && b[1] <= 0xFE) && (b[1] != 0x7F)) || // GBK/3
            ((b[0] >= 0xAA && b[0] <= 0xFE) && (b[1] >= 0x40 && b[1] <= 0xA0) && (b[1] != 0x7F)) || // GBK/4
            ((b[0] >= 0xA8 && b[0] <= 0xA9) && (b[1] >= 0x40 && b[1] <= 0xA0) && (b[1] != 0x7F)) || // GBK/5
            ((b[0] >= 0xAA && b[0] <= 0xAF) && (b[1] >= 0xA1 && b[1] <= 0xFE)) || // user-defined 1
            ((b[0] >= 0xF8 && b[0] <= 0xFE) && (b[1] >= 0xA1 && b[1] <= 0xFE)) || // user-defined 2
            ((b[0] >= 0xA1 && b[0] <= 0xA7) && (b[1] >= 0x40 && b[1] <= 0xA0) && (b[1] != 0x7F)) // user-defined 3
        )
    ) {
        return 2;
    }

    return 0;
}

#endif

/**
 * This is the table of all of the encodings that prism supports.
 */
const pm_encoding_t pm_encodings[] = {
    [PM_ENCODING_UTF_8] = {
        .name = "UTF-8",
        .char_width = pm_encoding_utf_8_char_width,
        .alnum_char = pm_encoding_utf_8_alnum_char,
        .alpha_char = pm_encoding_utf_8_alpha_char,
        .isupper_char = pm_encoding_utf_8_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_US_ASCII] = {
        .name = "US-ASCII",
        .char_width = pm_encoding_ascii_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char,
        .alpha_char = pm_encoding_ascii_alpha_char,
        .isupper_char = pm_encoding_ascii_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ASCII_8BIT] = {
        .name = "ASCII-8BIT",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char,
        .alpha_char = pm_encoding_ascii_alpha_char,
        .isupper_char = pm_encoding_ascii_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_EUC_JP] = {
        .name = "EUC-JP",
        .char_width = pm_encoding_euc_jp_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_euc_jp_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_WINDOWS_31J] = {
        .name = "Windows-31J",
        .char_width = pm_encoding_shift_jis_char_width,
        .alnum_char = pm_encoding_shift_jis_alnum_char,
        .alpha_char = pm_encoding_shift_jis_alpha_char,
        .isupper_char = pm_encoding_shift_jis_isupper_char,
        .multibyte = true
    },

#ifndef PRISM_ENCODING_EXCLUDE_FULL
    [PM_ENCODING_BIG5] = {
        .name = "Big5",
        .char_width = pm_encoding_big5_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_BIG5_HKSCS] = {
        .name = "Big5-HKSCS",
        .char_width = pm_encoding_big5_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_BIG5_UAO] = {
        .name = "Big5-UAO",
        .char_width = pm_encoding_big5_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_CESU_8] = {
        .name = "CESU-8",
        .char_width = pm_encoding_cesu_8_char_width,
        .alnum_char = pm_encoding_cesu_8_alnum_char,
        .alpha_char = pm_encoding_cesu_8_alpha_char,
        .isupper_char = pm_encoding_cesu_8_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_CP51932] = {
        .name = "CP51932",
        .char_width = pm_encoding_euc_jp_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_euc_jp_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_CP850] = {
        .name = "CP850",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_cp850_alnum_char,
        .alpha_char = pm_encoding_cp850_alpha_char,
        .isupper_char = pm_encoding_cp850_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_CP852] = {
        .name = "CP852",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_cp852_alnum_char,
        .alpha_char = pm_encoding_cp852_alpha_char,
        .isupper_char = pm_encoding_cp852_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_CP855] = {
        .name = "CP855",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_cp855_alnum_char,
        .alpha_char = pm_encoding_cp855_alpha_char,
        .isupper_char = pm_encoding_cp855_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_CP949] = {
        .name = "CP949",
        .char_width = pm_encoding_cp949_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_CP950] = {
        .name = "CP950",
        .char_width = pm_encoding_big5_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_CP951] = {
        .name = "CP951",
        .char_width = pm_encoding_big5_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_EMACS_MULE] = {
        .name = "Emacs-Mule",
        .char_width = pm_encoding_emacs_mule_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_EUC_JP_MS] = {
        .name = "eucJP-ms",
        .char_width = pm_encoding_euc_jp_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_euc_jp_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_EUC_JIS_2004] = {
        .name = "EUC-JIS-2004",
        .char_width = pm_encoding_euc_jp_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_euc_jp_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_EUC_KR] = {
        .name = "EUC-KR",
        .char_width = pm_encoding_euc_kr_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_EUC_TW] = {
        .name = "EUC-TW",
        .char_width = pm_encoding_euc_tw_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_GB12345] = {
        .name = "GB12345",
        .char_width = pm_encoding_euc_kr_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_GB18030] = {
        .name = "GB18030",
        .char_width = pm_encoding_gb18030_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_GB1988] = {
        .name = "GB1988",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_gb1988_alnum_char,
        .alpha_char = pm_encoding_gb1988_alpha_char,
        .isupper_char = pm_encoding_gb1988_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_GB2312] = {
        .name = "GB2312",
        .char_width = pm_encoding_euc_kr_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_GBK] = {
        .name = "GBK",
        .char_width = pm_encoding_gbk_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_IBM437] = {
        .name = "IBM437",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm437_alnum_char,
        .alpha_char = pm_encoding_ibm437_alpha_char,
        .isupper_char = pm_encoding_ibm437_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM720] = {
        .name = "IBM720",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm720_alnum_char,
        .alpha_char = pm_encoding_ibm720_alpha_char,
        .isupper_char = pm_encoding_ibm720_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM737] = {
        .name = "IBM737",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm737_alnum_char,
        .alpha_char = pm_encoding_ibm737_alpha_char,
        .isupper_char = pm_encoding_ibm737_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM775] = {
        .name = "IBM775",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm775_alnum_char,
        .alpha_char = pm_encoding_ibm775_alpha_char,
        .isupper_char = pm_encoding_ibm775_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM852] = {
        .name = "IBM852",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm852_alnum_char,
        .alpha_char = pm_encoding_ibm852_alpha_char,
        .isupper_char = pm_encoding_ibm852_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM855] = {
        .name = "IBM855",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm855_alnum_char,
        .alpha_char = pm_encoding_ibm855_alpha_char,
        .isupper_char = pm_encoding_ibm855_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM857] = {
        .name = "IBM857",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm857_alnum_char,
        .alpha_char = pm_encoding_ibm857_alpha_char,
        .isupper_char = pm_encoding_ibm857_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM860] = {
        .name = "IBM860",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm860_alnum_char,
        .alpha_char = pm_encoding_ibm860_alpha_char,
        .isupper_char = pm_encoding_ibm860_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM861] = {
        .name = "IBM861",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm861_alnum_char,
        .alpha_char = pm_encoding_ibm861_alpha_char,
        .isupper_char = pm_encoding_ibm861_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM862] = {
        .name = "IBM862",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm862_alnum_char,
        .alpha_char = pm_encoding_ibm862_alpha_char,
        .isupper_char = pm_encoding_ibm862_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM863] = {
        .name = "IBM863",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm863_alnum_char,
        .alpha_char = pm_encoding_ibm863_alpha_char,
        .isupper_char = pm_encoding_ibm863_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM864] = {
        .name = "IBM864",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm864_alnum_char,
        .alpha_char = pm_encoding_ibm864_alpha_char,
        .isupper_char = pm_encoding_ibm864_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM865] = {
        .name = "IBM865",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm865_alnum_char,
        .alpha_char = pm_encoding_ibm865_alpha_char,
        .isupper_char = pm_encoding_ibm865_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM866] = {
        .name = "IBM866",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm866_alnum_char,
        .alpha_char = pm_encoding_ibm866_alpha_char,
        .isupper_char = pm_encoding_ibm866_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_IBM869] = {
        .name = "IBM869",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_ibm869_alnum_char,
        .alpha_char = pm_encoding_ibm869_alpha_char,
        .isupper_char = pm_encoding_ibm869_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_1] = {
        .name = "ISO-8859-1",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_1_alnum_char,
        .alpha_char = pm_encoding_iso_8859_1_alpha_char,
        .isupper_char = pm_encoding_iso_8859_1_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_2] = {
        .name = "ISO-8859-2",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_2_alnum_char,
        .alpha_char = pm_encoding_iso_8859_2_alpha_char,
        .isupper_char = pm_encoding_iso_8859_2_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_3] = {
        .name = "ISO-8859-3",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_3_alnum_char,
        .alpha_char = pm_encoding_iso_8859_3_alpha_char,
        .isupper_char = pm_encoding_iso_8859_3_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_4] = {
        .name = "ISO-8859-4",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_4_alnum_char,
        .alpha_char = pm_encoding_iso_8859_4_alpha_char,
        .isupper_char = pm_encoding_iso_8859_4_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_5] = {
        .name = "ISO-8859-5",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_5_alnum_char,
        .alpha_char = pm_encoding_iso_8859_5_alpha_char,
        .isupper_char = pm_encoding_iso_8859_5_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_6] = {
        .name = "ISO-8859-6",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_6_alnum_char,
        .alpha_char = pm_encoding_iso_8859_6_alpha_char,
        .isupper_char = pm_encoding_iso_8859_6_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_7] = {
        .name = "ISO-8859-7",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_7_alnum_char,
        .alpha_char = pm_encoding_iso_8859_7_alpha_char,
        .isupper_char = pm_encoding_iso_8859_7_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_8] = {
        .name = "ISO-8859-8",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_8_alnum_char,
        .alpha_char = pm_encoding_iso_8859_8_alpha_char,
        .isupper_char = pm_encoding_iso_8859_8_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_9] = {
        .name = "ISO-8859-9",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_9_alnum_char,
        .alpha_char = pm_encoding_iso_8859_9_alpha_char,
        .isupper_char = pm_encoding_iso_8859_9_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_10] = {
        .name = "ISO-8859-10",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_10_alnum_char,
        .alpha_char = pm_encoding_iso_8859_10_alpha_char,
        .isupper_char = pm_encoding_iso_8859_10_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_11] = {
        .name = "ISO-8859-11",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_11_alnum_char,
        .alpha_char = pm_encoding_iso_8859_11_alpha_char,
        .isupper_char = pm_encoding_iso_8859_11_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_13] = {
        .name = "ISO-8859-13",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_13_alnum_char,
        .alpha_char = pm_encoding_iso_8859_13_alpha_char,
        .isupper_char = pm_encoding_iso_8859_13_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_14] = {
        .name = "ISO-8859-14",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_14_alnum_char,
        .alpha_char = pm_encoding_iso_8859_14_alpha_char,
        .isupper_char = pm_encoding_iso_8859_14_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_15] = {
        .name = "ISO-8859-15",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_15_alnum_char,
        .alpha_char = pm_encoding_iso_8859_15_alpha_char,
        .isupper_char = pm_encoding_iso_8859_15_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_ISO_8859_16] = {
        .name = "ISO-8859-16",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_iso_8859_16_alnum_char,
        .alpha_char = pm_encoding_iso_8859_16_alpha_char,
        .isupper_char = pm_encoding_iso_8859_16_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_KOI8_R] = {
        .name = "KOI8-R",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_koi8_r_alnum_char,
        .alpha_char = pm_encoding_koi8_r_alpha_char,
        .isupper_char = pm_encoding_koi8_r_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_KOI8_U] = {
        .name = "KOI8-U",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_koi8_u_alnum_char,
        .alpha_char = pm_encoding_koi8_u_alpha_char,
        .isupper_char = pm_encoding_koi8_u_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_MAC_CENT_EURO] = {
        .name = "macCentEuro",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_mac_cent_euro_alnum_char,
        .alpha_char = pm_encoding_mac_cent_euro_alpha_char,
        .isupper_char = pm_encoding_mac_cent_euro_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_MAC_CROATIAN] = {
        .name = "macCroatian",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_mac_croatian_alnum_char,
        .alpha_char = pm_encoding_mac_croatian_alpha_char,
        .isupper_char = pm_encoding_mac_croatian_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_MAC_CYRILLIC] = {
        .name = "macCyrillic",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_mac_cyrillic_alnum_char,
        .alpha_char = pm_encoding_mac_cyrillic_alpha_char,
        .isupper_char = pm_encoding_mac_cyrillic_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_MAC_GREEK] = {
        .name = "macGreek",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_mac_greek_alnum_char,
        .alpha_char = pm_encoding_mac_greek_alpha_char,
        .isupper_char = pm_encoding_mac_greek_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_MAC_ICELAND] = {
        .name = "macIceland",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_mac_iceland_alnum_char,
        .alpha_char = pm_encoding_mac_iceland_alpha_char,
        .isupper_char = pm_encoding_mac_iceland_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_MAC_JAPANESE] = {
        .name = "MacJapanese",
        .char_width = pm_encoding_shift_jis_char_width,
        .alnum_char = pm_encoding_shift_jis_alnum_char,
        .alpha_char = pm_encoding_shift_jis_alpha_char,
        .isupper_char = pm_encoding_shift_jis_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_MAC_ROMAN] = {
        .name = "macRoman",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_mac_roman_alnum_char,
        .alpha_char = pm_encoding_mac_roman_alpha_char,
        .isupper_char = pm_encoding_mac_roman_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_MAC_ROMANIA] = {
        .name = "macRomania",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_mac_romania_alnum_char,
        .alpha_char = pm_encoding_mac_romania_alpha_char,
        .isupper_char = pm_encoding_mac_romania_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_MAC_THAI] = {
        .name = "macThai",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_mac_thai_alnum_char,
        .alpha_char = pm_encoding_mac_thai_alpha_char,
        .isupper_char = pm_encoding_mac_thai_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_MAC_TURKISH] = {
        .name = "macTurkish",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_mac_turkish_alnum_char,
        .alpha_char = pm_encoding_mac_turkish_alpha_char,
        .isupper_char = pm_encoding_mac_turkish_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_MAC_UKRAINE] = {
        .name = "macUkraine",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_mac_ukraine_alnum_char,
        .alpha_char = pm_encoding_mac_ukraine_alpha_char,
        .isupper_char = pm_encoding_mac_ukraine_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_SHIFT_JIS] = {
        .name = "Shift_JIS",
        .char_width = pm_encoding_shift_jis_char_width,
        .alnum_char = pm_encoding_shift_jis_alnum_char,
        .alpha_char = pm_encoding_shift_jis_alpha_char,
        .isupper_char = pm_encoding_shift_jis_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_SJIS_DOCOMO] = {
        .name = "SJIS-DoCoMo",
        .char_width = pm_encoding_shift_jis_char_width,
        .alnum_char = pm_encoding_shift_jis_alnum_char,
        .alpha_char = pm_encoding_shift_jis_alpha_char,
        .isupper_char = pm_encoding_shift_jis_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_SJIS_KDDI] = {
        .name = "SJIS-KDDI",
        .char_width = pm_encoding_shift_jis_char_width,
        .alnum_char = pm_encoding_shift_jis_alnum_char,
        .alpha_char = pm_encoding_shift_jis_alpha_char,
        .isupper_char = pm_encoding_shift_jis_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_SJIS_SOFTBANK] = {
        .name = "SJIS-SoftBank",
        .char_width = pm_encoding_shift_jis_char_width,
        .alnum_char = pm_encoding_shift_jis_alnum_char,
        .alpha_char = pm_encoding_shift_jis_alpha_char,
        .isupper_char = pm_encoding_shift_jis_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_STATELESS_ISO_2022_JP] = {
        .name = "stateless-ISO-2022-JP",
        .char_width = pm_encoding_emacs_mule_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_STATELESS_ISO_2022_JP_KDDI] = {
        .name = "stateless-ISO-2022-JP-KDDI",
        .char_width = pm_encoding_emacs_mule_char_width,
        .alnum_char = pm_encoding_ascii_alnum_char_7bit,
        .alpha_char = pm_encoding_ascii_alpha_char_7bit,
        .isupper_char = pm_encoding_ascii_isupper_char_7bit,
        .multibyte = true
    },
    [PM_ENCODING_TIS_620] = {
        .name = "TIS-620",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_tis_620_alnum_char,
        .alpha_char = pm_encoding_tis_620_alpha_char,
        .isupper_char = pm_encoding_tis_620_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_UTF8_MAC] = {
        .name = "UTF8-MAC",
        .char_width = pm_encoding_utf_8_char_width,
        .alnum_char = pm_encoding_utf_8_alnum_char,
        .alpha_char = pm_encoding_utf_8_alpha_char,
        .isupper_char = pm_encoding_utf_8_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_UTF8_DOCOMO] = {
        .name = "UTF8-DoCoMo",
        .char_width = pm_encoding_utf_8_char_width,
        .alnum_char = pm_encoding_utf_8_alnum_char,
        .alpha_char = pm_encoding_utf_8_alpha_char,
        .isupper_char = pm_encoding_utf_8_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_UTF8_KDDI] = {
        .name = "UTF8-KDDI",
        .char_width = pm_encoding_utf_8_char_width,
        .alnum_char = pm_encoding_utf_8_alnum_char,
        .alpha_char = pm_encoding_utf_8_alpha_char,
        .isupper_char = pm_encoding_utf_8_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_UTF8_SOFTBANK] = {
        .name = "UTF8-SoftBank",
        .char_width = pm_encoding_utf_8_char_width,
        .alnum_char = pm_encoding_utf_8_alnum_char,
        .alpha_char = pm_encoding_utf_8_alpha_char,
        .isupper_char = pm_encoding_utf_8_isupper_char,
        .multibyte = true
    },
    [PM_ENCODING_WINDOWS_1250] = {
        .name = "Windows-1250",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_windows_1250_alnum_char,
        .alpha_char = pm_encoding_windows_1250_alpha_char,
        .isupper_char = pm_encoding_windows_1250_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_WINDOWS_1251] = {
        .name = "Windows-1251",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_windows_1251_alnum_char,
        .alpha_char = pm_encoding_windows_1251_alpha_char,
        .isupper_char = pm_encoding_windows_1251_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_WINDOWS_1252] = {
        .name = "Windows-1252",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_windows_1252_alnum_char,
        .alpha_char = pm_encoding_windows_1252_alpha_char,
        .isupper_char = pm_encoding_windows_1252_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_WINDOWS_1253] = {
        .name = "Windows-1253",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_windows_1253_alnum_char,
        .alpha_char = pm_encoding_windows_1253_alpha_char,
        .isupper_char = pm_encoding_windows_1253_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_WINDOWS_1254] = {
        .name = "Windows-1254",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_windows_1254_alnum_char,
        .alpha_char = pm_encoding_windows_1254_alpha_char,
        .isupper_char = pm_encoding_windows_1254_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_WINDOWS_1255] = {
        .name = "Windows-1255",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_windows_1255_alnum_char,
        .alpha_char = pm_encoding_windows_1255_alpha_char,
        .isupper_char = pm_encoding_windows_1255_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_WINDOWS_1256] = {
        .name = "Windows-1256",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_windows_1256_alnum_char,
        .alpha_char = pm_encoding_windows_1256_alpha_char,
        .isupper_char = pm_encoding_windows_1256_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_WINDOWS_1257] = {
        .name = "Windows-1257",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_windows_1257_alnum_char,
        .alpha_char = pm_encoding_windows_1257_alpha_char,
        .isupper_char = pm_encoding_windows_1257_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_WINDOWS_1258] = {
        .name = "Windows-1258",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_windows_1258_alnum_char,
        .alpha_char = pm_encoding_windows_1258_alpha_char,
        .isupper_char = pm_encoding_windows_1258_isupper_char,
        .multibyte = false
    },
    [PM_ENCODING_WINDOWS_874] = {
        .name = "Windows-874",
        .char_width = pm_encoding_single_char_width,
        .alnum_char = pm_encoding_windows_874_alnum_char,
        .alpha_char = pm_encoding_windows_874_alpha_char,
        .isupper_char = pm_encoding_windows_874_isupper_char,
        .multibyte = false
    }
#endif
};

/**
 * Parse the given name of an encoding and return a pointer to the corresponding
 * encoding struct if one can be found, otherwise return NULL.
 */
const pm_encoding_t *
pm_encoding_find(const uint8_t *start, const uint8_t *end) {
    size_t width = (size_t) (end - start);

    // First, we're going to check for UTF-8. This is the most common encoding.
    // UTF-8 can contain extra information at the end about the platform it is
    // encoded on, such as UTF-8-MAC or UTF-8-UNIX. We'll ignore those suffixes.
    if ((start + 5 <= end) && (pm_strncasecmp(start, (const uint8_t *) "UTF-8", 5) == 0)) {
#ifndef PRISM_ENCODING_EXCLUDE_FULL
        // We need to explicitly handle UTF-8-HFS, as that one needs to switch
        // over to being UTF8-MAC.
        if (width == 9 && (pm_strncasecmp(start + 5, (const uint8_t *) "-HFS", 4) == 0)) {
            return &pm_encodings[PM_ENCODING_UTF8_MAC];
        }
#endif

        // Otherwise we'll return the default UTF-8 encoding.
        return PM_ENCODING_UTF_8_ENTRY;
    }

    // Next, we're going to loop through each of the encodings that we handle
    // explicitly. If we found one that we understand, we'll use that value.
#define ENCODING1(name, encoding) if (width == sizeof(name) - 1 && pm_strncasecmp(start, (const uint8_t *) name, width) == 0) return &pm_encodings[encoding];
#define ENCODING2(name1, name2, encoding) ENCODING1(name1, encoding) ENCODING1(name2, encoding)

    if (width >= 3) {
        switch (*start) {
            case 'A': case 'a':
                ENCODING1("ASCII", PM_ENCODING_US_ASCII);
                ENCODING1("ASCII-8BIT", PM_ENCODING_ASCII_8BIT);
                ENCODING1("ANSI_X3.4-1968", PM_ENCODING_US_ASCII);
                break;
            case 'B': case 'b':
                ENCODING1("BINARY", PM_ENCODING_ASCII_8BIT);
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING1("Big5", PM_ENCODING_BIG5);
                ENCODING2("Big5-HKSCS", "Big5-HKSCS:2008", PM_ENCODING_BIG5_HKSCS);
                ENCODING1("Big5-UAO", PM_ENCODING_BIG5_UAO);
#endif
                break;
            case 'C': case 'c':
                ENCODING1("CP65001", PM_ENCODING_UTF_8);
                ENCODING2("CP932", "csWindows31J", PM_ENCODING_WINDOWS_31J);
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING1("CESU-8", PM_ENCODING_CESU_8);
                ENCODING1("CP437", PM_ENCODING_IBM437);
                ENCODING1("CP720", PM_ENCODING_IBM720);
                ENCODING1("CP737", PM_ENCODING_IBM737);
                ENCODING1("CP775", PM_ENCODING_IBM775);
                ENCODING1("CP850", PM_ENCODING_CP850);
                ENCODING1("CP852", PM_ENCODING_CP852);
                ENCODING1("CP855", PM_ENCODING_CP855);
                ENCODING1("CP857", PM_ENCODING_IBM857);
                ENCODING1("CP860", PM_ENCODING_IBM860);
                ENCODING1("CP861", PM_ENCODING_IBM861);
                ENCODING1("CP862", PM_ENCODING_IBM862);
                ENCODING1("CP864", PM_ENCODING_IBM864);
                ENCODING1("CP865", PM_ENCODING_IBM865);
                ENCODING1("CP866", PM_ENCODING_IBM866);
                ENCODING1("CP869", PM_ENCODING_IBM869);
                ENCODING1("CP874", PM_ENCODING_WINDOWS_874);
                ENCODING1("CP878", PM_ENCODING_KOI8_R);
                ENCODING1("CP863", PM_ENCODING_IBM863);
                ENCODING1("CP936", PM_ENCODING_GBK);
                ENCODING1("CP949", PM_ENCODING_CP949);
                ENCODING1("CP950", PM_ENCODING_CP950);
                ENCODING1("CP951", PM_ENCODING_CP951);
                ENCODING1("CP1250", PM_ENCODING_WINDOWS_1250);
                ENCODING1("CP1251", PM_ENCODING_WINDOWS_1251);
                ENCODING1("CP1252", PM_ENCODING_WINDOWS_1252);
                ENCODING1("CP1253", PM_ENCODING_WINDOWS_1253);
                ENCODING1("CP1254", PM_ENCODING_WINDOWS_1254);
                ENCODING1("CP1255", PM_ENCODING_WINDOWS_1255);
                ENCODING1("CP1256", PM_ENCODING_WINDOWS_1256);
                ENCODING1("CP1257", PM_ENCODING_WINDOWS_1257);
                ENCODING1("CP1258", PM_ENCODING_WINDOWS_1258);
                ENCODING1("CP51932", PM_ENCODING_CP51932);
#endif
                break;
            case 'E': case 'e':
                ENCODING2("EUC-JP", "eucJP", PM_ENCODING_EUC_JP);
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING2("eucJP-ms", "euc-jp-ms", PM_ENCODING_EUC_JP_MS);
                ENCODING2("EUC-JIS-2004", "EUC-JISX0213", PM_ENCODING_EUC_JIS_2004);
                ENCODING2("EUC-KR", "eucKR", PM_ENCODING_EUC_KR);
                ENCODING2("EUC-CN", "eucCN", PM_ENCODING_GB2312);
                ENCODING2("EUC-TW", "eucTW", PM_ENCODING_EUC_TW);
                ENCODING1("Emacs-Mule", PM_ENCODING_EMACS_MULE);
#endif
                break;
            case 'G': case 'g':
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING1("GBK", PM_ENCODING_GBK);
                ENCODING1("GB12345", PM_ENCODING_GB12345);
                ENCODING1("GB18030", PM_ENCODING_GB18030);
                ENCODING1("GB1988", PM_ENCODING_GB1988);
                ENCODING1("GB2312", PM_ENCODING_GB2312);
#endif
                break;
            case 'I': case 'i':
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING1("IBM437", PM_ENCODING_IBM437);
                ENCODING1("IBM720", PM_ENCODING_IBM720);
                ENCODING1("IBM737", PM_ENCODING_IBM737);
                ENCODING1("IBM775", PM_ENCODING_IBM775);
                ENCODING1("IBM850", PM_ENCODING_CP850);
                ENCODING1("IBM852", PM_ENCODING_IBM852);
                ENCODING1("IBM855", PM_ENCODING_IBM855);
                ENCODING1("IBM857", PM_ENCODING_IBM857);
                ENCODING1("IBM860", PM_ENCODING_IBM860);
                ENCODING1("IBM861", PM_ENCODING_IBM861);
                ENCODING1("IBM862", PM_ENCODING_IBM862);
                ENCODING1("IBM863", PM_ENCODING_IBM863);
                ENCODING1("IBM864", PM_ENCODING_IBM864);
                ENCODING1("IBM865", PM_ENCODING_IBM865);
                ENCODING1("IBM866", PM_ENCODING_IBM866);
                ENCODING1("IBM869", PM_ENCODING_IBM869);
                ENCODING2("ISO-8859-1", "ISO8859-1", PM_ENCODING_ISO_8859_1);
                ENCODING2("ISO-8859-2", "ISO8859-2", PM_ENCODING_ISO_8859_2);
                ENCODING2("ISO-8859-3", "ISO8859-3", PM_ENCODING_ISO_8859_3);
                ENCODING2("ISO-8859-4", "ISO8859-4", PM_ENCODING_ISO_8859_4);
                ENCODING2("ISO-8859-5", "ISO8859-5", PM_ENCODING_ISO_8859_5);
                ENCODING2("ISO-8859-6", "ISO8859-6", PM_ENCODING_ISO_8859_6);
                ENCODING2("ISO-8859-7", "ISO8859-7", PM_ENCODING_ISO_8859_7);
                ENCODING2("ISO-8859-8", "ISO8859-8", PM_ENCODING_ISO_8859_8);
                ENCODING2("ISO-8859-9", "ISO8859-9", PM_ENCODING_ISO_8859_9);
                ENCODING2("ISO-8859-10", "ISO8859-10", PM_ENCODING_ISO_8859_10);
                ENCODING2("ISO-8859-11", "ISO8859-11", PM_ENCODING_ISO_8859_11);
                ENCODING2("ISO-8859-13", "ISO8859-13", PM_ENCODING_ISO_8859_13);
                ENCODING2("ISO-8859-14", "ISO8859-14", PM_ENCODING_ISO_8859_14);
                ENCODING2("ISO-8859-15", "ISO8859-15", PM_ENCODING_ISO_8859_15);
                ENCODING2("ISO-8859-16", "ISO8859-16", PM_ENCODING_ISO_8859_16);
#endif
                break;
            case 'K': case 'k':
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING1("KOI8-R", PM_ENCODING_KOI8_R);
                ENCODING1("KOI8-U", PM_ENCODING_KOI8_U);
#endif
                break;
            case 'M': case 'm':
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING1("macCentEuro", PM_ENCODING_MAC_CENT_EURO);
                ENCODING1("macCroatian", PM_ENCODING_MAC_CROATIAN);
                ENCODING1("macCyrillic", PM_ENCODING_MAC_CYRILLIC);
                ENCODING1("macGreek", PM_ENCODING_MAC_GREEK);
                ENCODING1("macIceland", PM_ENCODING_MAC_ICELAND);
                ENCODING1("MacJapanese", PM_ENCODING_MAC_JAPANESE);
                ENCODING1("MacJapan", PM_ENCODING_MAC_JAPANESE);
                ENCODING1("macRoman", PM_ENCODING_MAC_ROMAN);
                ENCODING1("macRomania", PM_ENCODING_MAC_ROMANIA);
                ENCODING1("macThai", PM_ENCODING_MAC_THAI);
                ENCODING1("macTurkish", PM_ENCODING_MAC_TURKISH);
                ENCODING1("macUkraine", PM_ENCODING_MAC_UKRAINE);
#endif
                break;
            case 'P': case 'p':
                ENCODING1("PCK", PM_ENCODING_WINDOWS_31J);
                break;
            case 'S': case 's':
                ENCODING1("SJIS", PM_ENCODING_WINDOWS_31J);
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING1("Shift_JIS", PM_ENCODING_SHIFT_JIS);
                ENCODING1("SJIS-DoCoMo", PM_ENCODING_SJIS_DOCOMO);
                ENCODING1("SJIS-KDDI", PM_ENCODING_SJIS_KDDI);
                ENCODING1("SJIS-SoftBank", PM_ENCODING_SJIS_SOFTBANK);
                ENCODING1("stateless-ISO-2022-JP", PM_ENCODING_STATELESS_ISO_2022_JP);
                ENCODING1("stateless-ISO-2022-JP-KDDI", PM_ENCODING_STATELESS_ISO_2022_JP_KDDI);
#endif
                break;
            case 'T': case 't':
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING1("TIS-620", PM_ENCODING_TIS_620);
#endif
                break;
            case 'U': case 'u':
                ENCODING1("US-ASCII", PM_ENCODING_US_ASCII);
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING2("UTF8-MAC", "UTF-8-HFS", PM_ENCODING_UTF8_MAC);
                ENCODING1("UTF8-DoCoMo", PM_ENCODING_UTF8_DOCOMO);
                ENCODING1("UTF8-KDDI", PM_ENCODING_UTF8_KDDI);
                ENCODING1("UTF8-SoftBank", PM_ENCODING_UTF8_SOFTBANK);
#endif
                break;
            case 'W': case 'w':
                ENCODING1("Windows-31J", PM_ENCODING_WINDOWS_31J);
#ifndef PRISM_ENCODING_EXCLUDE_FULL
                ENCODING1("Windows-874", PM_ENCODING_WINDOWS_874);
                ENCODING1("Windows-1250", PM_ENCODING_WINDOWS_1250);
                ENCODING1("Windows-1251", PM_ENCODING_WINDOWS_1251);
                ENCODING1("Windows-1252", PM_ENCODING_WINDOWS_1252);
                ENCODING1("Windows-1253", PM_ENCODING_WINDOWS_1253);
                ENCODING1("Windows-1254", PM_ENCODING_WINDOWS_1254);
                ENCODING1("Windows-1255", PM_ENCODING_WINDOWS_1255);
                ENCODING1("Windows-1256", PM_ENCODING_WINDOWS_1256);
                ENCODING1("Windows-1257", PM_ENCODING_WINDOWS_1257);
                ENCODING1("Windows-1258", PM_ENCODING_WINDOWS_1258);
#endif
                break;
            case '6':
                ENCODING1("646", PM_ENCODING_US_ASCII);
                break;
        }
    }

#undef ENCODING2
#undef ENCODING1

    // If we didn't match any encodings, return NULL.
    return NULL;
}
