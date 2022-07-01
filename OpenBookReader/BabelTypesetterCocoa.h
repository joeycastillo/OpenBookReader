//
//  BabelTypesetterCocoa.h
//  OpenBookReader
//
//  Created by Joey Castillo on 6/21/22.
//

#ifndef BabelTypesetterCocoa_h
#define BabelTypesetterCocoa_h

#include <stdio.h>
#include <stdint.h>
#include <CoreGraphics/CoreGraphics.h>
#include "BabelTypesetter.h"
#include "BabelMockDevice.h"

class BabelTypesetterCocoa: public BabelTypesetter {
public:
    BabelTypesetterCocoa(CGContextRef context);
    void drawPixel(int16_t x, int16_t y, uint16_t color);
    void drawFillRect(int16_t x, int16_t y, int16_t w, int16_t h, uint16_t color);
    CGContextRef context;
private:
};

#endif /* BabelTypesetterCocoa_h */
