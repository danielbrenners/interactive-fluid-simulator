//
//  FluidGLViewController.m
//  FluidSim
//
//  Created by Michael hein on 9/24/13.
//  Copyright (c) 2013 self. All rights reserved.
//

#import "FluidGLViewController.h"
#import "Fluid.h"
#import "FluidModel.h"
#import "FluidAppDelegate.h"
#import "FluidMenuViewController.h"
#import <time.h>
#import <math.h>


#define IX(i,j) ((i)+(fluid.m+2)*(j))
#define VIX(i,j) ((i)+(fluid.m)*(j))

enum {
    VertexAttribPosition = 0,
    VertexAttribDensity,
    NumVertexAttribs = 2,
};

enum {
    UniformFluidColor,
    UniformProjection,
    NumUniforms,
};
GLint uniforms[NumUniforms];


const float diff = 0.0003f;
const float visc = 1.0f;


typedef struct
{
    GLfloat position[2];
    GLfloat density;
} FluidCell2D;


@interface FluidGLViewController () {
    GLuint glProgram;
    
    GLuint _vertexArray;
    GLuint _vertexBuffer;
    GLuint _elementBuffer;
    
    int numVertices;
    int numIndices;
    
    FluidCell2D *vertices;
    GLuint *indices;
}

@property (strong, nonatomic) IBOutlet GLKView *view;
@property (strong, nonatomic) EAGLContext *context;


////////////   SETUP   ///////////
- (void)setUpGL;
- (BOOL)loadShaders;
- (BOOL)linkProgram:(GLuint)program;
- (BOOL)compileShader:(GLuint*)shader ofType:(GLenum)type path:(NSString*)path;
//////////////////////////////////

- (IBAction)actionReturn:(id)sender;

@end


@implementation FluidGLViewController

@synthesize fluid = fluid;

#pragma mark - ViewController functions

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil fluid:(Fluid*)fluidIn
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setFluid:fluidIn];
        [self setTitle:@"Simulation"];
        numVertices = fluid.m*fluid.n;
        numIndices = 6*(fluid.m-1)*(fluid.n-1);
        
    }
    return self;
}


- (void)viewDidLoad
{
    vertices = malloc(sizeof(FluidCell2D)*numVertices);
    indices = malloc(sizeof(GLuint)*numIndices);
    
    //gesture recognizers for moving fluid around
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePanGesture:)];
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTapGesture:)];
    
    [self.view addGestureRecognizer:tapRecognizer];
    [self.view addGestureRecognizer:panRecognizer];
    
    for (int i = 0; i<fluid.m+2; i++) {
        for (int j = 0; j<fluid.n+2; j++) {
            if (i<fluid.m && j<fluid.n) {
                vertices[VIX(i, j)].position[0] = (((i)/((GLfloat)(fluid.m-1)))*2-1);
                vertices[VIX(i, j)].position[1] = (((j)/((GLfloat)(fluid.m-1)))*2-1*((float)fluid.n/fluid.m));
                
//                vertices[VIX(i, j)].position[0] = i;
//                vertices[VIX(i, j)].position[1] = j;
                vertices[VIX(i, j)].density = 0;
            }
            
        }
    }
    
    
    //once we have the dimensions  (m x n) of the model, we can prepare the triangles. I think this can be done any time before the rendering loop starts.
    for (int j = 0; j<fluid.n-1; j++) {
        for (int i = 0; i<fluid.m-1; i++) {
            int baseIndex = 6*(i+j*(fluid.m-1));
            indices[baseIndex] = VIX(i, j);
            indices[baseIndex+1] = VIX(i+1, j);
            indices[baseIndex+2] = VIX(i+1, j+1);
            indices[baseIndex+3] = VIX(i, j);
            indices[baseIndex+4] = VIX(i+1, j+1);
            indices[baseIndex+5] = VIX(i, j+1);
        }
    }
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    GLKView *view = (GLKView*)self.view;
    view.context = self.context;
    
    [self setUpGL];
}

- (void)viewDidUnload
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    free(vertices);
    free(indices);
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)gestureRecognizer
{
    CGPoint currentLocation = [gestureRecognizer locationInView:self.view];
    CGPoint velocity = [gestureRecognizer velocityInView:self.view];
    
    
    addVelocity(fluid.m, fluid.n, currentLocation.x/self.view.bounds.size.width*fluid.m, fabsf(1-currentLocation.y/self.view.bounds.size.height)*fluid.n, 5, 5, velocity.x/self.view.bounds.size.width*2, -velocity.y/self.view.bounds.size.height*2, fluid.bounds, fluid.u, fluid.v);
}

- (void)handleTapGesture:(UITapGestureRecognizer *)gestureRecognizer
{
    CGPoint currentLocation = [gestureRecognizer locationInView:self.view];
    
    int x = currentLocation.x/self.view.bounds.size.width*fluid.m;
    int y = fabsf(1-currentLocation.y/self.view.bounds.size.height)*fluid.n;
    
    for (int i = x; i<x+3; i++) {
        addVelocity(fluid.m, fluid.n, i, y-1, 1, 1, 0, -500, fluid.bounds, fluid.u, fluid.v);
        addVelocity(fluid.m, fluid.n, i, y+1, 1, 1, 0, 500, fluid.bounds, fluid.u, fluid.v);
    }
    for (int i = y; i<y+3; i++) {
        addVelocity(fluid.m, fluid.n, x-1, i, 1, 1, -500, 0, fluid.bounds, fluid.u, fluid.v);
        addVelocity(fluid.m, fluid.n, x+1, i, 1, 1, 500, 0, fluid.bounds, fluid.u, fluid.v);
    }
}

