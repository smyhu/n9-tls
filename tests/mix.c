/* Simulates nped/msyncd: process already uses system OpenSSL 0.9.8, then loads TLS-patched libcurl */
#include <stdio.h>
#include <curl/curl.h>
extern int SSL_library_init(void); extern const char *SSLeay_version(int);
static size_t w(void *p,size_t s,size_t n,void *u){return s*n;}
int main(int c,char**v){
  SSL_library_init(); printf("system OpenSSL: %s\n",SSLeay_version(0));
  printf("libcurl: %s\n",curl_version());
  CURL *h=curl_easy_init(); curl_easy_setopt(h,CURLOPT_URL,v[1]); curl_easy_setopt(h,CURLOPT_CAINFO,v[2]);
  curl_easy_setopt(h,CURLOPT_WRITEFUNCTION,w);
  CURLcode r=curl_easy_perform(h); printf("HTTPS result: %d %s\n",r,curl_easy_strerror(r)); return r;}
