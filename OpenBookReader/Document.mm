//
//  Document.m
//  OpenBookReader
//
//  Created by Joey Castillo on 6/21/22.
//

#import "Document.h"
#import "BabelTypesetterCocoa.h"
#import "Paginate.hpp"

@interface Document ()
{
    unsigned long currentPage;
    unsigned long numPages;
    BookPaginationHeader header;
}
@property (weak) IBOutlet NSImageView *imageView;
@property (nonatomic, strong) NSData *bookData;
@property (nonatomic, strong) NSData *paginationData;
- (void) updatePage;

@end

@implementation Document

- (instancetype)init {
    self = [super init];
    if (self) {
        self->currentPage = 0;
        self->numPages = 10;
    }
    return self;
}

+ (BOOL)autosavesInPlace {
    return YES;
}


- (NSString *)windowNibName {
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"Document";
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError {
    self.bookData = data;

    CFDataRef cfBookData = (__bridge CFDataRef)self.bookData;
    CFDataRef terminator = (__bridge CFDataRef)[@"---\n" dataUsingEncoding:NSUTF8StringEncoding];
    CFRange rangeOfTerminator = CFDataFind(cfBookData, terminator, CFRangeMake(1, CFDataGetLength(cfBookData) - 1), 0);

    BabelTypesetterCocoa *typesetter = new BabelTypesetterCocoa(NULL);
    typesetter->begin();
    CFDataRef paginationData = paginationDataCreate(cfBookData, rangeOfTerminator.location + rangeOfTerminator.length, typesetter->getBabel());
    self.paginationData = [NSData dataWithData:(__bridge NSMutableData *)paginationData];
    [self.paginationData getBytes:&(self->header) range:NSMakeRange(0, sizeof(BookPaginationHeader))];
    CFRelease(paginationData);
    delete typesetter;

    return YES;
}

- (void) windowControllerDidLoadNib:(NSWindowController *)windowController {
    NSLog(@"Data: %@", [self.paginationData debugDescription]);
    [self updatePage];
}

- (IBAction)previousPage:(id)sender {
    if (self->currentPage > 0) self->currentPage--;
    [self updatePage];
}

- (IBAction)nextPage:(id)sender {
    if (self->currentPage < self->header.numPages - 1) {
        self->currentPage++;
    }
    [self updatePage];
}

- (void) updatePage {
    NSRect imgRect = NSMakeRect(0.0, 0.0, 300, 400);
    NSSize imgSize = imgRect.size;

    NSBitmapImageRep *imageRep = [[NSBitmapImageRep alloc]
                                  initWithBitmapDataPlanes:NULL
                                  pixelsWide:imgSize.width
                                  pixelsHigh:imgSize.height
                                  bitsPerSample:8
                                  samplesPerPixel:4
                                  hasAlpha:YES
                                  isPlanar:NO
                                  colorSpaceName:NSDeviceRGBColorSpace
                                  bitmapFormat:NSBitmapFormatAlphaFirst
                                  bytesPerRow:0
                                  bitsPerPixel:0];

    NSGraphicsContext *g = [NSGraphicsContext graphicsContextWithBitmapImageRep: imageRep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext: g];
    CGContextRef context = [g CGContext];
    CGContextTranslateCTM(context, 0, imgSize.height);
    CGContextScaleCTM(context, 1, -1);

    CGContextSetFillColorWithColor(context, CGColorGetConstantColor(kCGColorWhite));
    CGContextFillRect(context, imgRect);
    
    BookPage page;
    [self.paginationData getBytes:&page range:NSMakeRange(self->header.pageStart + sizeof(BookPage) * self->currentPage, sizeof(BookPage))];
    
    BabelTypesetterCocoa *typesetter = new BabelTypesetterCocoa(context);
    typesetter->begin();
//    for(int i = 0; i <= 40; i++) typesetter->drawFillRect(0, 6 + i * 10, 4 * (i % 10 ? 1 : 2), 1, 1);
    typesetter->setLayoutArea(6, 6, 300 - 12, 800 - 26);
    typesetter->setLineSpacing(2);
    typesetter->setParagraphSpacing(8);
    typesetter->setTextColor(1);
    typesetter->setWordWrap(true);
    NSData *pageData = [self.bookData subdataWithRange:NSMakeRange(page.loc, page.len)];
    NSString *pageText = [[NSString alloc] initWithData:pageData encoding:NSUTF8StringEncoding];
    if ([pageText characterAtIndex:0] == 0x1e) typesetter->setTextSize(2);
    else typesetter->setTextSize(1);
//    typesetter->print("░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ░ ");
//    typesetter->setLayoutArea(6, 6, 300 - 12, 800 - 26);
    typesetter->print([pageText cStringUsingEncoding:NSUTF8StringEncoding]);
    delete typesetter;

    [NSGraphicsContext restoreGraphicsState];

    NSImage *image = [[NSImage alloc] initWithSize:imgSize];
    [image addRepresentation:imageRep];

    self.imageView.image = image;
}

@end