#pragma mark - GL state

- (void)setUpGL
{
    [EAGLContext setCurrentContext:self.context];
    
    
    
    //set up the program.
    [self loadShaders];
    
    //glGenVertexArraysOES(1, &_vertexArray);
    //glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(*vertices)*numVertices, vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_elementBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _elementBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(*indices)*numIndices, indices, GL_STATIC_DRAW);
    
    int offset = sizeof(*vertices);
    glEnableVertexAttribArray(VertexAttribPosition);
    glVertexAttribPointer(VertexAttribPosition, 2, GL_FLOAT, GL_FALSE, offset, 0);
    
    glEnableVertexAttribArray(VertexAttribDensity);
    glVertexAttribPointer(VertexAttribDensity, 1, GL_FLOAT, GL_FALSE, offset, (GLvoid*)(sizeof(GLfloat)*2));
    
    glBindVertexArrayOES(0);
    
    glEnable (GL_BLEND);
    glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    
    glEnable(GL_CULL_FACE);
    //glDisable(GL_LIGHTING);
    //glCullFace(GL_FRONT_FACE);
}

- (void)tearDownGL
{
    //undo everything in setUpGL()
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_elementBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
        
    if (glProgram) {
        glDeleteProgram(glProgram);
        glProgram = 0;
    }
}

#pragma mark - OpenGL Program

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    
    NSString *vertShaderPath, *fragShaderPath;
    glProgram = glCreateProgram();
    
    vertShaderPath = [[NSBundle mainBundle]pathForResource:@"Fluid" ofType:@"vsh"];
    
    if (![self compileShader:&vertShader ofType:GL_VERTEX_SHADER path:vertShaderPath]) {
        return NO;
    }
    
    fragShaderPath = [[NSBundle mainBundle]pathForResource:@"Fluid" ofType:@"fsh"];
    if (![self compileShader:&fragShader ofType:GL_FRAGMENT_SHADER path:fragShaderPath]) {
        return NO;
    }
    glAttachShader(glProgram, vertShader);
    glAttachShader(glProgram, fragShader);
    
    glBindAttribLocation(glProgram, VertexAttribPosition, "position");
    glBindAttribLocation(glProgram, VertexAttribDensity, "density");
    
    if (![self linkProgram:glProgram]) {
        NSLog(@"Failed to link program: %d", glProgram);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (glProgram) {
            glDeleteProgram(glProgram);
            glProgram = 0;
        }
        
        return NO;
    }
    
    uniforms[UniformFluidColor] = glGetUniformLocation(glProgram, "fluidColor");
    uniforms[UniformProjection] = glGetUniformLocation(glProgram, "modelViewProjectionMatrix");
    
    if (vertShader) {
        glDetachShader(glProgram, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(glProgram, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}


- (BOOL)linkProgram:(GLuint)program
{
    glLinkProgram(program);
    
    GLint status;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}


- (BOOL)compileShader:(GLuint*)shader ofType:(GLenum)type path:(NSString*)path
{
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]UTF8String];
    
    if (!source) {
        return NO;
    }
    
    *shader = glCreateShader(type);
    
    glShaderSource(*shader, 1, &source, NULL);
    
    glCompileShader(*shader);
    
    GLint status;
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}


- (IBAction)actionReturn:(id)sender
{
    FluidMenuViewController *fluidMenuVC = [[FluidMenuViewController alloc]initWithNibName:@"FluidMenuView" bundle:[NSBundle mainBundle]];
    [self presentViewController:fluidMenuVC animated:YES completion:nil];
}


#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    [fluid stepForward:1.0f/self.framesPerSecond];
    for (int i = 1; i<fluid.m+1; i++) {
        for (int j = 1; j<fluid.n+1; j++) {
            vertices[VIX(i-1, j-1)].density = fluid.dens[IX(i, j)];
        }
    }
    glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(*vertices)*numVertices, vertices);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    glClearColor(1.0f, 1.0f, 1.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glUseProgram(glProgram);
    
    glBindVertexArrayOES(_vertexArray);
    
    glUniform4fv(uniforms[UniformFluidColor], 1, fluid.color);   //fluidColor
    
    
    float aspect = fabsf((float)self.view.bounds.size.width/self.view.bounds.size.height);
    const float near=0.1, f=.101f;
    const float t = -tanf(90.0f)*near, b=-t, r=t*aspect, l=-t*aspect;
    float projectionMatrix[16] = {
//        (2*n)/(r-l),    0,              (r+l)/(r-l),    0,
//        0,              (2*n)/(t-b),    (t+b)/(t-b),    0,
//        0,              0,              -(f+n)/(f-n)    -2*(f*n)/(f-n),
//        0,              0,              -1,             0
        (2*near)/(r-l),    0,              0,              0,
        0,              (2*near)/(t-b),    0,              0,
        (r+l)/(r-l),    (t+b)/(t-b),    -(f+near)/(f-near),   -1,
        0,              0,              -2*(f*near)/(f-near), 0
    };
    
    
    float translateMatrix[16] = {
        1,      0,      0,      0,
        0,      1,      0,      0,
        0,      0,      1,      -1,
        0,      0,      -1,      0,
    };
    
    GLKMatrix4 matrix1 = GLKMatrix4MakeWithArray(projectionMatrix);
    GLKMatrix4 matrix2 = GLKMatrix4MakeWithArray(translateMatrix);
    GLKMatrix4 perspectiveProjectionMatrix = GLKMatrix4Multiply(matrix1, matrix2);
    
    glUniformMatrix4fv(uniforms[UniformProjection], 1, GL_FALSE, perspectiveProjectionMatrix.m);
    
    glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, 0);
}






@end







