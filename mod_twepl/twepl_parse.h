#ifndef __TWEPL_PARSE_H__
#define __TWEPL_PARSE_H__

  #define PERLIO_NOT_STDIO 0
  #define USE_PERLIO

  #include "EXTERN.h"
  #include "perl.h"
  #include "perliol.h"
  #include "XSUB.h"
  #include "ppport.h"

  #pragma pack(1)

  #ifndef TRUE
    #define TRUE 1
  #endif
  #ifndef FALSE
    #define FALSE 0
  #endif

  #define HEAD_DM ": \0"

  #define HTML_PS "print \"\0"
  #define HTML_PE "\";\0"
  #define HTML_LA 9
  #define HTML_LS 7
  #define HTML_LE 2

  enum TWEPL_STATE {
    TWEPL_OKEY_NOERR,
    TWEPL_FAIL_FOPEN,
    TWEPL_FAIL_FSEEK,
    TWEPL_FAIL_FTELL,
    TWEPL_FAIL_FREAD,
    TWEPL_FAIL_SLENG,
    TWEPL_FAIL_MALOC,
    TWEPL_FAIL_TAGOP,
    TWEPL_FAIL_TAGED
  };

  const char *TWEPL_ERROR_STRING[] = {
    "no error\0",
    "open\0",
    "seek\0",
    "tell\0",
    "read\0",
    "strlen\0",
    "malloc\0",
    "tagop\0",
    "tagend\0",
    NULL
  };

  static PerlInterpreter *tweps;

  #define EPL_XS_NAME "twepl"
  #define EPL_PM_NAME "HTML::EmbeddedPerl"

  #define EPL_VV_NAME "main::ep"
  #define EPL_VERSION "0.90"

  #define EPL_TAG "?"

  #define EPL_FIM "+<:scalar\0"
  #define EPL_FOM "+<:scalar\0"

  #define EPL_FIF O_RDWR
  #define EPL_FOF O_RDWR

  #define EPL_CONTYPE "text/html\0"
  #define EPL_POW_KEY "X-Powered-By\0"
  #define EPL_POW_VAL EPL_XS_NAME "/" EPL_VERSION "\0"

  #define EPL_CRIGHTS \
    "Copyright (C)2013 Twinkle Computing All rights reserved.\n" \
    "\n" \
    "Report bugs to <twepl@twinkle.tk>\n\0"

  #define EPC_APPNAME "twepc"
  #define EPP_APPNAME "twepl"

  #define EPC_OPTIONS \
    EPC_APPNAME " [OPTION(FEATURE)S] file\n\n" \
    "  [OPTIONS]\n" \
    "    -o    output filename, default is stdout.\n\n\0"

  #define EPC_VERSION \
    EPC_APPNAME " (twinkle-utils) " EPL_VERSION "\n" \
    "\n" EPL_CRIGHTS

  #define EPP_OPTIONS \
    EPP_APPNAME " [OPTION(FEATURE)S] file\n\n" \
    "  [OPTIONS]\n" \
    "    -c    convert-mode: output converted code.\n" \
    "    -o    output filename, default is stdout.\n\n\0"

  #define EPP_VERSION \
    EPP_APPNAME " (twinkle-utils) " EPL_VERSION "\n" \
    "\n" EPL_CRIGHTS

  long count_quote(char *src, long stp, long edp);
  long twepl_serach_tag(char *src, long ssz, long idx, int ttp);
  int twepl_lint(char *src, long ssz, long *nsz);
  int twepl_quote(char *src, char *cnv, long stp, long edp);
  int twepl_parse(char *src, char *cnv, long ssz);

  char *twepl_file(char *flp, char *cnv, int *err);
  char *twepl_code(char *src, char *cnv, int *err);

  const char *twepl_strerr(int num);

#endif
