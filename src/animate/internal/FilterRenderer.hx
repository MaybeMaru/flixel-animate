package animate.internal;

import animate.FlxAnimateJson.FilterJson;
import animate.internal.elements.*;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxPool;
import openfl.display.BitmapData;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.filters.DropShadowFilter;
import openfl.filters.GlowFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import openfl.geom.Point;
import openfl.geom.Rectangle;
#if !flash
import animate.internal.filters.MaskShader;
import openfl.display.Graphics;
import openfl.display.OpenGLRenderer;
import openfl.display.Shader;
import openfl.display._internal.Context3DGraphics;
#end

#if !flash
@:access(flixel.FlxCamera)
@:access(flixel.graphics.frames.FlxFrame)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.display.Stage)
@:access(openfl.display3D.Context3D)
@:access(openfl.geom.Rectangle)
@:access(openfl.geom.Point)
@:access(openfl.display.internal.DrawCommandBuffer)
@:access(openfl.display.Graphics)
@:access(openfl.geom.ColorTransform)
@:access(openfl.display.BitmapData)
@:access(openfl.filters.BitmapFilter)
@:access(lime.graphics.Image)
@:access(openfl.display3D.textures.TextureBase)
#end
class FilterRenderer
{
	#if !flash
	public static function maskFrame(frame:Frame, currentFrame:Int, layer:Layer):Null<AtlasInstance>
	{
		var masker = layer.parentLayer;
		if (masker == null)
			return null;

		var maskerFrame = masker.getFrameAtIndex(currentFrame);
		if (maskerFrame == null || maskerFrame.elements.length <= 0)
			return null;

		var maskerBounds:Rectangle;
		var maskedBounds:Rectangle;

		var masker = renderToBitmap((cam, mat) ->
		{
			maskerFrame.draw(cam, currentFrame, mat, null, null, true, null);
			cam.render();
			maskerBounds = cam.canvas.getBounds(null);
		});

		var masked = renderToBitmap((cam, mat) ->
		{
			frame.draw(cam, currentFrame, mat, null, null, true, null);
			cam.render();
			maskedBounds = cam.canvas.getBounds(null);
		});

		var intersectX = Math.max(maskerBounds.x, maskedBounds.x);
		var intersectY = Math.max(maskerBounds.y, maskedBounds.y);
		var intersectWidth = Math.min(maskerBounds.right, maskedBounds.right) - intersectX;
		var intersectHeight = Math.min(maskerBounds.bottom, maskedBounds.bottom) - intersectY;

		var rect = Rectangle.__pool.get();
		var point = Point.__pool.get();

		rect.setTo(intersectX - maskedBounds.x, intersectY - maskedBounds.y, intersectWidth, intersectHeight);
		point.setTo(0, 0);

		// make masked bitmap
		var bitmap = new BitmapData(Math.ceil(intersectWidth), Math.ceil(intersectHeight), true, 0);
		bitmap.copyPixels(masked, rect, point, null, null, true);

		// copy masker channel
		rect.setTo(intersectX - maskerBounds.x, intersectY - maskerBounds.y, intersectWidth, intersectHeight);

		var frame = FlxGraphic.fromBitmapData(bitmap).imageFrame.frame;
		MaskShader.maskAlpha(bitmap, masker, rect);

		Rectangle.__pool.release(rect);
		Point.__pool.release(point);

		var element = new AtlasInstance();
		element.frame = frame;
		element.matrix = new FlxMatrix(1, 0, 0, 1, intersectX, intersectY);

		FlxDestroyUtil.dispose(masker);
		FlxDestroyUtil.dispose(masked);

		return element;
	}

