//
//  TCAppDelegate.m
//  CubeWalker
//
//  Created by Joachim Bengtsson on 2013-01-16.
//  Copyright (c) 2013 nevyn. All rights reserved.
//

#define frand() ((arc4random()%INT_MAX)/(float)INT_MAX)
#define SCNVector3ToString(v) [NSString stringWithFormat:@"(%.0f %.0f %.0f)", v.x, v.y, v.z]

#import "TCAppDelegate.h"
#import <Carbon/Carbon.h>

@interface TCAppDelegate ()
{
    SCNNode *_cubeParent;
    NSMutableArray *_cubes;
    SCNNode *_playerNode;
    SCNNode *_cameraNode;
    CGPoint _playerPos;
}

@property (weak) IBOutlet SCNView *sceneView;
@end

@implementation TCAppDelegate

static const CGFloat kCubeSize = 50;
static const CGFloat kCubeMargin = 0;
static const int kCubesPerSide = 40;

- (SCNVector3)gridPositionForCubeCoordinate:(CGPoint)p z:(CGFloat)z
{
    return SCNVector3Make(p.x*(kCubeSize+kCubeMargin), p.y*(kCubeSize+kCubeMargin), z);
}

- (void)awakeFromNib
{
    _cameraNode = [_sceneView.scene.rootNode childNodesPassingTest:^BOOL(SCNNode *child, BOOL *stop) {
        if(child.camera) {
            *stop = YES;
            return YES;
        }
        return NO;
    }][0];
    
    _cubeParent = [SCNNode node];
    [_sceneView.scene.rootNode addChildNode:_cubeParent];
    
    _cubes = [NSMutableArray new];
    for(int y = 0; y < kCubesPerSide; y++) {
        for(int x = 0; x < kCubesPerSide; x++) {
            SCNBox *geometry = [SCNBox boxWithWidth:kCubeSize height:kCubeSize*2 length:kCubeSize chamferRadius:0];
            SCNNode *cube = [SCNNode nodeWithGeometry:geometry];
            cube.position = [self gridPositionForCubeCoordinate:CGPointMake(x,y) z:0];
            [_cubeParent addChildNode:cube];
            [_cubes addObject:cube];
            
            CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
            anim.fromValue = [NSValue valueWithSCNVector3:cube.position];
            anim.toValue = [NSValue valueWithSCNVector3:SCNVector3Make(cube.position.x, cube.position.y, frand()*50.)];
            anim.duration = frand()*5 + 1.0;
            anim.repeatCount = 4;//HUGE_VALF;
            anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
            anim.autoreverses = YES;
            [cube addAnimation:anim forKey:@"wobble"];
        }
    }
    _cubeParent.position = SCNVector3Make(-(kCubeSize+kCubeMargin)*kCubesPerSide/2, -(kCubeSize+kCubeMargin)*kCubesPerSide/2, 0);
    
    SCNBox *geometry = [SCNBox boxWithWidth:kCubeSize height:kCubeSize length:kCubeSize chamferRadius:0];
    SCNMaterial *material = [SCNMaterial material];
    material.diffuse.contents  = [NSColor blueColor];
    material.specular.contents = [NSColor whiteColor];
    material.shininess = 1.0;
    geometry.materials = @[material];

    _playerNode = [SCNNode nodeWithGeometry:geometry];
    _playerPos = CGPointMake(15, 20);
    [_cubeParent addChildNode:_playerNode];

    
    [_sceneView enterFullScreenMode:[NSScreen mainScreen] withOptions:nil];
    [_sceneView setNextResponder:self];
    
    [NSTimer scheduledTimerWithTimeInterval:1/60. target:self selector:@selector(tick) userInfo:nil repeats:YES];
}

- (void)tick
{
    SCNNode *cubeUnderPlayer = _cubes[(int)(_playerPos.y*kCubesPerSide + _playerPos.x)];

    _playerNode.position = [self gridPositionForCubeCoordinate:CGPointMake(_playerPos.x, _playerPos.y) z:cubeUnderPlayer.presentationNode.position.z+kCubeSize];
    
    SCNVector3 camPos = _playerNode.position;
    camPos.x -= 995;
    camPos.y -= 1400;
    camPos.z = 130; //+= 100;
//    NSLog(@"%@   %@", SCNVector3ToString(camPos), SCNVector3ToString(_playerNode));
    
    if(!SCNVector3EqualToVector3(camPos, _cameraNode.position)) {
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"position"];
        anim.fromValue = [NSValue valueWithSCNVector3:_cameraNode.position];
        anim.toValue = [NSValue valueWithSCNVector3:camPos];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        anim.duration = 0.5;
        
        [_cameraNode addAnimation:anim forKey:@"cameraMove"];
        _cameraNode.position = camPos;
    }
}

- (void)keyDown:(NSEvent *)theEvent;
{
    SCNVector4 rotation;
    CGPoint newPos = _playerPos;
    if(theEvent.keyCode == kVK_UpArrow) {
        newPos.y += 1;
        rotation = SCNVector4Make(-1, 0, 0, M_PI/2);
    } else if(theEvent.keyCode == kVK_DownArrow) {
        newPos.y -= 1;
        rotation = SCNVector4Make(1, 0, 0, M_PI/2);
    } else if(theEvent.keyCode == kVK_RightArrow) {
        newPos.x += 1;
        rotation = SCNVector4Make(0, 1, 0, M_PI/2);
    } else if(theEvent.keyCode == kVK_LeftArrow) {
        newPos.x -= 1;
        rotation = SCNVector4Make(0, -1, 0, M_PI/2);
    }
    _playerPos = newPos;
    
    CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"rotation"];
    anim.fromValue = [NSValue valueWithSCNVector4:SCNVector4Make(0, 0, 0, 0)];
    anim.toValue = [NSValue valueWithSCNVector4:rotation];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_playerNode addAnimation:anim forKey:@"rotation"];
    
    anim = [CABasicAnimation animationWithKeyPath:@"position"];
    anim.fromValue = [NSValue valueWithSCNVector3:_playerNode.position];
    anim.toValue = [NSValue valueWithSCNVector3:[self gridPositionForCubeCoordinate:CGPointMake(_playerPos.x, _playerPos.y) z:_playerNode.presentationNode.position.z]];
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [_playerNode addAnimation:anim forKey:@"position"];
}

@end
