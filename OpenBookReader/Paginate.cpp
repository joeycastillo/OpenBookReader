//
//  Paginate.cpp
//  OpenBookReader
//
//  Created by Joey Castillo on 7/1/22.
//

#include "Paginate.hpp"

CFMutableDataRef paginationDataCreate(CFDataRef bookData, uint64_t textStart, BabelDevice *babel) {
    CFMutableDataRef paginationData = CFDataCreateMutable(NULL, 1000000);
    BookPaginationHeader header;
    CFDataAppendBytes(paginationData, (const UInt8 *)&header, sizeof(BookPaginationHeader));

    // now process the whole file and seek out chapter headings.
    BookChapter chapter = {0};
    CFIndex size = CFDataGetLength(bookData);
    UInt8 *bookText = (UInt8 *)malloc(size);
    CFDataGetBytes(bookData, CFRangeMake(0, size), bookText);
    CFIndex pos = textStart;
    do {
        if (bookText[pos++] == 0x1e) {
            chapter.loc = (uint32_t)(pos - 1);
            chapter.len++;
            header.numChapters++;
            char c;
            do {
                c = bookText[pos++];
                chapter.len++;
            } while(c != '\n');
            // printf("Found chapter %d : %d, %d\n", header.numChapters, chapter.loc, chapter.len);
            CFDataAppendBytes(paginationData, (const UInt8 *)&chapter, sizeof(BookChapter));
            pos = chapter.loc + chapter.len;
            chapter = {0};
        }
    } while (pos < size);


    // if we found chapters, mark the TOC as starting right after the header.
    if (header.numChapters) header.tocStart = sizeof(BookPaginationHeader);

    header.pageStart = header.tocStart + header.numChapters * sizeof(BookChapter);

    // OKAY! Time to do pages. For this we have to traverse the whole file again,
    // but this time we need to simulate actually laying it out.
    BookPage page = {0};
    uint16_t yPos = 0;
    char utf8bytes[128];
    BABEL_CODEPOINT codepoints[127];

    // printf("Starting page parsing at %lld\n", textStart);
    pos = textStart;
    const int16_t pageWidth = 288;
    const int16_t pageHeight = 384;
    CFIndex nextPosition = 0;
    bool firstLoop = true;

    page.loc = (uint32_t)pos;
    page.len = 0;
    // printf("\nypos = %d\n", yPos);
    do {
        CFIndex startPosition = pos;
        int bytesRead = 0;
        for(int i = 0; i < 127; i++) {
            if (pos > size) break;
            utf8bytes[i] = bookText[pos++];
            bytesRead++;
        }
        utf8bytes[127] = {0};
        bool wrapped = false;
        babel->utf8_parse(utf8bytes, codepoints);

        if (codepoints[0] == 0x1e) {
            if (!firstLoop) {
                // close out the last chapter
                nextPosition = pos;
                // printf(" Closing out chapter at page %d : %d, %d\n", header.numPages, page.loc, page.len);
                CFDataAppendBytes(paginationData, (const UInt8 *)&page, sizeof(BookPage));
                header.numPages++;
                page.loc = page.loc + page.len;
                page.len = 0;
                pos = page.loc;
            }

            int32_t line_end = 0;
            // FIXME: handle case where no newline in 127 code points
            while(codepoints[line_end++] != '\n');
            nextPosition = startPosition + line_end;
            page.len = line_end;
            goto BREAK_PAGE;
        } else {
            size_t bytePosition;
            int32_t line_end = babel->word_wrap_position(codepoints, bytesRead, &wrapped, &bytePosition, pageWidth, 1);
            if (bytePosition > 0) {
                for(int i = bytePosition; i < 127; i++) {
                    if (utf8bytes[i] == 0x20) {
                        bytePosition++;
                    } else {
                        break;
                    }
                }
                page.len += bytePosition;
                // printf("↲ (%zu page length now %d)\n", bytePosition, page.len);
                for(int i = 0; i < bytePosition; i++) // printf("^");
                // printf("\n");
                nextPosition = startPosition + bytePosition;
            } else {
                // printf(" no wrap, line end at %d\n", bytesRead);
                page.len += bytesRead;
                nextPosition = startPosition + bytesRead;
            }
        }

        if (wrapped) {
            // printf(",");
            yPos += 16 + 2;
        } else {
            // printf(".");
            yPos += 16 + 2 + 8;
        }
        // printf(" (yPos = %d)\n", yPos);

        if (yPos + 16 > pageHeight) {
BREAK_PAGE:
            // printf("----------Breaking for page %d : %d, %d\n", header.numPages, page.loc, page.len);
            CFDataAppendBytes(paginationData, (const UInt8 *)&page, sizeof(BookPage));
            header.numPages++;
            yPos = 0;
            // printf("yPos = %d\n", yPos);
            page.loc = page.loc + page.len;
            page.len = 0;
        }
        pos = nextPosition;
        firstLoop = false;
    } while (pos < size);

    // printf(" Breaking for end of book : %d, %d\n", page.loc, page.len);

    CFDataAppendBytes(paginationData, (const UInt8 *)&page, sizeof(BookPage));
    header.numPages++;

    // printf("Writing final header: %d chapters, %d pages.\n", header.numChapters, header.numPages);
    CFDataReplaceBytes(paginationData, CFRangeMake(0, sizeof(BookPaginationHeader)), (const UInt8 *)&header, sizeof(BookPaginationHeader));
    
    return paginationData;
}