	public static function renderGfx(gfx:Graphics):Null<BitmapData>
	{
		if (gfx.__bounds == null)
			return null;

		var cacheRTT = renderer.__context3D.__state.renderToTexture;
		var cacheRTTDepthStencil = renderer.__context3D.__state.renderToTextureDepthStencil;
		var cacheRTTAntiAlias = renderer.__context3D.__state.renderToTextureAntiAlias;
		var cacheRTTSurfaceSelector = renderer.__context3D.__state.renderToTextureSurfaceSelector;

		var bounds = gfx.__owner.getBounds(null);
		var bmp = new BitmapData(Math.ceil(bounds.width), Math.ceil(bounds.height), true, 0);

		renderer.__worldTransform.translate(-bounds.x, -bounds.y);

		var context = renderer.__context3D;

		renderer.__setRenderTarget(bmp);
		context.setRenderToTexture(bmp.getTexture(context));

		Context3DGraphics.render(gfx, renderer);

		renderer.__worldTransform.identity();

		var gl = renderer.__gl;
		var renderBuffer = bmp.getTexture(context);

		@:privateAccess
		gl.readPixels(0, 0, Math.round(bmp.width), Math.round(bmp.height), renderBuffer.__format, gl.UNSIGNED_BYTE, bmp.image.data);

		if (cacheRTT != null)
		{
			renderer.__context3D.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		}
		else
		{
			renderer.__context3D.setRenderToBackBuffer();
		}

		return bmp;
	}

	static function renderToBitmap(draw:(FlxCamera, FlxMatrix) -> Void):BitmapData
	{
		Frame.__isDirtyCall = true;

		var cam = CamPool.get();
		var gfx = cam.canvas.graphics;
		draw(cam, new FlxMatrix());

		var bitmap:BitmapData = renderGfx(gfx);

		cam.clearDrawStack();
		gfx.clear();
		cam.put();

		Frame.__isDirtyCall = false;

		return bitmap;
	}

	public static function bakeFilters(symbol:SymbolInstance, filters:Array<BitmapFilter>, scale:FlxPoint):AtlasInstance
	{
		var bitmap:BitmapData;
		var bounds:Rectangle;
		var filteredBounds:Rectangle;

		bitmap = renderToBitmap((cam, mat) ->
		{
			mat.setTo(1 / scale.x, 0, 0, 1 / scale.y, 0, 0);
			symbol.draw(cam, 0, null, mat, null, null, true, null);
			cam.render();

			bounds = cam.canvas.getBounds(null);
			var gfx = cam.canvas.graphics;

			if (filters != null && filters.length > 0)
				@:privateAccess
			{
				filters = filters.copy();
				var inflate = Rectangle.__pool.get();
				for (i => filter in filters)
				{
					if (filter == null)
						continue;

					var left:Float = 0.0; // filter.__leftExtension;
					var top:Float = 0.0; // filter.__topExtension;
					var right:Float = 0.0; // filter.__rightExtension;
					var bottom:Float = 0.0; // filter.__bottomExtension;

					if (filter is BlurFilter)
					{
						var blur:BlurFilter = cast filter.clone();
						filters[i] = blur;

						blur.blurX /= scale.x;
						blur.blurY /= scale.y;

						left = right = blur.blurX;
						top = bottom = blur.blurY;

						blur.blurX = Math.pow(blur.blurX, 0.6);
						blur.blurY = Math.pow(blur.blurY, 0.6);
					}
					else
					{
						left = filter.__leftExtension;
						top = filter.__topExtension;
						right = filter.__rightExtension;
						bottom = filter.__bottomExtension;
					}

					inflate.__expand(-left, -top, left + right, top + bottom);
				}

				var boundsX = bounds.x + inflate.x - scale.x;
				var boundsY = bounds.y + inflate.y - scale.y;

				gfx.__inflateBounds(boundsX, boundsY);
				gfx.__bounds.width += inflate.width;
				gfx.__bounds.height += inflate.height;

				Rectangle.__pool.release(inflate);
			}

			filteredBounds = cam.canvas.getBounds(null);
		});

		var frame = FlxGraphic.fromBitmapData(bitmap).imageFrame.frame;
		filterFrame(frame, filters);

		var mat = new FlxMatrix();
		mat.scale(scale.x, scale.y);

		symbol.matrix.identity();
		symbol.matrix.translate(filteredBounds.x * scale.x, filteredBounds.y * scale.y);

		var element = new AtlasInstance();
		element.frame = frame;
		element.matrix = mat;

		return element;
	}

