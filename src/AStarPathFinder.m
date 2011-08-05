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

#import "AStarPathFinder.h"
#import "cocos2d.h"

@interface AStarPathFinder (Private)
  - (AStarNode *) lowCostNode;
  - (BOOL) isCollision:(CGPoint)point;
  - (AStarNode *) findPathFrom:(CGPoint)src to:(CGPoint)dst;
  - (CGImageRef) makePathTile;
@end

@implementation AStarPathFinder
@synthesize collideKey;
@synthesize collideValue;
@synthesize considerDiagonalMovement;

- (id) initWithTileMap:(CCTMXTiledMap*)aTileMap collideLayer:(NSString*)name
{
  if ((self=[super init])) 
  {
    tileMap = [aTileMap retain];
    openNodes = [[NSMutableSet setWithCapacity:16] retain];
    closedNodes = [[NSMutableSet setWithCapacity:64] retain];
    collideLayer = [tileMap layerNamed:name];
    collideKey = ASTAR_COLLIDE_PROP_NAME;
    collideValue = ASTAR_COLLIDE_PROP_VALUE;
    considerDiagonalMovement = YES;
  }

  return self;
}

- (void) dealloc
{
  [tileMap release];
  [openNodes release];
  [closedNodes release];
  [super dealloc];
}

- (CGImageRef) makePathTile
{
  int width = [tileMap tileSize].width;
  int height = [tileMap tileSize].height;

  CGContextRef context = NULL;
  CGColorSpaceRef imageColorSpace = CGColorSpaceCreateDeviceRGB();
  
  context = CGBitmapContextCreate(NULL, width, 
    height, 8, width * 4, imageColorSpace, kCGImageAlphaPremultipliedLast);
  
  CGContextSetRGBFillColor(context, ASTAR_PATH_COLOR);
  CGContextFillRect(context, CGRectMake(0, 0, width, height));
  
  CGImageRef imgRef = CGBitmapContextCreateImage(context);
  return imgRef;
}
  
- (AStarNode *) findPathFrom:(CGPoint)src to:(CGPoint)dst
{
  [self removeAllChildrenWithCleanup:YES];

  [openNodes removeAllObjects];
  [closedNodes removeAllObjects];

  if ([self isCollision:dst]) {
    return nil;
  }

  AStarNode *origin = [AStarNode nodeAtPoint:src];
  origin->parent = nil;
  [openNodes addObject:origin];

  AStarNode *closestNode = nil;
  while ([openNodes count])
  {
    closestNode = [self lowCostNode];
    if (closestNode->point.x == dst.x && closestNode->point.y == dst.y)
    {
      return closestNode;
    }
    else
    {
      [openNodes removeObject:closestNode];
      [closedNodes addObject:closestNode];
      
      int currentX = closestNode->point.x;
      int currentY = closestNode->point.y;
      
      for (int y=-1; y<=1; y++)
      {
        for(int x=-1; x<=1; x++)
        {
          // Skip over self
          if (x == 0 && y == 0)
            continue;
          
          AStarNode *adjacentNode = [AStarNode
            nodeAtPoint:ccp(currentX+x, currentY+y)];
          adjacentNode->parent = closestNode;
          
          // Skip over this node if its already been closed.
          if ([closedNodes containsObject:adjacentNode])
            continue;
   
          // Skip over collide nodes, and add them to the closed set.
          if ([self isCollision:adjacentNode->point]) {
            [closedNodes addObject:adjacentNode];
            continue;
          }

          // Calculate G
          // G cost is 10 for adjacent and 14 for a diagonal move.
          // We use these numbers because the distance to move diagonally
          // is the square root of 2, or 1.414 the cost of moving
          // horizontally or vertically.
          if (abs(x) == 1 && abs(y) == 1) {
            if (![self considerDiagonalMovement])
              continue;
            adjacentNode->G = 14;
          }
          else {
            adjacentNode->G = 10;
          }
          // Calculate H
          // Uses 'Mahhattan' method wich is just the number
          // of horizonal and vertical hops to the target.
          adjacentNode->H = abs(adjacentNode->point.x - dst.x) +
            abs(adjacentNode->point.y - dst.y);

          [openNodes addObject:adjacentNode];
        }
      }
    }
  }
  return nil;
}


