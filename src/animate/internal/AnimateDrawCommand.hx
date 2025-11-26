package animate.internal;

import animate.internal.elements.SymbolInstance;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

class AnimateDrawCommand implements IFlxDestroyable
{
	public var transform:Null<ColorTransform> = null;
	public var blend:Null<BlendMode> = null;
	public var antialiasing:Null<Bool> = false;
	public var shader:Null<FlxShader> = null;
	public var onSymbolDraw:SymbolInstance->Void = null;

	public function new() {}

	public function prepareCommand(?command:AnimateDrawCommand, ?colorOut:ColorTransform, ?colorData:ColorTransform, blend:BlendMode):Void
	{
		// set some default data if parent command is null
		if (command == null)
		{
			this.transform = colorData;

			if (Frame.__isDirtyCall)
				this.blend = NORMAL
			else
				this.blend = blend;

			this.antialiasing = true;
			this.shader = null;
			this.onSymbolDraw = null;
			return;
		}

		// prepare color transform
		if (((colorData != null) && (colorOut != null)))
		{
			colorOut.setMultipliers(colorData.redMultiplier, colorData.greenMultiplier, colorData.blueMultiplier, colorData.alphaMultiplier);
			colorOut.setOffsets(colorData.redOffset, colorData.greenOffset, colorData.blueOffset, colorData.alphaOffset);

			if (command.transform != null)
				colorOut.concat(command.transform);

			this.transform = colorOut;
		}
		else
		{
			this.transform = command.transform;
		}

		// prepare blend
		if (Frame.__isDirtyCall)
			this.blend = NORMAL;
		else if (command.blend == null || command.blend == NORMAL)
			this.blend = blend;
		else
			this.blend = command.blend;

		// prepare other values
		this.antialiasing = command.antialiasing;
		this.shader = command.shader;
		this.onSymbolDraw = command.onSymbolDraw;
	}

	public inline function isVisible():Bool
	{
		return transform == null ? true : transform.alphaMultiplier > 0;
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