	public static function filterFrame(frame:FlxFrame, ?filters:Array<BitmapFilter>):Void
	{
		if (filters == null || filters.length <= 0)
			return;

		var f = frame.frame;
		var filterFrame = new FlxFrame(FlxGraphic.fromRectangle(Math.ceil(f.width), Math.ceil(f.height), 0, true));

		var _filterBmp1:BitmapData = new BitmapData(filterFrame.parent.width, filterFrame.parent.height, 0);
		var _filterBmp2:BitmapData = null;

		var needsPreserveObject:Bool = false;
		for (filter in filters)
		{
			if (filter != null && filter.__preserveObject)
				needsPreserveObject = true;
		}

		if (needsPreserveObject)
			_filterBmp2 = new BitmapData(_filterBmp1.width, _filterBmp1.height, true, 0);
		filterFrame.parent.bitmap = __applyFilter(filterFrame.parent.bitmap, _filterBmp1, _filterBmp2, frame.parent.bitmap, filters);

		filterFrame.frame = FlxRect.get(0, 0, filterFrame.parent.bitmap.width, filterFrame.parent.bitmap.height);
		filterFrame.copyTo(frame);
	}

	static function __applyFilter(target:BitmapData, target1:BitmapData, ?target2:BitmapData, bmp:BitmapData, filters:Array<BitmapFilter>, ?point:Point)
	{
		if (filters == null || filters.length == 0)
			return bmp;

		renderer.__setBlendMode(NORMAL);
		renderer.__worldAlpha = 1;

		if (renderer.__worldTransform == null)
		{
			renderer.__worldTransform = new Matrix();
			renderer.__worldColorTransform = new ColorTransform();
		}

		renderer.__worldTransform.identity();
		renderer.__worldColorTransform.__identity();

		var bitmap:BitmapData = target;
		var bitmap2:BitmapData = target1;
		var bitmap3:BitmapData = target2;

		bmp.__renderTransform.identity();
		if (point != null)
			bmp.__renderTransform.translate(point.x, point.y);

		renderer.__setRenderTarget(bitmap);
		renderer.__renderFilterPass(bmp, renderer.__defaultDisplayShader, true);
		bmp.__renderTransform.identity();

		var shader:Shader = null;
		for (filter in filters)
		{
			if (filter == null)
				continue;

			var preserveObject = filter.__preserveObject;

			if (preserveObject)
			{
				renderer.__setRenderTarget(bitmap3);
				renderer.__renderFilterPass(bitmap, renderer.__defaultDisplayShader, filter.__smooth);
			}

			for (i in 0...filter.__numShaderPasses)
			{
				shader = filter.__initShader(renderer, i, preserveObject ? bitmap3 : null);
				renderer.__setBlendMode(filter.__shaderBlendMode);
				renderer.__setRenderTarget(bitmap2);
				renderer.__renderFilterPass(bitmap, shader, filter.__smooth);
				shader = null;

				renderer.__setRenderTarget(bitmap);
				renderer.__renderFilterPass(bitmap2, renderer.__defaultDisplayShader, filter.__smooth);
			}

			filter.__renderDirty = false;
		}

		var gl = renderer.__gl;
		var renderBuffer = bitmap.getTexture(renderer.__context3D);

		@:privateAccess
		gl.readPixels(0, 0, bitmap.width, bitmap.height, renderBuffer.__format, gl.UNSIGNED_BYTE, bitmap.image.data);
		bitmap.image.version = 0;
		bitmap.__textureVersion = -1;

		if (target1 != bitmap)
			FlxDestroyUtil.dispose(target1);

		FlxDestroyUtil.dispose(target2);

		return bitmap;
	}

	public static function renderWithShader(target:BitmapData, bitmap:BitmapData, shader:Shader):Void @:privateAccess
	{
		var renderer = FilterRenderer.renderer;
		renderer.__setRenderTarget(target);

		target.__renderTransform.identity();
		renderer.__renderFilterPass(bitmap, shader, true);

		var gl = renderer.__gl;
		var renderBuffer = target.getTexture(renderer.__context3D);

		gl.readPixels(0, 0, target.width, target.height, renderBuffer.__format, gl.UNSIGNED_BYTE, target.image.data);
		target.image.version = 0;
		target.__textureVersion = -1;
	}

	static var renderer(get, null):OpenGLRenderer;

	static function get_renderer()
		return (renderer != null) ? renderer : (renderer = __createRenderer());