- (void) highlightPathFrom:(CGPoint)src to:(CGPoint)dst 
{
  AStarNode *node = [self findPathFrom:src to:dst];
  if (node == nil)
    return;

  // TODO: allow people to chnage the color of the highlight path.
  CGImageRef pathImage = [self makePathTile];
  
  int tileWidthOffset = [tileMap tileSize].width / 2;
  int tileHeightOffset = [tileMap tileSize].height / 2;

  while(node != nil)
  {
    CGPoint p1 = [collideLayer
      positionAt:node->point];
    p1.x = p1.x + tileWidthOffset;
    p1.y = p1.y + tileHeightOffset;
    
    CCSprite *spr = [CCSprite spriteWithCGImage:pathImage key:@"T"];
    spr.position = p1;
    [self addChild:spr];
    node = node->parent;
  }
}


- (void) moveSprite:(CCSprite*)sprite 
         from:(CGPoint)src to:(CGPoint)dst atSpeed:(float)speed
{
  AStarNode *node = [self findPathFrom:src to:dst];
  if (node == nil)
    return;

  int tileWidthOffset = [tileMap tileSize].width / 2;
  int tileHeightOffset = [tileMap tileSize].height / 2;
  
  NSMutableArray *actionList = [NSMutableArray array];

  while(node != nil) 
  {
    CGPoint p1 = [collideLayer
      positionAt:node->point];
    p1.x = p1.x + tileWidthOffset;
    p1.y = p1.y + tileHeightOffset;
    
    CCAction *move = [CCMoveTo actionWithDuration: speed position: p1];
    [actionList addObject:move];
    node = node->parent;
  }
  
  NSArray* reversedArray = [[actionList reverseObjectEnumerator] allObjects];
  [sprite runAction:[CCSequence actionsWithArray:reversedArray]];
}


- (BOOL) isCollision:(CGPoint)point
{
  // Check for a tile in the collide layer.
  UInt32 tileGid = [collideLayer tileGIDAt:point];
  if (tileGid)
  {
    // If a tile exists, see if collide is enabled on the entire layer.
    NSDictionary *ldict = [collideLayer propertyNamed:collideKey];
    if (ldict)
      return YES;

    // If not, then check the tile for the collide property.
    NSDictionary *dict = [tileMap propertiesForGID:tileGid];
    if (dict)
    {
      NSString *collide = [dict valueForKey:collideKey];
      if (collide && [collide compare:collideValue] == NSOrderedSame)
        return YES;
    }
  }
  return NO;
}

- (AStarNode *) lowCostNode
{  
  AStarNode *lowCostNode = [openNodes anyObject];
  for (id setObject in openNodes)
  {
    if ([(AStarNode*)setObject cost] < [lowCostNode cost])
    {
      lowCostNode = (AStarNode*)setObject;
    }
  }
  return lowCostNode;
}

@end

@implementation AStarNode

+ (id) nodeAtPoint:(CGPoint)point;
{
  return [[[AStarNode alloc] initAtPoint:point] autorelease];
}

- (id) initAtPoint:(CGPoint)pnt
{
  point = pnt;
  x = pnt.x;
  y = pnt.y;
  return self;
}

- (void) dealloc {
  parent = nil;
  [super dealloc];
}

- (int) cost {
  return G + H;
}

- (NSUInteger) hash
{
  return (x << 16) | (y & 0xFFFF);
}

- (BOOL)isEqual:(id)otherObject
{
  if (![otherObject isKindOfClass:[self class]])
  {
    return NO;
  }
  
  AStarNode *otherNode = (AStarNode*) otherObject;
  if (point.x == otherNode->point.x && point.y == otherNode->point.y)
  {
    return YES;
  }
  
  return NO;
}

@end

