package;

import haxe.Timer;
import flash.events.MouseEvent;
import com.grantech.impulse.Vec2;
import com.grantech.impulse.Circle;
import com.grantech.impulse.Shape;
import com.grantech.impulse.Polygon;
import com.grantech.impulse.Body;
import com.grantech.impulse.ImpulseMath;
import com.grantech.impulse.ImpulseScene;
import flash.events.Event;
import flash.display.Sprite;

/**
 * ...
 * @author Mansour Djawadi
 */
class TestSimple extends Sprite {
	static function main() {
		flash.Lib.current.stage.align = flash.display.StageAlign.TOP_LEFT;
		flash.Lib.current.stage.scaleMode = flash.display.StageScaleMode.NO_SCALE;
		flash.Lib.current.addChild(new TestSimple());
	}

	private var inited:Bool;
	private var dt:Float = 0;
	private var accumulator:Float = 0;
	private var impulse:ImpulseScene;
	private var playing:Bool;

	/* ENTRY POINT */
	public function new() {
		super();
		this.addEventListener(Event.ADDED_TO_STAGE, this.this_addedToStageHandler);
	}

	private function this_addedToStageHandler(event:Event):Void {
		this.removeEventListener(Event.ADDED_TO_STAGE, this.this_addedToStageHandler);
		stage.addEventListener(Event.RESIZE, stage_resizeHandler);
		#if ios
		haxe.Timer.delay(init, 100); // iOS 6
		#else
		init();
		#end
	}

	private function stage_resizeHandler(event:Event):Void {
		stage.removeEventListener(Event.RESIZE, stage_resizeHandler);
		init();
		// else (resize or orientation change)
	}

	private function init():Void {
		if (this.inited)
			return;
		this.inited = true;

		this.impulse = new ImpulseScene(ImpulseMath.DT);

		var b:Body = null;
		b = impulse.add(new Circle(30.0), 300, 500);
		b.setStatic();

		var p = new Polygon();
		p.setBox(250.0, 10.0);
		b = this.impulse.add(p, 300, 600);
		b.setStatic();
		b.setOrient(0);

		this.accumulator = 0;
		this.playing = true;

		// this.addChild(new FPS(10, 10, 0xFFFFFF));
		this.addEventListener(Event.ENTER_FRAME, this.this_enterFrameHandler);
		this.stage.addEventListener(MouseEvent.CLICK, this.stage_clickHandler);
	}

	private function stage_clickHandler(event:MouseEvent):Void {
		var mx = Math.round(event.stageX);
		var my = Math.round(event.stageY);
		var min = 10;
		var max = 30;
		var b:Body;
		if (event.shiftKey) {
			var p = new Polygon();
			p.setBox(ImpulseMath.random(min, max), ImpulseMath.random(min, max));
			b = this.impulse.add(p, mx, my);
			b.setOrient(0.0);
		} else if (event.altKey) {
			skipDrawing = !skipDrawing;
			return;
		} else if (event.ctrlKey) {
			var r = ImpulseMath.random(min, max);
			var vertCount = ImpulseMath.randomR(3, Polygon.MAX_POLY_VERTEX_COUNT);
			var verts = Vec2.arrayOf(vertCount);
			for (i in 0...vertCount)
				verts[i].set(ImpulseMath.random(-r, r), ImpulseMath.random(-r, r));
			b = this.impulse.add(new Polygon(verts), mx, my);
			b.setOrient(ImpulseMath.random(-ImpulseMath.PI, ImpulseMath.PI));
			b.restitution = 0.2;
			b.dynamicFriction = 0.2;
			b.staticFriction = 0.4;
		} else {
			b = this.impulse.add(new Circle(ImpulseMath.random(min, max)), mx, my);
		}
	}

	private function this_enterFrameHandler(event:flash.events.Event):Void {
		var t = Timer.stamp() * 1000;
		this.accumulator += (t - this.dt);
		this.dt = t;
		if (this.accumulator >= this.impulse.dt) {
			this.impulse.step();
			this.accumulator -= this.impulse.dt;
			this.cleanup();
			if (!skipDrawing)
				this.draw();
		}
	}

	var skipDrawing:Bool = false;

	private function cleanup():Void {
		for (b in this.impulse.bodies) {
			if (b.position.x < 0 || b.position.x > this.stage.stageWidth || b.position.y < 0 || b.position.y > this.stage.stageHeight)
				this.impulse.remove(b);
		}
	}

	private function draw():Void {
		this.graphics.clear();
		if (skipDrawing)
			return;
		for (b in this.impulse.bodies) {
			if (b.shape.getType() == Shape.TYPE_CIRCLE) {
				var c = cast(b.shape, Circle);
				this.graphics.lineStyle(1, 0xFF0000);
				this.graphics.moveTo(b.position.x, b.position.y);
				this.graphics.lineTo(b.position.x + b.shape.radius * Math.cos(b.orient), b.position.y + b.shape.radius * Math.sin(b.orient));
				this.graphics.drawCircle(b.position.x, b.position.y, c.radius);
			} else if (b.shape.getType() == Shape.TYPE_POLY) {
				var p = cast(b.shape, Polygon);
				this.graphics.lineStyle(1, 0x0000FF);

				for (i in 0...p.vertexCount) {
					var v = new Vec2(p.vertices[i].x, p.vertices[i].y);
					b.shape.u.muli(v);
					v.addi(b.position);

					if (i == 0)
						this.graphics.moveTo(v.x, v.y);
					else
						this.graphics.lineTo(v.x, v.y);
				}
				var v = new Vec2(p.vertices[0].x, p.vertices[0].y);
				b.shape.u.muli(v);
				v.addi(b.position);
				this.graphics.lineTo(v.x, v.y);
			}
		}

		this.graphics.lineStyle(1, 0xFFFFFF);
		for (m in impulse.contacts) {
			for (i in 0...m.contactCount) {
				var v = m.contacts[i];
				var n = m.normal;
				this.graphics.moveTo(v.x, v.y);
				this.graphics.lineTo(v.x + n.x * 4.0, v.y + n.y * 4.0);
			}
		}
	}
}
