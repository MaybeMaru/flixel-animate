package animate.internal;

import animate.internal.elements.ButtonInstance;
import animate.internal.elements.Element.ElementType;
import animate.internal.elements.MovieClipInstance;
import animate.internal.elements.SymbolInstance;
import flixel.FlxG;
import flixel.math.FlxMatrix;
import flixel.util.FlxDestroyUtil;
import openfl.display.MovieClip;
import openfl.geom.ColorTransform;

class SymbolItem implements IFlxDestroyable
{
	public var name:String;
	public var timeline:Timeline;

	public function new(timeline:Timeline)
	{
		this.timeline = timeline;
		this.timeline.libraryItem = this;
		this.name = timeline.name;
	}

	public function destroy():Void
	{
		timeline = FlxDestroyUtil.destroy(timeline);
	}

	public function toString():String
	{
		return '{name: $name}';
	}

	@:access(animate.internal.elements.SymbolInstance)
	public function createInstance(?type:ElementType = GRAPHIC):Null<SymbolInstance>
	{
		var instance:SymbolInstance;
		switch (type)
		{
			case GRAPHIC:
				instance = new SymbolInstance(null, null, null);
			case MOVIECLIP:
				instance = new MovieClipInstance(null, null, null);
			case BUTTON:
				instance = new ButtonInstance(null, null);
			default:
				FlxG.log.warn('Invalid Symbol Instance type.');
				return null;
		}

		instance.libraryItem = this;
		instance.matrix = new FlxMatrix();
		instance.loopType = "LP";
		instance.firstFrame = 0;
		instance.transform = new ColorTransform();
		instance._transform = new ColorTransform();
		return instance;
	}
}
