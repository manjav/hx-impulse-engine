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

class Body {
	public var position:Vec2 = new Vec2();
	public var velocity:Vec2 = new Vec2();
	public var force:Vec2 = new Vec2();
	public var angularVelocity:Float = 0;
	public var torque:Float = 0;
	public var orient:Float = 0;
	public var mass:Float = 0;
	public var invMass:Float = 0;
	public var inertia:Float = 0;
	public var invInertia:Float = 0;
	public var staticFriction:Float = 0;
	public var dynamicFriction:Float = 0;
	public var restitution:Float = 0;
	public var shape:Shape;

	public function new(shape:Shape, x:Int, y:Int) {
		this.shape = shape;

		position.set(x, y);
		velocity.set(0, 0);
		angularVelocity = 0;
		torque = 0;
		orient = ImpulseMath.random(-ImpulseMath.PI, ImpulseMath.PI);
		force.set(0, 0);
		staticFriction = 0.5;
		dynamicFriction = 0.3;
		restitution = 0.2;

		shape.body = this;
		shape.initialize();
	}

	public function applyForce(f:Vec2) {
		// force += f;
		force.addi(f);
	}

	public function applyImpulse(impulse:Vec2, contactVector:Vec2) {
		// velocity += im * impulse;
		// angularVelocity += iI * Cross( contactVector, impulse );

		velocity.addsi(impulse, invMass);
		angularVelocity += invInertia * Vec2.crossVV(contactVector, impulse);
	}

	public function setStatic() {
		inertia = 0.0;
		invInertia = 0.0;
		mass = 0.0;
		invMass = 0.0;
	}

	public function setOrient(radians:Float) {
		orient = radians;
		shape.setOrient(radians);
	}
}