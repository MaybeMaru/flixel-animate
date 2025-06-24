package animate.internal.elements;

import flixel.FlxCamera;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
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
