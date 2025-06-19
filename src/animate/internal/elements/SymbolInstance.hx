package animate.internal.elements;

import animate.FlxAnimateJson;
import animate.internal.elements.Element;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

class SymbolInstance extends AnimateElement<SymbolInstanceJson>
{
	public var libraryItem:SymbolItem;
	public var blend:BlendMode;
	public var firstFrame:Int;
	public var loopType:String;

	var transform:ColorTransform;
	var _transform:ColorTransform;

	public function new(data:SymbolInstanceJson, parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent);

		isSymbolInstance = true;
		libraryItem = parent.getSymbol(data.SN);
		this.matrix = data.MX.toMatrix();
		this.loopType = data.LP;
		this.firstFrame = data.FF;

		var color = data.C;
		if (color != null)
		{
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

		if (libraryItem == null)
			visible = false;
	}

	override function destroy()
	{
		super.destroy();
		libraryItem = null;
		transform = null;
		_transform = null;
		tmpMatrix = null;

		if (bakedElement != null)
		{
			bakedElement.frame.destroy();
			bakedElement = FlxDestroyUtil.destroy(bakedElement);
		}
	}

	var bakedElement:AtlasInstance = null;
	var tmpMatrix:FlxMatrix = new FlxMatrix();

	override function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader):Void
	{
		_mat.copyFrom(matrix);
		_mat.concat(parentMatrix);

		// Is colored
		if (this.transform != null)
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

		var b:Null<BlendMode> = this.blend;
		if (b == null)
			b = blend;

		if (bakedElement != null && bakedElement.visible)
		{
			bakedElement.draw(camera, 0, null, _mat, transform, b, antialiasing, shader);
			return;
		}

		libraryItem.timeline.currentFrame = getFrameIndex(index, tlFrame != null ? tlFrame.index : 0);
		libraryItem.timeline.draw(camera, _mat, transform, b, antialiasing, shader);
	}

	function getFrameIndex(index:Int, frameIndex:Int):Int
	{
		var frameIndex = firstFrame + (index - frameIndex);
		var frameCount = libraryItem.timeline.frameCount;

		switch (loopType)
		{
			case "LP" | "loop":
				frameIndex = FlxMath.wrap(frameIndex, 0, frameCount - 1);
			case "PO" | "playonce":
				frameIndex = Std.int(Math.min(frameIndex, frameCount - 1));
			case "SF" | "singleframe":
				frameIndex = firstFrame;
		}

		return frameIndex;
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix):FlxRect
	{
		// Prepare the bounds matrix
		var targetMatrix:FlxMatrix;
		if (matrix != null)
		{
			tmpMatrix.copyFrom(this.matrix);
			tmpMatrix.concat(matrix);
			targetMatrix = tmpMatrix;
		}
		else
		{
			targetMatrix = this.matrix;
		}

		// Return baked bounds, if they exist
		if (bakedElement != null)
			return bakedElement.getBounds(0, rect, targetMatrix);

		// Get the bounds of the symbol item timeline
		return libraryItem.timeline.getBounds(getFrameIndex(frameIndex, 0), null, rect, targetMatrix);
	}

	public function toString():String
	{
		return '{name: ${libraryItem.name}, matrix: $matrix}';
	}
}
