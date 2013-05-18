#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define __EMBEDDED_MODULE__
#include "twepl_xcore.c"
#undef __EMBEDDED_MODULE__

MODULE = HTML::EmbeddedPerl PACKAGE = HTML::EmbeddedPerl

BOOT:
  /* Register */
  twepl_register(aTHX_ file);

SV*
_twepl_handler(file_path)
      char *file_path;
  CODE:

    PerlIO *pio;
    PerlIO *pxo;
        GV *pgv;
        GV *ogv;
        SV *bak;
        SV *buf;
      char *epc;
       int  ret;

    /* Buffer */
    buf = perl_get_sv(EPL_PM_NAME "::STOBUF", FALSE);

    /* Convert */
    epc = twepl_file(file_path, epc, &ret);

    if(ret != TWEPL_OKEY_NOERR){
      Perl_croak(aTHX_ "%s", twepl_strerr(ret));
    }

    /* PerlIO_stdout -> PerlIO::Scalar */
    if(! twepl_do_open(aTHX_ EPL_PM_NAME "::STOTMP", "STDOUT", EPL_FOM, EPL_PM_NAME "::STOBUF", EPL_FOF)){
      Perl_croak(aTHX_ "_twepl_handler: failed override stdhandle.");
    }

    /* Run */
    eval_pv((const char *)epc, G_EVAL|G_KEEPERR|G_DISCARD);

    if(SvTRUE(ERRSV)){
      Perl_croak(aTHX_ "%s", SvPV_nolen(ERRSV));
    }

    /* Clean-Ups */
    free(epc);

    /* Return Value */
    RETVAL = newSVpv(SvPV_nolen(buf), 0);

    /* PerlIO_stdout <- PerlIO::Scalar */
    twepl_do_close(aTHX_ "STDOUT");

  OUTPUT:
    RETVAL
