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

class CollisionCircleCircle extends CollisionCallback {
	public function new() {
		super();
	}

	static public var instance:CollisionCircleCircle = new CollisionCircleCircle();

	override public function handleCollision(m:Manifold, a:Body, b:Body):Bool {
		if (!super.handleCollision(m, a, b))
			return false;

		m.contactCount = 1;

		if (distance == 0.0) {
			// m->penetration = A->radius;
			// m->normal = Vec2( 1, 0 );
			// m->contacts [0] = a->position;
			m.penetration = a.shape.radius;
			m.normal.set(1.0, 0.0);
			m.contacts[0].set(a.position.x, a.position.y);
		} else {
			// m->penetration = radius - distance;
			// m->normal = normal / distance; // Faster than using Normalized since
			// we already performed sqrt
			// m->contacts[0] = m->normal * A->radius + a->position;
			m.penetration = radiuses - distance;
			m.normal.set(normal.x, normal.y).diviF(distance);

			m.contacts[0].set(m.normal.x, m.normal.y).muliF(a.shape.radius).addi(a.position);
			m.scene.vec_ds(normal);
		}
		return true;
	}
}
