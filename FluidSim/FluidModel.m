//
//  FluidModel.m
//  FluidSim
//
//  Created by Michael hein on 9/24/13.
//  Copyright (c) 2013 self. All rights reserved.
//

#import "FluidModel.h"

#define IX(i,j) ((i)+(m+2)*(j))
#define SWAP(x0,x) {float *tmp=x0;x0=x;x=tmp;}

@interface FluidModel()
{
    
}

@end


typedef enum {
    BoundDensity,
    BoundVelocityX,
    BoundVelocityY,
    NumBoundOperations
} BoundOperation;


typedef enum {
    BoundDirectionUp,
    BoundDirectionRight,
    BoundDirectionDown,
    BoundDirectionLeft,
    BoundCornerTopLeft,
    BoundCornerTopRight,
    BoundCornerBottomRight,
    BoundCornerBottomLeft,
    NumBoundDirections,
} BoundDirection;



@implementation FluidModel

const int iterations = 20;

//////////  Density Step   /////////////
void addSource(int m, int n, float *x, float *s, BoundType *bounds, float dt);
void addAccel(int m, int n, float *x, float *s, BoundType *bounds, float dt);
void diffuse(int m, int n, BoundOperation b, float *x, float *xPrev, BoundType *bounds, float diff, float dt);
void advect(int m, int n, BoundOperation b, float *d, float *dPrev, float *U, float *V, BoundType *bounds, float dt);

//////////  Velocity Step   ////////////
void project (int m, int n, float *u, float *v, float *p, float *div, BoundType *bounds);

void setBound (int m, int n, BoundOperation b, float *x, BoundType *bounds);
BoundDirection findBoundDirection(int m, int n, BoundType *bounds, int i, int j);
void performBoundOperation(int m, int n, BoundOperation b, float *x, int i, int j, BoundDirection direction);
bool isValidOperation(BoundOperation b, BoundDirection direction);

////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

#pragma mark - Major Steps

void densityStep(int m, int n, float *x, float *xPrev, float *u, float *v, float *source, BoundType *bounds, float diff, float dt)
{
    addSource(m, n, x, source, bounds, dt);
    SWAP(xPrev, x); diffuse(m, n, BoundDensity, x, xPrev, bounds, diff, dt);
    SWAP(xPrev, x); advect(m, n, BoundDensity, x, xPrev, u, v, bounds, dt);
}

void velocityStep(int m, int n, float *u, float *v, float *uPrev, float *vPrev, float *uAccel, float *vAccel, BoundType *bounds, float visc, float dt)
{
    addAccel(m, n, u, uAccel, bounds, dt); addAccel(m, n, v, vAccel, bounds, dt );
    SWAP ( uPrev, u ); diffuse (m, n, BoundVelocityX, u, uPrev, bounds, visc, dt );
    SWAP ( vPrev, v ); diffuse (m, n, BoundVelocityY, v, vPrev, bounds, visc, dt );
    project (m, n, u, v, uPrev, vPrev, bounds);
    SWAP ( uPrev, u ); SWAP ( vPrev, v );
    advect (m, n, BoundVelocityX, u, uPrev, uPrev, vPrev, bounds, dt ); advect (m, n, BoundVelocityY, v, vPrev, uPrev, vPrev, bounds, dt );
    project (m, n, u, v, uPrev, vPrev, bounds);
}

#pragma mark - Sub-steps

void addSource(int m, int n, float *x, float *s, BoundType *bounds, float dt)
{
    int size = (m+2)*(n+2);
    for (int i = 0; i<size; i++) {
        x[i] += s[i]*dt;
        if (x[i] < 0) {
            x[i] = 0;
        }
    }
}

void addAccel(int m, int n, float *x, float *s, BoundType *bounds, float dt)
{
    int size = (m+2)*(n+2);
    for (int i = 0; i<size; i++) {
        x[i] += s[i]*dt;
    }
}

