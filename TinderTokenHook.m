#import <Foundation/Foundation.h>
#include <objc/runtime.h>

static NSDateFormatter *g_dateFormatter = nil;

// Function to find Tinder's data directory
NSString* findTinderDataDirectory() {
    // Try common paths
    NSArray *paths = @[
        @"/var/mobile/Containers/Data/Application",
        @"/var/mobile/Containers/Shared/AppGroup"
    ];
    
    for (NSString *basePath in paths) {
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:basePath error:nil];
        for (NSString *uuid in contents) {
            NSString *fullPath = [basePath stringByAppendingPathComponent:uuid];
            NSString *bundlePath = [fullPath stringByAppendingPathComponent:@"com.cardify.tinder"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:bundlePath]) {
                return fullPath;
            }
            // Check Library/Preferences
            NSString *prefsPath = [fullPath stringByAppendingPathComponent:@"Library/Preferences"];
            if ([[NSFileManager defaultManager] fileExistsAtPath:prefsPath]) {
                NSArray *prefsFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:prefsPath error:nil];
                for (NSString *file in prefsFiles) {
                    if ([file containsString:@"tinder"] || [file containsString:@"cardify"]) {
                        return fullPath;
                    }
                }
            }
        }
    }
    return nil;
}

// Function to extract tokens from plist files
NSDictionary* extractTokensFromPlist(NSString *plistPath) {
    NSDictionary *plist = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    if (!plist) return nil;
    
    NSMutableDictionary *tokens = [NSMutableDictionary dictionary];
    NSArray *tokenKeys = @[@"X-AUTH-TOKEN", @"Authorization", @"X-Client-Id", @"X-Client-Session", @"token", @"auth_token"];
    
    for (NSString *key in [plist allKeys]) {
        for (NSString *tokenKey in tokenKeys) {
            if ([key.lowercaseString containsString:tokenKey.lowercaseString]) {
                [tokens setObject:plist[key] forKey:key];
            }
        }
    }
    return tokens;
}

// Function to search for tokens in all plist files
void searchForTokens(NSString *directory, NSMutableDictionary *allTokens) {
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:nil];
    for (NSString *item in contents) {
        NSString *fullPath = [directory stringByAppendingPathComponent:item];
        BOOL isDir = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:fullPath isDirectory:&isDir];
        
        if (isDir) {
            searchForTokens(fullPath, allTokens);
        } else if ([item hasSuffix:@".plist"]) {
            NSDictionary *tokens = extractTokensFromPlist(fullPath);
            if (tokens.count > 0) {
                [allTokens addEntriesFromDictionary:tokens];
                NSLog(@"[TinderTokenHook] Found tokens in: %@", fullPath);
            }
        }
    }
}

__attribute__((constructor))
static void initialize() {
    @try {
        g_dateFormatter = [[NSDateFormatter alloc] init];
        [g_dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        NSLog(@"[TinderTokenHook] Starting token extraction...");
        
        // Create marker file
        NSString *markerPath = @"/tmp/tinder_hook_loaded.txt";
        NSString *markerContent = [NSString stringWithFormat:@"Loaded at %@", [g_dateFormatter stringFromDate:[NSDate date]]];
        [markerContent writeToFile:markerPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
        // Find Tinder data directory
        NSString *tinderDir = findTinderDataDirectory();
        if (!tinderDir) {
            NSLog(@"[TinderTokenHook] Tinder directory not found");
            [@"FAILED: Tinder directory not found" writeToFile:@"/tmp/tinder_hook_error.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            return;
        }
        
        NSLog(@"[TinderTokenHook] Found Tinder directory: %@", tinderDir);
        
        // Search for tokens
        NSMutableDictionary *allTokens = [NSMutableDictionary dictionary];
        searchForTokens(tinderDir, allTokens);
        
        // Add timestamp
        NSString *timestamp = [g_dateFormatter stringFromDate:[NSDate date]];
        [allTokens setObject:timestamp forKey:@"last_updated"];
        
        // Save results
        if (allTokens.count > 1) {  // More than just timestamp
            [allTokens writeToFile:@"/tmp/tinder_tokens.plist" atomically:YES];
            
            NSMutableString *plainText = [NSMutableString string];
            [plainText appendString:@"=== Tinder Token ===\n"];
            [plainText appendFormat:@"Time: %@\n", timestamp];
            [plainText appendFormat:@"Found in: %@\n", tinderDir];
            [plainText appendString:@"--- Tokens ---\n"];
            for (NSString *key in [allTokens allKeys]) {
                if (![key isEqualToString:@"last_updated"]) {
                    [plainText appendFormat:@"%@: %@\n", key, allTokens[key]];
                }
            }
            [plainText writeToFile:@"/tmp/tinder_tokens.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
            
            NSLog(@"[TinderTokenHook] Tokens saved. Count: %lu", (unsigned long)allTokens.count);
            [NSString stringWithFormat:@"SUCCESS: Found %lu tokens", (unsigned long)allTokens.count] writeToFile:@"/tmp/tinder_hook_status.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
        } else {
            NSLog(@"[TinderTokenHook] No tokens found");
            [@"No tokens found in plist files" writeToFile:@"/tmp/tinder_hook_status.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
        }
        
    } @catch (NSException *exception) {
        NSLog(@"[TinderTokenHook] Exception: %@", exception);
    }
}