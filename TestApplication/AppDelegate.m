#import <zlib.h>
#import <openssl/blowfish.h>
#import <libetpan/libetpan.h>
#import <libssh2.h>
#import <curl/curl.h>

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window=_window;

- (BOOL) application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions {    
  // Test linking with zlib
  {
    NSLog(@"zlib = %s (%s)", zlibVersion(), ZLIB_VERSION);
  }
  
  // Test linking with OpenSSL
  {
    NSLog(@"Blowfish = %s", BF_options());
  }
  
  // Test linking with libEtPan
  {
    struct mailstorage* storage = mailstorage_new(NULL);
    imap_mailstorage_init(storage, "server", 143, NULL, CONNECTION_TYPE_STARTTLS, IMAP_AUTH_TYPE_PLAIN,
                          "username", "password", 0, NULL);
    mailstorage_free(storage);
    
    size_t currToken = 0;
    char* decodedSubject;
    mailmime_encoded_phrase_parse("UTF-8", "hello world", 11, &currToken, "UTF-8", &decodedSubject);
  }
  
  // Test linking with libssh2
  {
    LIBSSH2_SESSION* session = libssh2_session_init();
    libssh2_session_free(session);
  }
  
  // Test linking with curl
  {
    curl_global_init(CURL_GLOBAL_DEFAULT);
    CURL* handle = curl_easy_init();
    curl_easy_cleanup(handle);
  }
  
  // Show window
  _window.backgroundColor = [UIColor greenColor];
  [_window makeKeyAndVisible];
  return YES;
}

@end
