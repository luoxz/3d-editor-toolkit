//
//  Mesh.m
//  OpenGLEditor
//
//  Created by Filip Kunc on 7/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "Mesh.h"

BOOL IsTriangleDegenerated(Triangle triangle)
{
	if (triangle.vertexIndices[0] == triangle.vertexIndices[1])
		return YES;
	if (triangle.vertexIndices[0] == triangle.vertexIndices[2])
		return YES;
	if (triangle.vertexIndices[1] == triangle.vertexIndices[2])
		return YES;

	return NO;
}

BOOL AreEdgesSame(Edge a, Edge b)
{
	if (a.vertexIndices[0] == b.vertexIndices[0] &&
		a.vertexIndices[1] == b.vertexIndices[1])
		return YES;
	
	if (a.vertexIndices[0] == b.vertexIndices[1] &&
		b.vertexIndices[1] == b.vertexIndices[0])
		return YES;
	
	return NO;
}

BOOL IsIndexInTriangle(Triangle triangle, NSUInteger index)
{
	for (NSUInteger i = 0; i < 3; i++)
	{
		if (triangle.vertexIndices[i] == index)
			return YES;
	}
	return NO;
}

BOOL IsEdgeInTriangle(Triangle triangle, Edge edge)
{
	if (IsIndexInTriangle(triangle, edge.vertexIndices[0]) &&
		IsIndexInTriangle(triangle, edge.vertexIndices[1]))
	{
		return YES;
	}
	return NO;
}

NSUInteger NonEdgeIndexInTriangle(Triangle triangle, Edge edge)
{
	for (NSUInteger i = 0; i < 3; i++)
	{
		if (triangle.vertexIndices[i] != edge.vertexIndices[0] &&
			triangle.vertexIndices[i] != edge.vertexIndices[1])
		{
			return triangle.vertexIndices[i];
		}
	}
	return 0;
}

@implementation Mesh

@synthesize selectionMode;

- (NSUInteger)vertexCount
{
	return vertices->size();
}

- (NSUInteger)triangleCount
{
	return triangles->size();
}

- (NSUInteger)edgeCount
{
	return edges->size();
}

- (id)init
{
	self = [super init];
	if (self)
	{
		vertices = new vector<Vector3D>();
		triangles = new vector<Triangle>();
		edges = new vector<Edge>();
		selectedIndices = new vector<BOOL>();
	}
	return self;
}

- (void)dealloc
{
	delete vertices;
	delete triangles;
	delete edges;
	delete selectedIndices;
	[super dealloc];
}

- (void)setSelectionMode:(enum MeshSelectionMode)value
{
	selectionMode = value;
	selectedIndices->clear();
	switch (selectionMode) 
	{
		case MeshSelectionModeVertices:
		{
			for (NSUInteger i = 0; i < vertices->size(); i++)
			{
				selectedIndices->push_back(NO);
			}
		} break;
		case MeshSelectionModeTriangles:
		{
			for (NSUInteger i = 0; i < triangles->size(); i++)
			{
				selectedIndices->push_back(NO);
			}
		} break;
		case MeshSelectionModeEdges:
		{
			[self makeEdges];
			for (NSUInteger i = 0; i < edges->size(); i++)
			{
				selectedIndices->push_back(NO);
			}
		} break;
	}
}

- (Vector3D)vertexAtIndex:(NSUInteger)anIndex
{
	return vertices->at(anIndex);
}

- (Triangle)triangleAtIndex:(NSUInteger)anIndex
{
	return triangles->at(anIndex);
}

- (Edge)edgeAtIndex:(NSUInteger)anIndex
{
	return edges->at(anIndex);
}

- (void)addVertex:(Vector3D)aVertex
{
	vertices->push_back(aVertex);
	if (selectionMode == MeshSelectionModeVertices)
		selectedIndices->push_back(NO);
}

- (void)addTriangleWithIndex1:(NSUInteger)index1
					   index2:(NSUInteger)index2
					   index3:(NSUInteger)index3
{
	Triangle triangle;
	triangle.vertexIndices[0] = index1;
	triangle.vertexIndices[1] = index2;
	triangle.vertexIndices[2] = index3;
	triangles->push_back(triangle);
	if (selectionMode == MeshSelectionModeTriangles)
		selectedIndices->push_back(NO);
}

