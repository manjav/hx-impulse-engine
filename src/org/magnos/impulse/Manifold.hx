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

class Manifold {
	public var A:Body;
	public var B:Body;
	public var scene:ImpulseScene;
	public var penetration:Float = 0;
	public var normal:Vec2 = new Vec2();
	public var contacts:Array<Vec2> = [new Vec2(), new Vec2()];
	public var contactCount:Int;
	public var e:Float = 0;
	public var df:Float = 0;
	public var sf:Float = 0;

	public function new(a:Body, b:Body, scene:ImpulseScene) {
		A = a;
		B = b;
		this.scene = scene;
	}

	public function solve() {
		Collisions.dispatch[A.shape.getType()][B.shape.getType()].handleCollision(this, A, B);
	}

	public function initialize() {
		// Calculate average restitution
		// e = std::min( A->restitution, B->restitution );
		e = Math.min(A.restitution, B.restitution);

		// Calculate static and dynamic friction
		// sf = std::sqrt( A->staticFriction * A->staticFriction );
		// df = std::sqrt( A->dynamicFriction * A->dynamicFriction );
		sf = Math.sqrt(A.staticFriction * A.staticFriction + B.staticFriction * B.staticFriction);
		df = Math.sqrt(A.dynamicFriction * A.dynamicFriction + B.dynamicFriction * B.dynamicFriction);

		for (i in 0...contactCount) {
			// Calculate radii from COM to contact
			// ra:Vec = contacts[i] - A->position;
			// rb:Vec = contacts[i] - B->position;
			var ra:Vec2 = contacts[i].sub(A.position);
			var rb:Vec2 = contacts[i].sub(B.position);

			// rv:Vec = B->velocity + Cross( B->angularVelocity, rb ) -
			// A->velocity - Cross( A->angularVelocity, ra );
			var cra = Vec2.crossFVV(A.angularVelocity, ra, scene.vec_in());
			var crb = Vec2.crossFVV(B.angularVelocity, rb, scene.vec_in());
			var bacrb = B.velocity.add(crb);
			var rv:Vec2 = bacrb.subi(A.velocity).subi(cra);
			scene.vec_ds(cra);
			scene.vec_ds(crb);
			scene.vec_ds(bacrb);

			// Determine if we should perform a resting collision or not
			// The idea is if the only thing moving this object is gravity, // then the collision should be performed without any restitution
			// if(rv.LenSqr( ) < (dt * gravity).LenSqr( ) + EPSILON)
			if (rv.lengthSq() < ImpulseMath.RESTING) {
				e = 0.0;
			}
		}
	}

