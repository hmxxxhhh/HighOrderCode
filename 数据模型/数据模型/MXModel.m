//
//  MXModel.m
//  数据模型
//
//  Created by IOS_HMX on 16/12/8.
//  Copyright © 2016年 humingxing. All rights reserved.
//

#import "MXModel.h"
#import <objc/runtime.h>
@implementation MXModel
-(NSString *)description
{
     NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [[self propertyClassesByName] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id object = [self valueForKey:key];
        dic[key] = object;
    }];
    return [NSString stringWithFormat:@"<%@: %p> %@", self.class, self, dic];
}
-(NSUInteger)hash
{
   __block NSUInteger value = 0;
    [[self propertyClassesByName] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        value ^= [[self valueForKey:key]hash];
    }];
    return value;
}
-(BOOL)isEqual:(id)object
{
    if (object == self) {
        return YES;
    }
    if (![object isMemberOfClass:self.class]) {
        return NO;
    }
    __block BOOL equal = YES;
    [[self propertyClassesByName] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id value = [self valueForKey:key];
        id otherValue = [object valueForKey:key];
        equal = ((value == nil && otherValue == nil) || [value isEqual:otherValue]);
    }];
    return equal;
}
+(BOOL)supportsSecureCoding
{
    return YES;
}
- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super init];
    if (self) {
        BOOL secureAvailable = [coder respondsToSelector:@selector(decodeObjectOfClass:forKey:)];
        BOOL secureSupported = [[self class]supportsSecureCoding];
        [[self propertyClassesByName] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            id object = nil;
            if (secureAvailable) {
                object = [coder decodeObjectOfClass:obj forKey:key];
            }else
            {
                object = [coder decodeObjectForKey:key];
            }
            
            if (object) {
                if (secureSupported && ![object isKindOfClass:obj]) {
                    [NSException raise:@"MApiException" format:@"Expected '%@' to be a %@, but was actually a %@", key, obj, [object class]];
                }
                [self setValue:object forKey:key];
            }
            
        }];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder
{
    [[self propertyClassesByName] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id object = [self valueForKey:key];
        if (object) {
            [coder encodeObject:object forKey:key];
        }
    }];
}
-(id)copyWithZone:(NSZone *)zone
{
    id model = [[self.class allocWithZone:zone]init];
    [[self propertyClassesByName] enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        id object = [self valueForKey:key];
        [model setValue:object forKey:key];
    }];
    return model;
}
-(NSDictionary *)propertyClassesByName
{
    NSMutableDictionary *dictionary = objc_getAssociatedObject([self class], _cmd);
    if (dictionary) {
        return dictionary;
    }
    dictionary = [NSMutableDictionary dictionary];
    Class subClass = [self class];
    while (subClass != [NSObject class]) {
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(subClass, &propertyCount);
        for (int i=0; i<propertyCount; i++) {
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            NSString *key = @(propertyName);
            Class propertyClass = nil;
            char *typeEncoding = property_copyAttributeValue(property, "T");
            switch (typeEncoding[0])
            {
                case 'c': // Numeric types
                case 'i':
                case 's':
                case 'l':
                case 'q':
                case 'C':
                case 'I':
                case 'S':
                case 'L':
                case 'Q':
                case 'f':
                case 'd':
                case 'B':
                {
                    propertyClass = [NSNumber class];
                    break;
                }
                case '*': // C-String
                {
                    propertyClass = [NSString class];
                    break;
                }
                case '@': // Object
                {
                    if (strlen(typeEncoding) >= 3) {
                        char *className = strndup(typeEncoding + 2, strlen(typeEncoding)-3);
                        __autoreleasing NSString *name = @(className);
                        NSRange range = [name rangeOfString:@"<"];
                        if (range.location != NSNotFound ) {
                            name = [name substringToIndex:range.location];
                        }
                        propertyClass = NSClassFromString(name) ?: [NSObject class];
                        free(className);
                    }
                    
                    break;
                }
                case '{': // Struct
                {
                    propertyClass = [NSValue class];
                    break;
                }
                case '[': // C-Array
                case '(': // Enum
                case '#': // Class
                case ':': // Selector
                case '^': // Pointer
                case 'b': // Bitfield
                case '?': // Unknown type
                default:
                {
                    propertyClass = nil; // Not supported by KVC
                    break;
                }
            }
            free(typeEncoding);
            if (propertyClass) {
                char *ivar = property_copyAttributeValue(property, "V");
                if (ivar) {
                    NSString *ivarName = @(ivar);
                    if ([ivarName isEqualToString:key] ||
                        [ivarName isEqualToString:[NSString stringWithFormat:@"_%@",key]]) {
                        dictionary[key] = propertyClass;
                    }
                    free(ivar);
                }else {
                    char *dynamic = property_copyAttributeValue(property, "D");
                    char *readonly = property_copyAttributeValue(property, "R");
                    if (dynamic && !readonly) { // no ivar, but setValue:forKey: will still work
                        dictionary[key] = propertyClass;
                    }
                    free(dynamic);
                    free(readonly);
                }
                
            }
        }
        free(properties);
        subClass = [subClass superclass];
    }
    objc_setAssociatedObject([self class], _cmd, dictionary, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return dictionary;
}
@end
