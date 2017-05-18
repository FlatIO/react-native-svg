/**
 * Copyright (c) 2015-present, Horcrux.
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RNSVGNodeManager.h"
#import "RNSVGRenderable.h"
#import "RCTUIManager.h"
#import "RNSVGNode.h"

@implementation RNSVGNodeManager

RCT_EXPORT_MODULE()

- (RNSVGNode *)node
{
    return [RNSVGNode new];
}

- (UIView *)view
{
    return [self node];
}

- (RCTShadowView *)shadowView
{
    return nil;
}

RCT_EXPORT_VIEW_PROPERTY(name, NSString)
RCT_EXPORT_VIEW_PROPERTY(opacity, CGFloat)
RCT_EXPORT_VIEW_PROPERTY(matrix, CGAffineTransform)
RCT_EXPORT_VIEW_PROPERTY(clipPath, NSString)
RCT_EXPORT_VIEW_PROPERTY(clipRule, RNSVGCGFCRule)
RCT_EXPORT_VIEW_PROPERTY(responsible, BOOL)

RCT_EXPORT_METHOD(getBoundingBox:(nonnull NSNumber *)reactTag callback:(RCTResponseSenderBlock)callback)
{
    RCTUIManager* manager = [self.bridge uiManager];

    [manager addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        __kindof UIView *view = viewRegistry[reactTag];
        if ([view isKindOfClass:[RNSVGRenderable class]]) {
            RNSVGRenderable *svg = view;

            CGAffineTransform baset = [svg getBaseTransform];
            CGRect bbox = [svg getPathBox: &baset];
            RNSVGSvgView* svgview = [svg getSvgView];

            callback(@[[NSNumber numberWithDouble:bbox.size.width],
                       [NSNumber numberWithDouble:bbox.size.height],
                       [NSNumber numberWithDouble:bbox.origin.x + svgview.bounds.origin.x],
                       [NSNumber numberWithDouble:bbox.origin.y + svgview.bounds.origin.y]]);
        } else {
            RCTLogError(@"Invalid svg returned frin registry, expecting RNSVGRenderable, got: %@", view);
        }
    }];
}

@end
