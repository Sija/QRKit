//
//  QKLog.h
//  QRKit
//
//  Created by Sijawusz Pur Rahnama on 11/8/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#ifdef DEBUG
    #define QKLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
    #define QKLog(...)
#endif
