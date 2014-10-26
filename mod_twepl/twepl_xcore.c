#ifndef __TWEPL_XCORE_C__
#define __TWEPL_XCORE_C__

#include "twepl_parse.c"
#include "twepl_xsubs.c"

#ifdef __EMBEDDED_MODULE__
  #define EPL_VAR_FLAG FALSE
#else
  #define EPL_VAR_FLAG GV_ADD|GV_ADDMULTI
#endif

EXTERN_C void twepl_register(pTHX_ const char *file){

  HV *hdr;
  SV *ctt;
  SV *ibf;
  SV *obf;

  newXS(EPL_PM_NAME "::headers_out", XS_HTML__EmbeddedPerl_headers_out, file);
  newXS(EPL_PM_NAME "::header", XS_HTML__EmbeddedPerl_header, file);
  newXS(EPL_PM_NAME "::content_type", XS_HTML__EmbeddedPerl_content_type, file);
  newXS(EPL_PM_NAME "::echo", XS_HTML__EmbeddedPerl_echo, file);
  newXS(EPL_PM_NAME "::new", XS_HTML__EmbeddedPerl_new, file);
  newXS(EPL_PM_NAME "::run_file", XS_HTML__EmbeddedPerl_run_file, file);
  newXS(EPL_PM_NAME "::run_code", XS_HTML__EmbeddedPerl_run_code, file);

  newXS(EPL_XS_NAME "::headers_out", XS_HTML__EmbeddedPerl_headers_out, file);
  newXS(EPL_XS_NAME "::header", XS_HTML__EmbeddedPerl_header, file);
  newXS(EPL_XS_NAME "::content_type", XS_HTML__EmbeddedPerl_content_type, file);
  newXS(EPL_XS_NAME "::echo", XS_HTML__EmbeddedPerl_echo, file);
  newXS(EPL_XS_NAME "::new", XS_HTML__EmbeddedPerl_new, file);
  newXS(EPL_XS_NAME "::run_file", XS_HTML__EmbeddedPerl_run_file, file);
  newXS(EPL_XS_NAME "::run_code", XS_HTML__EmbeddedPerl_run_code, file);

  newXS("main::headers_out", XS_HTML__EmbeddedPerl_headers_out, file);
  newXS("main::header", XS_HTML__EmbeddedPerl_header, file);
  newXS("main::content_type", XS_HTML__EmbeddedPerl_content_type, file);
  newXS("main::echo", XS_HTML__EmbeddedPerl_echo, file);

  /* HEADERS */
  hdr = perl_get_hv(EPL_PM_NAME "::HEADER", EPL_VAR_FLAG);

  /* X-Powered-By */
  #ifndef __MOD_TWEPL__
    hv_store(hdr, EPL_POW_KEY, strlen(EPL_POW_KEY), newSVpv(EPL_POW_VAL, 0), 0);
  #endif

  /* CONTENT-TYPE */
  ctt = perl_get_sv(EPL_PM_NAME "::CONTYP", EPL_VAR_FLAG);
  /* text/html is default */
  sv_setpv(ctt, EPL_CONTYPE);
  /* BUFFER */
  ibf = perl_get_sv(EPL_PM_NAME "::STIBAK", EPL_VAR_FLAG);
  ibf = perl_get_sv(EPL_PM_NAME "::STITMP", EPL_VAR_FLAG);
  ibf = perl_get_sv(EPL_PM_NAME "::STIBUF", EPL_VAR_FLAG);
  ibf = perl_get_sv(EPL_PM_NAME "::STOBAK", EPL_VAR_FLAG);
  ibf = perl_get_sv(EPL_PM_NAME "::STOTMP", EPL_VAR_FLAG);
  obf = perl_get_sv(EPL_PM_NAME "::STOBUF", EPL_VAR_FLAG);

}

