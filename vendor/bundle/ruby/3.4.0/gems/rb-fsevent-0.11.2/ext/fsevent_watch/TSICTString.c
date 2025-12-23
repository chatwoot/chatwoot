//
//  TSICTString.c
//  TSITString
//
//  Created by Travis Tilley on 9/27/11.
//

#include "TSICTString.h"


const char* const TNetstringTypes = ",#^!~}]Z";
const char* const OTNetstringTypes = ",#^!~{[Z";
const UInt8 TNetstringSeparator = ':';

TSITStringFormat TSITStringDefaultFormat = kTSITStringFormatTNetstring;

static const CFRange BeginningRange = {0,0};

static CFTypeID kCFDataTypeID       = -1UL;
static CFTypeID kCFStringTypeID     = -1UL;
static CFTypeID kCFNumberTypeID     = -1UL;
static CFTypeID kCFBooleanTypeID    = -1UL;
static CFTypeID kCFNullTypeID       = -1UL;
static CFTypeID kCFArrayTypeID      = -1UL;
static CFTypeID kCFDictionaryTypeID = -1UL;


__attribute__((constructor)) void Init_TSICTString(void)
{
    kCFDataTypeID        = CFDataGetTypeID();
    kCFStringTypeID      = CFStringGetTypeID();
    kCFNumberTypeID      = CFNumberGetTypeID();
    kCFBooleanTypeID     = CFBooleanGetTypeID();
    kCFNullTypeID        = CFNullGetTypeID();
    kCFArrayTypeID       = CFArrayGetTypeID();
    kCFDictionaryTypeID  = CFDictionaryGetTypeID();
}


void TSICTStringSetDefaultFormat(TSITStringFormat format)
{
    if (format == kTSITStringFormatDefault) {
        TSITStringDefaultFormat = kTSITStringFormatTNetstring;
    } else {
        TSITStringDefaultFormat = format;
    }
}

TSITStringFormat TSICTStringGetDefaultFormat(void)
{
    return TSITStringDefaultFormat;
}


void TSICTStringDestroy(TStringIRep* rep)
{
    CFRelease(rep->data);
    free(rep->length);
    free(rep);
}


static inline TStringIRep* TSICTStringCreateWithDataOfTypeAndFormat(CFDataRef data, TSITStringTag type, TSITStringFormat format)
{
    if (format == kTSITStringFormatDefault) {
        format = TSICTStringGetDefaultFormat();
    }

    TStringIRep* rep = calloc(1, sizeof(TStringIRep));
    rep->data = CFDataCreateCopy(kCFAllocatorDefault, data);
    rep->type = type;
    rep->format = format;
    rep->length = calloc(10, sizeof(char));

    CFIndex len = CFDataGetLength(rep->data);
    if (snprintf(rep->length, 10, "%lu", len)) {
        return rep;
    } else {
        TSICTStringDestroy(rep);
        return NULL;
    }
}

static inline CFDataRef TSICTStringCreateDataFromIntermediateRepresentation(TStringIRep* rep)
{
    CFIndex len = CFDataGetLength(rep->data);
    CFMutableDataRef buffer = CFDataCreateMutableCopy(kCFAllocatorDefault, (len + 12), rep->data);
    UInt8* bufferBytes = CFDataGetMutableBytePtr(buffer);

    size_t prefixLength = strlen(rep->length) + 1;
    CFDataReplaceBytes(buffer, BeginningRange, (const UInt8*)rep->length, (CFIndex)prefixLength);

    if (rep->format == kTSITStringFormatTNetstring) {
        const UInt8 ftag = (UInt8)TNetstringTypes[rep->type];
        CFDataAppendBytes(buffer, &ftag, 1);
        bufferBytes[(prefixLength - 1)] = TNetstringSeparator;
    } else if (rep->format == kTSITStringFormatOTNetstring) {
        const UInt8 ftag = (UInt8)OTNetstringTypes[rep->type];
        bufferBytes[(prefixLength - 1)] = ftag;
    }

    CFDataRef dataRep = CFDataCreateCopy(kCFAllocatorDefault, buffer);
    CFRelease(buffer);

    return dataRep;
}

static inline CFStringRef TSICTStringCreateStringFromIntermediateRepresentation(TStringIRep* rep)
{
    CFDataRef data = TSICTStringCreateDataFromIntermediateRepresentation(rep);
    CFStringRef string = CFStringCreateFromExternalRepresentation(kCFAllocatorDefault, data, kCFStringEncodingUTF8);
    CFRelease(data);
    return string;
}

