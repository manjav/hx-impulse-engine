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

class ImpulseMath {
	static public var PI:Float = Math.PI;
	static public var EPSILON:Float = 0.0001;
	static public var EPSILON_SQ:Float = EPSILON * EPSILON;
	static public var BIAS_RELATIVE:Float = 0.95;
	static public var BIAS_ABSOLUTE:Float = 0.01;
	static public var DT:Float = 1.0 / 60.0;
	static public var GRAVITY:Vec2 = new Vec2(0.0, 1000.0);
	static public var RESTING:Float = GRAVITY.mulF(DT).lengthSq() + EPSILON;
	static public var PENETRATION_ALLOWANCE:Float = 0.05;
	static public var PENETRATION_CORRETION:Float = 0.4;

	static public function equal(a:Float, b:Float):Bool {
		return Math.abs(a - b) <= EPSILON;
	}

	static public function clamp(min:Float, max:Float, a:Float):Float {
		return (a < min ? min : (a > max ? max : a));
	}

	static public function round(a:Float):Int {
		return Math.round(a + 0.5);
	}

	static public function random(min:Float, max:Float):Float {
		return (max - min) * Math.random() + min;
	}

	static public function randomR(min:Int, max:Int):Int {
		return Math.round((max - min + 1) * Math.random() + min);
	}

	static public function gt(a:Float, b:Float):Bool {
		return a >= b * BIAS_RELATIVE + a * BIAS_ABSOLUTE;
	}
}