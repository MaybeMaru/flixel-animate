package animate;

import animate.FlxAnimateFrames.FlxAnimateSettings;
import animate.internal.Frame;
import animate.internal.StageBG;
import animate.internal.Timeline;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxAngle;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxDestroyUtil;
import haxe.io.Path;
import openfl.display.BitmapData;

using flixel.util.FlxColorTransformUtil;

#if FLX_DEBUG
import flixel.FlxBasic;
import flixel.FlxG;
#end

class FlxAnimate extends FlxSprite
{
	public static var drawDebugLimbs:Bool = false;

	public var anim(default, set):FlxAnimateController = null;
	public var library(default, null):FlxAnimateFrames;
	public var isAnimate(default, null):Bool = false;
	public var timeline(default, null):Timeline;

	public var applyStageMatrix:Bool = false;
	public var renderStage:Bool = false;

	public var skew(default, null):FlxPoint;

	public function new(?x:Float = 0, ?y:Float = 0, ?simpleGraphic:FlxGraphicAsset, ?settings:FlxAnimateSettings)
	{
		var loadedAnimateAtlas:Bool = false;
		if (simpleGraphic != null && simpleGraphic is String)
		{
			if (Path.extension(simpleGraphic).length == 0)
				loadedAnimateAtlas = true;
		}

		super(x, y, loadedAnimateAtlas ? null : simpleGraphic);

		if (loadedAnimateAtlas)
			frames = FlxAnimateFrames.fromAnimate(simpleGraphic, null, null, null, false, settings);
	}

	override function initVars()
	{
		super.initVars();
		anim = new FlxAnimateController(this);
		skew = new FlxPoint();
		animation = anim;
	}

	override function set_frames(frames:FlxFramesCollection):FlxFramesCollection
	{
		isAnimate = (frames != null) && (frames is FlxAnimateFrames);

		var resultFrames = super.set_frames(frames);

		if (isAnimate)
		{
			library = cast frames;
			timeline = library.timeline;
			anim.updateTimelineBounds();
			resetHelpers();
		}
		else
		{
			library = null;
			timeline = null;
		}

		return resultFrames;
	}