static inline void TSICTStringAppendObjectToMutableDataWithFormat(CFTypeRef object, CFMutableDataRef buffer, TSITStringFormat format)
{
    if (object == NULL) {
        object = kCFNull;
    }

    CFRetain(object);

    TStringIRep* objRep = TSICTStringCreateWithObjectAndFormat(object, format);
    CFDataRef objData = TSICTStringCreateDataFromIntermediateRepresentation(objRep);
    CFDataAppendBytes(buffer, (CFDataGetBytePtr(objData)), CFDataGetLength(objData));
    CFRelease(objData);
    TSICTStringDestroy(objRep);

    CFRelease(object);
}

static void ArrayBufferAppendCallback(const void* item, void* context)
{
    TStringCollectionCallbackContext* cx = (TStringCollectionCallbackContext*)context;
    CFMutableDataRef buffer = cx->buffer;
    TSITStringFormat format = cx->format;

    TSICTStringAppendObjectToMutableDataWithFormat(item, buffer, format);
}

static void DictionaryBufferAppendCallback(const void* key, const void* value, void* context)
{
    TStringCollectionCallbackContext* cx = (TStringCollectionCallbackContext*)context;
    CFMutableDataRef buffer = cx->buffer;
    TSITStringFormat format = cx->format;

    TSICTStringAppendObjectToMutableDataWithFormat(key, buffer, format);
    TSICTStringAppendObjectToMutableDataWithFormat(value, buffer, format);
}


CFDataRef TSICTStringCreateRenderedData(TStringIRep* rep)
{
    return TSICTStringCreateDataFromIntermediateRepresentation(rep);
}

CFDataRef TSICTStringCreateRenderedDataFromObjectWithFormat(CFTypeRef object, TSITStringFormat format)
{
    if (object == NULL) {
        object = kCFNull;
    }

    CFRetain(object);

    TStringIRep* rep = TSICTStringCreateWithObjectAndFormat(object, format);
    CFDataRef data = TSICTStringCreateDataFromIntermediateRepresentation(rep);

    TSICTStringDestroy(rep);
    CFRelease(object);

    return data;
}

CFStringRef TSICTStringCreateRenderedString(TStringIRep* rep)
{
    return TSICTStringCreateStringFromIntermediateRepresentation(rep);
}

CFStringRef TSICTStringCreateRenderedStringFromObjectWithFormat(CFTypeRef object, TSITStringFormat format)
{
    if (object == NULL) {
        object = kCFNull;
    }

    CFRetain(object);

    TStringIRep* rep = TSICTStringCreateWithObjectAndFormat(object, format);
    CFStringRef string = TSICTStringCreateStringFromIntermediateRepresentation(rep);

    TSICTStringDestroy(rep);
    CFRelease(object);

    return string;
}


TStringIRep* TSICTStringCreateWithObjectAndFormat(CFTypeRef object, TSITStringFormat format)
{
    if (object == NULL) {
        return TSICTStringCreateNullWithFormat(format);
    }
    CFRetain(object);

    CFTypeID cfType = CFGetTypeID(object);
    TStringIRep* rep = NULL;

    if (cfType == kCFDataTypeID) {
        rep = TSICTStringCreateWithDataOfTypeAndFormat(object, kTSITStringTagString, format);
    } else if (cfType == kCFStringTypeID) {
        rep = TSICTStringCreateWithStringAndFormat(object, format);
    } else if (cfType == kCFNumberTypeID) {
        rep = TSICTStringCreateWithNumberAndFormat(object, format);
    } else if (cfType == kCFBooleanTypeID) {
        if (CFBooleanGetValue(object)) {
            rep = TSICTStringCreateTrueWithFormat(format);
        } else {
            rep = TSICTStringCreateFalseWithFormat(format);
        }
    } else if (cfType == kCFNullTypeID) {
        rep = TSICTStringCreateNullWithFormat(format);
    } else if (cfType == kCFArrayTypeID) {
        rep = TSICTStringCreateWithArrayAndFormat(object, format);
    } else if (cfType == kCFDictionaryTypeID) {
        rep = TSICTStringCreateWithDictionaryAndFormat(object, format);
    } else {
        rep = TSICTStringCreateInvalidWithFormat(format);
    }

    CFRelease(object);
    return rep;
}

TStringIRep* TSICTStringCreateWithStringAndFormat(CFStringRef string, TSITStringFormat format)
{
    CFRetain(string);
    CFDataRef data = CFStringCreateExternalRepresentation(kCFAllocatorDefault, string, kCFStringEncodingUTF8, '?');
    TStringIRep* rep = TSICTStringCreateWithDataOfTypeAndFormat(data, kTSITStringTagString, format);
    CFRelease(data);
    CFRelease(string);
    return rep;
}

