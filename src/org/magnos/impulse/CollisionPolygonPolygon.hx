/*
	Copyright (c) 2013 Randy Gaul http://RandyGaul.net

	This software is provided 'as-is', without any express or implied
	warranty. In no event will the authors be held liable for any damages
	arising from the use of this software.

	Permission is granted to anyone to use this software for any purpose,
	including commercial applications, and to alter it and redistribute it
	freely, subject to the following restrictions:
	  1. The origin of this software must not be misrepresented; you must not
		 claim that you wrote the original software. If you use this software
		 in a product, an acknowledgment in the product documentation would be
		 appreciated but is not required.
	  2. Altered source versions must be plainly marked as such, and must not be
		 misrepresented as being the original software.
	  3. This notice may not be removed or altered from any source distribution.

	Impulse Engine wrote by Randy Gaul https://www.randygaul.net
	Port to Java by Philip Diffenderfer http://magnos.org
	Port to Haxe and added pooling by Mansour Djawadi http://github.com/manjav
 */

package org.magnos.impulse;

class CollisionPolygonPolygon extends CollisionCallback {
	static public var instance:CollisionPolygonPolygon = new CollisionPolygonPolygon();

	override public function handleCollision(m:Manifold, a:Body, b:Body):Bool {
		if (!super.handleCollision(m, a, b))
			return false;
		var A = cast(a.shape, Polygon);
		var B = cast(b.shape, Polygon);
		m.contactCount = 0;

		// Check for a separating axis with A's face planes
		var faceA:Array<Int> = [0];
		var penetrationA:Float = findAxisLeastPenetration(faceA, A, B);
		if (penetrationA >= 0.0)
			return false;

		// Check for a separating axis with B's face planes
		var faceB:Array<Int> = [0];
		var penetrationB:Float = findAxisLeastPenetration(faceB, B, A);
		if (penetrationB >= 0.0)
			return false;

		var referenceIndex:Int;
		var flip:Bool; // Always pofrom:Int a to b

		var refPoly:Polygon; // Reference
		var incPoly:Polygon; // Incident

		// Determine which shape contains reference face
		if (ImpulseMath.gt(penetrationA, penetrationB)) {
			refPoly = A;
			incPoly = B;
			referenceIndex = faceA[0];
			flip = false;
		} else {
			refPoly = B;
			incPoly = A;
			referenceIndex = faceB[0];
			flip = true;
		}

		// World space incident face
		var incidentFace:Array<Vec2> = Vec2.arrayOf(2);

		findIncidentFace(incidentFace, refPoly, incPoly, referenceIndex);

		// y
		// ^ .n ^
		// +---c ------posPlane--
		// x < | i |\
		// +---+ c-----negPlane--
		// \ v
		// r
		//
		// r : reference face
		// i : incident poly
		// c : clipped point
		// n : incident normal

		// Setup reference face vertices
		var v1:Vec2 = refPoly.vertices[referenceIndex];
		referenceIndex = referenceIndex + 1 == refPoly.vertexCount ? 0 : referenceIndex + 1;
		var v2:Vec2 = refPoly.vertices[referenceIndex];

		// Transform vertices to world space
		// v1 = refPoly->u * v1 + refPoly->body->position;
		// v2 = refPoly->u * v2 + refPoly->body->position;
		v1 = refPoly.u.mul(v1).addi(refPoly.body.position);
		v2 = refPoly.u.mul(v2).addi(refPoly.body.position);

		// Calculate reference face side normal in world space
		// sidePlaneNormal:Vec = (v2 - v1);
		// sidePlaneNormal.Normalize( );
		var sidePlaneNormal:Vec2 = v2.sub(v1);
		sidePlaneNormal.normalize();

		// Orthogonalize
		// refFaceNormal:Vec( sidePlaneNormal.y, -sidePlaneNormal.x );
		var refFaceNormal:Vec2 = new Vec2(sidePlaneNormal.y, -sidePlaneNormal.x);

		// ax + by = c
		// c is distance from origin
		// real refC = Dot( refFaceNormal, v1 );
		// real negSide = -Dot( sidePlaneNormal, v1 );
		// real posSide = Dot( sidePlaneNormal, v2 );
		var refC:Float = Vec2.dotVV(refFaceNormal, v1);
		var negSide:Float = -Vec2.dotVV(sidePlaneNormal, v1);
		var posSide:Float = Vec2.dotVV(sidePlaneNormal, v2);

		// Clip incident face to reference face side planes
		// if(Clip( -sidePlaneNormal, negSide, incidentFace ) < 2)
		if (clip(sidePlaneNormal.neg(), negSide, incidentFace) < 2) {
			return false; // Due to Floating poerror:Int, possible to not have required
			// points
		}

		// if(Clip( sidePlaneNormal, posSide, incidentFace ) < 2)
		if (clip(sidePlaneNormal, posSide, incidentFace) < 2) {
			return false; // Due to Floating poerror:Int, possible to not have required
			// points
		}

		// Flip
		m.normal.set(refFaceNormal.x, refFaceNormal.y);
		if (flip)
			m.normal.negi();

		// Keep points behind reference face
		var cp:Int = 0; // clipped points behind reference face
		var separation:Float = Vec2.dotVV(refFaceNormal, incidentFace[0]) - refC;
		if (separation <= 0.0) {
			m.contacts[cp].set(incidentFace[0].x, incidentFace[0].y);
			m.penetration = -separation;
			++cp;
		} else {
			m.penetration = 0;
		}

		separation = Vec2.dotVV(refFaceNormal, incidentFace[1]) - refC;

		if (separation <= 0.0) {
			m.contacts[cp].set(incidentFace[1].x, incidentFace[1].y);

			m.penetration += -separation;
			++cp;

			// Average penetration
			m.penetration /= cp;
		}

		m.contactCount = cp;
		return true;
	}

