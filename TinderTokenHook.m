#import <Foundation/Foundation.h>
#include <objc/runtime.h>
#include <dlfcn.h>

// Store captured tokens
static NSMutableDictionary *g_capturedTokens = nil;
static NSDateFormatter *g_dateFormatter = nil;

// Original method implementation
static NSDictionary* (*original_allHTTPHeaderFields)(id self, SEL _cmd);

// Hooked method implementation
static NSDictionary* hooked_allHTTPHeaderFields(id self, SEL _cmd) {
    NSDictionary *headers = original_allHTTPHeaderFields(self, _cmd);
    
    if (headers && headers.count > 0) {
        // Capture token-related headers
        NSArray *tokenKeys = @[@"X-AUTH-TOKEN", @"Authorization", @"X-Client-Id", @"X-Client-Session", @"X-Task-Lease"];
        
        for (NSString *key in tokenKeys) {
            NSString *value = headers[key];
            if (value && value.length > 0) {
                [g_capturedTokens setObject:value forKey:key];
                NSLog(@"[TinderTokenHook] Captured %@: %@", key, value);
            }
        }
        
        // Also capture any header containing "token" (case-insensitive)
        for (NSString *key in headers) {
            if ([key.lowercaseString containsString:@"token"] || 
                [key.lowercaseString containsString:@"auth"] ||
                [key.lowercaseString containsString:@"session"]) {
                NSString *value = headers[key];
                if (value && value.length > 0) {
                    [g_capturedTokens setObject:value forKey:key];
                    NSLog(@"[TinderTokenHook] Captured %@: %@", key, value);
                }
            }
        }
        
        // Add timestamp
        NSString *timestamp = [g_dateFormatter stringFromDate:[NSDate date]];
        [g_capturedTokens setObject:timestamp forKey:@"last_updated"];
        
        // Save to multiple locations for easy access
        NSError *error;
        
        // Save to /tmp (accessible via Filza)
        BOOL saved1 = [g_capturedTokens writeToFile:@"/tmp/tinder_tokens.plist" atomically:YES];
        NSLog(@"[TinderTokenHook] Save to /tmp/tinder_tokens.plist: %@", saved1 ? @"SUCCESS" : @"FAILED");
        
        // Save to /var/tmp as backup
        BOOL saved2 = [g_capturedTokens writeToFile:@"/var/tmp/tinder_tokens.plist" atomically:YES];
        NSLog(@"[TinderTokenHook] Save to /var/tmp/tinder_tokens.plist: %@", saved2 ? @"SUCCESS" : @"FAILED");
        
        // Save to Documents directory of Tinder (if accessible)
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        if (paths.count > 0) {
            NSString *documentsPath = paths[0];
            NSString *tinderTokensPath = [documentsPath stringByAppendingPathComponent:@"tinder_tokens.plist"];
            BOOL saved3 = [g_capturedTokens writeToFile:tinderTokensPath atomically:YES];
            NSLog(@"[TinderTokenHook] Save to %@: %@", tinderTokensPath, saved3 ? @"SUCCESS" : @"FAILED");
        }
        
        // Also save as plain text for easy reading
        NSMutableString *plainText = [NSMutableString string];
        [plainText appendString:@"=== Tinder Token Capture ===\n"];
        [plainText appendFormat:@"Time: %@\n", timestamp];
        [plainText appendString:@"--- Headers ---\n"];
        for (NSString *key in [g_capturedTokens allKeys]) {
            if (![key isEqualToString:@"last_updated"]) {
                [plainText appendFormat:@"%@: %@\n", key, g_capturedTokens[key]];
            }
        }
        
        // Write plain text to multiple locations
        [plainText writeToFile:@"/tmp/tinder_tokens.txt" atomically:YES encoding:NSUTF8StringEncoding error:&error];
        [plainText writeToFile:@"/var/tmp/tinder_tokens.txt" atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        NSLog(@"[TinderTokenHook] Tokens captured and saved. Total tokens: %lu", (unsigned long)g_capturedTokens.count);
    }
    
    return headers;
}

// Function to read tokens from file (for other apps to read)
NSDictionary* readTinderTokens() {
    NSDictionary *tokens = [NSDictionary dictionaryWithContentsOfFile:@"/tmp/tinder_tokens.plist"];
    if (!tokens) {
        tokens = [NSDictionary dictionaryWithContentsOfFile:@"/var/tmp/tinder_tokens.plist"];
    }
    return tokens;
}

__attribute__((constructor))
static void initialize() {
    g_capturedTokens = [NSMutableDictionary dictionary];
    
    // Setup date formatter
    g_dateFormatter = [[NSDateFormatter alloc] init];
    [g_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    NSLog(@"[TinderTokenHook] Initializing Tinder Token Hook...");
    
    // Get the class
    Class NSURLRequestClass = objc_getClass("NSURLRequest");
    if (!NSURLRequestClass) {
        NSLog(@"[TinderTokenHook] Failed to get NSURLRequest class");
        return;
    }
    
    // Get the original method
    Method originalMethod = class_getInstanceMethod(NSURLRequestClass, @selector(allHTTPHeaderFields));
    if (!originalMethod) {
        NSLog(@"[TinderTokenHook] Failed to get allHTTPHeaderFields method");
        return;
    }
    
    // Save original implementation
    original_allHTTPHeaderFields = (void*)method_getImplementation(originalMethod);
    
    // Replace with our hook
    method_setImplementation(originalMethod, (IMP)hooked_allHTTPHeaderFields);
    
    NSLog(@"[TinderTokenHook] Hook installed successfully");
    NSLog(@"[TinderTokenHook] Tokens will be saved to:");
    NSLog(@"[TinderTokenHook]   /tmp/tinder_tokens.plist");
    NSLog(@"[TinderTokenHook]   /tmp/tinder_tokens.txt");
    NSLog(@"[TinderTokenHook]   <Tinder Documents>/tinder_tokens.plist");
}