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
import haxe.ds.Vector;
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
					case "MC" | "movieclip":
						new MovieClipInstance(element.SI, parent);
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
	var _bakedFrames:Array<AtlasInstance>;

	function bakeFrame(frameIndex:Int):Void
	{
		if (layer.parentLayer == null)
			return;

		if (_bakedFrames == null)
		{
			_bakedFrames = [];
			for (i in 0...duration)
				_bakedFrames.push(null);
		}

		if (_bakedFrames[frameIndex] != null)
			return;

		var bakedFrame:Null<AtlasInstance> = FilterRenderer.maskFrame(this, frameIndex + this.index, layer);
		if (bakedFrame == null)
			return;

		_bakedFrames[frameIndex] = bakedFrame;
		if (bakedFrame.frame.frame.isEmpty)
			bakedFrame.visible = false;

		if (_dirty)
		{
			if (_bakedFrames.indexOf(null) == -1)
				_dirty = false;
		}
	}

	inline function _checkDirty(currentFrame:Int)
	{
		if (_dirty && layer != null)
		{
			bakeFrame(currentFrame);
		}
	}

	public function forEachElement(callback:Element->Void):Void
	{
		for (element in elements)
			callback(element);
	}

	public function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix):FlxRect
	{
		rect ??= FlxRect.get();

		// Returns empty bounds if theres no elements in the frame
		if (elements.length <= 0)
		{
			(matrix != null) ? rect.set(matrix.tx, matrix.ty, 0, 0) : rect.set(0, 0, 0, 0);
			return rect;
		}

		// Get the filtered/masked bounds, if they exist
		if (_bakedFrames != null)
		{
			var bakedFrame = _bakedFrames[frameIndex];
			if (bakedFrame != null)
			{
				bakedFrame.getBounds(frameIndex, rect, matrix);
				return rect;
			}
		}

		var tmpRect = FlxRect.get();

		// Loop through the bounds of each element
		rect = elements[0].getBounds(frameIndex, rect, matrix);
		for (i in 1...elements.length)
		{
			tmpRect = elements[i].getBounds(frameIndex, tmpRect, matrix);
			rect = Timeline.expandBounds(rect, tmpRect);
		}

		// If the frame is not yet masked, calculate the masked bounds manually
		if (_dirty && this.layer.parentLayer != null)
		{
			tmpRect.set();
			var maskerBounds = this.layer.parentLayer.getBounds(frameIndex + this.index, tmpRect, matrix);
			Timeline.maskBounds(rect, maskerBounds);
		}

		tmpRect.put();
		return rect;
	}

	@:allow(animate.internal.FilterRenderer)
	@:allow(animate.internal.elements.AtlasInstance)
	private static var __isDirtyCall:Bool = false;

	public function draw(camera:FlxCamera, currentFrame:Int, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?antialiasing:Bool,
			?shader:FlxShader):Void
	{
		if (!__isDirtyCall)
			_checkDirty(currentFrame - this.index);

		if (_bakedFrames != null)
		{
			var bakedFrame = _bakedFrames[currentFrame - this.index];
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
