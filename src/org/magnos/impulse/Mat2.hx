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

class Mat2
{
	public var m00:Float = 0;
	public var m01:Float = 0;
	public var m10:Float = 0;
	public var m11:Float = 0;

	public function new( radians:Float = 0 )
	{
		if (radians != 0)
			setF( radians );
	}

	/**
	 * Sets this matrix to a rotation matrix with the given radians.
	 */
	public function setF( radians:Float )
	{
		var c:Float = Math.cos( radians );
		var s:Float = Math.sin( radians );

		m00 = c;
		m01 = -s;
		m10 = s;
		m11 = c;
	}

	/**
	 * Sets the values of this matrix.
	 */
	public function set( a:Float, b:Float, c:Float, d:Float ):Mat2
	{
		m00 = a;
		m01 = b;
		m10 = c;
		m11 = d;
		return this;
	}

	/**
	 * Sets this matrix to have the same values as the given matrix.
	 */
	public function setM( m:Mat2 )
	{
		m00 = m.m00;
		m01 = m.m01;
		m10 = m.m10;
		m11 = m.m11;
	}

	/**
	 * Sets the values of this matrix to their absolute value.
	 */
	public function absi()
	{
		abs( this );
	}

	/**
	 * Sets out to the absolute value of this matrix.
	 */
	public function abs( out:Mat2 = null ):Mat2
	{
		if( out == null )
			out = new Mat2();
		out.m00 = Math.abs( m00 );
		out.m01 = Math.abs( m01 );
		out.m10 = Math.abs( m10 );
		out.m11 = Math.abs( m11 );
		return out;
	}

	/**
	 * Sets out to the x-axis (1st column) of this matrix.
	 */
	public function getAxisX( out:Vec2 = null ):Vec2
	{
		if( out == null )
			out = new Vec2();
		out.x = m00;
		out.y = m10;
		return out;
	}

	/**
	 * Sets out to the y-axis (2nd column) of this matrix.
	 */
	public function getAxisY( out:Vec2 = null ):Vec2
	{
		if( out == null )
			out = new Vec2();
		out.x = m01;
		out.y = m11;
		return out;
	}

	/**
	 * Sets the matrix to it's transpose.
	 */
	public function transposei():Void
	{
		var t:Float = m01;
		m01 = m10;
		m10 = t;
	}

	/**
	 * Sets out to the transpose of this matrix.
	 */
	public function transpose( out:Mat2 = null ):Mat2
	{
		if( out == null )
			out = new Mat2();
		out.m00 = m00;
		out.m01 = m10;
		out.m10 = m01;
		out.m11 = m11;
		return out;
	}
	/**
	 * Transforms v by this matrix.
	 */
	public function muli( v:Vec2 ):Vec2
	{
		return mulFF( v.x, v.y, v );
	}

	/**
	 * Sets out to the transformation of v by this matrix.
	 */
	public function mul( v:Vec2, out:Vec2 = null ):Vec2
	{
		if( out == null )
			out = new Vec2();
		return mulFF( v.x, v.y, out );
	}

	/**
	 * Sets out the to transformation of {x,y} by this matrix.
	 */
	public function mulFF( x:Float, y:Float, out:Vec2 ):Vec2
	{
		out.x = m00 * x + m01 * y;
		out.y = m10 * x + m11 * y;
		return out;
	}

	/**
	 * Multiplies this matrix by x.
	 */
	public function muliM( x:Mat2 ):Void
	{
		set(
			m00 * x.m00 + m01 * x.m10,
			m00 * x.m01 + m01 * x.m11,
			m10 * x.m00 + m11 * x.m10,
			m10 * x.m01 + m11 * x.m11 );
	}

	/**
	 * Sets out to the multiplication of this matrix and x.
	 */
	public function mulMM( x:Mat2, out:Mat2 = null ):Mat2
	{
		if (out == null)
			out = new Mat2();
		out.m00 = m00 * x.m00 + m01 * x.m10;
		out.m01 = m00 * x.m01 + m01 * x.m11;
		out.m10 = m10 * x.m00 + m11 * x.m10;
		out.m11 = m10 * x.m01 + m11 * x.m11;
		return out;
	}
}