	static function __createRenderer():OpenGLRenderer
	{
		var renderer = new OpenGLRenderer(FlxG.game.stage.context3D);
		renderer.__worldTransform = new Matrix();
		renderer.__worldColorTransform = new ColorTransform();
		return renderer;
	}
	#else
	// Basic Flash filter baking impl
	// NOTE: this is NOWHERE near done lol, still needs some work, its not really a priority for me though
	public static function bakeFilters(symbol:SymbolInstance, filters:Array<BitmapFilter>, scale:FlxPoint):AtlasInstance
	{
		var filteredBounds:FlxRect = symbol.getBounds(0);
		expandFilterBounds(filteredBounds, filters);

		var bitmap:BitmapData = getBitmap((cam, mat) -> symbol.draw(cam, 0, null, mat, null, null, true, null), filteredBounds);
		var frame = FlxGraphic.fromBitmapData(bitmap).imageFrame.frame;

		var rect = new Rectangle(0, 0, bitmap.width, bitmap.height);
		var point = new Point(0, 0);

		for (filter in filters)
			bitmap.applyFilter(bitmap, rect, point, filter);

		var mat = new FlxMatrix();
		mat.translate(filteredBounds.left, filteredBounds.top);
		var invertMat = symbol.matrix.clone();
		invertMat.invert();
		mat.concat(invertMat);

		var element = new AtlasInstance();
		element.frame = frame;
		element.matrix = mat;
		scale.put();

		return element;
	}

	public static function maskFrame(frame:Frame, currentFrame:Int, layer:Layer):Null<AtlasInstance>
	{
		var masker = layer.parentLayer;
		if (masker == null)
			return null;

		var maskerFrame = masker.getFrameAtIndex(currentFrame);
		if (maskerFrame == null)
			return null;

		var maskerBounds = maskerFrame.getBounds(currentFrame - maskerFrame.index);
		var masker = getBitmap((cam, mat) -> maskerFrame.draw(cam, currentFrame, mat, null, null, true, null), maskerBounds);

		var maskedBounds = frame.getBounds(currentFrame - frame.index);
		var masked = getBitmap((cam, mat) -> frame.draw(cam, currentFrame, mat, null, null, true, null), maskedBounds);

		var intersectX = Math.max(maskerBounds.x, maskedBounds.x);
		var intersectY = Math.max(maskerBounds.y, maskedBounds.y);
		var intersectWidth = Math.min(maskerBounds.right, maskedBounds.right) - intersectX;
		var intersectHeight = Math.min(maskerBounds.bottom, maskedBounds.bottom) - intersectY;

		var maskedBitmap = maskBitmap(masked, masker);
		var frame = FlxGraphic.fromBitmapData(maskedBitmap).imageFrame.frame;

		var element = new AtlasInstance();
		element.frame = frame;
		element.matrix = new FlxMatrix(1, 0, 0, 1, intersectX, intersectY);

		return element;
	}

	static function getBitmap(draw:(FlxCamera, FlxMatrix) -> Void, rect:FlxRect)
	{
		var cam = CamPool.get();
		cam.buffer.unlock();
		cam.buffer.fillRect(new Rectangle(0, 0, cam.buffer.width, cam.buffer.height), FlxColor.TRANSPARENT);

		var mat = new FlxMatrix();
		mat.translate(-rect.left, -rect.top);

		Frame.__isDirtyCall = true;
		draw(cam, mat);
		Frame.__isDirtyCall = false;

		var bitmap = new BitmapData(Std.int(rect.width), Std.int(rect.height), true, 0);
		bitmap.draw(cam.buffer, new Matrix(1, 0, 0, 1, 0, 0));
		cam.put();
		cam.buffer.lock();

		return bitmap;
	}

	static function maskBitmap(masked:BitmapData, masker:BitmapData):BitmapData
	{
		var width = Std.int(Math.min(masked.width, masker.width));
		var height = Std.int(Math.min(masked.height, masker.height));
		var result = new BitmapData(width, height, true, 0);

		masked.lock();
		masker.lock();
		result.lock();

		for (y in 0...height)
		{
			for (x in 0...width)
			{
				var maskColor:FlxColor = masker.getPixel32(x, y);
				var maskAlpha = maskColor.alphaFloat;
				if (maskAlpha <= 0)
					continue;

				var finalColor:FlxColor = masked.getPixel32(x, y);
				finalColor.alphaFloat *= maskAlpha;
				result.setPixel32(x, y, finalColor);
			}
		}

		masked.unlock();
		masker.unlock();
		result.unlock();

		return result;
	}
	#end

