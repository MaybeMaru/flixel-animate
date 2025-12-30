package animate.internal;

import animate.internal.elements.Element;
import animate.internal.elements.SymbolInstance;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

/**
 * Used internally to store temporal data used between different texture atlas elements to render.
 * Created as a way to abstract and simplify the way draw data gets merged in one place.
 */
class AnimateDrawCommand implements IFlxDestroyable
{
	public var transform:Null<ColorTransform> = null;
	public var blend:Null<BlendMode> = null;
	public var antialiasing:Null<Bool> = false;
	public var shader:Null<FlxShader> = null;
	public var onSymbolDraw:SymbolInstance->Void = null;

	public function new() {}

	public function prepareCommand(?command:AnimateDrawCommand, element:Element)
	{
		// set some default data if parent command is null
		if (command == null)
		{
			this.transform = element.transform;

			if (Frame.__isDirtyCall)
				this.blend = NORMAL
			else
				this.blend = element.blend;

			this.antialiasing = true;
			this.shader = null;
			this.onSymbolDraw = null;
			return;
		}

		// prepare color transform
		if (element.isColored)
		{
			var colorData = element.transform;
			var colorOut = element._transform;
			colorOut.setMultipliers(colorData.redMultiplier, colorData.greenMultiplier, colorData.blueMultiplier, colorData.alphaMultiplier);
			colorOut.setOffsets(colorData.redOffset, colorData.greenOffset, colorData.blueOffset, colorData.alphaOffset);

			if (command.transform != null)
				concatTransform(colorOut, command.transform);

			this.transform = colorOut;
		}
		else
		{
			this.transform = command.transform;
		}

		// prepare blend
		this.blend = resolveBlendMode(command.blend, element.blend);

		// prepare shader
		if (element.shader != null)
			this.shader = element.shader;
		else
			this.shader = command.shader;

		// prepare other values
		this.antialiasing = command.antialiasing;
		this.onSymbolDraw = command.onSymbolDraw;
	}

	public static inline function resolveBlendMode(commandBlend:BlendMode, elementBlend:BlendMode)
	{
		var result = NORMAL;
		if (!Frame.__isDirtyCall)
		{
			if (commandBlend == null || commandBlend == NORMAL)
				result = elementBlend;
			else
				result = commandBlend;
		}
		return result;
	}

	public function isVisible():Bool
	{
		return transform == null ? true : transform.alphaMultiplier > 0;
	}

	// adding my own color transform concat because the operators used by openfl's function assigns more variables
	// i know its stupid but trust me on this one
	function concatTransform(first:ColorTransform, second:ColorTransform):Void
	{
		first.redOffset = second.redOffset * first.redMultiplier + first.redOffset;
		first.greenOffset = second.greenOffset * first.greenMultiplier + first.greenOffset;
		first.blueOffset = second.blueOffset * first.blueMultiplier + first.blueOffset;
		first.alphaOffset = second.alphaOffset * first.alphaMultiplier + first.alphaOffset;

		first.redMultiplier = first.redMultiplier * second.redMultiplier;
		first.greenMultiplier = first.greenMultiplier * second.greenMultiplier;
		first.blueMultiplier = first.blueMultiplier * second.blueMultiplier;
		first.alphaMultiplier = first.alphaMultiplier * second.alphaMultiplier;
	}

	public function destroy():Void
	{
		transform = null;
		blend = null;
		antialiasing = false;
		shader = null;
		onSymbolDraw = null;
	}
}
