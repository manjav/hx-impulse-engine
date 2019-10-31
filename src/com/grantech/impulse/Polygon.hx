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

class Polygon extends Shape {
	static public var MAX_POLY_VERTEX_COUNT:Int = 64;

	public var vertexCount:Int;
	public var vertices:Array<Vec2> = Vec2.arrayOf(MAX_POLY_VERTEX_COUNT);
	public var normals:Array<Vec2> = Vec2.arrayOf(MAX_POLY_VERTEX_COUNT);

	public function new(verts:Array<Vec2> = null) {
		super();
		if (verts != null)
			set(verts);
	}

	override public function clone() {
		//		PolygonShape *poly = new PolygonShape( );
		//	    poly->u = u;
		//	    for(uint32 i = 0; i < m_vertexCount; ++i)
		//	    {
		//	      poly->m_vertices[i] = m_vertices[i];
		//	      poly->m_normals[i] = m_normals[i];
		//	    }
		//	    poly->m_vertexCount = m_vertexCount;
		//	    return poly;

		var p = new Polygon();
		p.u.setM(u);
		for (i in 0...vertexCount) {
			p.vertices[i].set(vertices[i].x, vertices[i].y);
			p.normals[i].set(normals[i].x, normals[i].y);
		}
		p.vertexCount = vertexCount;

		return p;
	}

	override public function initialize():Void {
		computeMass(1.0);
	}

	/* 	public function draw()
		{
			this.graphics.lineStyle(1);
			this.graphics.moveTo(0,0);
			for(i in 0...vertices.length)
				this.graphics.lineTo(vertices[i].x, vertices[i].y);
	}*/
	override public function computeMass(density:Float):Void {
		// Calculate centroid and moment of inertia
		var c = new Vec2(0.0, 0.0); // centroid
		var area = 0.0;
		var I = 0.0;
		var k_inv3 = 1.0 / 3.0;

		for (i in 0...vertexCount) {
			// Triangle vertices, third vertex implied as (0, 0)
			var p1 = vertices[i];
			var p2 = vertices[(i + 1) % vertexCount];

			var D = Vec2.crossVV(p1, p2);
			var triangleArea = 0.5 * D;

			area += triangleArea;

			// Use area to weight the centroid average, not just vertex position
			var weight:Float = triangleArea * k_inv3;
			c.addsi(p1, weight);
			c.addsi(p2, weight);

			var intx2 = p1.x * p1.x + p2.x * p1.x + p2.x * p2.x;
			var inty2 = p1.y * p1.y + p2.y * p1.y + p2.y * p2.y;
			I += (0.25 * k_inv3 * D) * (intx2 + inty2);
		}

		c.muliF(1.0 / area);

		// Translate vertices to centroid (make the centroid (0, 0)
		// for the polygon in model space)
		// Not really necessary, but I like doing this anyway
		for (i in 0...vertexCount)
			vertices[i].subi(c);

		body.mass = density * area;
		body.invMass = (body.mass != 0.0) ? 1.0 / body.mass : 0.0;
		body.inertia = I * density;
		body.invInertia = (body.inertia != 0.0) ? 1.0 / body.inertia : 0.0;
	}

	override public function setOrient(radians:Float) {
		u.setF(radians);
	}

	override public function getType():Int {
		return Shape.TYPE_POLY;
	}

	public function setBox(hw:Float, hh:Float) {
		vertexCount = 4;
		radius = Math.max(hw, hh);
		vertices[0].set(-hw, -hh);
		vertices[1].set(hw, -hh);
		vertices[2].set(hw, hh);
		vertices[3].set(-hw, hh);
		normals[0].set(0.0, -1.0);
		normals[1].set(1.0, 0.0);
		normals[2].set(0.0, 1.0);
		normals[3].set(-1.0, 0.0);
	}

	public function set(verts:Array<Vec2>) {
		// Find the right most poon:Int the hull

		var rightMost = 0;
		var highestXCoord = verts[0].x;
		var len = verts.length;
		var dx:Float = 0;
		var dy:Float = 0;
		for (i in 0...len) {
			var ax = Math.abs(verts[i].x);
			var ay = Math.abs(verts[i].y);
			if (dx < ax)
				dx = ax;
			if (dy < ay)
				dy = ay;

			var x = verts[i].x;
			if (x > highestXCoord) {
				highestXCoord = x;
				rightMost = i;
			}
			// If matching x then take farthest negative y
			else if (x == highestXCoord) {
				if (verts[i].y < verts[rightMost].y) {
					rightMost = i;
				}
			}
		}
		radius = Math.sqrt(dx * dx + dy * dy);
		// trace(radius, dx, dy);
		var hull = new Array<Int>(); // MAX_POLY_VERTEX_COUNT
		var outCount:Int = 0;
		var indexHull:Int = rightMost;

		while (true) {
			hull[outCount] = indexHull;

			// Search for next index that wraps around the hull
			// by computing cross products to find the most counter-clockwise
			// vertex in the set, given the previos hull index
			var nextHullIndex:Int = 0;
			for (i in 0...len) {
				// Skip if same coordinate as we need three unique
				// points in the set to perform a cross product
				if (nextHullIndex == indexHull) {
					nextHullIndex = i;
					continue;
				}

				// Cross every set of three unique vertices
				// Record each counter clockwise third vertex and add
				// to the output hull
				// See : http://www.oocities.org/pcgpe/math2d.html
				var e1:Vec2 = verts[nextHullIndex].sub(verts[hull[outCount]]);
				var e2:Vec2 = verts[i].sub(verts[hull[outCount]]);
				var c:Float = Vec2.crossVV(e1, e2);
				if (c < 0.0)
					nextHullIndex = i;

				// Cross product is zero then e vectors are on same line
				// therefore want to record vertex farthest along that line
				if (c == 0.0 && e2.lengthSq() > e1.lengthSq())
					nextHullIndex = i;
			}

			++outCount;
			indexHull = nextHullIndex;

			// Conclude algorithm upon wrap-around
			if (nextHullIndex == rightMost) {
				vertexCount = outCount;
				break;
			}
		}

		// Copy vertices into shape's vertices
		for (i in 0...vertexCount)
			vertices[i].set(verts[hull[i]].x, verts[hull[i]].y);

		// Compute face normals
		for (i in 0...vertexCount) {
			var face:Vec2 = vertices[(i + 1) % vertexCount].sub(vertices[i]);

			// Calculate normal with 2D cross product between vector and scalar
			normals[i].set(face.y, -face.x);
			normals[i].normalize();
		}
	}

	public function getSupport(dir:Vec2):Vec2 {
		var bestProjection:Float = Math.NEGATIVE_INFINITY;
		var bestVertex:Vec2 = null;

		for (i in 0...vertexCount) {
			var v:Vec2 = vertices[i];
			var projection:Float = Vec2.dotVV(v, dir);

			if (projection > bestProjection) {
				bestVertex = v;
				bestProjection = projection;
			}
		}
		return bestVertex;
	}
}
