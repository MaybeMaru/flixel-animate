package animate;

import animate.FlxAnimateController.FlxAnimateAnimation;
import animate.FlxAnimateJson;
import animate.internal.*;
import flixel.*;
import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.*;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.FlxBGSprite;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import haxe.io.Path;
import openfl.Assets;

using flixel.util.FlxColorTransformUtil;

class FlxAnimate extends FlxSprite
{
	public static var drawDebugLimbs:Bool = false;

	public var library(default, null):FlxAnimateFrames;
	public var animate(default, null):FlxAnimateController;

	@:deprecated('anim is deprecated, use animate')
	public var anim(get, never):FlxAnimateController;

	public var skew:FlxPoint;

	public var isAnimate(default, null):Bool = false;
	public var timeline:Timeline;

	public function new(?x:Float = 0, ?y:Float = 0, ?simpleGraphic:FlxGraphicAsset)
	{
		var loadedAnimateAtlas:Bool = false;
		if (simpleGraphic != null && simpleGraphic is String)
		{
			if (Path.extension(simpleGraphic).length == 0)
				loadedAnimateAtlas = true;
		}

		super(x, y, loadedAnimateAtlas ? null : simpleGraphic);

		if (loadedAnimateAtlas)
			frames = FlxAnimateFrames.fromAnimate(simpleGraphic);
	}

	override function initVars()
	{
		super.initVars();
		animate = new FlxAnimateController(this);
		skew = new FlxPoint();
		animation = animate;
	}

	@:noCompletion
	override function set_frames(frames:FlxFramesCollection):FlxFramesCollection
	{
		isAnimate = frames != null && (frames is FlxAnimateFrames);

		var resultFrames = super.set_frames(frames);

		if (isAnimate)
		{
			library = cast frames;
			timeline = library.timeline;
			frame = null;
			animate.updateTimelineBounds();
			resetHelpers();
		}
		else
		{
			library = null;
			timeline = null;
		}

		return resultFrames;
	}

	override function draw()
	{
		if (!isAnimate)
		{
			super.draw();
			return;
		}

		for (camera in #if (flixel >= "5.7.0") this.getCamerasLegacy() #else this.cameras #end)
		{
			if (!camera.visible || !camera.exists || (useLegacyBounds ? false : !isOnScreen(camera)))
				continue;

			drawAnimate(camera);

			#if FLX_DEBUG
			FlxBasic.visibleCount++;
			#end
		}

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug)
			drawDebug();
		#end
	}

	public var useLegacyBounds:Bool = #if FLX_ANIMATE_LEGACY_BOUNDS true; #else false; #end
	public var applyStageMatrix:Bool = false;
	public var renderStage:Bool = false;

	function drawAnimate(camera:FlxCamera)
	{
		if (alpha <= 0.0 || Math.abs(scale.x) < 0.0000001 || Math.abs(scale.y) < 0.0000001)
			return;

		_matrix.setTo(this.checkFlipX() ? -1 : 1, 0, 0, this.checkFlipY() ? -1 : 1, 0, 0);

		if (applyStageMatrix)
			_matrix.concat(library.matrix);

		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (angle != 0)
		{
			updateTrig();
			_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		if (skew.x != 0 || skew.y != 0)
		{
			updateSkew();
			_matrix.concat(_skewMatrix);
		}

		getScreenPosition(_point, camera);
		_point.add(-offset.x, -offset.y);
		_point.add(origin.x, origin.y);

		if (!useLegacyBounds)
		{
			@:privateAccess
			var bounds = timeline.__bounds;
			_point.add(-bounds.x, -bounds.y);
		}

		_matrix.translate(_point.x, _point.y);

		if (renderStage)
			drawStage(camera);

		timeline.draw(camera, _matrix, colorTransform, blend, antialiasing, shader);
	}

	var stageBg:FlxSprite;

	function drawStage(camera:FlxCamera)
	{
		if (stageBg == null)
			stageBg = new FlxSprite().makeGraphic(1, 1, FlxColor.WHITE, false, "flxanimate_stagebg_graphic_");

		var mat = stageBg._matrix;
		mat.identity();
		mat.scale(library.stageRect.width, library.stageRect.height);
		mat.translate(-0.5 * (mat.a - 1), -0.5 * (mat.d - 1));
		mat.concat(this._matrix);

		stageBg.color = library.stageColor;
		stageBg.colorTransform.concat(this.colorTransform);
		camera.drawPixels(stageBg.frame, stageBg.framePixels, stageBg._matrix, stageBg.colorTransform, blend, antialiasing, shader);
	}

	// semi stolen from FlxSkewedSprite
	static var _skewMatrix:FlxMatrix = new FlxMatrix();

	function updateSkew()
	{
		_skewMatrix.setTo(1, Math.tan(skew.y * FlxAngle.TO_RAD), Math.tan(skew.x * FlxAngle.TO_RAD), 1, 0, 0);
	}

	@:noCompletion
	override function get_numFrames():Int
	{
		if (isAnimate)
			return animation.curAnim != null ? timeline.frameCount : 0;

		return super.get_numFrames();
	}

	override function destroy():Void
	{
		super.destroy();
		animate = null;
		library = null;
		timeline = null;
		stageBg = FlxDestroyUtil.destroy(stageBg);
		skew = FlxDestroyUtil.put(skew);
	}

	@:noCompletion
	private inline function get_anim():FlxAnimateController {
		return animate;
	}
}
