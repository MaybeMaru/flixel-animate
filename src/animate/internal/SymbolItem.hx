package animate.internal;

import flixel.util.FlxDestroyUtil;

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
}
