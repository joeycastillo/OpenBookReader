//
//  Paginate.hpp
//  OpenBookReader
//
//  Created by Joey Castillo on 7/1/22.
//

#ifndef Paginate_hpp
#define Paginate_hpp

#include <CoreFoundation/CoreFoundation.h>
#include <stdio.h>
#include <stdint.h>
#import "BabelTypesetterCocoa.h"

#define OPEN_BOOK_NUM_FIELDS (5)

typedef struct BookField {
    uint32_t tag = 0;
    uint16_t loc = 0;
    uint16_t len = 0;
} BookField;

typedef struct BookRecord {
    char filename[128];
    uint64_t fileHash = 0;
    uint64_t fileSize = 0;
    uint64_t textStart = 0;
    uint64_t currentPosition = 0;
    uint64_t flags = 0;
    BookField metadata[OPEN_BOOK_NUM_FIELDS];
} BookRecord;

typedef struct BookPaginationHeader {
    uint64_t magic = 4992030523817504768;   // for identifying the file
    uint32_t numChapters = 0;               // Number of chapter descriptors
    uint32_t numPages = 0;                  // Number of page descriptors
    uint32_t tocStart = 0;                  // Start of chapter descriptors
    uint32_t pageStart = 0;                 // Start of page descriptors
} BookPaginationHeader;

typedef struct BookChapter {
    uint32_t loc = 0;       // Location in the text file of the RS indicating chapter separation
    uint16_t len = 0;       // Length of the chapter header, including RS character
    uint16_t reserved = 0;  // Reserved for future use
} BookChapter;

typedef struct BookPage {
    uint32_t loc = 0;                       // Location in the text file of the page
    uint16_t len = 0;                       // Length of the page in characters
    struct {
        uint16_t isChapterSeparator : 1;    // 1 if this is a chapter separator page
        uint16_t activeShifts : 2;          // 0-3 for number of format shifts
        uint16_t reserved : 13;             // Reserved for future use
    } flags = {0};
} BookPage;

CFMutableDataRef paginationDataCreate(CFDataRef bookData, uint64_t textStart, BabelDevice *babel);

#endif /* Paginate_hpp */