- (void)addQuadWithIndex1:(NSUInteger)index1
				   index2:(NSUInteger)index2
				   index3:(NSUInteger)index3 
				   index4:(NSUInteger)index4
{
	Triangle triangle1, triangle2;
	triangle1.vertexIndices[0] = index1;
	triangle1.vertexIndices[1] = index2;
	triangle1.vertexIndices[2] = index3;
	
	triangle2.vertexIndices[0] = index1;
	triangle2.vertexIndices[1] = index3;
	triangle2.vertexIndices[2] = index4;
	
	triangles->push_back(triangle1);
	triangles->push_back(triangle2);
	
	if (selectionMode == MeshSelectionModeTriangles)
	{
		selectedIndices->push_back(NO);
		selectedIndices->push_back(NO);
	}
}

- (void)addEdgeWithIndex1:(NSUInteger)index1
				   index2:(NSUInteger)index2
{
	Edge edge;
	edge.vertexIndices[0] = index1;
	edge.vertexIndices[1] = index2;
	edges->push_back(edge);
	
	if (selectionMode == MeshSelectionModeEdges)
		selectedIndices->push_back(NO);
}

- (void)drawFillWithScale:(Vector3D)scale
{	
	float normalDiffuse[] = { 0.5, 0.7, 1.0, 1 };
	float selectedDiffuse[] = { 1, 0, 0, 1 };
	
	glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, normalDiffuse);
	
	Vector3D triangleVertices[3];
	
	float *lastDiffuse = normalDiffuse; 
	
	glBegin(GL_TRIANGLES);
	
	for (NSUInteger i = 0; i < triangles->size(); i++)
	{
		if (selectionMode == MeshSelectionModeTriangles) 
		{
			if (selectedIndices->at(i))
			{
				if (lastDiffuse == normalDiffuse)
				{
					glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, selectedDiffuse);
					lastDiffuse = selectedDiffuse;
				}
			}
			else if (lastDiffuse == selectedDiffuse)
			{
				glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, normalDiffuse);
				lastDiffuse = normalDiffuse;
			}
		}
		Triangle currentTriangle = [self triangleAtIndex:i];
		for (NSUInteger j = 0; j < 3; j++)
		{
			Vector3D currentVertex = [self vertexAtIndex:currentTriangle.vertexIndices[j]];
			triangleVertices[j] = currentVertex;
		}
		Vector3D u = triangleVertices[1] - triangleVertices[0];
		Vector3D v = triangleVertices[2] - triangleVertices[0];
		Vector3D n = v.Cross(u);
		n.Normalize();
		n.x *= scale.x;
		n.y *= scale.y;
		n.z *= scale.z;		
		for (NSUInteger j = 0; j < 3; j++)
		{
			glNormal3f(n.x, n.y, n.z);
			glVertex3f(triangleVertices[j].x, triangleVertices[j].y, triangleVertices[j].z);			
		}
	}
	
	glEnd();
}

- (void)drawWireWithScale:(Vector3D)scale
{
	glDisable(GL_LIGHTING);
	glColor3f(1, 1, 1);
	if (selectionMode != MeshSelectionModeEdges)
	{
		glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		[self drawFillWithScale:scale];
		glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
	}
	glEnable(GL_LIGHTING);
}

- (void)drawWithScale:(Vector3D)scale selected:(BOOL)selected
{	
	if (selected)
	{
		glEnable(GL_POLYGON_OFFSET_FILL);
		glPolygonOffset(1.0f, 1.0f);
		[self drawFillWithScale:scale];
		glDisable(GL_POLYGON_OFFSET_FILL);
		[self drawWireWithScale:scale];
	}
	else
	{
		[self drawFillWithScale:scale];
	}
}