void diffuse (int m, int n, BoundOperation b, float *x, float *xPrev, BoundType *bounds, float diff, float dt)
{
    float a=dt*diff*n*m;
    for (int k=0 ; k<iterations ; k++ ) {
        for (int i=1 ; i<=m ; i++ ) {
            for (int j=1 ; j<=n ; j++ ) {
                if (!(bounds[IX(i, j)]==BoundEdge || bounds[IX(i, j)]==BoundFill)) {
                    x[IX(i,j)] = (xPrev[IX(i,j)] + a*(x[IX(i-1,j)]+x[IX(i+1,j)]+
                                                      x[IX(i,j-1)]+x[IX(i,j+1)]))/(1+4*a);
                    if (x[IX(i, j)] < 0 && b == BoundDensity) {
                        x[IX(i, j)] = 0;
                    }
                }
            }
        }
        setBound(m, n, b, x, bounds);
    }
}

void advect(int m, int n, BoundOperation b, float *d, float *dPrev, float *U, float *V, BoundType *bounds, float dt)
{
    int i, j, i0, j0, i1, j1;
    float x, y, s0, t0, s1, t1, dt0x, dt0y;
    dt0x = dt*m;
    dt0y = dt*n;
    for ( i=1 ; i<=m ; i++ ) {
        for ( j=1 ; j<=n ; j++ ) {
            x = i-dt0x*U[IX(i,j)]; y = j-dt0y*V[IX(i,j)];
            if (x<0.5) x=0.5; if (x>m+0.5) x=m+ 0.5; i0=(int)x; i1=i0+1;
            if (y<0.5) y=0.5; if (y>n+0.5) y=n+ 0.5; j0=(int)y; j1=j0+1;
            s1 = x-i0; s0 = 1-s1; t1 = y-j0; t0 = 1-t1;
            d[IX(i,j)] = s0*(t0*dPrev[IX(i0,j0)]+t1*dPrev[IX(i0,j1)])+s1*(t0*dPrev[IX(i1,j0)]+t1*dPrev[IX(i1,j1)]);
            if (d[IX(i, j)] < 0 && b == BoundDensity) {
                d[IX(i, j)] = 0;
            }
        }
    }
    setBound (m, n, b, d, bounds);
}

void project (int m, int n, float *u, float *v, float *p, float *div, BoundType *bounds)
{
    int i, j, k;
    float hx, hy;
    hx = 1.0/m;
    hy = 1.0/n;
    for ( i=1 ; i<=m ; i++ ) {
        for ( j=1 ; j<=n ; j++ ) {
            div[IX(i,j)] = -0.5*(hx*(u[IX(i+1,j)]-u[IX(i-1,j)])+hy*(v[IX(i,j+1)]-v[IX(i,j-1)]));
            p[IX(i,j)] = 0;
        }
    }
    setBound (m, n, 0, div, bounds); setBound (m, n, 0, p, bounds);
    for ( k=0 ; k<iterations ; k++ ) {
        for ( i=1 ; i<=m ; i++ ) {
            for ( j=1 ; j<=n ; j++ ) {
                p[IX(i,j)] = (div[IX(i,j)]+p[IX(i-1,j)]+p[IX(i+1,j)]+
                              p[IX(i,j-1)]+p[IX(i,j+1)])/4;
            }
        }
        setBound (m, n, 0, p, bounds);
    }
    for ( i=1 ; i<=m ; i++ ) {
        for ( j=1 ; j<=n ; j++ ) {
            u[IX(i,j)] -= 0.5*(p[IX(i+1,j)]-p[IX(i-1,j)])/hx;
            v[IX(i,j)] -= 0.5*(p[IX(i,j+1)]-p[IX(i,j-1)])/hy;
        }
    }
    setBound (m, n, 1, u, bounds); setBound (m, n, 2, v, bounds);
}


void setBound (int m, int n, BoundOperation b, float *x, BoundType *bounds)
{
    for (int i = 0; i<m+2; i++) {
        for (int j = 0; j<n+2; j++) {
            if (bounds[IX(i, j)] == BoundEdge) {
                BoundDirection direction = findBoundDirection(m, n, bounds, i, j);
                if (isValidOperation(b, direction)) {
                    performBoundOperation(m, n, b, x, i, j, direction);
                }
            }
            else if(bounds[IX(i, j)] == BoundFill) {
                x[IX(i, j)] = 0;
            }
        }
    }
}


