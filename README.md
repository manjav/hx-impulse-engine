[![MIT License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)](LICENSE.md)
[![Haxelib Version](https://img.shields.io/badge/haxelib-v.1.0.1-blue)](https://lib.haxe.org/p/impulse)
# Impulse Engine

![Test Project](https://github.com/manjav/hx-impulse-engine/blob/master/screenshot.png)

Impulse Engine is a small 2D physics engine  that originaly written in [C++ by Randy Gaul](https://github.com/RandyGaul/ImpulseEngine). 
thanks to [Philip Diffenderfer for java port](https://github.com/ClickerMonkey/ImpulseEngine). Impulse Engine is intended to be used in an educational manner by other looking to learn the inner workings of physics engines, but you can use in server-side and pure-logic projects.

TestSimple.hx class is demo of haxe-as3 language. based on your needs, build to cpp, java, js, cs, php and other haxe support languages.

<b>Step 1 : Initialize impulse scene</b>

```haxe
this.impulse = new ImpulseScene(ImpulseMath.DT, 10);
```

<b>Step 2 : Define static items</b>
```haxe
// center circle
var b:Body = null;
b = this.impulse.add(new Circle(30.0), 300, 500);
b.setStatic();

// bottom rectangle
var p = new Polygon();
p.setBox(250.0, 10.0);
b = this.impulse.add(p, 300, 600);
b.setStatic();
b.setOrient(0);
```

<b>Step 3 : Instantiate circle, rectangle and polygon by click</b>
```haxe
this.stage.addEventListener(MouseEvent.CLICK, this.stage_clickHandler);

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
```

<b>Step 4 : Update every frames</b>
```haxe
this.addEventListener(Event.ENTER_FRAME, this.this_enterFrameHandler);
private function this_enterFrameHandler(event:flash.events.Event):Void {
  var t = Timer.stamp() * 1000;
  this.accumulator += (t - this.dt);
  this.dt = t;
  if (this.accumulator >= this.impulse.dt) {
    this.impulse.step();
    this.accumulator -= this.impulse.dt;
  }
}
```
