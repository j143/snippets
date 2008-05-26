/*
 *  Copyright 2008 James Peach
 *
 *  Licensed under the Apache License, Version 2.0 (the "License");
 *  you may not use this file except in compliance with the License.
 *  You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 */

/* Emusic .emp file decryptor. The crypto key and algorithm is taken
 * from Thomas Themel's decrypt-emp.pl,
 *
 *      <http://wannabehacker.com/src/decrypt-emp.pl>
 *
 * From <http://wannabehacker.com/src/>:
 *
 *      "Slapping a license on most of the stuff would be a gross
 *      overestimation of its value, so you're basically free to do
 *      with it whatever you want, as long as you don't hold me
 *      responsible."
 */

#import <stdint.h>
#import <stdbool.h>
#import <Foundation/Foundation.h>

extern NSData * base64_decode(NSData * input);

const uint8_t empkey[] = 
{
     0x6b, 0xd8, 0x44, 0x87, 0x52, 0x94, 0xfd, 0x6e,
     0x2c, 0x18, 0xe4, 0xc8, 0xde, 0x0b, 0xfa, 0x6d, 
     0xb5, 0x06, 0x7b, 0xce, 0x77, 0xf4, 0x67, 0x3f, 
     0x93, 0x09, 0x1c, 0x20, 0xf5, 0xbe, 0x27, 0xb1,  
     0x02, 0xc9, 0x8f, 0x37, 0x68, 0x5e, 0xc1, 0x91,
     0xb4, 0x57, 0x8d, 0x90, 0x55, 0x8e, 0x45, 0x19,
     0xdb, 0x9c, 0xec, 0xa3, 0x9d, 0x32, 0xf7, 0x81,
     0xc5, 0x61, 0x8b, 0xab, 0x30, 0xa0, 0xbc, 0x31,
     0xdf, 0xf3, 0x4b, 0xa9, 0x2f, 0x3a, 0x4a, 0xbf,
     0x08, 0x66, 0xa7, 0xe2, 0x62, 0x3d, 0x36, 0xb2,
     0x4f, 0x73, 0x6c, 0x9a, 0x56, 0xcf, 0x33, 0xe5,
     0x43, 0x10, 0x17, 0xc2, 0x3e, 0x1e, 0x2b, 0x70,
     0x04, 0x7e, 0xc0, 0x9e, 0xc6, 0x4c, 0x92, 0x5c,
     0x0f, 0x23, 0x35, 0xd2, 0x7a, 0x3b, 0xaf, 0x80,
     0xd6, 0x9f, 0x0e, 0x78, 0x63, 0x76, 0x95, 0x58,
     0x1d, 0x83, 0x22, 0x4d, 0x96, 0xda, 0xc4, 0xae,
     0xca, 0xcb, 0xed, 0xd9, 0x86, 0x98, 0xea, 0xef,
     0xc3, 0xd0, 0x00, 0xba, 0x71, 0x46, 0xa8, 0x42,
     0x72, 0x2a, 0xd1, 0x49, 0xe8, 0xd3, 0xc7, 0xd5,
     0x50, 0xcc, 0x47, 0x21, 0xd7, 0x60, 0x38, 0x3c,
     0xe7, 0xd4, 0x89, 0xb6, 0x8a, 0x0c, 0xb8, 0xac,
     0x0d, 0x82, 0x29, 0x05, 0xe6, 0x5f, 0xfc, 0x5a,
     0x12, 0x74, 0x5d, 0x8c, 0x14, 0x03, 0x2d, 0x59,
     0x6f, 0xdc, 0x28, 0x7c, 0x15, 0xad, 0xa2, 0x26,
     0x11, 0x9b, 0x99, 0x24, 0xfb, 0xf8, 0xa4, 0x07,
     0x7d, 0x64, 0x75, 0x1b, 0xcd, 0xa5, 0x25, 0xfe,
     0xb7, 0xb9, 0xff, 0x5b, 0xb0, 0xe0, 0x13, 0x51,
     0x65, 0x4e, 0xbb, 0xf1, 0xeb, 0x48, 0x39, 0x53,
     0xf0, 0xe9, 0x85, 0xf2, 0x69, 0x0a, 0xaa, 0x34,
     0x84, 0x40, 0x41, 0x54, 0xdd, 0xf6, 0x1f, 0xbd,
     0xa1, 0xe1, 0x1a, 0xe3, 0x01, 0x97, 0x88, 0xa6,
     0xf9, 0x2e, 0x16, 0xb3, 0x6a, 0xee, 0x79, 0x7f
};

uint8_t * memdup(const uint8_t * src, size_t len)
{
    uint8_t * dst;

    dst = malloc(len);
    if (dst == NULL) {
        return NULL;
    }

    memcpy(dst, src, len);
    return dst;
}

void emp_decrypt(NSMutableData * input)
{
    NSUInteger len = [input length];
    int i;
    uint32_t carry = 0;
    uint8_t * key;
    
    key = memdup(empkey, sizeof(empkey));
        if (key == NULL) {
        return;
    }

    for (i = 1; i <= len; ++i) {
        uint32_t k1, k2;
        uint8_t clear;
        
        k1 = key[i & 0xFF];

        carry += k1;
        carry &= 0xFF;

        k2 = key[carry];
        key[i & 0xFF] = k2;
        key[carry] = k1;

        [input getBytes: &clear range: NSMakeRange(i - 1, 1)];
        clear ^= key[(k1 + k2) & 0xFF];

        [input replaceBytesInRange: NSMakeRange(i - 1, 1) withBytes: &clear];
    }

    free(key);
}

int main(int argc, const char ** argv)
{
    int i;
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    for (i = 1; i < argc; ++i) {
        NSString * filename = [NSString stringWithCString: argv[i]
                                        encoding: NSUTF8StringEncoding];
        NSData * input = [NSData dataWithContentsOfFile: filename];

        NSData * output = base64_decode(input);

        emp_decrypt((NSMutableData *)output);

        NSString * printable = [output description];

        [output writeToFile: @"/dev/fd/1" atomically: NO];

    }

    [pool drain];
    return 0;
}

/* vim: set et ts=4 sw=4 ft=C: */
