package animate.internal.elements;

import animate.FlxAnimateJson;
import flixel.FlxCamera;
import flixel.math.FlxMath;
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
	/**
	 * If to render the movieclip with the rendering method of Swf files.
	 * When turned off it renders like in the Animate program, with only the first frame getting rendered.
	 * When turn on it renders like in a Swf player, with all frames getting rendered (and baked).
	 */
	public var swfMode:Bool = false;

	@:allow(animate.internal.FilterRenderer)
	var _dirty:Bool = false;
	var _filters:Array<BitmapFilter> = null;
	var _bakedFrames:Array<AtlasInstance>;

	public function new(?data:SymbolInstanceJson, ?parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent, frame);

		this.elementType = MOVIECLIP;

		// Add settings from parent frames
		@:privateAccess {
			if (parent != null && parent._settings != null)
				swfMode = parent._settings.swfMode ?? false;
		}

		if (data == null)
			return;

		// Resolve blend mode
		this.blend = #if flash animate.internal.filters.Blend.fromInt(data.B); #else data.B; #end

		// Resolve and precache bitmap filters
		var jsonFilters = data.F;
		if (jsonFilters != null && jsonFilters.length > 0)
		{
			var filters:Array<BitmapFilter> = [];
			for (filter in jsonFilters)
			{
				var bmpFilter:Null<BitmapFilter> = filter.toBitmapFilter();
				if (bmpFilter != null)
					filters.push(bmpFilter);
			}

			setFilters(filters);
		}

		// Set whole frame for blending
		// if (this.blend != null && !Blend.isGpuSupported(this.blend))
		//	frame._dirty = true;
	}

	/**
	 * Changes the filters of the movieclip.
	 * Requires the movieclip to be rebaked when called.
	 *
	 * @param filters An array with ``BitmapFilter`` objects to apply to the movieclip.
	 */
	public function setFilters(filters:Array<BitmapFilter>):Void
	{
		this._filters = filters;
		this._dirty = true;

		if (_bakedFrames != null)
		{
			for (i in 0..._bakedFrames.length)
				_bakedFrames[i] = FlxDestroyUtil.destroy(_bakedFrames[i]);
		}
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true):FlxRect
	{
		var bounds = super.getBounds(frameIndex, rect, matrix, includeFilters);

		if (!includeFilters || _filters == null || _filters.length <= 0)
			return bounds;

		return FilterRenderer.expandFilterBounds(bounds, _filters);
	}

	function _bakeFilters(?filters:Array<BitmapFilter>, frameIndex:Int):Void
	{
		if (filters == null || filters.length <= 0)
		{
			_dirty = false;
			return;
		}

		if (_bakedFrames == null)
		{
			_bakedFrames = [];
			for (i in 0...this.libraryItem.timeline.frameCount)
				_bakedFrames.push(null);
		}

		if (_bakedFrames[frameIndex] != null)
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

		var bakedFrame:Null<AtlasInstance> = FilterRenderer.bakeFilters(this, frameIndex, filters, scale);
		scale.put();

		if (bakedFrame == null)
			return;

		_bakedFrames[frameIndex] = bakedFrame;
		if (bakedFrame.frame == null || bakedFrame.frame.frame.isEmpty)
			bakedFrame.visible = false;

		if (_dirty)
		{
			if (_bakedFrames.indexOf(null) == -1)
				_dirty = false;
		}
	}

	override function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader):Void
	{
		if (_dirty)
			_bakeFilters(_filters, getFrameIndex(index, tlFrame.index));

		super.draw(camera, index, tlFrame, parentMatrix, transform, blend, antialiasing, shader);
	}

	override function _drawTimeline(camera:FlxCamera, index:Int, frameIndex:Int, mat:FlxMatrix, transform:Null<ColorTransform>, blend:Null<BlendMode>,
			antialiasing:Null<Bool>, shader:Null<FlxShader>)
	{
		if (_bakedFrames != null)
		{
			var index = getFrameIndex(index, frameIndex);
			var bakedFrame = _bakedFrames[Std.int(FlxMath.bound(index, 0, _bakedFrames.length - 1))];

			if (bakedFrame != null)
			{
				if (bakedFrame.visible)
					bakedFrame.draw(camera, 0, null, mat, transform, blend, antialiasing, shader);
				return;
			}
		}

		super._drawTimeline(camera, index, frameIndex, mat, transform, blend, antialiasing, shader);
	}

	override function destroy()
	{
		super.destroy();
		_filters = null;
		_bakedFrames = FlxDestroyUtil.destroyArray(_bakedFrames);
	}

	override function getFrameIndex(index:Int, frameIndex:Int = 0):Int
	{
		return swfMode ? super.getFrameIndex(index, frameIndex) : 0;
	}
}
