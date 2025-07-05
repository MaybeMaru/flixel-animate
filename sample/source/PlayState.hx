package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxState;
import flixel.addons.animate.FlxAnimate;
import flixel.addons.animate.FlxAnimateFrames;
import flixel.util.FlxColor;
import openfl.display.FPS;

class PlayState extends FlxState
{
	override public function create()
	{
		FlxG.game.addChild(new FPS());

		FlxG.camera.bgColor = FlxColor.GRAY;

		FlxG.fixedTimestep = false;
		FlxG.drawFramerate = FlxG.updateFramerate = 999;
		FlxG.debugger.drawDebug = true;

		FlxAnimate.drawDebugLimbs = true;

		animate = new FlxAnimate();

		animate.antialiasing = true;

		animate.frames = FlxAnimateFrames.fromAnimate('assets/images/Boyfriend DJ new character');
		animate.anim.addByTimeline("main", animate.library.timeline);
		animate.anim.play("main", true);

		animate.screenCenter();

		add(animate);

		focus = new FlxObject();
		focus.screenCenter();
		camera.follow(focus);

		super.create();
	}

	var animate:FlxAnimate;
	var focus:FlxObject;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		var elapsed = elapsed / FlxG.timeScale;

		if (FlxG.keys.justPressed.Z)
			animate.flipX = !animate.flipX;

		if (FlxG.keys.justPressed.X)
			animate.flipY = !animate.flipY;

		if (FlxG.keys.justPressed.R && animate != null)
			FlxG.resetState();

		if (FlxG.keys.pressed.E)
			FlxG.camera.zoom += 2 * FlxG.camera.zoom * elapsed;
		if (FlxG.keys.pressed.Q)
			FlxG.camera.zoom -= 2 * FlxG.camera.zoom * elapsed;

		if (FlxG.keys.pressed.W)
			focus.y -= 200 * elapsed / FlxG.camera.zoom;
		if (FlxG.keys.pressed.S)
			focus.y += 200 * elapsed / FlxG.camera.zoom;
		if (FlxG.keys.pressed.A)
			focus.x -= 200 * elapsed / FlxG.camera.zoom;
		if (FlxG.keys.pressed.D)
			focus.x += 200 * elapsed / FlxG.camera.zoom;
	}
}
