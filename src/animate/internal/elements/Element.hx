package animate.internal.elements;

import animate.internal.AnimateDrawCommand;
import flixel.FlxCamera;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

typedef Element = AnimateElement<Dynamic>;

class AnimateElement<T> implements IFlxDestroyable
{
	public var blend:BlendMode;
	public var shader:FlxShader;
	public var matrix:FlxMatrix;
	public var visible:Bool;
	public var elementType(default, null):ElementType;
	public var parentFrame:Frame;

	public var isColored(default, null):Bool;

	@:noCompletion
	public var transform:ColorTransform;

	@:noCompletion
	public var _transform:ColorTransform;

	var _mat:FlxMatrix;

	var drawCommand:AnimateDrawCommand;

	public function new(?data:T, ?parent:FlxAnimateFrames, ?frame:Frame)
	{
		_mat = new FlxMatrix();
		matrix = new FlxMatrix();
		blend = null;
		parentFrame = frame;
		visible = true;

		drawCommand = new AnimateDrawCommand();
	}

	/**
	 * Returns the bounds of the element at a specific frame index.
	 *
	 * @param frameIndex			The frame index where to calculate the bounds from.
	 * @param rect					Optional, the rectangle used to input the final calculated values.
	 * @param matrix				Optional, the matrix to apply to the bounds calculation.
	 * @param includeFilters		Optional, if to include filtered bounds in the calculation or use the unfilitered ones (true to Flash's bounds).
	 * @return						A ``FlxRect`` with the complete frames's bounds at an index, empty if no elements were found.
	 */
	public function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, includeFilters:Bool = true, useCachedBounds:Bool = false):FlxRect
	{
		return rect ?? FlxRect.get();
	}

	public function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand):Void {}

	public extern overload inline function setColorTransform(rMult:Float = 1, gMult:Float = 1, bMult:Float = 1, aMult:Float = 1, rOffset:Float = 0,
			gOffset:Float = 0, bOffset:Float = 0, aOffset:Float = 0):Void
	{
		_setColorTransform(rMult, gMult, bMult, aMult, rOffset, gOffset, bOffset, aOffset);
	}

	public extern overload inline function setColorTransform(color:FlxColor):Void
	{
		_setColorTransform(color.redFloat, color.greenFloat, color.blueFloat, 1, 0, 0, 0, 0);
	}

	function _setColorTransform(rMult:Float, gMult:Float, bMult:Float, aMult:Float, rOffset:Float, gOffset:Float, bOffset:Float, aOffset:Float)
	{
		if (transform == null)
			transform = new ColorTransform();
		if (_transform == null)
			_transform = new ColorTransform();

		transform.setMultipliers(rMult, gMult, bMult, aMult);
		transform.setOffsets(rOffset, gOffset, bOffset, aOffset);
		isColored = (transform.hasRGBAMultipliers() || transform.hasRGBAOffsets());
	}

	public inline function toSymbolInstance():SymbolInstance
		return cast this;

	public inline function toMovieClipInstance():MovieClipInstance
		return cast this;

	public inline function toAtlasInstance():AtlasInstance
		return cast this;

	public inline function toButtonInstance():ButtonInstance
		return cast this;

	public inline function toTextFieldInstance():TextFieldInstance
		return cast this;

	public function destroy()
	{
		_mat = null;
		matrix = null;
		parentFrame = null;
		shader = null;
		drawCommand = FlxDestroyUtil.destroy(drawCommand);
	}
}

enum abstract ElementType(String) to String
{
	var ATLAS = "atlas";
	var GRAPHIC = "graphic";
	var MOVIECLIP = "movieclip";
	var BUTTON = "button";
	var TEXT = "text";
}
/*
	camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?antialiasing:Bool,
	?shader:FlxShader
 */ /*
	class ElementDrawCommand extends BaseDrawCommand
	{
	public var frameIndex:Int = 0;
	}
 */
