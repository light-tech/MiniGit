//
//  StringHelpers.mm
//  Various functions and structs to help with NSString conversion in C++ code
//
//  Created by Lightech on 10/24/2048.
//

static NSString* _Nullable NSStringFromCString(const char * _Nullable text) {
    if (text == NULL)
        return nil;

    return [NSString stringWithUTF8String:text];
}

static NSString* _Nullable NSStringFromBuffer(const char * _Nullable text, size_t length) {
    if (text == NULL)
        return nil;

    return [[NSString alloc] initWithBytes :text length:length encoding: NSUTF8StringEncoding];
}
