package animate.internal.elements;

import animate.FlxAnimateJson;
import animate.internal.filters.*;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import openfl.display.BlendMode;
import openfl.display.Timeline;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

class ButtonInstance extends SymbolInstance
{
	public var curButtonState(default, null):ButtonState;
	public var onClick:FlxSignal;

	public function new(data:SymbolInstanceJson, parent:FlxAnimateFrames)
	{
		super(data, parent);

		this.curButtonState = ButtonState.UP;
		this.onClick = new FlxSignal();
		this._hitbox = FlxRect.get();
	}

	override function getFrameIndex(index:Int, frameIndex:Int):Int
	{
		return curButtonState;
	}

	override function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader)
	{
		updateButtonState(camera, parentMatrix);

		super.draw(camera, index, tlFrame, parentMatrix, transform, blend, antialiasing, shader);

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug && FlxAnimate.drawDebugLimbs)
			AtlasInstance.drawBoundingBox(camera, _hitbox, FlxColor.PURPLE);
		#end
	}

	var _hitbox:FlxRect;

	function updateButtonState(camera:FlxCamera, drawMatrix:FlxMatrix):Void
	{
		_hitbox = getBounds(0, _hitbox, drawMatrix);

		var mousePos = #if (flixel >= "5.9.0") FlxG.mouse.getViewPosition(camera,
			FlxPoint.get()); #else FlxG.mouse.getScreenPosition(camera, FlxPoint.get()); #end

		var xPos = mousePos.x;
		var yPos = mousePos.y;
		var isOverlaped = xPos >= _hitbox.left && xPos <= _hitbox.right && yPos >= _hitbox.top && yPos <= _hitbox.bottom;
		mousePos.put();

		if (isOverlaped)
		{
			this.curButtonState = FlxG.mouse.pressed ? ButtonState.DOWN : ButtonState.OVER;
			if (FlxG.mouse.justPressed)
				onClick.dispatch();
		}
		else
		{
			this.curButtonState = ButtonState.UP;
		}
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix):FlxRect
	{
		var bounds = this.libraryItem.timeline.getBounds(ButtonState.HIT, false, rect, this.matrix);
		if (matrix != null)
			bounds = Timeline.applyMatrixToRect(bounds, matrix);
		return bounds;
	}

	override function destroy():Void
	{
		super.destroy();
		_hitbox = FlxDestroyUtil.put(_hitbox);
		onClick = null;
	}

	override function toString():String
	{
		return '{name: ${libraryItem.name}, matrix: $matrix, curButtonState: $curButtonState}';
	}
}

enum abstract ButtonState(Int) to Int
{
	var UP = 0;
	var OVER = 1;
	var DOWN = 2;
	var HIT = 3;

	public inline function toString():String
	{
		return switch (cast this)
		{
			case UP: "UP";
			case OVER: "OVER";
			case DOWN: "DOWN";
			case HIT: "HIT";
		}
	}
}
