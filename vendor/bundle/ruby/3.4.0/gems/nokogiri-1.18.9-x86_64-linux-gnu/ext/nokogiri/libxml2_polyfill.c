#include <nokogiri.h>

#ifndef HAVE_XMLCTXTSETOPTIONS
/* based on libxml2-2.14.0-dev (1d8bd126) parser.c xmlCtxtSetInternalOptions */
int
xmlCtxtSetOptions(xmlParserCtxtPtr ctxt, int options)
{
  int keepMask = 0;
  int allMask;

  if (ctxt == NULL) {
    return (-1);
  }

  /*
   * XInclude options aren't handled by the parser.
   *
   * XML_PARSE_XINCLUDE
   * XML_PARSE_NOXINCNODE
   * XML_PARSE_NOBASEFIX
   */
  allMask = XML_PARSE_RECOVER |
            XML_PARSE_NOENT |
            XML_PARSE_DTDLOAD |
            XML_PARSE_DTDATTR |
            XML_PARSE_DTDVALID |
            XML_PARSE_NOERROR |
            XML_PARSE_NOWARNING |
            XML_PARSE_PEDANTIC |
            XML_PARSE_NOBLANKS |
#ifdef LIBXML_SAX1_ENABLED
            XML_PARSE_SAX1 |
#endif
            XML_PARSE_NONET |
            XML_PARSE_NODICT |
            XML_PARSE_NSCLEAN |
            XML_PARSE_NOCDATA |
            XML_PARSE_COMPACT |
            XML_PARSE_OLD10 |
            XML_PARSE_HUGE |
            XML_PARSE_OLDSAX |
            XML_PARSE_IGNORE_ENC |
            XML_PARSE_BIG_LINES;

  ctxt->options = (ctxt->options & keepMask) | (options & allMask);

  /*
   * For some options, struct members are historically the source
   * of truth. The values are initalized from global variables and
   * old code could also modify them directly. Several older API
   * functions that don't take an options argument rely on these
   * deprecated mechanisms.
   *
   * Once public access to struct members and the globals are
   * disabled, we can use the options bitmask as source of
   * truth, making all these struct members obsolete.
   *
   * The XML_DETECT_IDS flags is misnamed. It simply enables
   * loading of the external subset.
   */
  ctxt->recovery = (options & XML_PARSE_RECOVER) ? 1 : 0;
  ctxt->replaceEntities = (options & XML_PARSE_NOENT) ? 1 : 0;
  ctxt->loadsubset = (options & XML_PARSE_DTDLOAD) ? XML_DETECT_IDS : 0;
  ctxt->loadsubset |= (options & XML_PARSE_DTDATTR) ? XML_COMPLETE_ATTRS : 0;
  ctxt->validate = (options & XML_PARSE_DTDVALID) ? 1 : 0;
  ctxt->pedantic = (options & XML_PARSE_PEDANTIC) ? 1 : 0;
  ctxt->keepBlanks = (options & XML_PARSE_NOBLANKS) ? 0 : 1;
  ctxt->dictNames = (options & XML_PARSE_NODICT) ? 0 : 1;

  /*
   * Changing SAX callbacks is a bad idea. This should be fixed.
   */
  if (options & XML_PARSE_NOBLANKS) {
    ctxt->sax->ignorableWhitespace = xmlSAX2IgnorableWhitespace;
  }
  if (options & XML_PARSE_NOCDATA) {
    ctxt->sax->cdataBlock = NULL;
  }
  if (options & XML_PARSE_HUGE) {
    if (ctxt->dict != NULL) {
      xmlDictSetLimit(ctxt->dict, 0);
    }
  }

  ctxt->linenumbers = 1;

  return (options & ~allMask);
}
#endif

#ifndef HAVE_XMLCTXTGETOPTIONS
int
xmlCtxtGetOptions(xmlParserCtxtPtr ctxt)
{
  return (ctxt->options);
}
#endif

#ifndef HAVE_XMLSWITCHENCODINGNAME
int
xmlSwitchEncodingName(xmlParserCtxtPtr ctxt, const char *encoding)
{
  if (ctxt == NULL) {
    return (-1);
  }

  xmlCharEncodingHandlerPtr handler = xmlFindCharEncodingHandler(encoding);
  if (handler == NULL) {
    return (-1);
  }

  return (xmlSwitchToEncoding(ctxt, handler));
}
#endif
