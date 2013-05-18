#ifndef __TWINKLE_PERL_APMOD_H__
#define __TWINKLE_PERL_APMOD_H__

#include "httpd.h"
#include "http_config.h"
#include "http_core.h"
#include "http_main.h"
#include "http_protocol.h"
#include "http_request.h"
#include "http_log.h"
#include "ap_compat.h"
#include "ap_config.h"
#include "apr_strings.h"
#include "util_filter.h"
#include "util_script.h"
#include "mpm_common.h"

#define __MOD_TWEPL__

#include "twepl_parse.h"

#pragma pack(1)

#define YES   1
#define NO    0

#define ASCII_CRLF "\015\012"

#define IS_NONOPT 0x0000
#define IS_ENGINE 0x1000
#define IS_SOURCE 0x0100
#define IS_DEBUGS 0x0010
#define IS_OPCODE 0x0001

#define if_engine(f) (f & IS_ENGINE)
#define if_source(f) (f & IS_SOURCE)
#define if_debugs(f) (f & IS_DEBUGS)
#define if_opcode(f) (f & IS_OPCODE)

#define MODULE  "twepl"
#define PACKAGE "twepl"

module AP_MODULE_DECLARE_DATA twepl_module;

typedef struct{
  unsigned char *TWEPL_OPTIONS;
  unsigned short TWEPL_RDFLINE;
} TWEPL_CONFIG, *PTWEPL_CONFIG;

#endif
