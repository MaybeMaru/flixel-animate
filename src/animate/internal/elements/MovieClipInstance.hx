package animate.internal.elements;

import animate.FlxAnimateFrames.FilterQuality;
import animate.FlxAnimateJson;
import animate.internal.elements.AtlasInstance;
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
	var _filterQuality:FilterQuality = FilterQuality.MEDIUM;
	var _bakedFrames:BakedFramesVector;

	public function new(?data:SymbolInstanceJson, ?parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent, frame);
		this.elementType = MOVIECLIP;

		// Add settings from parent frames
		var cacheOnLoad:Bool = false;
		@:privateAccess {
			if (parent != null && parent._settings != null)
			{
				swfMode = parent._settings.swfMode ?? false;
				cacheOnLoad = parent._settings.cacheOnLoad ?? false;
				_filterQuality = parent._settings.filterQuality ?? FilterQuality.MEDIUM;
			}
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

		// Cache all frames on start, if set by the settings
		if (cacheOnLoad && _dirty)
		{
			for (i in 0...this.libraryItem.timeline.frameCount)
				_bakeFilters(_filters, getFrameIndex(i, 0));
		}
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
			_bakedFrames.dispose();
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
			_bakedFrames = new BakedFramesVector(this.libraryItem.timeline.frameCount);

		if (_bakedFrames[frameIndex] != null)
			return;

		var scale = FlxPoint.get(1, 1);
		var pixelFactor:Float = _filterQuality.getPixelFactor();
		var qualityFactor:Float = _filterQuality.getQualityFactor();

		for (filter in filters)
		{
			if (filter is BlurFilter)
			{
				var blur:BlurFilter = cast filter;
				if (_filterQuality != FilterQuality.HIGH)
				{
					var qualityMult = FlxMath.remapToRange(blur.quality, 0, 3, 1, 3) * qualityFactor;
					scale.x *= Math.max(((blur.blurX) / pixelFactor) * qualityMult, 1);
					scale.y *= Math.max(((blur.blurY) / pixelFactor) * qualityMult, 1);
				}
			}
		}

		var bakedFrame:Null<AtlasInstance> = FilterRenderer.bakeFilters(this, frameIndex, filters, scale, _filterQuality);
		scale.put();

		if (bakedFrame == null)
			return;

		_bakedFrames[frameIndex] = bakedFrame;
		if (bakedFrame.frame == null || bakedFrame.frame.frame.isEmpty)
			bakedFrame.visible = false;

		// All frames have been baked
		if (_dirty && _bakedFrames.isFull())
			_dirty = false;
	}

	override function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader):Void
	{
		if (_dirty)
			_bakeFilters(_filters, getFrameIndex(index, tlFrame.index));

		super.draw(camera, index, tlFrame, parentMatrix, transform, blend, antialiasing, shader);
	}

	override function _drawTimeline(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, transform:Null<ColorTransform>,
			blend:Null<BlendMode>, antialiasing:Null<Bool>, shader:Null<FlxShader>)
	{
		if (_bakedFrames != null)
		{
			var index = getFrameIndex(index, frameIndex);
			var bakedFrame = _bakedFrames.findFrame(index);

			if (bakedFrame != null)
			{
				if (bakedFrame.visible)
					bakedFrame.draw(camera, 0, null, parentMatrix, transform, blend, antialiasing, shader);
				return;
			}
		}

		super._drawTimeline(camera, index, frameIndex, parentMatrix, transform, blend, antialiasing, shader);
	}

	override function destroy():Void
	{
		super.destroy();
		_filters = null;

		if (_bakedFrames != null)
		{
			_bakedFrames.dispose();
			_bakedFrames = null;
		}
	}

	override function getFrameIndex(index:Int, frameIndex:Int = 0):Int
	{
		return swfMode ? super.getFrameIndex(index, frameIndex) : 0;
	}
}

extern abstract BakedFramesVector(Array<AtlasInstance>)
{
	public inline function new(length:Int)
	{
		#if cpp
		this = cpp.NativeArray.create(length);
		#else
		this = [];
		for (i in 0...length)
			this.push(null);
		#end
	}

	public inline function isFull():Bool
	{
		return this.indexOf(null) == -1;
	}

	public inline function dispose():Void
	{
		for (i => frame in this)
		{
			if (frame == null)
				continue;

			// Manually clear the baked bitmaps
			if (frame.frame != null)
			{
				frame.frame.parent = FlxDestroyUtil.destroy(frame.frame.parent);
				frame.frame = FlxDestroyUtil.destroy(frame.frame);
			}

			this[i] = FlxDestroyUtil.destroy(frame);
		}
	}

	public inline function findFrame(index:Int):Null<AtlasInstance>
	{
		final max:Int = this.length - 1;
		final lowerBound:Int = (index < 0) ? 0 : index;
		return this[(lowerBound > max) ? max : lowerBound];
	}

	@:arrayAccess
	public inline function get(index:Int):AtlasInstance
		return this[index];

	@:arrayAccess
	public inline function set(index:Int, value:AtlasInstance):AtlasInstance
		return this[index] = value;
}
