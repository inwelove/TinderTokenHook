#import <Foundation/Foundation.h>
#include <objc/runtime.h>
#include <dlfcn.h>

// Store captured tokens
static NSMutableDictionary *g_capturedTokens = nil;
static NSDateFormatter *g_dateFormatter = nil;
static BOOL g_hookEnabled = YES;

// Original method implementation
static NSDictionary* (*original_allHTTPHeaderFields)(id self, SEL _cmd);

// Safe hook with protection
static NSDictionary* hooked_allHTTPHeaderFields(id self, SEL _cmd) {
    // Prevent recursion
    if (!g_hookEnabled) {
        return original_allHTTPHeaderFields(self, _cmd);
    }
    
    @try {
        g_hookEnabled = NO;  // Disable hook temporarily
        NSDictionary *headers = original_allHTTPHeaderFields(self, _cmd);
        g_hookEnabled = YES;  // Re-enable hook
        
        if (headers && headers.count > 0) {
            // Only capture specific token headers
            NSArray *tokenKeys = @[@"X-AUTH-TOKEN", @"Authorization", @"X-Client-Id", @"X-Client-Session"];
            
            for (NSString *key in tokenKeys) {
                NSString *value = headers[key];
                if (value && value.length > 0) {
                    [g_capturedTokens setObject:value forKey:key];
                }
            }
            
            // Add timestamp
            NSString *timestamp = [g_dateFormatter stringFromDate:[NSDate date]];
            [g_capturedTokens setObject:timestamp forKey:@"last_updated"];
            
            // Save to file (with error handling)
            NSError *error;
            BOOL saved = [g_capturedTokens writeToFile:@"/tmp/tinder_tokens.plist" atomically:YES];
            if (!saved) {
                NSLog(@"[TinderTokenHook] Failed to save plist");
            }
            
            // Also save as plain text
            NSMutableString *plainText = [NSMutableString string];
            [plainText appendString:@"=== Tinder Token ===\n"];
            [plainText appendFormat:@"Time: %@\n", timestamp];
            for (NSString *key in [g_capturedTokens allKeys]) {
                if (![key isEqualToString:@"last_updated"]) {
                    [plainText appendFormat:@"%@: %@\n", key, g_capturedTokens[key]];
                }
            }
            [plainText writeToFile:@"/tmp/tinder_tokens.txt" atomically:YES encoding:NSUTF8StringEncoding error:&error];
        }
        
        return headers;
    } @catch (NSException *exception) {
        NSLog(@"[TinderTokenHook] Exception: %@", exception);
        g_hookEnabled = YES;
        return original_allHTTPHeaderFields(self, _cmd);
    }
}

__attribute__((constructor))
static void initialize() {
    @try {
        g_capturedTokens = [NSMutableDictionary dictionary];
        
        // Setup date formatter
        g_dateFormatter = [[NSDateFormatter alloc] init];
        [g_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        NSLog(@"[TinderTokenHook] Initializing...");
        
        // Create marker file
        NSString *markerPath = @"/tmp/tinder_hook_loaded.txt";
        NSString *markerContent = [NSString stringWithFormat:@"Loaded at %@", [g_dateFormatter stringFromDate:[NSDate date]]];
        [markerContent writeToFile:markerPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        // Get the class
        Class NSURLRequestClass = objc_getClass("NSURLRequest");
        if (!NSURLRequestClass) {
            NSLog(@"[TinderTokenHook] Failed to get NSURLRequest class");
            [@"FAILED: class not found" writeToFile:@"/tmp/tinder_hook_error.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            return;
        }
        
        // Get the original method
        Method originalMethod = class_getInstanceMethod(NSURLRequestClass, @selector(allHTTPHeaderFields));
        if (!originalMethod) {
            NSLog(@"[TinderTokenHook] Failed to get method");
            [@"FAILED: method not found" writeToFile:@"/tmp/tinder_hook_error.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            return;
        }
        
        // Save original implementation
        original_allHTTPHeaderFields = (void*)method_getImplementation(originalMethod);
        
        // Replace with our hook
        method_setImplementation(originalMethod, (IMP)hooked_allHTTPHeaderFields);
        
        NSLog(@"[TinderTokenHook] Hook installed");
        [@"SUCCESS" writeToFile:@"/tmp/tinder_hook_status.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
    } @catch (NSException *exception) {
        NSLog(@"[TinderTokenHook] Init exception: %@", exception);
    }
}