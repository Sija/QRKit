//
//  QKQRCodeReader.mm
//  ZXingWidget
//
//  Created by Romain Pechayre on 6/14/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <zxing/qrcode/QRCodeReader.h>
#import "QKQRCodeReader.h"
#import "QKFormatReader.h"

@implementation QKQRCodeReader

- init {
    zxing::qrcode::QRCodeReader *reader = new zxing::qrcode::QRCodeReader();
    return [super initWithReader:reader];
}

@end
