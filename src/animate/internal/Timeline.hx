package animate.internal;

import animate.FlxAnimateJson.TimelineJson;
import animate.internal.elements.*;
import flixel.FlxCamera;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import flixel.util.typeLimit.OneOfTwo;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

@:access(openfl.geom.Point)
@:access(openfl.geom.Matrix)
@:access(flixel.graphics.frames.FlxFrame)
class Timeline implements IFlxDestroyable
{
	public var libraryItem:SymbolItem;
	public var layers:Array<Layer>;
	public var name:String;
	public var currentFrame:Int;
	public var frameCount:Int;

	var _layerMap:Map<String, Layer>;
	var _bounds:FlxRect;
	var parent:FlxAnimateFrames;

	public function new(timeline:TimelineJson, parent:FlxAnimateFrames, ?name:String)
	{
		this.layers = [];
		this.currentFrame = 0;
		this.parent = parent;

		_layerMap = [];
		_bounds = FlxRect.get();

		if (name != null)
			this.name = name;

		_loadJson(timeline);
		_bounds = getWholeBounds(false, _bounds);
	}

	public function getLayer(name:OneOfTwo<Int, String>):Null<Layer>
	{
		return (name is String) ? _layerMap.get(name) : layers[name];
	}

	public function forEachLayer(callback:Layer->Void):Void
	{
		for (layer in layers)
			callback(layer);
	}

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

	public function getCurrentElements():Array<Element>
	{
		return getElementsAtIndex(currentFrame);
	}

	// Returns the whole bounds of the timeline
	public function getWholeBounds(?includeHiddenLayers:Bool = false, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true):FlxRect
	{
		var first:Bool = true;
		var tmpRect:FlxRect = FlxRect.get();
		rect ??= FlxRect.get();

		for (i in 0...this.frameCount)
		{
			var frameBounds = getBounds(i, includeHiddenLayers, tmpRect, matrix, includeFilters);
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

		// Apply matrix in case the rect is empty
		if (rect.isEmpty && matrix != null)
			rect.set(matrix.tx, matrix.ty, 0, 0);

		tmpRect.put();
		return rect;
	}

	// Returns the bounds of the timeline at a specific frame
	public function getBounds(frameIndex:Int, ?includeHiddenLayers:Bool = false, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true):FlxRect
	{
		var first:Bool = true;
		var tmpRect:FlxRect = FlxRect.get();

		rect ??= FlxRect.get();
		rect.set();

		for (layer in layers)
		{
			if (!layer.visible && !includeHiddenLayers)
				continue;

			// Get frame at the bounds index
			var frame = layer.getFrameAtIndex(frameIndex);
			if (frame == null || frame.elements.length <= 0)
				continue;

			// Get the bounds of the frame at the index
			var frameBounds = frame.getBounds((frameIndex - frame.index), tmpRect, matrix, includeFilters);
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

		// Apply matrix in case the rect is empty
		if (rect.isEmpty && matrix != null)
			rect.set(matrix.tx, matrix.ty, 0, 0);

		tmpRect.put();
		return rect;
	}

	@:allow(animate.FlxAnimateController)
	private function signalFrameChange(frameIndex:Int):Void
	{
		for (layer in layers)
		{
			var frame = layer.getFrameAtIndex(frameIndex);
			if (frame != null)
			{
				if (frame.sound != null && frame.index == frameIndex)
					frame.sound.play(true);
			}
		}
	}

	public function draw(camera:FlxCamera, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?antialiasing:Bool, ?shader:FlxShader)
	{
		for (layer in layers)
		{
			if (!layer.visible)
				continue;

			var frame = layer.getFrameAtIndex(currentFrame);
			if (frame == null)
				continue;

			frame.draw(camera, currentFrame, parentMatrix, transform, blend, antialiasing, shader);
		}
	}

	function _loadJson(timeline:TimelineJson)
	{
		var layersJson = timeline.L;

		for (layerJson in layersJson)
		{
			var layer = new Layer(this);
			layer.name = layerJson.LN;
			layers.unshift(layer);
			_layerMap.set(layer.name, layer);
		}

		for (i in 0...layersJson.length)
		{
			var layerIndex = layers.length - i - 1;
			var layer = layers[layerIndex];
			layer._loadJson(layersJson[i], parent, layerIndex, layers);

			if (layer.frameCount > frameCount)
				frameCount = layer.frameCount;
		}
	}

	public function destroy():Void
	{
		parent = null;
		libraryItem = null;
		layers = FlxDestroyUtil.destroyArray(layers);
		_bounds = FlxDestroyUtil.put(_bounds);
		_layerMap = null;
	}

	public function toString():String
	{
		return '{name: $name, frameCount: $frameCount}';
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
	public static function applyMatrixToRect(rect:FlxRect, matrix:FlxMatrix):FlxRect
	{
		var p1x = rect.left * matrix.a + rect.top * matrix.c + matrix.tx;
		var p1y = rect.left * matrix.b + rect.top * matrix.d + matrix.ty;
		var p2x = rect.right * matrix.a + rect.top * matrix.c + matrix.tx;
		var p2y = rect.right * matrix.b + rect.top * matrix.d + matrix.ty;
		var p3x = rect.left * matrix.a + rect.bottom * matrix.c + matrix.tx;
		var p3y = rect.left * matrix.b + rect.bottom * matrix.d + matrix.ty;
		var p4x = rect.right * matrix.a + rect.bottom * matrix.c + matrix.tx;
		var p4y = rect.right * matrix.b + rect.bottom * matrix.d + matrix.ty;

		var minX = Math.min(Math.min(p1x, p2x), Math.min(p3x, p4x));
		var minY = Math.min(Math.min(p1y, p2y), Math.min(p3y, p4y));
		var maxX = Math.max(Math.max(p1x, p2x), Math.max(p3x, p4x));
		var maxY = Math.max(Math.max(p1y, p2y), Math.max(p3y, p4y));

		rect.set(minX, minY, maxX - minX, maxY - minY);
		return rect;
	}
}