	override function draw():Void
	{
		if (!isAnimate)
		{
			super.draw();
			return;
		}

		if (alpha <= 0.0 || Math.abs(scale.x) < FlxPoint.EPSILON || Math.abs(scale.y) < FlxPoint.EPSILON)
			return;

		for (camera in #if (flixel >= "5.7.0") this.getCamerasLegacy() #else this.cameras #end)
		{
			if (!camera.visible || !camera.exists || !isOnScreen(camera))
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

	function drawAnimate(camera:FlxCamera):Void
	{
		var mat = _matrix;
		mat.identity();

		@:privateAccess
		var bounds = timeline._bounds;
		mat.translate(-bounds.x, -bounds.y);

		var doFlipX = this.checkFlipX();
		var doFlipY = this.checkFlipY();

		if (doFlipX)
		{
			mat.scale(-1, 1);
			mat.translate(frame.sourceSize.x, 0);
		}

		if (doFlipY)
		{
			mat.scale(1, -1);
			mat.translate(0, frame.sourceSize.y);
		}

		if (applyStageMatrix)
			mat.concat(library.matrix);

		mat.translate(-origin.x, -origin.y);
		mat.scale(scale.x, scale.y);

		if (angle != 0)
		{
			updateTrig();
			mat.rotateWithTrig(_cosAngle, _sinAngle);
		}

		if (skew.x != 0 || skew.y != 0)
		{
			updateSkew();
			mat.concat(_skewMatrix);
		}

		getScreenPosition(_point, camera);
		_point.x += origin.x - offset.x;
		_point.y += origin.y - offset.y;
		mat.translate(_point.x, _point.y);

		if (renderStage)
			drawStage(camera);

		timeline.currentFrame = animation.frameIndex;
		timeline.draw(camera, mat, colorTransform, blend, antialiasing, shader);
	}

	// I dont think theres a way to override the matrix without needing to do this lol
	#if (flixel >= "6.1.0")
	override function drawFrameComplex(frame:FlxFrame, camera:FlxCamera):Void
	#else
	override function drawComplex(camera:FlxCamera):Void
	#end
	{
		#if (flixel < "6.1.0") final frame = this._frame; #end
		final matrix = this._matrix; // TODO: Just use local?

		frame.prepareMatrix(matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		matrix.translate(-origin.x, -origin.y);
		matrix.scale(scale.x, scale.y);
		if (bakedRotationAngle <= 0)
		{
			updateTrig();
			if (angle != 0)
				matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}
		if (skew.x != 0 || skew.y != 0)
		{
			updateSkew();
			_matrix.concat(_skewMatrix);
		}
		getScreenPosition(_point, camera);
		_point.x += origin.x - offset.x;
		_point.y += origin.y - offset.y;
		matrix.translate(_point.x, _point.y);
		if (isPixelPerfectRender(camera))
		{
			matrix.tx = Math.floor(matrix.tx);
			matrix.ty = Math.floor(matrix.ty);
		}
		camera.drawPixels(frame, framePixels, matrix, colorTransform, blend, antialiasing, shader);
	}

	var stageBg:StageBG;

	function drawStage(camera:FlxCamera):Void
	{
		if (stageBg == null)
			stageBg = new StageBG();

		stageBg.render(this, camera);
	}

	// semi stolen from FlxSkewedSprite
	static var _skewMatrix:FlxMatrix = new FlxMatrix();

	private inline function updateSkew():Void
	{
		_skewMatrix.setTo(1, Math.tan(skew.y * FlxAngle.TO_RAD), Math.tan(skew.x * FlxAngle.TO_RAD), 1, 0, 0);
	}

	override function get_numFrames():Int
	{
		if (!isAnimate)
			return super.get_numFrames();

		return animation.curAnim != null ? timeline.frameCount : 0;
	}

	private function set_anim(newController:FlxAnimateController):FlxAnimateController
	{
		anim = newController;
		animation = anim;
		return newController;
	}

	override function updateFramePixels():BitmapData
	{
		if (!isAnimate)
			return super.updateFramePixels();

		if (timeline == null || !dirty)
			return framePixels;

		@:privateAccess
		{
			var mat = new FlxMatrix(checkFlipX() ? -1 : 1, 0, 0, checkFlipY() ? -1 : 1, 0, 0);

			#if flash
			framePixels = animate.internal.FilterRenderer.getBitmap((cam, _) -> timeline.draw(cam, mat, null, NORMAL, true, null), timeline._bounds);
			#else
			var cam = new FlxCamera();
			Frame.__isDirtyCall = true;
			timeline.draw(cam, mat, null, NORMAL, true, null);
			Frame.__isDirtyCall = false;
			cam.render();

			var bounds = timeline._bounds;
			framePixels = new BitmapData(Std.int(bounds.width), Std.int(bounds.height), true, 0);
			framePixels.draw(cam.canvas, new openfl.geom.Matrix(1, 0, 0, 1, -bounds.x, -bounds.y), null, null, null, true);
			cam.canvas.graphics.clear();
			#end
		}

		dirty = false;
		return framePixels;
	}

	override function getScreenBounds(?newRect:FlxRect, ?camera:FlxCamera):FlxRect
	{
		var bounds = super.getScreenBounds(newRect, camera);

		if (isAnimate)
		{
			if (applyStageMatrix)
				Timeline.applyMatrixToRect(bounds, library.matrix);
		}

		// TODO: add skewed bounds expansion

		return bounds;
	}

	override function destroy():Void
	{
		super.destroy();
		anim = FlxDestroyUtil.destroy(anim);
		library = null;
		timeline = null;
		stageBg = FlxDestroyUtil.destroy(stageBg);
		skew = FlxDestroyUtil.put(skew);
	}
}