#ifndef __EMBEDDED_MODULE__
EXTERN_C void twepl_xs_init (pTHX);
EXTERN_C void boot_DynaLoader (pTHX_ CV* cv);
EXTERN_C void twepl_xs_init (pTHX){

  HV *inc;
  AV *isa;
  AV *exp;
  AV *eok;
  SV *ver;

  /* DynaLoader is a special case */
  newXS("DynaLoader::boot_DynaLoader", boot_DynaLoader, EPL_XS_NAME "\0");

  XS_VERSION_BOOTCHECK;

  /* EXPORTS */
  isa = perl_get_av(EPL_XS_NAME "::ISA", GV_ADD|GV_ADDMULTI);
  av_push(isa, newSVpv("Exporter", 0));
  exp = perl_get_av(EPL_XS_NAME "::EXPORT", GV_ADD|GV_ADDMULTI);
  av_push(exp, newSVpv("headers_out", 0));
  av_push(exp, newSVpv("header", 0));
  av_push(exp, newSVpv("content_type", 0));
  av_push(exp, newSVpv("echo", 0));
  ver = perl_get_sv(EPL_XS_NAME "::VERSION", GV_ADD|GV_ADDMULTI);
  sv_setpv(ver, EPL_VERSION);
  SvREADONLY(ver);

  /* Register */
  twepl_register(aTHX_ EPL_XS_NAME "\0");

  /* %INC */
  inc = perl_get_hv("INC", FALSE);
  hv_store(inc, "mod_twepl.pm", 12, newSVpv("INTERNAL:xs_init/mod_twepl.pm", 0), 0);

  if(PL_unitcheckav)
    call_list(PL_scopestack_ix, PL_unitcheckav);

}
#endif

static int twepl_do_open(pTHX_ char *ioh, char *doh, char *iom, char *iov, int iof){

  PerlIO  *pxo;
      GV  *pgv;
      SV  *ssv;

  pgv = gv_fetchpv(doh, TRUE, SVt_PVIO);
  save_gp(pgv, 1);

  pxo = PerlIO_allocate(aTHX);

  if(do_open9(pgv, iom, strlen(iom), FALSE, iof, 0, pxo, newSVpv(iov, 0), 1) == 0){
    Perl_warn(aTHX_ "%s: failed open standard %s handle.", EPL_XS_NAME "\0", doh);
    return 0;
  }

  ssv = perl_get_sv(ioh, FALSE);
  sv_setiv(ssv, (IV)pxo);

  return 1;

}

static int twepl_do_close(pTHX_ char *doh){

  GV *ogv;

  ogv = gv_fetchpv(doh, FALSE, SVt_PVIO);
  if(strcmp(doh, "STDOUT") == 0 && GvIOn(ogv) && IoOFP(GvIOn(ogv)) && (PerlIO_flush(IoOFP(GvIOn(ogv))) == -1)){
    Perl_warn(aTHX_ "%s: failed restore standard %s handle.", EPL_XS_NAME "\0", doh);
    return 0;
  }
  do_close(ogv, FALSE);

  return 1;

}

#ifdef __MOD_TWEPL__
static int twepl_do_iget(request_rec *r){

  apr_bucket_brigade *br;
          apr_bucket *bi;
          apr_size_t  bs;
        apr_status_t  rv;

              PerlIO *pi;
                  SV* ti;

          const char *rm = apr_table_get(r->subprocess_env, "REQUEST_METHOD");
          const char *cs = apr_table_get(r->headers_in, "Content-Length");
          const char *iv;

  if(strcasecmp(rm, "POST") != 0 || cs == NULL || strcmp(cs, "0") == 0){
    return APR_SUCCESS;
  }

  ti = perl_get_sv(EPL_PM_NAME "::STITMP", FALSE);
  pi = (PerlIO*)SvIV(ti);

  br = apr_brigade_create(r->pool, r->connection->bucket_alloc);

  if((rv = ap_get_brigade(r->input_filters, br, AP_MODE_READBYTES, APR_BLOCK_READ, HUGE_STRING_LEN)) != APR_SUCCESS){
    ap_log_rerror(APLOG_MARK, APLOG_ERR, rv, r, "%s: apr_get_bridge() failed.", EPL_XS_NAME "\0");
    return rv;
  }

  for(bi = APR_BRIGADE_FIRST(br); bi != APR_BRIGADE_SENTINEL(br); bi = APR_BUCKET_NEXT(bi)){
    if(APR_BUCKET_IS_EOS(bi)){
      break;
    }
    if(APR_BUCKET_IS_FLUSH(bi)){
      continue;
    }
    if((rv = apr_bucket_read(bi, &iv, &bs, APR_BLOCK_READ)) != APR_SUCCESS){
      ap_log_rerror(APLOG_MARK, APLOG_ERR, rv, r, "%s: apr_bucket_read() failed.", EPL_XS_NAME "\0");
      return rv;
    }
    PerlIO_write(pi, iv, bs);
  }

  PerlIO_seek(pi, 0, SEEK_SET);

  apr_brigade_cleanup(br);

  return APR_SUCCESS;

}
#endif