	public function applyImpulse() {
		// Early out and positional correct if both objects have infinite mass
		// if(Equal( A->im + B->im, 0 ))
		if (ImpulseMath.equal(A.invMass + B.invMass, 0)) {
			infiniteMassCorrection();
			return;
		}

		for (i in 0...contactCount) {
			// Calculate radii from COM to contact
			// ra:Vec = contacts[i] - A->position;
			// rb:Vec = contacts[i] - B->position;
			var ra = contacts[i].sub(A.position, scene.vec_in());
			var rb = contacts[i].sub(B.position, scene.vec_in());

			// Relative velocity
			// rv:Vec = B->velocity + Cross( B->angularVelocity, rb ) -
			// A->velocity - Cross( A->angularVelocity, ra );
			var ca = Vec2.crossFVV(A.angularVelocity, ra, scene.vec_in());
			var cb = Vec2.crossFVV(B.angularVelocity, rb, scene.vec_in());
			var rv = B.velocity.add(cb, scene.vec_in()).subi(A.velocity).subi(ca);

			// Relative velocity along the normal
			// real contactVel = Dot( rv, normal );
			var contactVel = Vec2.dotVV(rv, normal);
			scene.vec_ds(ca);
			scene.vec_ds(cb);
			scene.vec_ds(rv);

			// Do not resolve if velocities are separating
			if (contactVel > 0)
				return;

			// real raCrossN = Cross( ra, normal );
			// real rbCrossN = Cross( rb, normal );
			// real invMassSum = A->im + B->im + Sqr( raCrossN ) * A->iI + Sqr(
			// rbCrossN ) * B->iI;
			var raCrossN:Float = Vec2.crossVV(ra, normal);
			var rbCrossN:Float = Vec2.crossVV(rb, normal);
			var invMassSum = A.invMass + B.invMass + (raCrossN * raCrossN) * A.invInertia + (rbCrossN * rbCrossN) * B.invInertia;

			// Calculate impulse scalar
			var j:Float = -(1.0 + e) * contactVel;
			j /= invMassSum;
			j /= contactCount;

			// Apply impulse
			var impulse = normal.mulF(j, scene.vec_in());
			var impulsn = impulse.neg(scene.vec_in());
			A.applyImpulse(impulsn, ra);
			B.applyImpulse(impulse, rb);
			scene.vec_ds(impulse);
			scene.vec_ds(impulsn);
			
			// Friction impulse
			// rv = B->velocity + Cross( B->angularVelocity, rb ) -
			// A->velocity - Cross( A->angularVelocity, ra );
			ca = Vec2.crossFVV(A.angularVelocity, ra, scene.vec_in());
			cb = Vec2.crossFVV(B.angularVelocity, rb, scene.vec_in());
			rv = B.velocity.add(cb, scene.vec_in()).subi(A.velocity).subi(ca);

			// t:Vec = rv - (normal * Dot( rv, normal ));
			// t.Normalize( );
			var t = new Vec2(rv.x, rv.y);
			t.addsi(normal, -Vec2.dotVV(rv, normal));
			t.normalize();

			// j tangent magnitude
			var jt = -Vec2.dotVV(rv, t);
			jt /= invMassSum;
			jt /= contactCount;

			scene.vec_ds(ca);
			scene.vec_ds(cb);
			scene.vec_ds(rv);

			// Don't apply tiny friction impulses
			if (ImpulseMath.equal(jt, 0.0))
				return;

			// Coulumb's law
			var tangentImpulse:Vec2;
			// if(std::abs( jt ) < j * sf)
			if (Math.abs(jt) < j * sf) {
				// tangentImpulse = t * jt;
				tangentImpulse = t.mulF(jt, scene.vec_in());
			} else {
				// tangentImpulse = t * -j * df;
				tangentImpulse = t.mulF(j, scene.vec_in()).muliF(-df);
			}

			var tangentImpulsn = tangentImpulse.neg(scene.vec_in());
			// Apply friction impulse
			// A->ApplyImpulse( -tangentImpulse, ra );
			// B->ApplyImpulse( tangentImpulse, rb );
			A.applyImpulse(tangentImpulsn, ra);
			B.applyImpulse(tangentImpulse, rb);
			scene.vec_ds(tangentImpulse);
			scene.vec_ds(tangentImpulsn);
			scene.vec_ds(ra);
			scene.vec_ds(rb);
		}
	}

	public function positionalCorrection() {
		// const real k_slop = 0.05f; // Penetration allowance
		// const real percent = 0.4f; // Penetration percentage to correct
		// correction:Vec = (std::max( penetration - k_slop, 0.0f ) / (A->im +
		// B->im)) * normal * percent;
		// A->position -= correction * A->im;
		// B->position += correction * B->im;

		var correction:Float = Math.max(penetration - ImpulseMath.PENETRATION_ALLOWANCE, 0.0) / (A.invMass + B.invMass) * ImpulseMath.PENETRATION_CORRETION;

		A.position.addsi(normal, -A.invMass * correction);
		B.position.addsi(normal, B.invMass * correction);
	}

	private function infiniteMassCorrection() {
		A.velocity.set(0, 0);
		B.velocity.set(0, 0);
	}
}