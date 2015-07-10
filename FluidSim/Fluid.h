//
//  Fluid.h
//  FluidSim
//
//  Created by Michael hein on 10/10/13.
//  Copyright (c) 2013 self. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FluidModel.h"

@interface Fluid : NSObject

- (id)initWithWidth:(int)width Height:(int)height;
- (void)reset;
- (void)stepForward:(float)dt;

@property (nonatomic, readonly) int m;
@property (nonatomic, readonly) int n;

@property (nonatomic, readonly) int size;
@property (nonatomic) float diff;
@property (nonatomic) float visc;

//remove later
@property (nonatomic) float lowerDens;
@property (nonatomic) float upperDens;

@property (nonatomic, readonly) float *dens;
@property (nonatomic, readonly) float *u;
@property (nonatomic, readonly) float *v;
@property (nonatomic, readonly) BoundType *bounds;

@property (nonatomic, readonly) float *color;

- (void)addBoundWithX:(int)x Y:(int)y Width:(int)width Height:(int)height;
- (void)setColor:(float[4])colorIn;
- (void)addRandomDensities;

@end
