package animate.internal;

import animate.FlxAnimateJson.TimelineJson;
import animate.internal.elements.*;
import flixel.FlxCamera;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
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

	var __layerMap:Map<String, Layer>;
	var parent:FlxAnimateFrames;

	public function new(timeline:TimelineJson, parent:FlxAnimateFrames, ?name:String)
	{
		layers = [];
		currentFrame = 0;
		this.parent = parent;

		if (name != null)
			this.name = name;

		var layersJson = timeline.L;

		__layerMap = [];
		for (layerJson in layersJson)
		{
			var layer = new Layer(this);
			layer.name = layerJson.LN;
			layers.unshift(layer);
			__layerMap.set(layer.name, layer);
		}

		for (i in 0...layersJson.length)
		{
			var layerIndex = layers.length - i - 1;
			var layer = layers[layerIndex];
			layer.__loadJson(layersJson[i], parent, layerIndex, layers);

			if (layer.frameCount > frameCount)
				frameCount = layer.frameCount;
		}
	}

	public function destroy():Void
	{
		parent = null;
		libraryItem = null;
		layers = FlxDestroyUtil.destroyArray(layers);
	}

	public function signalFrameChange(frameIndex:Int):Void
	{
		for (layer in layers)
		{
			var frame = layer.getFrameAtIndex(frameIndex);
			if (frame != null)
			{
				if (frame.sound != null && frame.index == frameIndex)
				{
					frame.sound.play(true);
				}
			}
		}
	}

	public function getLayer(name:String):Null<Layer>
	{
		return __layerMap.get(name);
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

	public function draw(camera:FlxCamera, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?antialiasing:Bool, ?shader:FlxShader)
	{
		for (layer in layers)
		{
			if (!layer.visible)
				continue;

			var frame = layer.getFrameAtIndex(currentFrame);
			if (frame == null)
				continue;

			frame.draw(camera, currentFrame, layer, parentMatrix, transform, blend, antialiasing, shader);
		}
	}

	public function getBounds(frameIndex:Int, ?includeHiddenLayers:Bool, ?rect:FlxRect, ?matrix:FlxMatrix):FlxRect
	{
		includeHiddenLayers ??= false;
		var tmpRect:FlxRect = FlxRect.get();
		rect ??= FlxRect.get();
		rect.set(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);

		for (layer in layers)
		{
			if (!layer.visible && !includeHiddenLayers)
				continue;

			var frame = layer.getFrameAtIndex(frameIndex);
			if (frame == null && frame.elements.length > 0)
				continue;

			var frameBounds = frame.getBounds(tmpRect, matrix);
			if (Math.isNaN(frameBounds.right) || Math.isNaN(frameBounds.bottom))
				continue;

			rect = expandBounds(rect, frameBounds);
		}

		if (rect.x == Math.POSITIVE_INFINITY
			|| rect.y == Math.POSITIVE_INFINITY
			|| rect.width == Math.NEGATIVE_INFINITY
			|| rect.height == Math.NEGATIVE_INFINITY)
		{
			rect.set(0, 0, 0, 0);
			if (matrix != null)
				rect.set(matrix.tx, matrix.ty, 0, 0);
		}

		tmpRect.put();
		return rect;
	}

	public function toString():String
	{
		return '{name: $name, frameCount: $frameCount}';
	}

	@:noCompletion
	public static function expandBounds(baseBounds:FlxRect, expandedBounds:FlxRect):FlxRect
	{
		baseBounds.x = Math.min(baseBounds.x, expandedBounds.x);
		baseBounds.y = Math.min(baseBounds.y, expandedBounds.y);

		baseBounds.width = Math.max(baseBounds.right, expandedBounds.right) - baseBounds.x;
		baseBounds.height = Math.max(baseBounds.bottom, expandedBounds.bottom) - baseBounds.y;
		return baseBounds;
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
