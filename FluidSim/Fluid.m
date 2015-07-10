//
//  Fluid.m
//  FluidSim
//
//  Created by Michael hein on 10/10/13.
//  Copyright (c) 2013 self. All rights reserved.
//

#import "Fluid.h"
#import "FluidModel.h"
#import <time.h>
#import <math.h>

#define IX(i,j) ((i)+(m+2)*(j))

@interface Fluid () {
    
}


@property (nonatomic, readwrite) int m;
@property (nonatomic, readwrite) int n;

@property (nonatomic, readwrite) int size;

@property (nonatomic, readwrite) float *dens;
@property (nonatomic, readwrite) float *u;
@property (nonatomic, readwrite) float *v;

@property (nonatomic) float *densPrev;
@property (nonatomic) float *uPrev;
@property (nonatomic) float *vPrev;

@property (nonatomic) float *densSource;
@property (nonatomic) float *uAccel;
@property (nonatomic) float *vAccel;

@property (nonatomic, readwrite) float *color;

@property (nonatomic, readwrite) BoundType *bounds;


@end




@implementation Fluid


@synthesize m = m;
@synthesize n = n;
@synthesize diff = diff;
@synthesize visc = visc;
@synthesize size = size;
@synthesize dens = dens;
@synthesize u = u;
@synthesize v = v;
@synthesize densPrev = densPrev;
@synthesize uPrev = uPrev;
@synthesize vPrev = vPrev;
@synthesize densSource = densSource;
@synthesize uAccel = uAccel;
@synthesize vAccel = vAccel;
@synthesize bounds = bounds;
@synthesize color = color;

- (id)initWithWidth:(int)width Height:(int)height
{
    self = [super init];
    if (self) {
        //remove later
        srand(time(0));
        self.lowerDens = 0;
        self.upperDens = 1;
        
        m = width;
        n = height;
        size = (m+2)*(n+2);
        diff = 0.0003f;
        visc = 1.0f;
        
        dens = malloc(sizeof(float)*size);
        u = malloc(sizeof(float)*size);
        v = malloc(sizeof(float)*size);
        densPrev = malloc(sizeof(float)*size);
        uPrev = malloc(sizeof(float)*size);
        vPrev = malloc(sizeof(float)*size);
        densSource = malloc(sizeof(float)*size);
        uAccel = malloc(sizeof(float)*size);
        vAccel = malloc(sizeof(float)*size);
        color = malloc(sizeof(float)*4);
        bounds = malloc(sizeof(BoundType)*size);
        
        color[0] = 0.9f; color[1] = 0.9f; color[2] = 0.9f; color[3] = 1.0f;
        
        [self reset];
    }
    return self;
}

- (void)dealloc
{
    free(dens);
    free(u);
    free(v);
    free(densPrev);
    free(uPrev);
    free(vPrev);
    free(densSource);
    free(uAccel);
    free(vAccel);
    free(bounds);
}

- (void)reset
{
    for (int i = 0; i<m+2; i++) {
        for (int j = 0; j<n+2; j++) {
            dens[IX(i, j)] = 0.0f;
            
            densPrev[IX(i, j)] = 0.0f; densSource[IX(i, j)] = 0.0f;
            u[IX(i, j)] = 0.0f; v[IX(i, j)] = 0.0f;
            uPrev[IX(i, j)] = 0.0f; vPrev[IX(i, j)] = 0.0f;
            uAccel[IX(i, j)] = 0.0f; vAccel[IX(i, j)] = 0.0f;
            
            if (i == 0 || j == 0 || i == m+1 || j == n+1) {
                bounds[IX(i, j)] = BoundEdge;
            }
            else {
                bounds[IX(i, j)] = NoBound;
            }
            
        }
    }
}


- (void)stepForward:(float)dt
{
    for (int i = 0; i<m+2; i++) {
        for (int j = 0; j<n+2; j++) {
            densPrev[IX(i, j)] = dens[IX(i, j)];
            uPrev[IX(i, j)] = u[IX(i, j)];
            vPrev[IX(i, j)] = v[IX(i, j)];
        }
    }
    velocityStep(m, n, u, v, uPrev, vPrev, uAccel, vAccel, bounds, visc, dt); //always first
    densityStep(m, n, dens, densPrev, u, v, densSource, bounds, diff, dt); //always second
    
}

- (void)addBoundWithX:(int)x Y:(int)y Width:(int)width Height:(int)height
{
    
}

- (void)setColor:(float[4])colorIn
{
    color[0] = colorIn[0];
    color[1] = colorIn[1];
    color[2] = colorIn[2];
    color[3] = colorIn[3];
}

- (void)addRandomDensities
{
    for (int i = 0; i<m+2; i++) {
        for (int j = 0; j<(n+2)/3; j++) {
            dens[IX(i, j)] += ((float)rand()/(float)RAND_MAX)*(fabsf(self.upperDens)-fabsf(self.lowerDens))+fabsf(self.lowerDens);
        }
    }
}



@end
