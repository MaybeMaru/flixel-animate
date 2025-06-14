package animate.internal;

import animate.FlxAnimateJson.FrameJson;
import animate.internal.elements.*;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.display.Timeline;
import openfl.geom.ColorTransform;

class Frame implements IFlxDestroyable
{
	public var layer:Null<Layer>;
	public var elements:Array<Element>;
	public var index:Int;
	public var duration:Int;
	public var name:String;

	public function new(?layer:Layer)
	{
		this.elements = [];
		this.name = "";
		this.layer = layer;
		this.duration = 0;
		this.index = 0;
	}

	public var sound:Null<FlxSound>;

	@:allow(animate.internal.Layer)
	function __loadJson(frame:FrameJson, parent:FlxAnimateFrames):Void
	{
		this.index = frame.I;
		this.duration = frame.DU;
		this.name = frame.N ?? "";
		for (element in frame.E)
		{
			var si = element.SI;
			if (si != null)
			{
				this.elements.push(switch (si.ST)
				{
					case "B" | "button":
						new ButtonInstance(element.SI, parent);
					default:
						new SymbolInstance(element.SI, parent);
				});
			}
			else
			{
				this.elements.push(new AtlasInstance(element.ASI, parent));
			}
		}

		if (frame.SND != null)
		{
			sound = FlxG.sound.load(parent.path + '/LIBRARY/' + frame.SND.N);
		}
	}

	public function destroy():Void
	{
		elements = FlxDestroyUtil.destroyArray(elements);
		sound = FlxDestroyUtil.destroy(sound);
		layer = null;
	}

	@:allow(animate.internal.Layer)
	var _dirty:Bool = false;

	// TODO: maybe instead of a map this could be a vector
	// which turns off _dirty after its filled with baked masks
	var bakedFrames:Null<Map<Int, AtlasInstance>> = null;

	function bakeFrame(currentFrame:Int, layer:Layer):Void
	{
		if (layer.parentLayer == null)
			return;

		if (bakedFrames == null)
			bakedFrames = [];

		if (bakedFrames.exists(currentFrame))
			return;

		var bakedFrame = FilterRenderer.maskFrame(this, currentFrame, layer);
		bakedFrames.set(currentFrame, bakedFrame);

		if (bakedFrame != null && (bakedFrame.frame.frame.width <= 1 || bakedFrame.frame.frame.height <= 1))
			bakedFrame.visible = false;
	}

	public function forEachElement(callback:Element->Void):Void
	{
		for (element in elements)
			callback(element);
	}

	public function getBounds(?rect:FlxRect, ?matrix:FlxMatrix):FlxRect
	{
		var tmpRect = FlxRect.get();
		rect ??= FlxRect.get();
		rect.set(Math.POSITIVE_INFINITY, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, Math.NEGATIVE_INFINITY);

		for (element in elements)
		{
			tmpRect = element.getBounds(tmpRect, matrix);
			rect = Timeline.expandBounds(rect, tmpRect);
		}

		tmpRect.put();
		return rect;
	}

	public function draw(camera:FlxCamera, currentFrame:Int, layer:Layer, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader):Void
	{
		if (_dirty && layer != null)
		{
			bakeFrame(currentFrame, layer);
		}

		if (bakedFrames != null)
		{
			var bakedFrame = bakedFrames.get(currentFrame);
			if (bakedFrame != null)
			{
				if (bakedFrame.visible)
					bakedFrame.draw(camera, currentFrame, this, parentMatrix, transform, blend, antialiasing, shader);
				return;
			}
		}

		for (element in elements)
		{
			if (element.visible)
				element.draw(camera, currentFrame, this, parentMatrix, transform, blend, antialiasing, shader);
		}
	}

	public function toString():String
	{
		return '{name: "$name", index: $index, duration: $duration}';
	}
}