- (void)makeCube
{
	NSLog(@"makeCube");
	
	vertices->clear();
	triangles->clear();
	selectedIndices->clear();
	
	// back vertices
	vertices->push_back(Vector3D(-1, -1, -1)); // 0
	vertices->push_back(Vector3D( 1, -1, -1)); // 1
	vertices->push_back(Vector3D( 1,  1, -1)); // 2
	vertices->push_back(Vector3D(-1,  1, -1)); // 3
	
	// front vertices
	vertices->push_back(Vector3D(-1, -1,  1)); // 4
	vertices->push_back(Vector3D( 1, -1,  1)); // 5
	vertices->push_back(Vector3D( 1,  1,  1)); // 6
	vertices->push_back(Vector3D(-1,  1,  1)); // 7
	
	// back triangles
	[self addQuadWithIndex1:0 index2:1 index3:2 index4:3];
	
	// front triangles
	[self addQuadWithIndex1:7 index2:6 index3:5 index4:4];
	
	// bottom triangles
	[self addQuadWithIndex1:1 index2:0 index3:4 index4:5];
	
	// top triangles
	[self addQuadWithIndex1:3 index2:2 index3:6 index4:7];
	
	// left triangles
	[self addQuadWithIndex1:7 index2:4 index3:0 index4:3];
	
	// right triangles
	[self addQuadWithIndex1:2 index2:1 index3:5 index4:6];
	
	[self setSelectionMode:[self selectionMode]];
}

- (void)makeCylinderWithSteps:(NSUInteger)steps
{
	NSLog(@"makeCylinderWithSteps:%i", steps);
	
	vertices->clear();
	triangles->clear();
	selectedIndices->clear();
	
	vertices->push_back(Vector3D(0, -1, 0)); // 0
 	vertices->push_back(Vector3D(0,  1, 0)); // 1
	
	vertices->push_back(Vector3D(cosf(0.0f), -1, sinf(0.0f))); // 2
	vertices->push_back(Vector3D(cosf(0.0f),  1, sinf(0.0f))); // 3
		
	NSUInteger max = steps;
	float step = (FLOAT_PI * 2.0f) / max;
	float angle = step;
	for (NSUInteger i = 1; i < max; i++)
	{
		vertices->push_back(Vector3D(cosf(angle), -1, sinf(angle))); // 4
		vertices->push_back(Vector3D(cosf(angle),  1, sinf(angle))); // 5
		
		Triangle triangle1, triangle2;
		triangle1.vertexIndices[0] = vertices->size() - 3;
		triangle1.vertexIndices[1] = vertices->size() - 2;
		triangle1.vertexIndices[2] = vertices->size() - 1;
	
		triangle2.vertexIndices[0] = vertices->size() - 2;
		triangle2.vertexIndices[1] = vertices->size() - 3;
		triangle2.vertexIndices[2] = vertices->size() - 4;
		
		triangles->push_back(triangle1);
		triangles->push_back(triangle2);
		
		Triangle triangle3, triangle4;
		triangle3.vertexIndices[0] = vertices->size() - 4;
		triangle3.vertexIndices[1] = 0;
		triangle3.vertexIndices[2] = vertices->size() - 2;
		
		triangle4.vertexIndices[0] = vertices->size() - 3;
		triangle4.vertexIndices[1] = vertices->size() - 1;
		triangle4.vertexIndices[2] = 1;
		
		triangles->push_back(triangle3);
		triangles->push_back(triangle4);
		
		angle += step;
	}
	
	Triangle triangle1, triangle2;
	triangle1.vertexIndices[0] = 2;
	triangle1.vertexIndices[1] = 3;
	triangle1.vertexIndices[2] = vertices->size() - 1;
	
	triangle2.vertexIndices[0] = vertices->size() - 1;
	triangle2.vertexIndices[1] = vertices->size() - 2;
	triangle2.vertexIndices[2] = 2;
	
	triangles->push_back(triangle1);
	triangles->push_back(triangle2);
	
	Triangle triangle3, triangle4;
	triangle3.vertexIndices[0] = 0;
	triangle3.vertexIndices[1] = 2;
	triangle3.vertexIndices[2] = vertices->size() - 2;
	
	triangle4.vertexIndices[0] = 3;
	triangle4.vertexIndices[1] = 1;
	triangle4.vertexIndices[2] = vertices->size() - 1;
	
	triangles->push_back(triangle3);
	triangles->push_back(triangle4);
	
	[self setSelectionMode:[self selectionMode]];
}

