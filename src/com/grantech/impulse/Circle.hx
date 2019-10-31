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

class Circle extends Shape {
	public function new(r:Float) {
		super();
		radius = r;
	}

	override public function clone():Shape {
		return new Circle(radius);
	}

	override public function initialize() {
		computeMass(1.0);
	}

	override public function computeMass(density:Float) {
		body.mass = ImpulseMath.PI * radius * radius * density;
		body.invMass = (body.mass != 0.0) ? 1.0 / body.mass : 0.0;
		body.inertia = body.mass * radius * radius;
		body.invInertia = (body.inertia != 0.0) ? 1.0 / body.inertia : 0.0;
	}

	override public function setOrient(radians:Float) {}

	override public function getType():Int {
		return Shape.TYPE_CIRCLE;
	}
}
