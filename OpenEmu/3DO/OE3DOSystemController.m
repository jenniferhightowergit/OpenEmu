/*
 Copyright (c) 2012, OpenEmu Team
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * Neither the name of the OpenEmu Team nor the
 names of its contributors may be used to endorse or promote products
 derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY OpenEmu Team ''AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL OpenEmu Team BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "OE3DOSystemController.h"
#import "OE3DOSystemResponder.h"
#import "OE3DOSystemResponderClient.h"

@implementation OE3DOSystemController

- (NSString *)systemName
{
    return @"3DO";
}

- (OEFileSupport)canHandleFile:(__kindof OEFile *)file
{
    if (![file isKindOfClass:[OECUESheet class]])
        return OEFileSupportNo;

    // First check if we find these bytes at offset 0x0 found in some dumps
    uint8_t bytes[] = { 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x02, 0x00, 0x01 };
    NSData *dataCompare = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];

    NSData *dataTrackBuffer = [file readDataInRange:NSMakeRange(0, 16)];
    BOOL bytesFound = [dataTrackBuffer isEqualToData:dataCompare];

    dataTrackBuffer = [file readDataInRange:NSMakeRange(bytesFound ? 0x10 : 0x0, 8)];

    NSData *dataTrackBufferComparison = [NSData dataWithBytes:(const uint8_t[]){ 0x01, 0x5a, 0x5a, 0x5a, 0x5a, 0x5a, 0x01, 0x00 } length:8];

    NSLog(@"%@", dataTrackBuffer);
    if (![dataTrackBuffer isEqualToData:dataTrackBufferComparison])
        return OEFileSupportNo;

    NSString *otherDataTrackString = [file readASCIIStringInRange:NSMakeRange(bytesFound ? 0x38 : 0x28, 6)];
    NSLog(@"%@", otherDataTrackString);

    if (otherDataTrackString && [otherDataTrackString caseInsensitiveCompare:@"CD-ROM"] == NSOrderedSame)
        return OEFileSupportYes;

    if([otherDataTrackString rangeOfString:@"TECD"].location != NSNotFound)
        return OEFileSupportYes;

    return OEFileSupportNo;
}

- (NSString *)headerLookupForFile:(__kindof OEFile *)file
{
    if (![file isKindOfClass:[OECUESheet class]])
        return nil;

    // First check if we find these bytes at offset 0x0 found in some dumps
    uint8_t bytes[] = { 0x00, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x02, 0x00, 0x01 };
    NSData *dataCompare = [[NSData alloc] initWithBytes:bytes length:sizeof(bytes)];

    NSData *dataTrackBuffer = [file readDataInRange:NSMakeRange(0, 16)];
    BOOL bytesFound = [dataTrackBuffer isEqualToData:dataCompare];

    // Read disc header, these 16 bytes seem to be unique for each game
    NSData *headerDataTrackBuffer = [file readDataInRange:NSMakeRange(bytesFound ? 0x60 : 0x50, 16)];

    // Format the hexadecimal representation and return
    NSString *buffer = [[headerDataTrackBuffer description] uppercaseString];
    NSString *hex = [[buffer componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] componentsJoinedByString:@""];
    
    return hex;
}

@end
