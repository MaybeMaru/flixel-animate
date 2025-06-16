package animate.internal.elements;

import animate.FlxAnimateJson;
import animate.internal.filters.*;
import flixel.FlxCamera;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.geom.ColorTransform;

class MovieClipInstance extends SymbolInstance
{
	var filters:Array<FilterJson> = null;
	var _dirty:Bool = false;

	public function new(data:SymbolInstanceJson, parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent, frame);

		this.blend = #if flash Blend.resolveBlend(data.B); #else data.B; #end
		this.filters = data.F;

		// Set filters dirty
		if (this.filters != null && this.filters.length > 0)
			_dirty = true;

		// Set whole frame for blending
		// if (this.blend != null && !Blend.isGpuSupported(this.blend))
		//	frame._dirty = true;
	}

	override function destroy()
	{
		super.destroy();
		filters = null;
	}

	function bakeFilters(?filters:Array<FilterJson>):Void
	{
		if (filters == null || filters.length <= 0)
			return;

		var bitmapFilters:Array<BitmapFilter> = [];
		var scale = FlxPoint.get(1, 1);

		for (i in 0...filters.length) // filter in filters)
		{
			var filter = filters[i];
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
		FlxDestroyUtil.put(scale);
	}

	override function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader):Void
	{
		if (_dirty)
		{
			_dirty = false;
			bakeFilters(this.filters);
		}

		super.draw(camera, index, tlFrame, parentMatrix, transform, blend, antialiasing, shader);
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix):FlxRect
	{
		var bounds = super.getBounds(frameIndex, rect, matrix);

		// baked element doesnt exist yet, gotta fake the bounds
		if (_dirty)
		{
			FilterRenderer.expandFilterBounds(bounds, this.filters);
		}

		return bounds;
	}

	override function getFrameIndex(index:Int, frameIndex:Int):Int
	{
		return 0;
	}
}