BoundDirection findBoundDirection(int m, int n, BoundType *bounds, int i, int j)
{
    if (i == 0) {
        if (j == 0) {
            return BoundCornerBottomLeft;
        }
        else if (j == n+1) {
            return BoundCornerTopLeft;
        }
        else {
            return BoundDirectionRight;
        }
    }
    else if (i == m+1) {
        if (j == 0) {
            return BoundCornerBottomRight;
        }
        else if (j == n+1) {
            return BoundCornerTopRight;
        }
        else {
            return BoundDirectionLeft;
        }
    }
    else if (j == 0) {
        return BoundDirectionUp;
    }
    else if (j == n+1) {
        return BoundDirectionDown;
    }
    
    const int numDirections = 4;
    const char zero[5] = "tfff\0";
    const char one[5] = "ftff\0";
    const char two[5] = "fftf\0";
    const char three[5] = "ffft\0";
    const char four[5] = "tfft\0";
    const char five[5] = "ttff\0";
    const char six[5] = "fttf\0";
    const char seven[5] = "fftt\0";
    
    const char *patterns[NumBoundDirections] = {
        zero,
        one,
        two,
        three,
        four,
        five,
        six,
        seven,
    };
    char patternFound[numDirections+1] = "";
    patternFound[4] = '\0';
    switch ((int)bounds[IX(i, j+1)]) {
        case NoBound:
            patternFound[0] = 't';
            break;
        case BoundEdge:
        case BoundFill:
            patternFound[0] = 'f';
            break;
    }
    switch ((int)bounds[IX(i+1, j)]) {
        case NoBound:
            patternFound[1] = 't';
            break;
        case BoundEdge:
        case BoundFill:
            patternFound[1] = 'f';
            break;
    }
    switch ((int)bounds[IX(i, j-1)]) {
        case NoBound:
            patternFound[2] = 't';
            break;
        case BoundEdge:
        case BoundFill:
            patternFound[2] = 'f';
            break;
    }
    switch ((int)bounds[IX(i-1, j)]) {
        case NoBound:
            patternFound[3] = 't';
            break;
        case BoundEdge:
        case BoundFill:
            patternFound[3] = 'f';
            break;
    }
    for (int i = 0; i<NumBoundDirections; i++) {
        if (strncmp(patternFound, patterns[i], numDirections+1) == 0) {
            return (BoundDirection)i;
        }
    }
    if (strncmp(patternFound, "ffff", numDirections)) {
        bounds[IX(i, j)] = BoundFill;
    }
    return NumBoundDirections;
}