- (void)makeEdges
{
	edges->clear();
	for (NSUInteger i = 0; i < triangles->size(); i++)
	{
		Triangle triangle = triangles->at(i);
		Edge edge1, edge2, edge3;
		
		edge1.vertexIndices[0] = triangle.vertexIndices[0];
		edge1.vertexIndices[1] = triangle.vertexIndices[1];
		
		edge2.vertexIndices[0] = triangle.vertexIndices[1];
		edge2.vertexIndices[1] = triangle.vertexIndices[2];
		
		edge3.vertexIndices[0] = triangle.vertexIndices[0];
		edge3.vertexIndices[1] = triangle.vertexIndices[2];
		
		BOOL addEdge1 = YES;
		BOOL addEdge2 = YES;
		BOOL addEdge3 = YES;
		
		for (NSUInteger j = 0; j < edges->size(); j++)
		{
			Edge edge = edges->at(j);
			if (AreEdgesSame(edge1, edge))
			{
				addEdge1 = NO;
			}
			if (AreEdgesSame(edge2, edge))
			{
				addEdge2 = NO;
			}
			if 	(AreEdgesSame(edge3, edge))
			{
				addEdge3 = NO;
			}
			//if (addEdge1 == addEdge2 == addEdge3 == NO)
//				break;
		}
		
		if (addEdge1)
			edges->push_back(edge1);
		if (addEdge2)
			edges->push_back(edge2);
		if (addEdge3)
			edges->push_back(edge3);
	}
}

- (void)removeVertexAtIndex:(NSUInteger)index
{
	for (NSUInteger i = 0; i < triangles->size(); i++)
	{
		for (NSUInteger j = 0; j < 3; j++)
		{
			if (triangles->at(i).vertexIndices[j] >= index)
				triangles->at(i).vertexIndices[j]--;
		}
	}
	vertices->erase(vertices->begin() + index);
	if (selectionMode == MeshSelectionModeVertices)
		selectedIndices->erase(selectedIndices->begin() + index);
}

- (void)removeTriangleAtIndex:(NSUInteger)index
{
	triangles->erase(triangles->begin() + index);
	if (selectionMode == MeshSelectionModeTriangles)
		selectedIndices->erase(selectedIndices->begin() + index);
}

- (void)removeEdgeAtIndex:(NSUInteger)index
{
	edges->erase(edges->begin() + index);
	if (selectionMode == MeshSelectionModeEdges)
		selectedIndices->erase(selectedIndices->begin() + index);
}

- (void)removeDegeneratedTriangles
{
	NSLog(@"removeDegeneratedTriangles");
	
	for (int i = 0; i < triangles->size(); i++)
	{
		if (IsTriangleDegenerated(triangles->at(i)))
		{
			[self removeTriangleAtIndex:i];
			i--;
		}
	}	
}

- (BOOL)isVertexUsedAtIndex:(NSUInteger)index
{
	for (NSUInteger i = 0; i < triangles->size(); i++)
	{
		Triangle triangle = triangles->at(i);
		for (NSUInteger j = 0; j < 3; j++)
		{
			if (triangle.vertexIndices[j] == index)
				return YES;
		}
	}
	return NO;
}

- (void)removeNonUsedVertices
{
	NSLog(@"removeNonUsedVertices");
	
	for (int i = 0; i < vertices->size(); i++)
	{
		if (![self isVertexUsedAtIndex:i])
		{
			[self removeVertexAtIndex:i];
			i--;
		}
	}
}

- (void)removeSelectedVertices
{
	NSLog(@"removeSelectedVertices");
	
	NSAssert(vertices->size() == selectedIndices->size(), @"vertices->size() == selectedIndices->size()");
	
	for (int i = 0; i < selectedIndices->size(); i++)
	{
		if (selectedIndices->at(i))
		{
			[self removeVertexAtIndex:i];
			i--;
		}
	}
}

