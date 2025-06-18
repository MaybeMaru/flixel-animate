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
	var _filters:Array<BitmapFilter> = null;
	var _dirty:Bool = false;

	public function new(data:SymbolInstanceJson, parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent, frame);

		this.blend = #if flash Blend.resolveBlend(data.B); #else data.B; #end

		var jsonFilters = data.F;
		if (jsonFilters != null && jsonFilters.length > 0)
		{
			setFilters([for (filter in jsonFilters) filter.toBitmapFilter()]);
		}

		// Set whole frame for blending
		// if (this.blend != null && !Blend.isGpuSupported(this.blend))
		//	frame._dirty = true;
	}

	public function setFilters(filters:Array<BitmapFilter>):Void
	{
		this._filters = filters;
		this._dirty = true;
	}

	override function destroy()
	{
		super.destroy();
		_filters = null;
	}

	function bakeFilters(?filters:Array<BitmapFilter>):Void
	{
		if (filters == null || filters.length <= 0)
			return;

		var scale = FlxPoint.get(1, 1);

		for (filter in filters)
		{
			if (filter is BlurFilter)
			{
				var blur:BlurFilter = cast filter;
				scale.x *= Math.max(((blur.blurX) / 16) * (blur.quality * 1.75), 1);
				scale.y *= Math.max(((blur.blurY) / 16) * (blur.quality * 1.75), 1);
			}
		}

		bakedElement = FilterRenderer.bakeFilters(this, filters, scale);
		libraryItem = null;
		scale.put();
	}

	override function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader):Void
	{
		if (_dirty)
		{
			_dirty = false;
			bakeFilters(_filters);
		}

		super.draw(camera, index, tlFrame, parentMatrix, transform, blend, antialiasing, shader);
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix):FlxRect
	{
		var bounds = super.getBounds(frameIndex, rect, matrix);

		// baked element doesnt exist yet, gotta fake the bounds
		if (_dirty)
		{
			FilterRenderer.expandFilterBounds(bounds, _filters);
		}

		return bounds;
	}

	override function getFrameIndex(index:Int, frameIndex:Int):Int
	{
		return 0;
	}
}
