#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "twepl_parse.c"

MODULE = HTML::EmbeddedPerl PACKAGE = HTML::EmbeddedPerl

void
headers_out(...)
  INIT:
    char *key   = (sv_isobject(ST(0)))? SvPV_nolen(ST(1)) : SvPV_nolen(ST(0));
    char *value = (sv_isobject(ST(0)))? SvPV_nolen(ST(2)) : SvPV_nolen(ST(1));
  CODE:
    HV *hdr = perl_get_hv(EPL_PM_NAME "::HEADER", FALSE);
    /* Content-Type */
    if(strcasecmp(key, "Content-Type") == 0){
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(sv_2mortal(newSVpv(value, 0)));
      PUTBACK;
      call_pv(EPL_PM_NAME "::content_type", G_VOID|G_KEEPERR|G_DISCARD);
      SPAGAIN;
      PUTBACK;
      FREETMPS;
      LEAVE;
    } else{
      if(hv_exists(hdr, key, strlen(key)) && *value == '\0'){
        hv_delete(hdr, key, strlen(key), FALSE);
      } else{
        hv_store(hdr, key, strlen(key), newSVpv(value, 0), 0);
      }
    }

void
header(...)
  INIT:
    char *header_pair = (sv_isobject(ST(0)))? SvPV_nolen(ST(1)) : SvPV_nolen(ST(0));
  CODE:
      HV *hdr = perl_get_hv(EPL_PM_NAME "::HEADER", FALSE);
      SV *key;
      SV *val;
    char *pos;
    if((pos = strstr(header_pair, HEAD_DM)) != NULL){
      key = newSVpv(header_pair, ((long)pos - (long)header_pair));
      val = newSVpv(pos+2, (strlen(pos) - 2));
      ENTER;
      SAVETMPS;
      PUSHMARK(SP);
      XPUSHs(sv_2mortal(key));
      XPUSHs(sv_2mortal(val));
      PUTBACK;
      call_pv(EPL_PM_NAME "::headers_out", G_VOID|G_KEEPERR|G_DISCARD);
      SPAGAIN;
      PUTBACK;
      FREETMPS;
      LEAVE;
    } else{
      Perl_warn(aTHX_ "Usage: %s(%s)", "twepl::header", "header string pair");
    }

void
content_type(contype)
  INIT:
    char *contype = (sv_isobject(ST(0)))? SvPV_nolen(ST(1)) : SvPV_nolen(ST(0));
  CODE:
    SV *ctt = perl_get_sv(EPL_PM_NAME "::CONTYP", FALSE);
    (*contype == '\0')? sv_setpv(ctt, EPL_CONTYPE) : sv_setpv(ctt, contype);

void
echo(...)
  CODE:
    SV* bak = perl_get_sv(EPL_PM_NAME "::STOTMP", FALSE);
    PerlIO_puts((PerlIO*)SvIV(bak), SvPV_nolen(sv_isobject(ST(0))? ST(1) : ST(0)));

SV*
new(...)
  INIT:
    char *classname = (sv_isobject(ST(0)))? HvNAME(SvSTASH(SvRV(ST(0)))) : SvPV_nolen(ST(0));
  CODE:
    SV *obj;
    SV *ref;
    obj = (SV*)newSV(0);
    ref = newRV_noinc(obj);
    sv_bless(ref, gv_stashpv(classname, FALSE));
    RETVAL = ref;
  OUTPUT:
    RETVAL

void
run_file(file)
  INIT:
    char *file;
  CODE:
     int  ret;
    char *cnv;
    cnv = twepl_file(file , cnv, &ret);
    if(ret != TWEPL_OKEY_NOERR)
      Perl_warn(aTHX_ "Usage: %s(%s)", "twepl::run_code", "code");
    eval_pv((const char*)cnv, G_EVAL|G_KEEPERR|G_DISCARD);
    free(cnv);
    XSRETURN_EMPTY;

void
run_code(code)
  INIT:
    char *code;
  CODE:
     int  ret;
    char *cnv;
    cnv = twepl_code(code , cnv, &ret);
    if(ret != TWEPL_OKEY_NOERR)
      Perl_warn(aTHX_ "Usage: %s(%s)", "twepl::run_code", "code");
    eval_pv((const char*)cnv, G_EVAL|G_KEEPERR|G_DISCARD);
    free(cnv);
    XSRETURN_EMPTY;
