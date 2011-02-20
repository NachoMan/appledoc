//
//  GBCommentsProcessor-MarkdownTesting.m
//  appledoc
//
//  Created by Tomaz Kragelj on 19.2.11.
//  Copyright (C) 2011 Gentle Bytes. All rights reserved.
//

#import "GBApplicationSettingsProvider.h"
#import "GBDataObjects.h"
#import "GBStore.h"
#import "GBCommentsProcessor.h"

@interface GBCommentsProcessorMarkdownTesting : GBObjectsAssertor

- (GBCommentsProcessor *)defaultProcessor;
- (GBStore *)defaultStore;
- (GBStore *)storeWithDefaultObjects;
- (void)assertComment:(GBComment *)comment matchesLongDescMarkdown:(NSString *)first, ... NS_REQUIRES_NIL_TERMINATION;

@end

#pragma mark -

@implementation GBCommentsProcessorMarkdownTesting

#pragma mark Text blocks handling

- (void)testProcessCommentWithContextStore_markdown_shouldHandleSimpleText {
	// setup
	GBStore *store = [self defaultStore];
	GBCommentsProcessor *processor = [self defaultProcessor];
	GBComment *comment = [GBComment commentWithStringValue:@"Some text\n\nAnother paragraph"];
	// execute
	[processor processComment:comment withContext:nil store:store];
	// verify
	[self assertComment:comment matchesLongDescMarkdown:@"Some text\n\nAnother paragraph", nil];
}

- (void)testProcessCommentWithContextStore_markdown_shouldConvertWarning {
	// setup
	GBStore *store = [self defaultStore];
	GBCommentsProcessor *processor = [self defaultProcessor];
	GBComment *comment = [GBComment commentWithStringValue:@"Some text\n\n@warning Another paragraph\n\nAnd another"];
	// execute
	[processor processComment:comment withContext:nil store:store];
	// verify
	[self assertComment:comment matchesLongDescMarkdown:@"Some text", @"> %warning%\n> Another paragraph\n> \n> And another", nil];
}

- (void)testProcessCommentWithContextStore_markdown_shouldConvertBug {
	// setup
	GBStore *store = [self defaultStore];
	GBCommentsProcessor *processor = [self defaultProcessor];
	GBComment *comment = [GBComment commentWithStringValue:@"Some text\n\n@bug Another paragraph\n\nAnd another"];
	// execute
	[processor processComment:comment withContext:nil store:store];
	// verify
	[self assertComment:comment matchesLongDescMarkdown:@"Some text", @"> %bug%\n> Another paragraph\n> \n> And another", nil];
}

#pragma mark Cross references handling

- (void)testProcessCommentWithContextStore_markdown_shouldKeepInlineTopLevelObjectsCrossRefsTexts {
	// setup
	GBStore *store = [self storeWithDefaultObjects];
	GBCommentsProcessor *processor = [self defaultProcessor];
	GBComment *comment1 = [GBComment commentWithStringValue:@"Class"];
	GBComment *comment2 = [GBComment commentWithStringValue:@"Class(Category)"];
	GBComment *comment3 = [GBComment commentWithStringValue:@"Protocol"];
	GBComment *comment4 = [GBComment commentWithStringValue:@"Document"];
	// execute
	[processor processComment:comment1 withContext:nil store:store];
	[processor processComment:comment2 withContext:nil store:store];
	[processor processComment:comment3 withContext:nil store:store];
	[processor processComment:comment4 withContext:nil store:store];
	// verify
	[self assertComment:comment1 matchesLongDescMarkdown:@"[Class](Classes/Class.html)", nil];
	[self assertComment:comment2 matchesLongDescMarkdown:@"[Class(Category)](Categories/Class(Category).html)", nil];
	[self assertComment:comment3 matchesLongDescMarkdown:@"[Protocol](Protocols/Protocol.html)", nil];
	[self assertComment:comment4 matchesLongDescMarkdown:@"[Document](docs/Document.html)", nil];
}

