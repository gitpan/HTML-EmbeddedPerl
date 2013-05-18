#ifndef __TWEPL_PARSE_C__
#define __TWEPL_PARSE_C__

#include "twepl_parse.h"

long count_quote(char *src, long stp, long edp){

  long  c = 0;
  long  i;

  for(i=stp; i<(stp+edp)&&src[i]!='\0'; i++){
    if(src[i] == '\x22'){
      c += 4;
    } else{
      c++;
    }
  }

  return c;

}

long twepl_serach_tag(char *src, long ssz, long idx, int ttp){

  char *tmp;
  char  tag[3];
  long  i;

  tmp = src + idx;

  (ttp)? strcpy(tag, EPL_TAG ">") : strcpy(tag, "<" EPL_TAG "\0");

  for(i=0; (i+idx)<ssz&&*tmp!='\0'; i++){
    if(strncmp(tmp, tag, 2) == 0){
      return i;
    }; tmp++;
  }

  return i;

}

int twepl_optag_skip(char *src, int idx){

    if(strncasecmp((src + idx), "p5\0", 2) == 0){
      return 2;
    } else if(strncasecmp((src + idx), "pl\0", 2) == 0){
      return 2;
    } else if(strncasecmp((src + idx), "pl5\0", 3) == 0){
      return 3;
    } else if(strncasecmp((src + idx), "perl\0", 4) == 0){
      return 4;
    } else if(strncasecmp((src + idx), "perl5\0", 5) == 0){
      return 5;
    }

  return 0;

}

int twepl_lint(char *src, long ssz, long *nsz){

  long idx = 0;
  long ret = 0;
  long qqc = 0;
  long erf = 0;

  while(ssz > idx){

    ret = twepl_serach_tag(src, ssz, idx, 0);

    if(ret != 0){

      *nsz += HTML_LS;
      qqc = count_quote(src, idx, ret);
      *nsz += (qqc + HTML_LE);

    }

    if((idx+ret) >= ssz){
      break;
    }

    idx += (ret + 2);
    idx += twepl_optag_skip(src, idx);

    ret = twepl_serach_tag(src, ssz, idx, 1);

    if((idx+ret) >= ssz){
      erf = 1; break;
    }

    idx += (ret + 2);

    *nsz += idx;

  }

  if(erf == 1){
    return TWEPL_FAIL_TAGED;
  } else{
    return TWEPL_OKEY_NOERR;
  }

}

int twepl_quote(char *src, char *cnv, long stp, long edp){

  char *tmp = cnv;
  long  c = 0;
  long  i;

  for(i=stp; i<(stp+edp)&&src[i]!='\0'; i++){

    if(src[i] == '\x22'){
      strcpy(tmp, "\\x22");
      tmp += 4;
      c += 4;
    } else{
      *tmp = src[i];
      tmp++;
      c++;
    }
  }

  return c;

}

int twepl_parse(char *src, char *cnv, long ssz){

  long idx = 0;
  long ret = 0;
  long qqc = 0;
  long erf = 0;

  while(ssz > idx){

    ret = twepl_serach_tag(src, ssz, idx, 0);

    if(ret != 0){

      strcpy(cnv, HTML_PS);
      cnv += HTML_LS;

      qqc = twepl_quote(src, cnv, idx, ret);
      cnv += qqc;

      strcpy(cnv, HTML_PE);
      cnv += HTML_LE;

      *cnv = '\0';

    }

    if((idx+ret) >= ssz){
      break;
    }

    idx += (ret + 2);
    idx += twepl_optag_skip(src, idx);

    ret = twepl_serach_tag(src, ssz, idx, 1);

    if((idx+ret) >= ssz){
      erf = 1; break;
    }

    strncpy(cnv, (src + idx), ret);
    cnv += ret;

    *cnv = '\0';

    idx += (ret + 2);

  }

  if(erf == 1){
    return TWEPL_FAIL_TAGED;
  } else{
    return TWEPL_OKEY_NOERR;
  }

}

char *twepl_file(char *ifp, char *cnv, int *err){

  FILE *epf;

  char *src;

  long  fsz, ret;
  long  csz = 0;

  if((epf = fopen(ifp, "rb")) == NULL){
    *err = TWEPL_FAIL_FOPEN;
    return NULL;
  }

  /* fseek (MAX: 2GB) */
  if((fseek(epf, 0, SEEK_END)) == -1){
    *err = TWEPL_FAIL_FSEEK;
    return NULL;
  }
  /* File size */
  if((fsz = ftell(epf)) == -1){
    *err = TWEPL_FAIL_FTELL;
    return NULL;
  }
  /* Return */
  if((fseek(epf, 0, SEEK_SET)) == -1){
    *err = TWEPL_FAIL_FSEEK;
    return NULL;
  }

  if((src = (char *)malloc(fsz+1)) == NULL){
    *err = TWEPL_FAIL_MALOC;
    return NULL;
  }; src[fsz] = '\0';

  if((fread(src, sizeof(char), fsz, epf)) == -1){
    *err = TWEPL_FAIL_FREAD;
    return NULL;
  }

  fclose(epf);

  *err = twepl_lint(src, fsz, &csz);

  if(*err != TWEPL_OKEY_NOERR){
    free(src);
    return NULL;
  }

  if((cnv = (char *)malloc(csz+1)) == NULL){
    *err = TWEPL_FAIL_MALOC;
    free(src);
    return NULL;
  }; memset(cnv, '\0', (csz + 1));

  twepl_parse(src, cnv, fsz);

  free(src);

  return cnv;

}

char *twepl_code(char *src, char *cnv, int *err){

  long  ssz, ret;
  long  csz = 0;

  if(!(ssz = strlen(src))){
    *err = TWEPL_FAIL_SLENG;
    return NULL;
  }

  *err = twepl_lint(src, ssz, &csz);

  if(*err != TWEPL_OKEY_NOERR){
    free(src);
    *err = ret;
    return NULL;
  }

  if((cnv = (char *)malloc(csz+1)) == NULL){
    *err = TWEPL_FAIL_MALOC;
    return NULL;
  }; memset(cnv, '\0', (csz + 1));

  twepl_parse(src, cnv, ssz);

  return cnv;

}

const char *twepl_strerr(int num){
  return (const char*)TWEPL_ERROR_STRING[num];
}

#endif
