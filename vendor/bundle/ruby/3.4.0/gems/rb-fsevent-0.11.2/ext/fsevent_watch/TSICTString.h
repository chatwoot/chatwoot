//
//  TSICTString.h
//  TSITString
//
//  Created by Travis Tilley on 9/27/11.
//

#ifndef TSICTString_H
#define TSICTString_H

#include <CoreFoundation/CoreFoundation.h>


typedef enum {
    kTSITStringTagString   = 0,
    kTSITStringTagNumber   = 1,
    kTSITStringTagFloat    = 2,
    kTSITStringTagBool     = 3,
    kTSITStringTagNull     = 4,
    kTSITStringTagDict     = 5,
    kTSITStringTagList     = 6,
    kTSITStringTagInvalid  = 7,
} TSITStringTag;

extern const char* const TNetstringTypes;
extern const char* const OTNetstringTypes;
extern const UInt8 TNetstringSeparator;

typedef enum {
    kTSITStringFormatDefault        = 0,
    kTSITStringFormatOTNetstring    = 1,
    kTSITStringFormatTNetstring     = 2,
} TSITStringFormat;

extern TSITStringFormat TSITStringDefaultFormat;

typedef struct TSITStringIntermediate {
    CFDataRef           data;
    char*               length;
    TSITStringTag       type;
    TSITStringFormat    format;
} TStringIRep;

typedef struct {
    CFMutableDataRef    buffer;
    TSITStringFormat    format;
} TStringCollectionCallbackContext;


void Init_TSICTString(void);

void TSICTStringSetDefaultFormat(TSITStringFormat format);
TSITStringFormat TSICTStringGetDefaultFormat(void);

void TSICTStringDestroy(TStringIRep* rep);

CFDataRef TSICTStringCreateRenderedData(TStringIRep* rep);
CFDataRef TSICTStringCreateRenderedDataFromObjectWithFormat(CFTypeRef object, TSITStringFormat format);

CFStringRef TSICTStringCreateRenderedString(TStringIRep* rep);
CFStringRef TSICTStringCreateRenderedStringFromObjectWithFormat(CFTypeRef object, TSITStringFormat format);

TStringIRep* TSICTStringCreateWithObjectAndFormat(CFTypeRef object, TSITStringFormat format);
TStringIRep* TSICTStringCreateWithStringAndFormat(CFStringRef string, TSITStringFormat format);
TStringIRep* TSICTStringCreateWithNumberAndFormat(CFNumberRef number, TSITStringFormat format);
TStringIRep* TSICTStringCreateTrueWithFormat(TSITStringFormat format);
TStringIRep* TSICTStringCreateFalseWithFormat(TSITStringFormat format);
TStringIRep* TSICTStringCreateNullWithFormat(TSITStringFormat format);
TStringIRep* TSICTStringCreateInvalidWithFormat(TSITStringFormat format);
TStringIRep* TSICTStringCreateWithArrayAndFormat(CFArrayRef array, TSITStringFormat format);
TStringIRep* TSICTStringCreateWithDictionaryAndFormat(CFDictionaryRef dictionary, TSITStringFormat format);


#endif
