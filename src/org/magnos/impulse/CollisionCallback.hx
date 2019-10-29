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

class CollisionCallback {
	var manifold:Manifold;
	var normal:Vec2;
	var distance:Float;
	var radiuses:Float;

	public function new() {}

	public function handleCollision(m:Manifold, a:Body, b:Body):Bool {
		this.manifold = m;

		// Calculate translational vector, which is normal
		// normal:Vec = b->position - a->position;
		normal = b.position.sub(a.position, m.scene.vec_in());

		// real dist_sqr = normal.LenSqr( );
		// real radius = A->radius + B->radius;
		distance = normal.length();
		radiuses = a.shape.radius + b.shape.radius;

		// is far
		if (distance > radiuses) {
			m.contactCount = 0;
			m.scene.vec_ds(normal);
			return false;
		}
		return true;
	}
}
