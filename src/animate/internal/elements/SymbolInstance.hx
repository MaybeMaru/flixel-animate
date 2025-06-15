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
import openfl.display.BlendMode;
import openfl.display.Timeline;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.geom.ColorTransform;
import openfl.geom.Rectangle;

using flixel.util.FlxColorTransformUtil;

class SymbolInstance extends AnimateElement<SymbolInstanceJson>
{
	var libraryItem:SymbolItem;

	var blend:BlendMode;
	var firstFrame:Int;
	var loopType:String;
	var isMovieClip:Bool;

	var transform:ColorTransform;
	var _transform:ColorTransform;

	override function destroy()
	{
		super.destroy();
		libraryItem = null;
		transform = null;
		_transform = null;

		if (bakedElement != null)
		{
			bakedElement.frame.destroy();
			bakedElement = FlxDestroyUtil.destroy(bakedElement);
		}
	}

	public function new(data:SymbolInstanceJson, parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent);

		isSymbolInstance = true;
		libraryItem = parent.getSymbol(data.SN);
		this.matrix = data.MX.toMatrix();
		this.loopType = data.LP;
		this.isMovieClip = data.ST == "MC" || data.ST == "movieclip";

		var color = data.C;
		if (color != null)
		{
			transform = new ColorTransform();
			_transform = new ColorTransform();
			switch (color.M)
			{
				case "AD" | "Advanced":
					transform.setMultipliers(color.RM, color.GM, color.BM, color.AM);
					transform.setOffsets(color.RO, color.GO, color.BO, color.AO);
				case "CA" | "Alpha":
					transform.alphaMultiplier = color.AM;
				case "CBRT" | "Brightness":
					var brt = color.BRT * 255;
					transform.setOffsets(brt, brt, brt, 0);
				case "T" | "Tint":
					var m = color.TM;
					var c = FlxColor.fromString(color.TC);
					var mult = 1 - m;
					transform.setMultipliers(mult, mult, mult, 1);
					transform.setOffsets(c.red * m, c.green * m, c.blue * m, 0);
			}
		}

		if (isMovieClip)
		{
			this.blend = #if flash Blend.resolveBlend(data.B); #else data.B; #end
			this.filters = data.F;

			// Set filters dirty
			if (this.filters != null && this.filters.length > 0)
				_dirty = true;

			// Set whole frame for blending
			// if (this.blend != null && !Blend.isGpuSupported(this.blend))
			//	frame._dirty = true;
		}
		else
		{
			this.firstFrame = data.FF;
		}

		if (libraryItem == null)
			visible = false;
	}

	var bakedElement:AtlasInstance = null;

	var filters:Array<FilterJson> = null;
	var _dirty:Bool = false;

	function bakeFilters(?filters:Array<FilterJson>):Void
	{
		if (!isMovieClip || filters == null || filters.length <= 0)
			return;

		var bitmapFilters:Array<BitmapFilter> = [];
		var scale = FlxPoint.get(1, 1);

		for (filter in filters)
		{
			var bmFilter:BitmapFilter = null;
			switch (filter.N)
			{
				case "blurFilter" | "BLF":
					var quality:Int = filter.Q;
					var blurX:Float = filter.BLX * 0.75;
					var blurY:Float = filter.BLY * 0.75;

					bmFilter = new BlurFilter(blurX, blurY, quality);
					scale.x *= Math.max((blurX / 16) * (quality * 1.75), 1);
					scale.y *= Math.max((blurY / 16) * (quality * 1.75), 1);

				case "adjustColorFilter" | "ACF":
					var colorFilter = new AdjustColorFilter();
					colorFilter.set(filter.BRT, filter.H, filter.CT, filter.SAT);
					bmFilter = colorFilter.filter;

				default: // TODO: add missing filters
			}

			if (bmFilter != null)
				bitmapFilters.push(bmFilter);
		}

		bakedElement = FilterRenderer.bakeFilters(this, bitmapFilters, scale);
		libraryItem = null;
	}

	override function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader):Void
	{
		if (_dirty)
		{
			_dirty = false;
			bakeFilters(this.filters);
		}

		_mat.copyFrom(matrix);
		_mat.concat(parentMatrix);

		// Is colored
		if (this.transform != null)
		{
			var t = this.transform;
			_transform.setMultipliers(t.redMultiplier, t.greenMultiplier, t.blueMultiplier, t.alphaMultiplier);
			_transform.setOffsets(t.redOffset, t.greenOffset, t.blueOffset, t.alphaOffset);

			if (transform != null)
				_transform.concat(transform);

			transform = _transform;

			if (transform.alphaMultiplier <= 0)
				return;
		}

		final blend:Null<BlendMode> = this.blend ?? blend;

		if (isMovieClip && bakedElement != null && bakedElement.visible)
		{
			bakedElement.draw(camera, 0, null, _mat, transform, blend, antialiasing, shader);
			return;
		}

		libraryItem.timeline.currentFrame = getFrameIndex(index, isMovieClip ? 0 : tlFrame.index);
		libraryItem.timeline.draw(camera, _mat, transform, blend, antialiasing, shader);
	}

	function getFrameIndex(index:Int, frameIndex:Int):Int
	{
		if (isMovieClip)
			return 0;

		var frameIndex = firstFrame + (index - frameIndex);
		var frameCount = libraryItem.timeline.frameCount;

		switch (loopType)
		{
			case "LP" | "loop":
				frameIndex = FlxMath.wrap(frameIndex, 0, frameCount - 1);
			case "PO" | "playonce":
				frameIndex = Std.int(Math.min(frameIndex, frameCount - 1));
			case "SF" | "singleframe":
				frameIndex = firstFrame;
		}

		return frameIndex;
	}

	final tmpMatrix:FlxMatrix = new FlxMatrix();

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix):FlxRect
	{
		// Prepare the bounds matrix
		var targetMatrix:FlxMatrix;
		if (matrix != null)
		{
			tmpMatrix.copyFrom(this.matrix);
			tmpMatrix.concat(matrix);
			targetMatrix = tmpMatrix;
		}
		else
		{
			targetMatrix = this.matrix;
		}

		// Return baked bounds, if they exist
		if (bakedElement != null)
			return bakedElement.getBounds(0, rect, targetMatrix);

		var bounds = libraryItem.timeline.getBounds(getFrameIndex(frameIndex, 0), null, rect, targetMatrix);

		// baked element doesnt yet exist, gotta fake the bounds
		if (_dirty)
		{
			FilterRenderer.expandFilterBounds(bounds, this.filters);
		}

		// Get the bounds of the symbol item timeline
		return bounds;
	}

	public function toString():String
	{
		return '{name: ${libraryItem.name}, matrix: $matrix}';
	}
}
