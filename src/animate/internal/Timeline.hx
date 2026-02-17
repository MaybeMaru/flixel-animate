package animate.internal;

import animate.FlxAnimateJson.TimelineJson;
import animate.internal.elements.Element;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import flixel.util.typeLimit.OneOfTwo;

using StringTools;

@:access(openfl.geom.Point)
@:access(openfl.geom.Matrix)
@:access(flixel.graphics.frames.FlxFrame)
@:allow(animate.FlxAnimate)
class Timeline implements IFlxDestroyable
{
	public var libraryItem:SymbolItem;
	public var layers:Array<Layer>;
	public var name:String;
	public var currentFrame:Int;
	public var parent(default, null):FlxAnimateFrames;

	public var frameCount(get, null):Int;

	var _dirtyFrameCount:Bool = false;

	var _layerMap:Map<String, Layer>;
	var _bounds:FlxRect;

	public function new(?timeline:TimelineJson, parent:FlxAnimateFrames, ?name:String)
	{
		this.name = name ?? "";
		this.layers = [];
		this.currentFrame = 0;
		this.parent = parent;

		_layerMap = [];
		_bounds = FlxRect.get();

		if (timeline != null)
			_loadJson(timeline);
	}

	public function addNewLayer(?name:String, ?duration:Int)
	{
		var layer = new Layer(this);
		layer.name = name ?? "Layer_" + (layers.length + 1);

		var keyframe = new Frame(layer);
		keyframe.index = 0;
		keyframe.duration = FlxMath.maxInt(duration ?? this.frameCount, 1);

		@:privateAccess {
			layer.frames.push(keyframe);
			for (_ in 0...keyframe.duration)
				layer.frameIndices.push(0);
		}

		_layerMap.set(layer.name, layer);
		layers.push(layer);

		_dirtyFrameCount = true;

		return layer;
	}

	/**
	 * Returns a layer based on name or index.
	 *
	 * @param layer Index ``Int`` or name ``String`` of the layer.
	 * @return		The ``Layer`` found with that name or index, null if not found.
	 */
	public function getLayer(name:OneOfTwo<Int, String>):Null<Layer>
	{
		return (name is String) ? _layerMap.get(name) : layers[name];
	}

	/**
	 * Applies a function to all the layers of the timeline.
	 *
	 * @param callback The ``Layer->Void`` function to call for all the existing layers.
	 */
	public function forEachLayer(callback:Layer->Void):Void
	{
		for (layer in layers)
			callback(layer);
	}

	/**
	 * Returns the frames through all the layers of a timeline at a specific frame index.
	 * 
	 * @param index Frame index ``Int`` to get the frames objects from.
	 * @return		An array of all the ``Frame`` objects at a specific frame index.
	 */
	public function getFramesAtIndex(index:Int):Array<Frame>
	{
		var frames:Array<Frame> = [];
		for (layer in layers)
		{
			var frame = layer.getFrameAtIndex(index);
			if (frame != null)
				frames.push(frame);
		}
		return frames;
	}

	/**
	 * Returns the elements through all the layers of a timeline at a specific frame index.
	 * 
	 * @param index Frame index ``Int`` to get the element objects from.
	 * @return		An array of all the ``Element`` objects at a specific frame index.
	 */
	public function getElementsAtIndex(index:Int):Array<Element>
	{
		var elements:Array<Element> = [];
		for (layer in layers)
		{
			var frame = layer.getFrameAtIndex(index);
			if (frame != null)
			{
				for (element in frame.elements)
					elements.push(element);
			}
		}
		return elements;
	}

	/**
	 * Returns an array of all the elements at the current frame displayed on the timeline.
	 * May be innacurate if theres more than one ``FlxAnimate`` object playing the same timeline.
	 * 
	 * For accuracy of your specific needs, I recommend using ``getElementsAtIndex`` more.
	 *
	 * @return An array of all the ``Element`` objects at the current frame.
	 */
	public function getCurrentElements():Array<Element>
	{
		return getElementsAtIndex(currentFrame);
	}

	/**
	 * Returns the first frame label in the timeline at a specific frame index.
	 * 
	 * @param index Frame index ``Int`` to get the element objects from.
	 * @return		Label ``String`` of the specific frame index, an empty string if not found.
	 */
	public function getFrameLabelAtIndex(index:Int):String
	{
		for (layer in layers)
		{
			var frame = layer.getFrameAtIndex(index);
			if (frame != null && frame.name.length > 0)
				return frame.name;
		}
		return "";
	}

	/**
	 * Gets the list of indices of a frame label to be found from a timeline.
	 *
	 * @param label Frame label tag to find the indices of.
	 * @return Array of ``Int`` indices of the frame label, empty if none were found.
	 */
	public function findFrameLabelIndices(label:String):Array<Int>
	{
		var foundFrames:Array<Int> = [];
		var hasFoundLabel:Bool = false;

		for (layer in layers)
		{
			for (frame in layer.frames)
			{
				if (frame.name.rtrim() == label)
				{
					hasFoundLabel = true;

					for (i in 0...frame.duration)
						foundFrames.push(frame.index + i);
				}
			}

			if (hasFoundLabel)
				break;
		}

		return foundFrames;
	}