void performBoundOperation(int m, int n, BoundOperation b, float *x, int i, int j, BoundDirection direction)
{
    if (!isValidOperation(b, direction)) {
        return;
    }
    switch (direction) {
        case BoundDirectionUp:
            switch (b) {
                case BoundDensity:
                    x[IX(i, j)] = x[IX(i, j+1)];
                    break;
                case BoundVelocityY:
                    x[IX(i, j)] = -x[IX(i, j+1)];
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BoundDirectionRight:
            switch (b) {
                case BoundDensity:
                    x[IX(i, j)] = x[IX(i+1, j)];
                    break;
                case BoundVelocityX:
                    x[IX(i, j)] = -x[IX(i+1, j)];
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BoundDirectionDown:
            switch (b) {
                case BoundDensity:
                    x[IX(i, j)] = x[IX(i, j-1)];
                    break;
                case BoundVelocityY:
                    x[IX(i, j)] = -x[IX(i, j-1)];
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BoundDirectionLeft:
            switch (b) {
                case BoundDensity:
                    x[IX(i, j)] = x[IX(i-1, j)];
                    break;
                case BoundVelocityX:
                    x[IX(i, j)] = -x[IX(i-1, j)];
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BoundCornerTopRight:
            switch (b) {
                case BoundDensity:
                    x[IX(i, j)] = (x[IX(i-1, j)]+x[IX(i, j-1)])/2;
                    break;
                case BoundVelocityY:
                    x[IX(i, j)] = (x[IX(i-1, j)]+x[IX(i, j-1)])/2;
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BoundCornerTopLeft:
            switch (b) {
                case BoundDensity:
                    x[IX(i, j)] = (x[IX(i+1, j)]+x[IX(i, j-1)])/2;
                    break;
                case BoundVelocityY:
                    x[IX(i, j)] = (x[IX(i+1, j)]+x[IX(i, j-1)])/2;
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BoundCornerBottomRight:
            switch (b) {
                case BoundDensity:
                    x[IX(i, j)] = (x[IX(i-1, j)]+x[IX(i, j+1)])/2;
                    break;
                case BoundVelocityY:
                    x[IX(i, j)] = (x[IX(i-1, j)]+x[IX(i, j+1)])/2;
                    break;
                default:
                    return;
                    break;
            }
            break;
        case BoundCornerBottomLeft:
            switch (b) {
                case BoundDensity:
                    x[IX(i, j)] = (x[IX(i+1, j)]+x[IX(i, j+1)])/2;
                    break;
                case BoundVelocityY:
                    x[IX(i, j)] = (x[IX(i+1, j)]+x[IX(i, j+1)])/2;
                    break;
                default:
                    return;
                    break;
            }
            break;
        default:
            return;
            break;
    }
}

bool isValidOperation(BoundOperation b, BoundDirection direction)
{
    const bool results[NumBoundOperations*NumBoundDirections] = {
        //Rows: density, vertical, horizontal   Cols: up, right, down, left, topleft, topright, botright, botleft
        true, true, true, true, true, true, true, true,
        false, true, false, true, false, false, false, false,
        true, false, true, false, true, true, true ,true
    };
    return results[(int)direction+8*(int)b];
}

void addBound(int m, int n, int x, int y, int width, int height, BoundType *bounds, float *dens, float *u, float *v)
{
    width = abs(width);
    height = abs(height);
    if (x<1 || y<1 || x+width>m+1 || y+height>n+1 || width<3 || height<3) {
        return;
    }
    
    for (int i=y ; i<y+height ; i++ ) {
        if (bounds[IX(x,i)] == NoBound) {
            bounds[IX(x,i)] = BoundEdge;
        }
        if (bounds[IX(x+width-1,i)] == NoBound) {
            bounds[IX(x+width-1,i)] = BoundEdge;
        }
    }
    for (int i=x ; i<x+width; i++) {
        if (bounds[IX(i,y)] == NoBound) {
            bounds[IX(i,y)] = BoundEdge;
        }
        if (bounds[IX(i,y+height-1)] == NoBound) {
            bounds[IX(i,y+height-1)] = BoundEdge;
        }
    }
    
    for (int i = x+1; i<x+width-1; i++) {
        for (int j = y+1; j<y+height-1; j++) {
            bounds[IX(i, j)] = BoundFill;
        }
    }
}

void addVelocity(int m, int n, int x, int y, int width, int height, float du, float dv, BoundType *bounds, float *u, float *v)
{    
    for (int i = x; i<x+width; i++) {
        for (int j = y; j<y+height; j++) {
            if (!(i<1 || j<1 || i>m || j>n)) {
                if (bounds[IX(i, j)] == NoBound) {
                    u[IX(i, j)] += du;
                    v[IX(i, j)] += dv;
                }
            }
        }
    }
}


//void setBound (int m, int n, BoundOperation b, float *x, BoundType *bounds)
//{
//    int i;
//    for ( i=1 ; i<=n ; i++ ) {
//        x[IX(0 ,i)] = (int)b==1 ? (-1)*x[IX(1,i)] : x[IX(1,i)];
//        x[IX(m+1,i)] = (int)b==1 ? (-1)*x[IX(m,i)] : x[IX(m,i)];
//    }
//    for ( i=1 ; i<=m; i++) {
//        x[IX(i,0 )] = (int)b==2 ? x[IX(i,1)]*(-1) : x[IX(i,1)];
//        x[IX(i,n+1)] = (int)b==2 ? x[IX(i,n)]*(-1) : x[IX(i,n)];
//    }
//
//    x[IX(0 ,0 )] = 0.5*(x[IX(1,0 )]+x[IX(0 ,1)]);
//    x[IX(0 ,n+1)] = 0.5*(x[IX(1,n+1)]+x[IX(0,n)]);
//    x[IX(m+1,0 )] = 0.5*(x[IX(m,0 )]+x[IX(m+1,1)]);
//    x[IX(m+1,n+1)] = 0.5*(x[IX(m,n+1)]+x[IX(m+1,n)]);
//}



@end
