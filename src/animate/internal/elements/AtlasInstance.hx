package animate.internal.elements;

import animate.FlxAnimateJson;
import animate.internal.elements.Element;
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
import haxe.ds.Vector;
import openfl.display.BlendMode;
import openfl.display.Timeline;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

@:access(openfl.geom.Point)
@:access(openfl.geom.Matrix)
@:access(flixel.FlxCamera)
@:access(flixel.graphics.frames.FlxFrame)
class AtlasInstance extends AnimateElement<AtlasInstanceJson>
{
	public var frame:FlxFrame;

	var tileMatrix:FlxMatrix;

	public function new(?data:AtlasInstanceJson, ?parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent);
		this.tileMatrix = new FlxMatrix();
		isSymbolInstance = false;

		if (data != null)
		{
			this.frame = parent.getByName(data.N);
			this.matrix = data.MX.toMatrix();

			#if flash
			// FlxFrame.paint doesnt work for rotated frames lol
			var bitmap = this.frame.checkInputBitmap(null, null, this.frame.angle);
			var mat = this.frame.prepareBlitMatrix(FlxFrame._matrix, true);
			bitmap.draw(this.frame.parent.bitmap, mat, null, null, this.frame.getDrawFrameRect(mat, FlxFrame._rect));
			this.frame = FlxGraphic.fromBitmapData(bitmap).imageFrame.frame;
			#else
			// new flixel broke the tileMatrix on hashlink, gotta manually do this shit
			// TODO: remove this when it gets fixed on flixel 6.1.1 or something
			this.frame.prepareBlitMatrix(tileMatrix, false);
			#end
		}
	}

	public function replaceFrame(frame:FlxFrame, adjustScale:Bool = true):Void
	{
		var copyFrame = frame.copyTo();

		// Scale adjustment
		if (adjustScale)
		{
			var lastFrame = this.frame;
			tileMatrix.a = lastFrame.frame.width / frame.frame.width;
			tileMatrix.d = lastFrame.frame.height / frame.frame.height;
		}

		this.frame = copyFrame;
	}

	override function destroy():Void
	{
		super.destroy();
		frame = null;
	}

	override function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader):Void
	{
		if (frame == null) // should add a warn here
			return;

		_mat.copyFrom(tileMatrix);
		_mat.concat(matrix);
		_mat.concat(parentMatrix);

		if (!isOnScreen(camera, _mat))
			return;

		#if flash
		drawPixelsFlash(camera, _mat, transform, blend, antialiasing);
		#else
		camera.drawPixels(frame, null, _mat, transform, blend, antialiasing, shader);
		#end

		#if FLX_DEBUG
		if (FlxG.debugger.drawDebug && FlxAnimate.drawDebugLimbs && !Frame.__isDirtyCall)
			drawBoundingBox(camera, _bounds);
		#end
	}

	#if flash
	@:access(flixel.FlxCamera)
	inline function drawPixelsFlash(cam:FlxCamera, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?antialiasing:Bool):Void
	{
		var smooth:Bool = (cam.antialiasing || antialiasing);
		cam._helperMatrix.copyFrom(matrix);

		if (cam._useBlitMatrix)
		{
			cam._helperMatrix.concat(cam._blitMatrix);
			cam.buffer.draw(frame.parent.bitmap, cam._helperMatrix, transform, blend, null, smooth);
		}
		else
		{
			cam._helperMatrix.translate(-cam.viewMarginLeft, -cam.viewMarginTop);
			cam.buffer.draw(frame.parent.bitmap, cam._helperMatrix, transform, blend, null, smooth);
		}
	}
	#end

	var _bounds:FlxRect = FlxRect.get();

	public function isOnScreen(camera:FlxCamera, matrix:FlxMatrix):Bool
	{
		if (Frame.__isDirtyCall)
			return true;

		var bounds = _bounds;
		bounds.x = 0.0;
		bounds.y = 0.0;
		bounds.width = frame.frame.width;
		bounds.height = frame.frame.height;

		Timeline.applyMatrixToRect(bounds, matrix);

		// manually inlining this because we dont need the bounds.putWeak part
		return (bounds.right > camera.viewMarginLeft)
			&& (bounds.x < camera.viewMarginRight)
			&& (bounds.bottom > camera.viewMarginTop)
			&& (bounds.y < camera.viewMarginBottom);
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix):FlxRect
	{
		var rect = super.getBounds(0, rect);
		rect.set(0, 0, frame.frame.width, frame.frame.height);

		Timeline.applyMatrixToRect(rect, tileMatrix);
		Timeline.applyMatrixToRect(rect, this.matrix);
		if (matrix != null)
			Timeline.applyMatrixToRect(rect, matrix);

		return rect;
	}

	#if (FLX_DEBUG && flash)
	static final __fillRect = new openfl.geom.Rectangle();
	#end

	#if FLX_DEBUG
	public static inline function drawBoundingBox(camera:FlxCamera, bounds:FlxRect, ?color:FlxColor = FlxColor.BLUE):Void
	{
		#if flash
		var cBounds = camera.transformRect(bounds.copyTo(FlxRect.get()));
		FlxG.signals.postDraw.addOnce(() ->
		{
			var buffer = FlxG.camera.buffer;
			__fillRect.setTo(cBounds.x, cBounds.y, cBounds.width, 1);
			buffer.fillRect(__fillRect, color);
			__fillRect.setTo(cBounds.x, cBounds.y + cBounds.height - 1, cBounds.width, 1);
			buffer.fillRect(__fillRect, color);
			__fillRect.setTo(cBounds.x, cBounds.y, 1, cBounds.height);
			buffer.fillRect(__fillRect, color);
			__fillRect.setTo(cBounds.x + cBounds.width - 1, cBounds.y, 1, cBounds.height);
			buffer.fillRect(__fillRect, color);
			cBounds.put();
		});
		#else
		var gfx = camera.debugLayer.graphics;
		gfx.lineStyle(1, color, 0.75);
		gfx.drawRect(bounds.x + 0.5, bounds.y + 0.5, bounds.width - 1.0, bounds.height - 1.0);
		#end
	}
	#end

	public function toString():String
	{
		return '{frame: ${frame.name}, matrix: $matrix}';
	}
}
