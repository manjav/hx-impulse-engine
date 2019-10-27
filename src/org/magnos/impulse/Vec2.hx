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

class Vec2
{

	public var x:Float = 0;
	public var y:Float = 0;

	public function new(x:Float = 0, y:Float = 0)
	{
		set( x, y );
	}

	public function set(x:Float, y:Float):Vec2
	{
		this.x = x;
		this.y = y;
		return this;
	}

	/**
	 * Negates this vector and returns this.
	 */
	public function negi():Vec2 
	{
		return neg( this );
	}

	/**
	 * Sets out to the negation of this vector and returns out.
	 */
	public function neg( out:Vec2 = null ):Vec2
	{
		if(out == null)
			out = new Vec2();
		out.x = -x;
		out.y = -y;
		return out;
	}

	/**
	 * Multiplies this vector by s and returns this.
	 */
	public function muliF( s:Float ):Vec2
	{
		return mulF( s, this );
	}

	/**
	 * Sets out to this vector multiplied by s and returns out.
	 */
	public function mulF( s:Float, out:Vec2=null ):Vec2
	{
		if(out == null)
			out = new Vec2();
		out.x = s * x;
		out.y = s * y;
		return out;
	}

	/**
	 * Divides this vector by s and returns this.
	 */
	public function diviF( s:Float ):Vec2
	{
		return divF( s, this );
	}

	/**
	 * Sets out to the division of this vector and s and returns out.
	 */
	public function divF( s:Float, out:Vec2 = null ):Vec2
	{
		if(out == null)
			out = new Vec2();
		out.x = x / s;
		out.y = y / s;
		return out;
	}

	/**
	 * Adds s to this vector and returns this. 
	 */
	public function addiF( s:Float ):Vec2
	{
		return addF( s, this );
	}

	/**
	 * Sets out to the sum of this vector and s and returns out.
	 */
	public function addF( s:Float, out:Vec2 ):Vec2
	{
		if(out == null)
			out = new Vec2();
		out.x = x + s;
		out.y = y + s;
		return out;
	}

	/**
	 * Multiplies this vector by v and returns this.
	 */
	public function muli( v:Vec2 ):Vec2
	{
		return mul( v, this );
	}

	/**
	 * Sets out to the product of this vector and v and returns out.
	 */
	public function mul( v:Vec2, out:Vec2 = null ):Vec2
	{
		if(out == null)
			out = new Vec2();
		out.x = x * v.x;
		out.y = y * v.y;
		return out;
	}

	/**
	 * Divides this vector by v and returns this.
	 */
	public function divi( v:Vec2 ):Vec2
	{
		return div( v, this );
	}

	/**
	 * Sets out to the division of this vector and v and returns out.
	 */
	public function div( v:Vec2, out:Vec2=null ):Vec2
	{
		if(out == null)
			out = new Vec2();
		out.x = x / v.x;
		out.y = y / v.y;
		return out;
	}

	/**
	 * Adds v to this vector and returns this.
	 */
	public function addi( v:Vec2 ):Vec2
	{
		return add( v, this );
	}

	/**
	 * Sets out to the addition of this vector and v and returns out.
	 */
	public function add( v:Vec2, out:Vec2=null ):Vec2
	{
		if(out == null)
			out = new Vec2();
		out.x = x + v.x;
		out.y = y + v.y;
		return out;
	}


	/**
	 * Adds v * s to this vector and returns this.
	 */
	public function addsi( v:Vec2, s:Float ):Vec2
	{
		return adds( v, s, this );
	}

	/**
	 * Sets out to the addition of this vector and v * s and returns out.
	 */
	public function adds( v:Vec2, s:Float, out:Vec2=null ):Vec2
	{
		if(out == null)
			out = new Vec2();
		out.x = x + v.x * s;
		out.y = y + v.y * s;
		return out;
	}

	/**
	 * Subtracts v from this vector and returns this.
	 */
	public function subi( v:Vec2 ):Vec2
	{
		return sub( v, this );
	}

	/**
	 * Sets out to the subtraction of v from this vector and returns out.
	 */
	public function sub( v:Vec2, out:Vec2=null ):Vec2
	{
		if(out == null)
			out = new Vec2();
		out.x = x - v.x;
		out.y = y - v.y;
		return out;
	}