- (void)fastCollapseSelectedVertices
{
	NSLog(@"fastCollapseSelectedVertices");
	NSAssert(vertices->size() == selectedIndices->size(), @"vertices->size() == selectedIndices->size()");
	
	NSUInteger selectedCount = 0;
	Vector3D center = Vector3D();
	
	for (NSUInteger i = 0; i < selectedIndices->size(); i++)
	{
		if (selectedIndices->at(i))
		{
			selectedCount++;
			center += vertices->at(i);
		}
	}
	
	NSLog(@"selectedCount = %i", selectedCount);
	
	if (selectedCount < 2)
		return;
	
	center /= selectedCount;
	vertices->push_back(center);
	selectedIndices->push_back(NO);
	
	NSUInteger centerIndex = vertices->size() - 1;
	
	for (NSUInteger i = 0; i < selectedIndices->size(); i++)
	{
		if (selectedIndices->at(i))
		{
			for (NSUInteger j = 0; j < triangles->size(); j++)
			{
				for (NSUInteger k = 0; k < 3; k++)
				{
					if (triangles->at(j).vertexIndices[k] == i)
						triangles->at(j).vertexIndices[k] = centerIndex;
				}				
			}
		}
	}
	
	[self removeSelectedVertices];
}

- (void)collapseSelectedVertices
{
	NSLog(@"collapseSelectedVertices");
	
	[self fastCollapseSelectedVertices];
	
	[self removeDegeneratedTriangles];
	[self removeNonUsedVertices];
	
	NSAssert(vertices->size() == selectedIndices->size(), @"vertices->size() == selectedIndices->size()");
}

- (void)transformWithMatrix:(Matrix4x4)matrix
{
	for (NSUInteger i = 0; i < vertices->size(); i++)
		vertices->at(i).Transform(matrix);
}

- (void)mergeWithMesh:(Mesh *)mesh
{
	NSLog(@"mergeWithMesh:");
	
	NSUInteger vertexCount = vertices->size();
	for (NSUInteger i = 0; i < mesh->vertices->size(); i++)
	{
		vertices->push_back(mesh->vertices->at(i));
	}
	for (NSUInteger i = 0; i < mesh->triangles->size(); i++)
	{
		Triangle triangle = mesh->triangles->at(i);
		triangle.vertexIndices[0] += vertexCount;
		triangle.vertexIndices[1] += vertexCount;
		triangle.vertexIndices[2] += vertexCount;
		triangles->push_back(triangle);
	}
	selectedIndices->clear();
	for (NSUInteger i = 0; i < vertices->size(); i++)
		selectedIndices->push_back(NO);
}

- (void)splitEdgeAtIndex:(NSUInteger)index
{
	NSLog(@"splitEdgeAtIndex:%i", index);
	
	Edge edge = [self edgeAtIndex:index];
	[self removeEdgeAtIndex:index];
	Vector3D firstVertex = [self vertexAtIndex:edge.vertexIndices[0]];
	Vector3D secondVertex = [self vertexAtIndex:edge.vertexIndices[1]];
	Vector3D centerVertex = firstVertex + secondVertex;
	centerVertex /= 2.0f;
	vertices->push_back(centerVertex);
	NSUInteger centerIndex = vertices->size() - 1;
		
	BOOL first = YES;
	
	for (int i = 0; i < triangles->size(); i++)
	{
		Triangle triangle = [self triangleAtIndex:i];
		if (IsEdgeInTriangle(triangle, edge))
		{
			NSUInteger oppositeIndex = NonEdgeIndexInTriangle(triangle, edge);
			
			[self removeTriangleAtIndex:i];
			i--;
			
			[self addEdgeWithIndex1:centerIndex index2:oppositeIndex];
			
			if (first)
			{
				first = NO;
				[self addTriangleWithIndex1:edge.vertexIndices[0] index2:oppositeIndex index3:centerIndex];
				[self addTriangleWithIndex1:edge.vertexIndices[1] index2:centerIndex index3:oppositeIndex];
			}
			else
			{
				[self addTriangleWithIndex1:edge.vertexIndices[1] index2:oppositeIndex index3:centerIndex];
				[self addTriangleWithIndex1:edge.vertexIndices[0] index2:centerIndex index3:oppositeIndex];
			}
		}
	}
	
	[self addEdgeWithIndex1:centerIndex index2:edge.vertexIndices[1]];
	[self addEdgeWithIndex1:centerIndex index2:edge.vertexIndices[0]];
}