TStringIRep* TSICTStringCreateWithNumberAndFormat(CFNumberRef number, TSITStringFormat format)
{
    CFRetain(number);
    TSITStringTag tag = kTSITStringTagNumber;
    CFDataRef data;
    CFNumberType numType = CFNumberGetType(number);

    switch(numType) {
        case kCFNumberCharType:
        {
            int value;
            if (CFNumberGetValue(number, kCFNumberIntType, &value)) {
                if (value == 0 || value == 1) {
                    tag = kTSITStringTagBool;
                } else {
                    tag = kTSITStringTagString;
                }
            }
            break;
        }
        case kCFNumberFloat32Type:
        case kCFNumberFloat64Type:
        case kCFNumberFloatType:
        case kCFNumberDoubleType:
        {
            tag = kTSITStringTagFloat;
            break;
        }
    }

    if (tag == kTSITStringTagBool) {
        bool value;
        CFNumberGetValue(number, kCFNumberIntType, &value);
        if (value) {
            data = CFDataCreate(kCFAllocatorDefault, (UInt8*)"true", 4);
        } else {
            data = CFDataCreate(kCFAllocatorDefault, (UInt8*)"false", 5);
        }
    } else if (tag == kTSITStringTagFloat) {
        char buf[32];
        char *p, *e;
        double value;

        CFNumberGetValue(number, numType, &value);
        sprintf(buf, "%#.15g", value);

        e = buf + strlen(buf);
        p = e;
        while (p[-1]=='0' && ('0' <= p[-2] && p[-2] <= '9')) {
            p--;
        }
        memmove(p, e, strlen(e)+1);

        data = CFDataCreate(kCFAllocatorDefault, (UInt8*)buf, (CFIndex)strlen(buf));
    } else {
        char buf[32];
        SInt64 value;
        CFNumberGetValue(number, numType, &value);
        sprintf(buf, "%lli", value);
        data = CFDataCreate(kCFAllocatorDefault, (UInt8*)buf, (CFIndex)strlen(buf));
    }

    TStringIRep* rep = TSICTStringCreateWithDataOfTypeAndFormat(data, tag, format);
    CFRelease(data);
    CFRelease(number);
    return rep;
}

TStringIRep* TSICTStringCreateTrueWithFormat(TSITStringFormat format)
{
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, (UInt8*)"true", 4);
    TStringIRep* rep = TSICTStringCreateWithDataOfTypeAndFormat(data, kTSITStringTagBool, format);
    CFRelease(data);
    return rep;
}

TStringIRep* TSICTStringCreateFalseWithFormat(TSITStringFormat format)
{
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, (UInt8*)"false", 5);
    TStringIRep* rep = TSICTStringCreateWithDataOfTypeAndFormat(data, kTSITStringTagBool, format);
    CFRelease(data);
    return rep;
}

TStringIRep* TSICTStringCreateNullWithFormat(TSITStringFormat format)
{
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, NULL, 0);
    TStringIRep* rep = TSICTStringCreateWithDataOfTypeAndFormat(data, kTSITStringTagNull, format);
    CFRelease(data);
    return rep;
}

TStringIRep* TSICTStringCreateInvalidWithFormat(TSITStringFormat format)
{
    CFDataRef data = CFDataCreate(kCFAllocatorDefault, NULL, 0);
    TStringIRep* rep = TSICTStringCreateWithDataOfTypeAndFormat(data, kTSITStringTagInvalid, format);
    CFRelease(data);
    return rep;
}

TStringIRep* TSICTStringCreateWithArrayAndFormat(CFArrayRef array, TSITStringFormat format)
{
    CFRetain(array);

    CFMutableDataRef buffer = CFDataCreateMutable(kCFAllocatorDefault, 0);

    CFRange all = CFRangeMake(0, CFArrayGetCount(array));
    TStringCollectionCallbackContext cx = {buffer, format};
    CFArrayApplyFunction(array, all, ArrayBufferAppendCallback, &cx);

    TStringIRep* rep = TSICTStringCreateWithDataOfTypeAndFormat(buffer, kTSITStringTagList, format);
    CFRelease(buffer);
    CFRelease(array);
    return rep;
}

TStringIRep* TSICTStringCreateWithDictionaryAndFormat(CFDictionaryRef dictionary, TSITStringFormat format)
{
    CFRetain(dictionary);

    CFMutableDataRef buffer = CFDataCreateMutable(kCFAllocatorDefault, 0);

    TStringCollectionCallbackContext cx = {buffer, format};
    CFDictionaryApplyFunction(dictionary, DictionaryBufferAppendCallback, &cx);

    TStringIRep* rep = TSICTStringCreateWithDataOfTypeAndFormat(buffer, kTSITStringTagDict, format);
    CFRelease(buffer);
    CFRelease(dictionary);
    return rep;
}
