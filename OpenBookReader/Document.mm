//
//  Document.m
//  OpenBookReader
//
//  Created by Joey Castillo on 6/21/22.
//

#import "Document.h"
#import "BabelTypesetterCocoa.h"

@interface Document ()
{
    int currentPage;
    int numPages;
}
@property (weak) IBOutlet NSImageView *imageView;
@property (nonatomic, strong) NSString *bookText;
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
    self.bookText = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return YES;
}

- (IBAction)previousPage:(id)sender {
    if (self->currentPage > 0) self->currentPage--;
    [self updatePage];
}

- (IBAction)nextPage:(id)sender {
    self->currentPage++;
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
    
    BabelTypesetterCocoa *typesetter = new BabelTypesetterCocoa(context);
    typesetter->begin();
    typesetter->setLayoutArea(8, 8, 300 - 16, 400 - 32);
    typesetter->setLineSpacing(2);
    typesetter->setParagraphSpacing(8);
    typesetter->setTextColor(1);
    typesetter->setWordWrap(true);
    typesetter->print([[self.bookText substringFromIndex: 400 * self->currentPage] cStringUsingEncoding:NSUTF8StringEncoding]);
    delete typesetter;

    [NSGraphicsContext restoreGraphicsState];

    NSImage *image = [[NSImage alloc] initWithSize:imgSize];
    [image addRepresentation:imageRep];

    self.imageView.image = image;
}

@end