	/**
	 * Returns the squared length of this vector.
	 */
	public function lengthSq():Float
	{
		return x * x + y * y;
	}

	/**
	 * Returns the length of this vector.
	 */
	public function length():Float
	{
		return Math.sqrt( x * x + y * y );
	}

	/**
	 * Rotates this vector by the given radians.
	 */
	public function rotate( radians:Float ):Void
	{
		var c = Math.cos( radians );
		var s = Math.sin( radians );

		var xp = x * c - y * s;
		var yp = x * s + y * c;

		x = xp;
		y = yp;
	}

	/**
	 * Normalizes this vector, making it a unit vector. A unit vector has a length of 1.0.
	 */
	public function normalize():Void
	{
		var lenSq = lengthSq();

		if (lenSq > ImpulseMath.EPSILON_SQ)
		{
			var invLen = 1.0 / Math.sqrt( lenSq );
			x *= invLen;
			y *= invLen;
		}
	}

	/**
	 * Sets this vector to the minimum between a and b.
	 */
	public function mini( a:Vec2, b:Vec2 ):Vec2
	{
		return min( a, b, this );
	}

	/**
	 * Sets this vector to the maximum between a and b.
	 */
	public function maxi( a:Vec2, b:Vec2 ):Vec2
	{
		return max( a, b, this );
	}

	/**
	 * Returns the dot product between this vector and v.
	 */
	public function dot( v:Vec2 ):Float
	{
		return dotVV( this, v );
	}

	/**
	 * Returns the squared distance between this vector and v.
	 */
	public function distanceSq( v:Vec2 ):Float
	{
		return distanceSqVV( this, v );
	}

	/**
	 * Returns the distance between this vector and v.
	 */
	public function distance( v:Vec2 ):Float
	{
		return distanceVV( this, v );
	}

	/**
	 * Sets this vector to the cross between v and a and returns this.
	 */
	public function crossVF( v:Vec2, a:Float ):Vec2
	{
		return crossVFV( v, a, this );
	}

	/**
	 * Sets this vector to the cross between a and v and returns this.
	 */
	public function crossFV( a:Float, v:Vec2 ):Vec2
	{
		return crossFVV( a, v, this );
	}

	/**
	 * Returns the scalar cross between this vector and v. This is essentially
	 * the length of the cross product if this vector were 3d. This can also
	 * indicate which way v is facing relative to this vector.
	 */
	public function crossV( v:Vec2 ):Float
	{
		return crossVV( this, v );
	}

	static public function min( a:Vec2, b:Vec2, out:Vec2 ):Vec2
	{
		out.x = Math.min( a.x, b.x );
		out.y = Math.min( a.y, b.y );
		return out;
	}

	static public function max( a:Vec2, b:Vec2, out:Vec2 ):Vec2
	{
		out.x = Math.max( a.x, b.x );
		out.y = Math.max( a.y, b.y );
		return out;
	}

	static public function dotVV( a:Vec2, b:Vec2 ):Float
	{
		return a.x * b.x + a.y * b.y;
	}


	static public function distanceSqVV( a:Vec2, b:Vec2 ):Float
	{
		var dx = a.x - b.x;
		var dy = a.y - b.y;

		return dx * dx + dy * dy;
	}

	static public function distanceVV( a:Vec2, b:Vec2 ):Float
	{
		var dx = a.x - b.x;
		var dy = a.y - b.y;

		return Math.sqrt( dx * dx + dy * dy );
	}

	static public function crossVFV( v:Vec2, a:Float, out:Vec2 ):Vec2
	{
		out.x = v.y * a;
		out.y = v.x * -a;
		return out;
	}

	static public function crossFVV( a:Float, v:Vec2, out:Vec2 ):Vec2
	{
		out.x = v.y * -a;
		out.y = v.x * a;
		return out;
	}

	static public function crossVV( a:Vec2, b:Vec2 ):Float
	{
		return a.x * b.y - a.y * b.x;
	}

	/**
	 * Returns an array of allocated Vec2 of the requested length.
	 */
	static public function arrayOf( length:Int ):Array<Vec2>
	{
		var array = new Array<Vec2>();

		while (--length >= 0)
			array[length] = new Vec2();

		return array;
	}

	public function toString():String {
		return "[x:" + x + ",y:" + y + "]";
	}
}