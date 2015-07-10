//
//  FluidModel.h
//  FluidSim
//
//  Created by Michael hein on 9/24/13.
//  Copyright (c) 2013 self. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FluidModel : NSObject




typedef enum {
    NoBound,
    BoundEdge,
    BoundFill,
    NumBoundTypes,
} BoundType;

void densityStep(int m, int n, float *x, float *xPrev, float *u, float *v, float *source, BoundType *bounds, float diff, float dt);
void velocityStep(int m, int n, float *u, float *v, float *uPrev, float *vPrev, float *uAccel, float *vAccel, BoundType *bounds, float visc, float dt);

void addBound(int m, int n, int x, int y, int width, int height, BoundType *bounds, float *dens, float *u, float *v);
void addVelocity(int m, int n, int x, int y, int width, int height, float du, float dv, BoundType *bounds, float *u, float *v);

@end