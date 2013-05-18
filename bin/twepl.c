/* twepl -c */

#include "twepl_xcore.c"

int main(int argc, char **argv, char **envp){

   struct stat   fs;
          FILE  *fo;
          char  *eb = NULL;
          char  *in = NULL;
          char  *on = NULL;
           int   rv, i;
           int   cf = 0;

  if(argc < 1){
    fprintf(stderr, EPP_APPNAME ": invalid arguments..\n");
    exit(1);
  }

  for(i=1; i<argc; i++){
    if(strcasecmp(argv[i], "-v") == 0){
      printf("%s",(char*)EPP_VERSION);
      return 0;
    } else if(strcasecmp(argv[i], "-h") == 0 ||  strcasecmp(argv[i], "--help") == 0){
      printf("%s", (char*)EPP_OPTIONS);
      printf("%s", (char*)EPP_VERSION);
      return 0;
    } else if(strcasecmp(argv[i], "-c") == 0){
      cf = 1;
    } else if(strcmp(argv[i], "-o") == 0 && i != argc){
      on = argv[++i];
    } else if(stat(argv[i],&fs) != -1){
      in = argv[i];
    }
  }

  if(in == NULL){
    fprintf(stderr, EPP_APPNAME ": couldn't found input file.\n");
    return 1;
  }

  if(on != NULL){
    if((fo = fopen(on,"wb")) == NULL){
      fprintf(stderr, EPP_APPNAME ": cauldn't open output file.\n");
      return 1;
    }
  } else{
    fo = stdout;
  }

  if(cf ==1){
    eb = twepl_file(in , eb, &rv);
    fprintf(fo, "%s", eb);
  } else{
    twepl_script_handler(fo, in, argc, argv, envp);
  }

  if(fo != NULL && fo != stdout)
    fclose(fo);

  free(eb);

  return 0;

}