	public static function expandFilterBounds(baseBounds:FlxRect, filters:Array<BitmapFilter>)
	{
		var inflate = #if flash new Rectangle(); #else Rectangle.__pool.get(); #end
		for (filter in filters)
		{
			var __leftExtension = 0;
			var __topExtension = 0;
			var __bottomExtension = 0;
			var __rightExtension = 0;

			if (filter is BlurFilter)
			{
				var blur:BlurFilter = cast filter;
				__leftExtension = __rightExtension = (blur.blurX > 0 ? Math.ceil(blur.blurX) : 0);
				__topExtension = __bottomExtension = (blur.blurY > 0 ? Math.ceil(blur.blurY) : 0);
			}
			else if (filter is GlowFilter)
			{
				var glow:GlowFilter = cast filter;
				if (!glow.inner)
				{
					__leftExtension = __rightExtension = (glow.blurX > 0 ? Math.ceil(glow.blurX) : 0);
					__topExtension = __bottomExtension = (glow.blurY > 0 ? Math.ceil(glow.blurY) : 0);
				}
			}
			else if (filter is DropShadowFilter)
			{
				var dropShadow:DropShadowFilter = cast filter;
				var __offsetX = Std.int(dropShadow.distance * FlxMath.fastCos(dropShadow.angle * Math.PI / 180));
				var __offsetY = Std.int(dropShadow.distance * FlxMath.fastSin(dropShadow.angle * Math.PI / 180));
				__topExtension = Math.ceil((__offsetY < 0 ? -__offsetY : 0) + dropShadow.blurY);
				__bottomExtension = Math.ceil((__offsetY > 0 ? __offsetY : 0) + dropShadow.blurY);
				__leftExtension = Math.ceil((__offsetX < 0 ? -__offsetX : 0) + dropShadow.blurX);
				__rightExtension = Math.ceil((__offsetX > 0 ? __offsetX : 0) + dropShadow.blurX);
			}
			#if flash
			else if (filter is flash.filters.GradientGlowFilter)
			{
				var gradientGlow:flash.filters.GradientGlowFilter = cast filter;
				var __offsetX = Std.int(gradientGlow.distance * FlxMath.fastCos(gradientGlow.angle * Math.PI / 180));
				var __offsetY = Std.int(gradientGlow.distance * FlxMath.fastSin(gradientGlow.angle * Math.PI / 180));
				__topExtension = Math.ceil((__offsetY < 0 ? -__offsetY : 0) + gradientGlow.blurY);
				__bottomExtension = Math.ceil((__offsetY > 0 ? __offsetY : 0) + gradientGlow.blurY);
				__leftExtension = Math.ceil((__offsetX < 0 ? -__offsetX : 0) + gradientGlow.blurX);
				__rightExtension = Math.ceil((__offsetX > 0 ? __offsetX : 0) + gradientGlow.blurX);
			}
			#end

			inflate.x -= __leftExtension;
			inflate.width += __leftExtension + __rightExtension;
			inflate.y -= __topExtension;
			inflate.height += __topExtension + __bottomExtension;
		}

		baseBounds.x = Math.min(baseBounds.x, baseBounds.x + inflate.x);
		baseBounds.y = Math.min(baseBounds.y, baseBounds.y + inflate.y);
		baseBounds.width = Math.max(baseBounds.width, baseBounds.width + inflate.width);
		baseBounds.height = Math.max(baseBounds.height, baseBounds.height + inflate.height);

		#if !flash Rectangle.__pool.release(inflate); #end
	}
}

class CamPool extends FlxCamera implements IFlxPooled
{
	public static final pool:FlxPool<CamPool> = new FlxPool(PoolFactory.fromFunction(() -> new CamPool()));

	public static function get()
	{
		return pool.get();
	}

	public function put()
	{
		pool.putUnsafe(this);
	}

	override function destroy() {}
}
