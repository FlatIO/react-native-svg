/**
 * Copyright (c) 2015-present, Horcrux.
 * All rights reserved.
 *
 * This source code is licensed under the MIT-style license found in the
 * LICENSE file in the root directory of this source tree.
 */

#import "RNSVGGroup.h"

@implementation RNSVGGroup

- (void)renderLayerTo:(CGContextRef)context
{
    RNSVGSvgView* svg = [self getSvgView];
    [self clip:context];

    [self traverseSubviews:^(RNSVGNode *node) {
        if (node.responsible && !svg.responsible) {
            svg.responsible = YES;
            return NO;
        }
        return YES;
    }];

    [self traverseSubviews:^(RNSVGNode *node) {
        [node mergeProperties:self mergeList:self.ownedPropList inherited:YES];
        [node renderTo:context];
        return YES;
    }];
}

- (CGPathRef)getPath:(CGContextRef)context
{
    CGMutablePathRef path = CGPathCreateMutable();
    [self traverseSubviews:^(RNSVGNode *node) {
        CGAffineTransform transform = node.matrix;
        CGPathAddPath(path, &transform, [node getPath:context]);
        return YES;
    }];

    return (CGPathRef)CFAutorelease(path);
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event withTransform:(CGAffineTransform)transform
{
    CGAffineTransform matrix = CGAffineTransformConcat(self.matrix, transform);

    for (RNSVGNode *node in [self.subviews reverseObjectEnumerator]) {
        if ([node isKindOfClass:[RNSVGNode class]]) {
            if (event) {
                node.active = NO;
            } else if (node.active) {
                return node;
            }

            UIView *view = [node hitTest: point withEvent:event withTransform:matrix];

            if (view) {
                node.active = YES;
                if (node.responsible || (node != view)) {
                    return view;
                } else {
                    return self;
                }
            }
        }
    }
    return nil;
}

- (void)saveDefinition
{
    if (self.name) {
        RNSVGSvgView* svg = [self getSvgView];
        [svg defineTemplate:self templateRef:self.name];
    }

    [self traverseSubviews:^(RNSVGNode *node) {
        [node saveDefinition];
        return YES;
    }];

}

- (void)mergeProperties:(__kindof RNSVGNode *)target mergeList:(NSArray<NSString *> *)mergeList
{
    [self traverseSubviews:^(RNSVGNode *node) {
        [node mergeProperties:target mergeList:mergeList];
        return YES;
    }];
}

- (void)resetProperties
{
    [self traverseSubviews:^(RNSVGNode *node) {
        [node resetProperties];
        return YES;
    }];
}

- (CGRect)getPathBox:(CGAffineTransform*)transform {
    CGPoint p = CGPointApplyAffineTransform(CGPointMake(0, 0), *transform);

    __block CGFloat top = p.y;
    __block CGFloat left = p.x;
    __block CGFloat right = p.x;
    __block CGFloat bottom = p.y;
    __block BOOL set = NO;

    [self traverseSubviews:^BOOL(RNSVGNode *node) {
        if ([node isKindOfClass:[RNSVGRenderable class]]) {
            RNSVGRenderable* renderable = node;

            CGAffineTransform subtransform = CGAffineTransformConcat(renderable.matrix, *transform);
            CGRect subbox = [renderable getPathBox:&subtransform];

            if (set == NO) {
                top = subbox.origin.y;
                left = subbox.origin.x;
                right = left + subbox.size.width;
                bottom = top + subbox.size.height;
                set = YES;
                return YES;
            }

            if (top > subbox.origin.y) {
                top = subbox.origin.y;
            }
            if (left > subbox.origin.x) {
                left = subbox.origin.x;
            }
            if (right < subbox.origin.x + subbox.size.width) {
                right = subbox.origin.x + subbox.size.width;
            }
            if (bottom < subbox.origin.y + subbox.size.height) {
                bottom = subbox.origin.y + subbox.size.height;
            }
        }
        return YES;
    }];

    [self setPathBox: CGRectMake(left, top, right - left, bottom - top)];

    return self._pathbox;
}

@end