	/**
	 * Returns the top-left position of the timeline, based on it's bounds.
	 * Useful as an offset value when migrating from a legacy bounds based project.
	 *
	 * @param result 			Optional, point where to store the origin data.
	 * @param applyStageMatrix	Optional, if to apply the stage matrix scaling to the result bounds (needed to replicate legacy bounds).
	 * @return 					A ``FlxPoint`` containing the origin point of the bounds top-left position.
	 */
	public function getBoundsOrigin(?result:FlxPoint, ?applyStageMatrix:Bool = false):FlxPoint
	{
		result ??= FlxPoint.get();
		result.set(_bounds.x, _bounds.y);

		if (applyStageMatrix && parent?.matrix != null)
		{
			result.x *= parent.matrix.a;
			result.y *= parent.matrix.d;
		}

		return result;
	}

	/**
	 * Returns the complete bounds of the timeline throught all the frames.
	 *
	 * @param includeHiddenLayers	If to include in the calculation layers currently invisible.
	 * @param rect					Optional, the rectangle used to input the final calculated values.
	 * @param matrix				Optional, the matrix to apply to the bounds calculation.
	 * @param includeFilters		Optional, if to include filtered bounds in the calculation or use the unfilitered ones (true to Flash's bounds).
	 *								But, in case the user changed something from the Texture Atlas, a recache may be needed.
	 * @return						A ``FlxRect`` with the complete timeline's bounds, empty if no elements were found.
	 */
	public function getWholeBounds(?includeHiddenLayers:Bool = false, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true):FlxRect
	{
		var first:Bool = true;
		var tmpRect:FlxRect = FlxRect.get();
		rect ??= FlxRect.get();

		for (i in 0...this.frameCount)
		{
			var frameBounds = getBounds(i, includeHiddenLayers, tmpRect, null, includeFilters, true);
			if (frameBounds.isEmpty)
				continue;

			if (first)
			{
				rect.copyFrom(frameBounds);
				first = false;
			}
			else
				rect = expandBounds(rect, frameBounds);
		}

		applyMatrixToRect(rect, matrix);

		tmpRect.put();
		return rect;
	}

	var _cachedBounds:Map<Int, FlxRect> = [];

	/**
	 * Returns the bounds of the timeline at a specific frame index.
	 *
	 * @param frameIndex			The frame index where to calculate the bounds from.
	 * @param includeHiddenLayers	If to include in the calculation layers currently invisible.
	 * @param rect					Optional, the rectangle used to input the final calculated values.
	 * @param matrix				Optional, the matrix to apply to the bounds calculation.
	 * @param includeFilters		Optional, if to include filtered bounds in the calculation or use the unfilitered ones (true to Flash's bounds).
	 * @param useCachedBounds		Optional, if to use previously cached bounds. Greatly improves the performance of the function, but wont work
	 * 								if something from the Texture Atlas was manually changed by the user in code (i.e. frames, matrices, etc)
	 * @return						A ``FlxRect`` with the timeline's bounds at an index, empty if no elements were found.
	 */
	public function getBounds(frameIndex:Int, ?includeHiddenLayers:Bool = false, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true,
			?useCachedBounds:Bool = false):FlxRect
	{
		rect ??= FlxRect.get();
		rect.set();

		if (useCachedBounds)
		{
			if (_cachedBounds.exists(frameIndex))
			{
				rect.copyFrom(_cachedBounds.get(frameIndex));
				return applyMatrixToRect(rect, matrix);
			}
		}

		var first:Bool = true;
		var tmpRect:FlxRect = FlxRect.get();

		for (layer in layers)
		{
			if (!layer.visible && !includeHiddenLayers)
				continue;

			// Get frame at the bounds index
			var frame = layer.getFrameAtIndex(frameIndex);
			if (frame == null || frame.elements.length <= 0)
				continue;

			// Get the bounds of the frame at the index
			var frameBounds = frame.getBounds((frameIndex - frame.index), tmpRect, null, includeFilters, useCachedBounds);
			if (frameBounds.isEmpty)
				continue;

			if (first)
			{
				first = false;
				rect.copyFrom(frameBounds);
			}
			else
				expandBounds(rect, frameBounds);
		}

		applyMatrixToRect(rect, matrix);

		if (useCachedBounds)
			_cachedBounds.set(frameIndex, rect.copyTo(FlxRect.get()));

		tmpRect.put();
		return rect;
	}

	/**
	 * Use this function to clear the currently cached timeline bounds.
	 *
	 * Some functions like ``getWholeBounds`` require the use of cached bounds to greatly save on performance.
	 * However, if the user changed something about the Texture Atlas, a recache of those bounds may be neccesary.
	 */
	public function clearBoundsCache():Void
	{
		for (i in _cachedBounds.iterator())
			i.put();
		_cachedBounds.clear();
	}

	public inline function iterator()
	{
		return layers.iterator();
	}

	public inline function keyValueIterator()
	{
		return layers.keyValueIterator();
	}

