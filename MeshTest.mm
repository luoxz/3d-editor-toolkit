//
//  MeshTest.mm
//  OpenGLEditor
//
//  Created by Filip Kunc on 7/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MeshTest.h"


@implementation MeshTest

- (void)testMesh
{
	mesh = [[Mesh alloc] init];
	
	STAssertNotNil(mesh, @"mesh can't be nil");
	
	Vector3D expected = Vector3D(1, 2, 3);
	[mesh addVertex:expected];
	Vector3D actual = [mesh vertexAtIndex:0];
	
	STAssertTrue(actual == expected, @"addVertex or vertexAtIndex not working properly");
	
	[mesh release];
}

- (void)testMakeEdges
{
	mesh = [[Mesh alloc] init];
	
	STAssertNotNil(mesh, @"mesh can't be nil");
	
	[mesh makeCube];

	STAssertEquals([mesh vertexCount], 8UL, @"vertexCount in cube must be equal to 8");
	STAssertEquals([mesh triangleCount], 12UL, @"triangleCount in cube must be equal to 12");
	
	[mesh makeEdges];
	
	STAssertEquals([mesh edgeCount], 18UL, @"edgeCount in cube must be equal to 18");
	
	[mesh release];
}

- (void)testTurnEdges
{
	mesh = [[Mesh alloc] init];
	
	STAssertNotNil(mesh, @"mesh can't be nil");
	
	[mesh makeCube];
	
	[mesh makeEdges];
	
	for (int i = 0; i < [mesh edgeCount]; i++)
	{
		[mesh turnEdgeAtIndex:i];
		
		STAssertEquals([mesh vertexCount], 8UL, @"vertexCount in cube must be equal to 8");
		STAssertEquals([mesh triangleCount], 12UL, @"triangleCount in cube must be equal to 12");
		STAssertEquals([mesh edgeCount], 18UL, @"edgeCount in cube must be equal to 18");
	}
	
	[mesh release];
}

- (void)testArchivation
{
	mesh = [[Mesh alloc] init];
	
	STAssertNotNil(mesh, @"mesh can't be nil");
	
	[mesh makeCube];
	
	NSData *data = [[NSKeyedArchiver archivedDataWithRootObject:mesh] retain];
	
	Mesh *mesh2 = (Mesh *)[NSKeyedUnarchiver unarchiveObjectWithData:data];
	[mesh2 retain];
	[mesh2 makeEdges];
	
	STAssertEquals([mesh2 vertexCount], 8UL, @"vertexCount in cube must be equal to 8");
	STAssertEquals([mesh2 triangleCount], 12UL, @"triangleCount in cube must be equal to 12");
	STAssertEquals([mesh2 edgeCount], 18UL, @"edgeCount in cube must be equal to 18");
	
	[data release];
	[mesh release];
	[mesh2 release];
}

@end
