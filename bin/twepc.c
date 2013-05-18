#include "twepl_parse.c"

int main(int argc, char **argv, char **envp){

         FILE  *fo;
         char  *ec;
         char  *in;
         char  *on;
  struct stat   fs;
          int   rv, i;

  if(argc < 1){
    fprintf(stderr, EPC_APPNAME ": invalid arguments..\n");
    exit(1);
  }

  for(i=1; i<argc; i++){
    if(strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "-V") == 0){
      printf("%s",(char*)EPP_VERSION);
      return 0;
    } else if(strcmp(argv[i], "-h") == 0 || strcmp(argv[i], "--help") == 0){
      printf("%s", (char*)EPP_OPTIONS);
      printf("%s", (char*)EPP_VERSION);
      return 0;
    } else if(strcmp(argv[i], "-o") == 0 && i != argc){
      on = argv[++i];
    } else if(stat(argv[i],&fs) != -1){
      in = argv[i];
    }
  }

  if(in == NULL){
    fprintf(stderr, EPC_APPNAME ": couldn't found input file.\n");
    return 1;
  }

  ec = twepl_file(in , ec, &rv);

  if(rv != TWEPL_OKEY_NOERR){
      fprintf(stderr, EPC_APPNAME ": parse error.\n");
      return 1;
  }

  if(on != NULL){
    if((fo = fopen(on,"wb")) == NULL){
      fprintf(stderr, EPC_APPNAME ": cauldn't open output file.\n");
      free(ec);
      return 1;
    }
  } else{
    fo = stdout;
  }

  fprintf(fo, "%s", ec);
  free(ec);

  if(fo != NULL){
    fclose(fo);
  }

  return 0;

}
