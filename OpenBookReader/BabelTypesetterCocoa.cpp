/*
 * The MIT License (MIT)
 *
 * Copyright © 2019 Joey Castillo. All rights reserved.
 * Incorporates ideas and code from the Adafruit_GFX library.
 * Copyright (c) 2013 Adafruit Industries.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include <string.h>
#include <CoreFoundation/CoreFoundation.h>
#include "BabelTypesetterCocoa.h"

BabelTypesetterCocoa::BabelTypesetterCocoa(CGContextRef context) {
    char pathToBabel[1024];
    CFURLRef url = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("babel"), CFSTR("bin"), NULL);
    CFStringRef path = CFURLCopyPath(url);
    CFStringGetCString(path, pathToBabel, 1024, kCFStringEncodingUTF8);

    this->context = context;
    this->babelDevice = new BabelMockDevice(pathToBabel);

    CFRelease(path);
    CFRelease(url);
}

void BabelTypesetterCocoa::drawPixel(int16_t x, int16_t y, uint16_t color) {
    this->drawFillRect(x, y, 1, 1, color);
}

void BabelTypesetterCocoa::drawFillRect(int16_t x, int16_t y, int16_t w, int16_t h, uint16_t color) {
    CGColorRef cgColor;

    if (color) cgColor = CGColorGetConstantColor(kCGColorBlack);
    else cgColor = CGColorGetConstantColor(kCGColorWhite);
    CGContextSetFillColor(this->context, CGColorGetComponents(cgColor));
    CGContextFillRect(this->context, CGRectMake(x, y, w, h));
}