	public function findAxisLeastPenetration(faceIndex:Array<Int>, A:Polygon, B:Polygon):Float {
		var bestDistance:Float = Math.NEGATIVE_INFINITY;
		var bestIndex:Int = 0;

		for (i in 0...A.vertexCount) {
			// Retrieve a face normal from A
			// n:Vec = A->m_normals[i];
			// nw:Vec = A->u * n;
			var nw:Vec2 = A.u.mul(A.normals[i], manifold.scene.vec_in());

			// Transform face normal into B's model space
			// buT:Mat2 = B->u.Transpose( );
			// n = buT * nw;
			var buT:Mat2 = B.u.transpose(manifold.scene.mat_in());
			var n:Vec2 = buT.mul(nw, manifold.scene.vec_in());

			// Retrieve support pofrom:Int B along -n
			// s:Vec = B->GetSupport( -n );
			var neg:Vec2 = n.neg(manifold.scene.vec_in());
			var s:Vec2 = B.getSupport(neg);
			// Retrieve vertex on face from A, transform into
			// B's model space
			// v:Vec = A->m_vertices[i];
			// v = A->u * v + A->body->position;
			// v -= B->body->position;
			// v = buT * v;
			var v:Vec2 = buT.muli(A.u.mul(A.vertices[i], manifold.scene.vec_in()).addi(A.body.position).subi(B.body.position));

			// Compute penetration distance (in B's model space)
			// real d = Dot( n, s - v );
			var b = s.sub(v, manifold.scene.vec_in());
			var d:Float = Vec2.dotVV(n, b);

			// Store greatest distance
			if (d > bestDistance) {
				bestDistance = d;
				bestIndex = i;
			}
			manifold.scene.vec_ds(nw);
			manifold.scene.vec_ds(n);
			manifold.scene.vec_ds(v);
			manifold.scene.vec_ds(b);
			manifold.scene.vec_ds(neg);
			manifold.scene.mat_ds(buT);
		}
		faceIndex[0] = bestIndex;
		return bestDistance;
	}

	public function findIncidentFace(v:Array<Vec2>, refPoly:Polygon, incPoly:Polygon, referenceIndex:Int) {
		var referenceNormal:Vec2 = refPoly.normals[referenceIndex];

		// Calculate normal in incident's frame of reference
		// referenceNormal = refPoly->u * referenceNormal; // To world space
		// referenceNormal = incPoly->u.Transpose( ) * referenceNormal; // To
		// incident's model space
		referenceNormal = refPoly.u.mul(referenceNormal); // To world space
		referenceNormal = incPoly.u.transpose().mul(referenceNormal); // To
		// incident's
		// model
		// space

		// Find most anti-normal face on incident polygon
		var incidentFace:Int = 0;
		var minDot:Float = Math.POSITIVE_INFINITY;
		for (i in 0...incPoly.vertexCount) {
			// real dot = Dot( referenceNormal, incPoly->m_normals[i] );
			var dot:Float = Vec2.dotVV(referenceNormal, incPoly.normals[i]);

			if (dot < minDot) {
				minDot = dot;
				incidentFace = i;
			}
		}

		// Assign face vertices for incidentFace
		// v[0] = incPoly->u * incPoly->m_vertices[incidentFace] +
		// incPoly->body->position;
		// incidentFace = incidentFace + 1 >= (int32)incPoly->m_vertexCount ? 0 :
		// incidentFace + 1;
		// v[1] = incPoly->u * incPoly->m_vertices[incidentFace] +
		// incPoly->body->position;

		v[0] = incPoly.u.mul(incPoly.vertices[incidentFace]).addi(incPoly.body.position);
		incidentFace = incidentFace + 1 >= incPoly.vertexCount ? 0 : incidentFace + 1;
		v[1] = incPoly.u.mul(incPoly.vertices[incidentFace]).addi(incPoly.body.position);
	}

	public function clip(n:Vec2, c:Float, face:Array<Vec2>):Int {
		var sp:Int = 0;
		var out:Array<Vec2> = [new Vec2(face[0].x, face[0].y), new Vec2(face[1].x, face[1].y)];

		// Retrieve distances from each endpoto:Int the line
		// d = ax + by - c
		// real d1 = Dot( n, face[0] ) - c;
		// real d2 = Dot( n, face[1] ) - c;
		var d1:Float = Vec2.dotVV(n, face[0]) - c;
		var d2:Float = Vec2.dotVV(n, face[1]) - c;

		// If negative (behind plane) clip
		// if(d1 <= 0.0f) out[sp++] = face[0];
		// if(d2 <= 0.0f) out[sp++] = face[1];
		if (d1 <= 0.0)
			out[sp++].set(face[0].x, face[0].y);
		if (d2 <= 0.0)
			out[sp++].set(face[1].x, face[1].y);

		// If the points are on different sides of the plane
		if (d1 * d2 < 0.0) // less than to ignore -0.0
		{
			// Push intersection point
			// real alpha = d1 / (d1 - d2);
			// out[sp] = face[0] + alpha * (face[1] - face[0]);
			// ++sp;

			var alpha:Float = d1 / (d1 - d2);

			out[sp++].set(face[1].x, face[1].y).subi(face[0]).muliF(alpha).addi(face[0]);
		}

		// Assign our new converted values
		face[0] = out[0];
		face[1] = out[1];

		// assert( sp != 3 );

		return sp;
	}
}
