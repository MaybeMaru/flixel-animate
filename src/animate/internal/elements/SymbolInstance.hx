package animate.internal.elements;

import animate.FlxAnimateJson;
import animate.internal.elements.Element;
import animate.internal.filters.Blend;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

class SymbolInstance extends AnimateElement<SymbolInstanceJson>
{
	public var libraryItem:SymbolItem;
	public var blend:BlendMode;
	public var firstFrame:Int;
	public var loopType:String;

	var isColored:Bool;
	var transform:ColorTransform;
	var _transform:ColorTransform;

	public function new(?data:SymbolInstanceJson, ?parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent);
		this.elementType = GRAPHIC;

		if (data == null)
			return;

		this.libraryItem = parent.getSymbol(data.SN);
		this.matrix = data.MX.toMatrix();
		this.loopType = data.LP;
		this.firstFrame = data.FF;
		this.isColored = false;

		if (libraryItem == null)
			visible = false;

		var color = data.C;
		if (color != null)
		{
			isColored = true;
			transform = new ColorTransform();
			_transform = new ColorTransform();
			switch (color.M)
			{
				case "AD" | "Advanced":
					transform.setMultipliers(color.RM, color.GM, color.BM, color.AM);
					transform.setOffsets(color.RO, color.GO, color.BO, color.AO);
				case "CA" | "Alpha":
					transform.alphaMultiplier = color.AM;
				case "CBRT" | "Brightness":
					var brt = color.BRT * 255.0;
					transform.setOffsets(brt, brt, brt, 0.0);
				case "T" | "Tint":
					var m = color.TM;
					var c = FlxColor.fromString(color.TC);
					var mult = 1.0 - m;
					transform.setMultipliers(mult, mult, mult, 1.0);
					transform.setOffsets(c.red * m, c.green * m, c.blue * m, 0.0);
			}
		}
	}

	/**
	 * Returns the timeline frame index needed to be rendered at a specific frameIndex
	 * @param index 		Index of the timeline to render.
	 * @param frameIndex 	Optional, relative frame index of the current keyframe the symbol instance is stored at.
	 */
	public function getFrameIndex(index:Int, frameIndex:Int = 0):Int
	{
		var frameIndex = firstFrame + (index - frameIndex);
		var frameCount = libraryItem.timeline.frameCount;

		switch (loopType)
		{
			case "LP" | "loop":
				frameIndex = FlxMath.wrap(frameIndex, 0, frameCount - 1);
			case "PO" | "playonce":
				frameIndex = FlxMath.minInt(frameIndex, frameCount - 1);
			case "SF" | "singleframe":
				frameIndex = firstFrame;
		}

		return frameIndex;
	}

	var _tmpMatrix:FlxMatrix = new FlxMatrix();

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true):FlxRect
	{
		// Prepare the bounds matrix
		var targetMatrix:FlxMatrix;
		if (matrix != null)
		{
			_tmpMatrix.copyFrom(this.matrix);
			_tmpMatrix.concat(matrix);
			targetMatrix = _tmpMatrix;
		}
		else
		{
			targetMatrix = this.matrix;
		}

		// Get the bounds of the symbol item timeline
		return libraryItem.timeline.getBounds(getFrameIndex(frameIndex, 0), null, rect, targetMatrix);
	}

	override function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader):Void
	{
		if (isColored) // Concat symbol's color to the current color transform
		{
			var t = this.transform;
			_transform.setMultipliers(t.redMultiplier, t.greenMultiplier, t.blueMultiplier, t.alphaMultiplier);
			_transform.setOffsets(t.redOffset, t.greenOffset, t.blueOffset, t.alphaOffset);

			if (transform != null)
				_transform.concat(transform);

			transform = _transform;

			if (transform.alphaMultiplier <= 0)
				return;
		}

		var b = Blend.resolve(this.blend, blend);
		var frameIndex = tlFrame != null ? tlFrame.index : 0;

		_drawTimeline(camera, index, frameIndex, parentMatrix, transform, b, antialiasing, shader);
	}

	function _drawTimeline(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, transform:Null<ColorTransform>, blend:Null<BlendMode>,
			antialiasing:Null<Bool>, shader:Null<FlxShader>)
	{
		_mat.copyFrom(matrix);
		_mat.concat(parentMatrix);
		libraryItem.timeline.currentFrame = getFrameIndex(index, frameIndex);
		libraryItem.timeline.draw(camera, _mat, transform, blend, antialiasing, shader);
	}

	override function destroy()
	{
		super.destroy();
		libraryItem = null;
		transform = null;
		_transform = null;
		_tmpMatrix = null;
	}

	public function toString():String
	{
		return '{name: ${libraryItem?.name}, matrix: $matrix}';
	}
}
