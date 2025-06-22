package animate.internal.elements;

import animate.FlxAnimateJson;
import animate.internal.filters.*;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal;
import openfl.display.BlendMode;
import openfl.display.Timeline;
import openfl.filters.BitmapFilter;
import openfl.filters.BlurFilter;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

typedef Element = AnimateElement<Dynamic>;

class AnimateElement<T> implements IFlxDestroyable
{
	var _mat:FlxMatrix;

	public var matrix:FlxMatrix;
	public var visible:Bool;
	public var elementType:ElementType;

	public function new(data:T, parent:FlxAnimateFrames, ?frame:Frame)
	{
		_mat = new FlxMatrix();
		visible = true;
	}

	public function destroy()
	{
		_mat = null;
		matrix = null;
	}

	public function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?antialiasing:Bool,
		?shader:FlxShader):Void {}

	public inline function toSymbolInstance():SymbolInstance
		return cast this;

	public inline function toMovieClipInstance():MovieClipInstance
		return cast this;

	public inline function toAtlasInstance():AtlasInstance
		return cast this;

	public inline function toButtonInstance():ButtonInstance
		return cast this;

	public function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true):FlxRect
	{
		return rect ?? FlxRect.get();
	}
}

enum abstract ElementType(String) to String
{
	var ATLAS = "atlas";
	var GRAPHIC = "graphic";
	var MOVIECLIP = "movieclip";
	var BUTTON = "button";
}