- (void)splitSelectedEdges
{
	NSLog(@"splitSelectedEdges");
	
	for (int i = 0; i < selectedIndices->size(); i++)
	{
		if ([self isSelectedAtIndex:i])
		{
			[self splitEdgeAtIndex:i];
			i--;
		}
	}
}

#pragma mark OpenGLManipulatingModel implementation

- (NSUInteger)count
{
	return selectedIndices->size();	
}

- (Vector3D)positionAtIndex:(NSUInteger)index
{
	if (selectionMode == MeshSelectionModeVertices)
		return vertices->at(index);
	return Vector3D();
}

- (Quaternion)rotationAtIndex:(NSUInteger)index
{
	return Quaternion();
}

- (Vector3D)scaleAtIndex:(NSUInteger)index
{
	return Vector3D(1, 1, 1);
}

- (void)setPosition:(Vector3D)position atIndex:(NSUInteger)index
{
	if (selectionMode == MeshSelectionModeVertices)
		vertices->at(index) = position;
}

- (void)setRotation:(Quaternion)rotation atIndex:(NSUInteger)index {}
- (void)setScale:(Vector3D)scale atIndex:(NSUInteger)index {}

- (void)moveByOffset:(Vector3D)offset atIndex:(NSUInteger)index
{
	if (selectionMode == MeshSelectionModeVertices)
		vertices->at(index) += offset;
}

- (void)rotateByOffset:(Quaternion)offset atIndex:(NSUInteger)index {}
- (void)scaleByOffset:(Vector3D)offset atIndex:(NSUInteger)index {}

- (BOOL)isSelectedAtIndex:(NSUInteger)index
{
	return selectedIndices->at(index);
}

- (void)setSelected:(BOOL)selected atIndex:(NSUInteger)index 
{
	selectedIndices->at(index) = selected;
}

- (void)drawAtIndex:(NSUInteger)index forSelection:(BOOL)forSelection
{
	switch (selectionMode) 
	{
		case MeshSelectionModeVertices:
		{
			Vector3D v = [self vertexAtIndex:index];
			if (!forSelection)
			{
				BOOL selected = [self isSelectedAtIndex:index];
				glPointSize(5.0f);
				if (selected)
					glColor3f(1, 0, 0);
				else
					glColor3f(0, 0, 1);
				glDisable(GL_LIGHTING);
			}
			glBegin(GL_POINTS);
			glVertex3f(v.x, v.y, v.z);
			glEnd();
		} break;
		case MeshSelectionModeTriangles:
		{
			if (forSelection)
			{
				Triangle currentTriangle = [self triangleAtIndex:index];
				glBegin(GL_TRIANGLES);
				for (NSUInteger i = 0; i < 3; i++)
				{
					Vector3D v = [self vertexAtIndex:currentTriangle.vertexIndices[i]];
					glVertex3f(v.x, v.y, v.z);
				}
				glEnd();
			}
		} break;
		case MeshSelectionModeEdges:
		{
			Edge currentEdge = [self edgeAtIndex:index];
			if (!forSelection)
			{
				BOOL selected = [self isSelectedAtIndex:index];
				if (selected)
					glColor3f(1, 0, 0);
				else
					glColor3f(1, 1, 1);
				glDisable(GL_LIGHTING);
			}
			glBegin(GL_LINES);
			for (NSUInteger i = 0; i < 2; i++)
			{
				Vector3D v = [self vertexAtIndex:currentEdge.vertexIndices[i]];
				glVertex3f(v.x, v.y, v.z);
			}
			glEnd();
		} break;
	}
}

- (void)cloneAtIndex:(NSUInteger)index {}

- (void)removeAtIndex:(NSUInteger)index
{
	if (selectionMode == MeshSelectionModeTriangles)
	{
		[self removeTriangleAtIndex:index];
		[self removeNonUsedVertices];
	}
}

@end