static void twepl_destroy (pTHX_ char *buf){

  perl_destruct(aTHX);
  perl_free(aTHX);
  PERL_SYS_TERM();
  if(buf != NULL) free(buf);

}

#ifndef __EMBEDDED_MODULE__
  #ifdef __MOD_TWEPL__
static int twepl_script_handler(request_rec *obj, char *ifp, int argc, char **argv, char **envp){
  #else
static int twepl_script_handler(FILE *obj, char *ifp, int argc, char **argv, char **envp){
  #endif

  PerlInterpreter  *twepl;

             char  *eps;
             char  *epb;
             char  *tmp;
              int   ret;

               HV  *hdr;
               HE  *hsh;
               SV  *ctt;

               SV  *ibf;
               SV  *obf;
           STRLEN   n_a;

             char  *twepl_argp[] = { EPL_XS_NAME "\0", "-e\0", "0\0", NULL };
             char  *twepl_args[] = { EPL_XS_NAME "\0", NULL };
             char **twepl_argv = (char **)twepl_args;
              int   twepl_argc = 1;

              int   i, l;

  eps = twepl_file(ifp , eps, &ret);

  if(ret != TWEPL_OKEY_NOERR){
    #ifdef __MOD_TWEPL__
      ap_log_rerror(APLOG_MARK, APLOG_ERR, HTTP_INTERNAL_SERVER_ERROR, (request_rec*)obj, "%s", twepl_strerr(ret));
      return HTTP_INTERNAL_SERVER_ERROR;
    #else
      fprintf(stderr, "%s\n", twepl_strerr(ret));
      return 1;
    #endif
  }

  PERL_SYS_INIT3(&argc, &argv, &envp);

  if((twepl = perl_alloc()) == NULL){
    #ifdef __MOD_TWEPL__
      ap_log_rerror(APLOG_MARK, APLOG_ERR, HTTP_INTERNAL_SERVER_ERROR, (request_rec*)obj, "%s: perl_alloc() failed.", EPL_XS_NAME "\0");
      PERL_SYS_TERM(); free(eps);
      return HTTP_INTERNAL_SERVER_ERROR;
    #else
      fprintf(stderr, "%s: perl_alloc() failed.", EPL_XS_NAME "\0");
      PERL_SYS_TERM(); free(eps);
      return 1;
    #endif
  }

  perl_construct(twepl);
  PL_origalen = 1;
  perl_parse(twepl, twepl_xs_init, 3, twepl_argp, envp);

  hdr = perl_get_hv(EPL_PM_NAME "::HEADER", FALSE);
  ctt = perl_get_sv(EPL_PM_NAME "::CONTYP", FALSE);
  ibf = perl_get_sv(EPL_PM_NAME "::STIBUF", FALSE);
  obf = perl_get_sv(EPL_PM_NAME "::STOBUF", FALSE);

  /* DUP HANDLE */
  #ifdef __MOD_TWEPL__
    if(! twepl_do_open(twepl, EPL_PM_NAME "::STITMP", "STDIN", EPL_FIM, EPL_PM_NAME "::STIBUF", EPL_FIF)){
      ap_log_rerror(APLOG_MARK, APLOG_ERR, HTTP_INTERNAL_SERVER_ERROR, (request_rec*)obj, "%s: failed open standard %s handle.", EPL_XS_NAME "\0", "STDIN");
      twepl_destroy(twepl, eps);
      return HTTP_INTERNAL_SERVER_ERROR;
    }
    if(twepl_do_iget(obj) != APR_SUCCESS){
      ap_log_rerror(APLOG_MARK, APLOG_ERR, HTTP_INTERNAL_SERVER_ERROR, (request_rec*)obj, "%s: failed read standard %s handle.", EPL_XS_NAME "\0", "STDIN");
      twepl_destroy(twepl, eps);
      return HTTP_INTERNAL_SERVER_ERROR;
    }
  #endif
  if(! twepl_do_open(twepl, EPL_PM_NAME "::STOTMP", "STDOUT", EPL_FOM, EPL_PM_NAME "::STOBUF", EPL_FOF)){
    #ifdef __MOD_TWEPL__
      ap_log_rerror(APLOG_MARK, APLOG_ERR, HTTP_INTERNAL_SERVER_ERROR, (request_rec*)obj, "%s: failed open standard %s handle.", EPL_XS_NAME "\0", "STDOUT");
    #endif
      twepl_destroy(twepl, eps);
    #ifdef __MOD_TWEPL__
      return HTTP_INTERNAL_SERVER_ERROR;
    #else
      return 1;
    #endif
  }

  eval_pv((const char *)eps, G_EVAL|G_KEEPERR|G_DISCARD);

  if(SvTRUE(ERRSV)){
    #ifdef __MOD_TWEPL__
      ap_log_rerror(APLOG_MARK, APLOG_NOTICE, 0, obj, "%s", apr_pstrdup(obj->pool, SvPV_nolen(ERRSV)));
      twepl_destroy(twepl, eps);
      return HTTP_INTERNAL_SERVER_ERROR;
    #else
      Perl_warn(twepl, "%s", SvPV_nolen(ERRSV));
      twepl_destroy(twepl, eps);
      return 1;
    #endif
  }

  /* DUMP
  Perl_sv_dump(twepl, (SV*)sv);
  Perl_dump_all(twepl);
  */

  epb = SvPV(obf, n_a);

  hv_iterinit(hdr); for(i=0; (hsh = hv_iternext(hdr)) != NULL; i++){
    #ifdef __MOD_TWEPL__
      apr_table_set(obj->headers_out, hv_iterkey(hsh, &l), SvPV_nolen(hv_iterval(hdr, hsh)));
    #else
      fprintf(obj, "%s: %s\n", hv_iterkey(hsh, &l), SvPV_nolen(hv_iterval(hdr, hsh)));
    #endif
  }

  #ifdef __MOD_TWEPL__
    ap_set_content_type(obj, SvPV_nolen(ctt));
  #else
    fprintf(obj, "Content-Type: %s\n\n", SvPV_nolen(ctt));
  #endif

  #ifdef __MOD_TWEPL__
    ap_rwrite(epb, n_a, obj);
    ap_rflush(obj);
  #else
    if(fwrite(epb, sizeof(char), n_a, obj) != n_a){
      twepl_destroy(twepl, eps);
      Perl_croak(twepl, "%s: invalid writed size in fwrite().", EPL_XS_NAME "\0");
    }
  #endif

  #ifdef __MOD_TWEPL__
    if(! twepl_do_close(twepl, "STDIN")){
      ap_log_rerror(APLOG_MARK, APLOG_ERR, HTTP_INTERNAL_SERVER_ERROR, (request_rec*)obj, "%s: failed restore standard %s handle.", EPL_XS_NAME "\0", "STDIN");
      twepl_destroy(twepl, eps);
      return HTTP_INTERNAL_SERVER_ERROR;
    }
  #endif
  if(! twepl_do_close(twepl, "STDOUT")){
    #ifdef __MOD_TWEPL__
      ap_log_rerror(APLOG_MARK, APLOG_ERR, HTTP_INTERNAL_SERVER_ERROR, (request_rec*)obj, "%s: failed restore standard %s handle.", EPL_XS_NAME "\0", "STDIN");
      twepl_destroy(twepl, eps);
      return HTTP_INTERNAL_SERVER_ERROR;
    #else
      twepl_destroy(twepl, eps);
      return 1;
    #endif
  }

  twepl_destroy(twepl, eps);

  #ifdef __MOD_TWEPL__
    return OK;
  #else
    return 0;
  #endif

}

  #endif
#endif
