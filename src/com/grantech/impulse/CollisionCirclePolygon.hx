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

package com.grantech.impulse;

class CollisionCirclePolygon extends CollisionCallback {
	static public var instance:CollisionCirclePolygon = new CollisionCirclePolygon();

	override public function handleCollision(m:Manifold, a:Body, b:Body):Bool {
		if (!super.handleCollision(m, a, b))
			return false;
		var A = cast(a.shape, Circle);
		var B = cast(b.shape, Polygon);

		m.contactCount = 0;

		// Transform circle center to Polygon model space
		// center:Vec = a->position;
		// center = B->u.Transpose( ) * (center - b->position);
		var trans = B.u.transpose(m.scene.mat_in());
		var center:Vec2 = trans.muli(a.position.sub(b.position, m.scene.vec_in()));
		m.scene.mat_ds(trans);

		// Find edge with minimum penetration
		// Exact concept as using support points in Polygon vs Polygon
		var separation:Float = Math.NEGATIVE_INFINITY;
		var faceNormal:Int = 0;
		for (i in 0...B.vertexCount) {
			// real s = Dot( B->m_normals[i], center - B->m_vertices[i] );

			var csb = center.sub(B.vertices[i], m.scene.vec_in());
			var s:Float = Vec2.dotVV(B.normals[i], csb);
			m.scene.vec_ds(csb);

			if (s > A.radius)
				return false;

			if (s > separation) {
				separation = s;
				faceNormal = i;
			}
		}

		// Grab face's vertices
		var v1:Vec2 = B.vertices[faceNormal];
		var i2:Int = faceNormal + 1 < B.vertexCount ? faceNormal + 1 : 0;
		var v2:Vec2 = B.vertices[i2];

		// Check to see if center is within polygon
		if (separation < ImpulseMath.EPSILON) {
			// m->contact_count = 1;
			// m->normal = -(B->u * B->m_normals[faceNormal]);
			// m->contacts[0] = m->normal * A->radius + a->position;
			// m->penetration = A->radius;

			m.contactCount = 1;
			B.u.mul(B.normals[faceNormal], m.normal).negi();
			m.contacts[0].set(m.normal.x, m.normal.y).muliF(A.radius).addi(a.position);
			m.penetration = A.radius;
			return false;
		}

		// Determine which voronoi region of the edge center of circle lies within
		// real dot1 = Dot( center - v1, v2 - v1 );
		// real dot2 = Dot( center - v2, v1 - v2 );
		// m->penetration = A->radius - separation;

		var csv1 = center.sub(v1, m.scene.vec_in());
		var csv2 = center.sub(v2, m.scene.vec_in());
		var v2sv1 = v2.sub(v1, m.scene.vec_in());
		var v1sv2 = v1.sub(v2, m.scene.vec_in());
		var dot1:Float = Vec2.dotVV(csv1, v2sv1);
		var dot2:Float = Vec2.dotVV(csv2, v1sv2);
		m.scene.vec_ds(csv1);
		m.scene.vec_ds(csv2);
		m.scene.vec_ds(v2sv1);
		m.scene.vec_ds(v1sv2);

		m.penetration = A.radius - separation;

		// Closest to v1
		if (dot1 <= 0.0) {
			if (Vec2.distanceSqVV(center, v1) > A.radius * A.radius)
				return false;

			// m->contact_count = 1;
			// n:Vec = v1 - center;
			// n = B->u * n;
			// n.Normalize( );
			// m->normal = n;
			// v1 = B->u * v1 + b->position;
			// m->contacts[0] = v1;

			m.contactCount = 1;
			B.u.muli(m.normal.set(v1.x, v1.y).subi(center)).normalize();
			B.u.mul(v1, m.contacts[0]).addi(b.position);
		}

		// Closest to v2
		else if (dot2 <= 0.0) {
			if (Vec2.distanceSqVV(center, v2) > A.radius * A.radius)
				return false;

			// m->contact_count = 1;
			// n:Vec = v2 - center;
			// v2 = B->u * v2 + b->position;
			// m->contacts[0] = v2;
			// n = B->u * n;
			// n.Normalize( );
			// m->normal = n;

			m.contactCount = 1;
			B.u.muli(m.normal.set(v2.x, v2.y).subi(center)).normalize();
			B.u.mul(v2, m.contacts[0]).addi(b.position);
		}

		// Closest to face
		else {
			var n:Vec2 = B.normals[faceNormal];

			var csv1 = center.sub(v1, m.scene.vec_in());
			var dotcsv1 = Vec2.dotVV(csv1, n);
			m.scene.vec_ds(csv1);
			if (dotcsv1 > A.radius)
				return false;

			// n = B->u * n;
			// m->normal = -n;
			// m->contacts[0] = m->normal * A->radius + a->position;
			// m->contact_count = 1;

			m.contactCount = 1;
			B.u.mul(n, m.normal).negi();
			m.contacts[0].set(a.position.x, a.position.y).addsi(m.normal, A.radius);
		}
		m.scene.vec_ds(center);
		return true;
	}
}