	@:allow(animate.FlxAnimateController)
	@:allow(animate.internal.elements.SymbolInstance)
	private function signalFrameChange(index:Int, animation:FlxAnimateController):Void
	{
		for (layer in layers)
		{
			var frame = layer.getFrameAtIndex(index);
			if (frame != null)
			{
				var isKeyFrame:Bool = (frame.index == index);
				if (isKeyFrame)
				{
					if (frame.sound != null)
						frame.sound.play(true);

					if (frame.name.length > 0)
						animation.onFrameLabel.dispatch(frame.name);
				}
			}
		}
	}

	public function draw(camera:FlxCamera, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand)
	{
		var i = layers.length - 1;
		while (i >= 0)
		{
			var layer = layers[i--];
			if (!layer.visible)
				continue;

			var frame = layer.getFrameAtIndex(currentFrame);
			if (frame == null)
				continue;

			frame.draw(camera, currentFrame, parentMatrix, command);
		}
	}

	function _loadJson(timeline:TimelineJson)
	{
		var layersJson = timeline.L;

		for (layerJson in layersJson)
		{
			var layer = new Layer(this);
			layer.name = layerJson.LN;
			layers.push(layer);
			_layerMap.set(layer.name, layer);
		}

		for (i in 0...layersJson.length)
		{
			var layer = layers[i];
			layer._loadJson(layersJson[i], parent, i, layers);
		}

		refresh();
	}

	@:noCompletion
	public function refresh():Void
	{
		_dirtyFrameCount = true;
		_bounds = getWholeBounds(false, _bounds);
	}

	public function destroy():Void
	{
		parent = null;
		libraryItem = null;
		layers = FlxDestroyUtil.destroyArray(layers);
		_bounds = FlxDestroyUtil.put(_bounds);
		_layerMap = null;

		if (_cachedBounds != null)
		{
			clearBoundsCache();
			_cachedBounds = null;
		}
	}

	public function toString():String
	{
		return '{name: $name, frameCount: $frameCount}';
	}

	function get_frameCount():Int
	{
		if (!_dirtyFrameCount)
			return frameCount;

		for (layer in layers)
		{
			if (layer.frameCount > frameCount)
				frameCount = layer.frameCount;
		}

		_dirtyFrameCount = false;
		return frameCount;
	}

	@:noCompletion
	public static inline function expandBounds(baseBounds:FlxRect, expandedBounds:FlxRect):FlxRect
	{
		var x = Math.min(baseBounds.x, expandedBounds.x);
		var y = Math.min(baseBounds.y, expandedBounds.y);
		var w = Math.max(baseBounds.right, expandedBounds.right) - x;
		var h = Math.max(baseBounds.bottom, expandedBounds.bottom) - y;

		baseBounds.set(x, y, w, h);
		return baseBounds;
	}

	@:noCompletion
	public static inline function maskBounds(masked:FlxRect, masker:FlxRect):FlxRect
	{
		if (masker.isEmpty)
			return masked;

		var x1:Float = Math.max(masked.x, masker.x);
		var y1:Float = Math.max(masked.y, masker.y);
		var x2:Float = Math.min(masked.right, masker.right);
		var y2:Float = Math.min(masked.bottom, masker.bottom);

		if (x2 <= x1 || y2 <= y1)
		{
			masked.set(0.0, 0.0, 0.0, 0.0);
			return masked;
		}

		masked.set(x1, y1, x2 - x1, y2 - y1);
		return masked;
	}

	@:noCompletion
	public static function applyMatrixToRect(rect:FlxRect, ?m:FlxMatrix):FlxRect
	{
		if (m == null)
			return rect;

		if (rect.isEmpty)
			return rect.set(m.tx, m.ty, 0, 0);

		var tx0 = m.a * rect.left + m.c * rect.top;
		var tx1 = tx0;
		var ty0 = m.b * rect.left + m.d * rect.top;
		var ty1 = ty0;

		var tx = m.a * rect.right + m.c * rect.top;
		var ty = m.b * rect.right + m.d * rect.top;

		if (tx < tx0)
			tx0 = tx;
		if (ty < ty0)
			ty0 = ty;
		if (tx > tx1)
			tx1 = tx;
		if (ty > ty1)
			ty1 = ty;

		tx = m.a * rect.right + m.c * rect.bottom;
		ty = m.b * rect.right + m.d * rect.bottom;

		if (tx < tx0)
			tx0 = tx;
		if (ty < ty0)
			ty0 = ty;
		if (tx > tx1)
			tx1 = tx;
		if (ty > ty1)
			ty1 = ty;

		tx = m.a * rect.left + m.c * rect.bottom;
		ty = m.b * rect.left + m.d * rect.bottom;

		if (tx < tx0)
			tx0 = tx;
		if (ty < ty0)
			ty0 = ty;
		if (tx > tx1)
			tx1 = tx;
		if (ty > ty1)
			ty1 = ty;

		rect.set(tx0 + m.tx, ty0 + m.ty, tx1 - tx0, ty1 - ty0);
		return rect;
	}

	var drawCommand:AnimateDrawCommand = new AnimateDrawCommand();
}