- (void)testProcessCommentWithContextStore_markdown_shouldKeepInlineLocalMemberCrossRefsTexts {
	// setup
	GBStore *store = [self storeWithDefaultObjects];
	GBCommentsProcessor *processor = [self defaultProcessor];
	GBComment *comment1 = [GBComment commentWithStringValue:@"instanceMethod:"];
	GBComment *comment2 = [GBComment commentWithStringValue:@"classMethod:"];
	GBComment *comment3 = [GBComment commentWithStringValue:@"value"];
	// execute
	id context = [store.classes anyObject];
	[processor processComment:comment1 withContext:context store:store];
	[processor processComment:comment2 withContext:context store:store];
	[processor processComment:comment3 withContext:context store:store];
	// verify
	[self assertComment:comment1 matchesLongDescMarkdown:@"[instanceMethod:](#//api/name/instanceMethod:)", nil];
	[self assertComment:comment2 matchesLongDescMarkdown:@"[classMethod:](#//api/name/classMethod:)", nil];
	[self assertComment:comment3 matchesLongDescMarkdown:@"[value](#//api/name/value)", nil];
}

- (void)testProcessCommentWithContextStore_markdown_shouldKeepInlineRemoteMemberCrossRefsTexts {
	// setup
	GBStore *store = [self storeWithDefaultObjects];
	GBCommentsProcessor *processor = [self defaultProcessor];
	GBComment *comment1 = [GBComment commentWithStringValue:@"[Class instanceMethod:]"];
	GBComment *comment2 = [GBComment commentWithStringValue:@"[Class classMethod:]"];
	GBComment *comment3 = [GBComment commentWithStringValue:@"[Class value]"];
	// execute
	[processor processComment:comment1 withContext:nil store:store];
	[processor processComment:comment2 withContext:nil store:store];
	[processor processComment:comment3 withContext:nil store:store];
	// verify
	[self assertComment:comment1 matchesLongDescMarkdown:@"[[Class instanceMethod:]](Classes/Class.html#//api/name/instanceMethod:)", nil];
	[self assertComment:comment2 matchesLongDescMarkdown:@"[[Class classMethod:]](Classes/Class.html#//api/name/classMethod:)", nil];
	[self assertComment:comment3 matchesLongDescMarkdown:@"[[Class value]](Classes/Class.html#//api/name/value)", nil];
}

#pragma mark Creation methods

- (GBCommentsProcessor *)defaultProcessor {
	return [GBCommentsProcessor processorWithSettingsProvider:[GBTestObjectsRegistry realSettingsProvider]];
}

- (GBStore *)defaultStore {
	return [GBTestObjectsRegistry store];
}

- (GBStore *)storeWithDefaultObjects {
	GBMethodData *instanceMethod = [GBTestObjectsRegistry instanceMethodWithNames:@"instanceMethod", nil];
	GBMethodData *classMethod = [GBTestObjectsRegistry classMethodWithNames:@"classMethod", nil];
	GBMethodData *property = [GBTestObjectsRegistry propertyMethodWithArgument:@"value"];
	GBClassData *class = [GBTestObjectsRegistry classWithName:@"Class" methods:instanceMethod, classMethod, property, nil];
	GBCategoryData *category = [GBCategoryData categoryDataWithName:@"Category" className:@"Class"];
	GBProtocolData *protocol = [GBProtocolData protocolDataWithName:@"Protocol"];
	GBDocumentData *document = [GBDocumentData documentDataWithContents:@"c" path:@"Document.ext"];
	return [GBTestObjectsRegistry storeWithObjects:class, category, protocol, document, nil];
}

#pragma mark Assertion methods

- (void)assertComment:(GBComment *)comment matchesLongDescMarkdown:(NSString *)first, ... {
	NSMutableArray *expectations = [NSMutableArray array];
	va_list args;
	va_start(args, first);
	for (NSString *arg=first; arg != nil; arg=va_arg(args, NSString*)) {
		[expectations addObject:arg];
	}
	va_end(args);
	
	assertThatInteger([comment.longDescription.components count], equalToInteger([expectations count]));
	for (NSUInteger i=0; i<[expectations count]; i++) {
		GBCommentComponent *component = [comment.longDescription.components objectAtIndex:i];
		NSString *expected = [expectations objectAtIndex:i];
		assertThat(component.markdownValue, is(expected));
	}
}

@end
