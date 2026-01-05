package animate.internal.elements;

import animate.FlxAnimateJson;
import animate.internal.elements.Element;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;

using flixel.util.FlxColorTransformUtil;

class SymbolInstance extends AnimateElement<SymbolInstanceJson>
{
	public var libraryItem:SymbolItem;
	public var firstFrame:Int = 0;
	public var loopType:LoopType = LOOP;
	public var symbolName(get, never):String;
	public var transformationPoint:FlxPoint;

	public function new(?data:SymbolInstanceJson, ?parent:FlxAnimateFrames, ?frame:Frame)
	{
		super(data, parent, frame);
		this.elementType = GRAPHIC;

		this.transformationPoint = FlxPoint.get();

		if (data == null)
			return;

		this.libraryItem = parent.getSymbol(data.SN);
		this.matrix = data.MX.toMatrix(this.matrix);
		this.firstFrame = data.FF;
		this.isColored = false;

		this.loopType = switch (data.LP)
		{
			case "PO" | "playonce": LoopType.PLAY_ONCE;
			case "SF" | "singleframe": LoopType.SINGLE_FRAME;
			default: LoopType.LOOP;
		}

		var trp:Null<PointJson> = data.TRP;
		if (trp != null)
			this.transformationPoint.set(trp.x, trp.y);
		else
			this.transformationPoint.set(0.0, 0.0);

		if (libraryItem == null)
			visible = false;

		var color = data.C;
		if (color != null)
		{
			switch (color.M)
			{
				case "AD" | "Advanced":
					setColorTransform(color.RM, color.GM, color.BM, color.AM, color.RO, color.GO, color.BO, color.AO);
				case "CA" | "Alpha":
					setColorTransform(1.0, 1.0, 1.0, color.AM, 0.0, 0.0, 0.0, 0.0);
				case "CBRT" | "Brightness":
					var brightness = color.BRT;
					var colorMult = 1.0 - Math.abs(brightness);
					var colorOff = brightness >= 0.0 ? brightness * 255.0 : 0.0;
					setColorTransform(colorMult, colorMult, colorMult, 1.0, colorOff, colorOff, colorOff, 0.0);
				case "T" | "Tint":
					var tint:FlxColor = FlxColor.fromString(color.TC);
					var tintMult:Float = color.TM;
					var mult:Float = 1.0 - tintMult;
					setColorTransform(mult, mult, mult, 1.0, tint.red * tintMult, tint.green * tintMult, tint.blue * tintMult, 0.0);
			}
		}
	}

	/**
	 * Returns the timeline frame index needed to be rendered at a specific frame, while taking loop types into consideration.
	 * @param index 		Index of the timeline to render.
	 * @param frameIndex 	Optional, relative frame index of the current keyframe the symbol instance is stored at.
	 * @return				Found frame index for rendering at a specific frame.
	 */
	public function getFrameIndex(index:Int, frameIndex:Int = 0):Int
	{
		var frameIndex = firstFrame + (index - frameIndex);
		var frameCount = libraryItem.timeline.frameCount;

		switch (loopType)
		{
			case LoopType.LOOP:
				frameIndex = FlxMath.wrap(frameIndex, 0, frameCount - 1);
			case LoopType.PLAY_ONCE:
				frameIndex = FlxMath.minInt(frameIndex, frameCount - 1);
			case LoopType.SINGLE_FRAME:
				frameIndex = firstFrame;
		}

		return frameIndex;
	}

	/**
	 * Method used internally to check if a symbol has simple rendering (one frame).
	 * @return If the symbol has simple rendering or not.
	 */
	public function isSimpleSymbol():Bool
	{
		var timeline = libraryItem.timeline;

		if (timeline.frameCount == 1)
			return true;

		if (loopType == SINGLE_FRAME)
			return true;

		// TODO: more indepth check through layers

		return false;
	}

	var _tmpMatrix:FlxMatrix = new FlxMatrix();

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, includeFilters:Bool = true, useCachedBounds:Bool = false):FlxRect
	{
		// TODO: look into this
		// Patch-on fix for a really weird fucking bug
		final name = symbolName;
		if (libraryItem != null && libraryItem.timeline.parent.existsSymbol(name))
			libraryItem = libraryItem.timeline.parent.getSymbol(name);

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
		return libraryItem.timeline.getBounds(getFrameIndex(frameIndex, 0), null, rect, targetMatrix, includeFilters, useCachedBounds);
	}

	override function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand):Void
	{
		if (command != null && command.onSymbolDraw != null)
			command.onSymbolDraw(this);

		drawCommand.prepareCommand(command, this);

		if (!drawCommand.isVisible())
			return;

		_drawTimeline(camera, index, frameIndex, parentMatrix, drawCommand);
	}

	function _drawTimeline(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand)
	{
		_mat.copyFrom(matrix);
		_mat.concat(parentMatrix);
		libraryItem.timeline.currentFrame = getFrameIndex(index, frameIndex);
		libraryItem.timeline.draw(camera, _mat, command);
	}

	inline function get_symbolName():String
	{
		return libraryItem != null ? libraryItem.name : "";
	}

	override function destroy()
	{
		super.destroy();
		transformationPoint = FlxDestroyUtil.put(transformationPoint);
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

enum abstract LoopType(Int) to Int
{
	var LOOP;
	var PLAY_ONCE;
	var SINGLE_FRAME;

	public function toString():String
	{
		return switch (cast this : LoopType)
		{
			case LOOP: "loop";
			case PLAY_ONCE: "play_once";
			case SINGLE_FRAME: "single_frame";
		}
	}
}
