/*
 * AStarPathfinder https://github.com/sqlboy/tiled-games
 *
 * Copyright (c) 2011 Matt Chambers
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 */

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#define ASTAR_COLLIDE_PROP_NAME @"COLLIDE"
#define ASTAR_COLLIDE_PROP_VALUE @"1"

@class AStarNode;
@class AStarPathFinder;

/**
* A structure for storing a A* node
*/
@interface AStarNode : NSObject {
  int x;
  int y;
@public
  AStarNode *parent;
  CGPoint point;
  int F;
  int G;
  int H;
}

/**
* Create a new autoreleased node at the given tile position.
*/
+ (id) nodeAtPoint:(CGPoint)pos;

/**
* Initialize the node at the given tile position;
**/
- (id) initAtPoint:(CGPoint)pos;

/**
* Returns the calculated cost of the node.
*/
- (int) cost;


@end

/**
* AStarPathFinder provides the the ability to animate sprites around
* a CCTMXTiledMap along an A* path calcuated by suppied source
* and destination tiles.
**/
@interface AStarPathFinder : CCLayer {
  CCTMXTiledMap *tileMap;
  CCTMXLayer *collideLayer;
  NSMutableSet *openNodes;
  NSMutableSet *closedNodes;
  NSString *collideKey;
  NSString *collideValue;
  BOOL considerDiagonalMovement;
  float pathFillColor[4];
  CGImageRef pathHighlightImage;
}

/** The name of the tile property which stores the collision boolean. */
@property (copy, nonatomic) NSString *collideKey;
/** The value of the tile property which indicates a collide tile. */
@property (copy, nonatomic) NSString *collideValue;
/** If True the path may use diagonal movement. */
@property (assign, nonatomic) BOOL considerDiagonalMovement;

/**
* Initialize the object with a CCTMXTileMap and the name of
* the layer which contains your collision tiles.
* 
* The default collide property name is COLLIDE,
* which is checked for the default value of 1.  Use setCollideKey
* and setCollideValue to customize.
*/
- (id) initWithTileMap:(CCTMXTiledMap*)aTileMap collideLayer:(NSString*)name;

/**
* Return an array of tiles which make up the shortest path between src and dst.
**/
- (NSArray*) getPath:(CGPoint)src to:(CGPoint)dst;

/**
* Highlight the calculated A* path.
**/
- (void) highlightPathFrom:(CGPoint)src to:(CGPoint)dst;

/**
* Move given sprite along the calcualted A* path.
**/
- (void) moveSprite:(CCSprite*)sprite 
        from:(CGPoint)src to:(CGPoint)dst atSpeed:(float)speed;
/**
* Set the fill color for the path highlight.
**/        
- (void) setPathRGBAFillColor:(float)red
                            g:(float)green
                            b:(float)blue
                            a:(float)alpha;
@end




