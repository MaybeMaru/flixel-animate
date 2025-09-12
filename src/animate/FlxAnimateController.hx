package animate;

import animate.internal.Timeline;
import flixel.FlxG;
import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;
import flixel.graphics.frames.FlxFrame;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSignal.FlxTypedSignal;

using StringTools;

@:access(animate.FlxAnimate)
class FlxAnimateController extends FlxAnimationController
{
	/**
	 * Dispatches each time the current animation's frame label changes.
	 * Exclusive to Texture Atlas animations.
	 *
	 * @param frameLabel The label of the current frame
	 */
	public final onFrameLabel = new FlxTypedSignal<(frameLabel:String) -> Void>();

	public function addByFrameLabel(name:String, label:String, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool, ?timeline:Timeline):Void
	{
		if (!isAnimate)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		var usedTimeline = timeline ?? getDefaultTimeline();
		var foundFrames = findFrameLabelIndices(label, usedTimeline);

		if (foundFrames.length <= 0)
		{
			var collectionTimelines = getCollectionTimelines();
			if (collectionTimelines.length > 0)
			{
				for (timeline in collectionTimelines)
				{
					var newFrames = findFrameLabelIndices(label, timeline);
					if (newFrames.length > 0)
					{
						FlxG.log.notice('Found frame label ${label} in timeline ${timeline.name} from another texture atlas');
						foundFrames = newFrames;
						usedTimeline = timeline;
						break;
					}
				}
			}
			else
			{
				FlxG.log.warn('No frames found with label "$label" in timeline "${usedTimeline.name}".');
				return;
			}
		}

		frameRate ??= getDefaultFramerate();

		var anim = new FlxAnimateAnimation(this, name, foundFrames, frameRate, looped, flipX, flipY);
		anim.timeline = usedTimeline;
		_animations.set(name, anim);
	}

	public function addByFrameLabelIndices(name:String, label:String, indices:Array<Int>, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool,
			?timeline:Timeline)
	{
		if (!isAnimate)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		var usedTimeline = timeline ?? getDefaultTimeline();
		var foundFrames:Array<Int> = findFrameLabelIndices(label, usedTimeline);
		var useableFrames:Array<Int> = [];

		if (foundFrames.length <= 0)
		{
			var collectionTimelines = getCollectionTimelines();
			if (collectionTimelines.length > 0)
			{
				for (timeline in collectionTimelines)
				{
					var newFrames = findFrameLabelIndices(label, timeline);
					if (newFrames.length > 0)
					{
						FlxG.log.notice('Found frame label ${label} in timeline ${timeline.name} from another texture atlas');
						foundFrames = newFrames;
						usedTimeline = timeline;
						break;
					}
				}
			}
		}

		for (index in indices)
		{
			var frameIndex:Null<Int> = foundFrames[index];
			if (frameIndex != null)
				useableFrames.push(frameIndex);
		}

		if (useableFrames.length <= 0)
		{
			FlxG.log.warn('No frames useable with label "$label" and indices $indices in timeline "${usedTimeline.name}".');
			return;
		}

		frameRate ??= getDefaultFramerate();

		var anim = new FlxAnimateAnimation(this, name, useableFrames, frameRate, looped, flipX, flipY);
		anim.timeline = usedTimeline;
		_animations.set(name, anim);
	}

	public function addByTimeline(name:String, timeline:Timeline, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool):Void
	{
		if (!isAnimate)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		addByTimelineIndices(name, timeline, [for (i in 0...timeline.frameCount) i], frameRate, looped, flipX, flipY);
	}

	public function addByTimelineIndices(name:String, timeline:Timeline, indices:Array<Int>, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool,
			?flipY:Bool):Void
	{
		if (!isAnimate)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		frameRate ??= getDefaultFramerate();
		var anim = new FlxAnimateAnimation(this, name, indices, frameRate, looped, flipX, flipY);
		anim.timeline = timeline;
		_animations.set(name, anim);
	}

	public function addBySymbol(name:String, symbolName:String, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool):Void
	{
		if (!isAnimate)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		var symbol = _animate.library.getSymbol(symbolName);
		if (symbol == null)
		{
			FlxG.log.warn('Symbol not found with name "$symbolName"');
			return;
		}

		frameRate ??= getDefaultFramerate();

		var anim = new FlxAnimateAnimation(this, name, [for (i in 0...symbol.timeline.frameCount) i], frameRate, looped, flipX, flipY);
		anim.timeline = symbol.timeline;
		_animations.set(name, anim);
	}

	public function addBySymbolIndices(name:String, symbolName:String, indices:Array<Int>, ?frameRate:Float, ?looped:Bool = true, ?flipX:Bool, ?flipY:Bool):Void
	{
		if (!isAnimate)
		{
			FlxG.log.warn('Sprite is not loaded with a texture atlas.');
			return;
		}

		var symbol = _animate.library.getSymbol(symbolName);
		if (symbol == null)
		{
			FlxG.log.warn('Symbol not found with name "$symbolName"');
			return;
		}

		frameRate ??= getDefaultFramerate();

		var anim = new FlxAnimateAnimation(this, name, indices, frameRate, looped, flipX, flipY);
		anim.timeline = symbol.timeline;
		_animations.set(name, anim);
	}

	public function findFrameLabelIndices(label:String, ?timeline:Timeline):Array<Int>
	{
		var foundFrames:Array<Int> = [];
		var hasFoundLabel:Bool = false;
		var mainTimeline = timeline ?? getDefaultTimeline();

		for (layer in mainTimeline.layers)
		{
			for (frame in layer.frames)
			{
				if (frame.name.rtrim() == label)
				{
					hasFoundLabel = true;

					for (i in 0...frame.duration)
						foundFrames.push(frame.index + i);
				}
			}

			if (hasFoundLabel)
				break;
		}

		return foundFrames;
	}

	var animateFrame:FlxFrame;

	public function new(sprite:FlxAnimate)
	{
		super(sprite);
	}

	override function set_frameIndex(frame:Int):Int
	{
		if (!isAnimate)
			return super.set_frameIndex(frame);

		if (numFrames > 0)
		{
			frame = frame % numFrames;
			_animate.timeline = cast(_curAnim, FlxAnimateAnimation).timeline;
			_animate.timeline.currentFrame = frame;
			_animate.timeline.signalFrameChange(frame, this);
			frameIndex = frame;
			fireCallback();

			updateTimelineBounds();
		}

		return frameIndex;
	}

	@:allow(animate.FlxAnimate)
	function updateTimelineBounds():Void
	{
		if (animateFrame == null)
		{
			@:privateAccess // FlxFrame constructor used to be private
			animateFrame = new FlxFrame(_animate.graphic);
			animateFrame.frame = FlxRect.get();
		}

		@:privateAccess
		var bounds = _animate.timeline._bounds;
		animateFrame.parent = _animate.graphic;
		animateFrame.sourceSize.set(bounds.width, bounds.height);

		if (_animate.applyStageMatrix)
			animateFrame.sourceSize.scale(_animate.library.matrix.a, _animate.library.matrix.d);

		animateFrame.frame.copyFrom(bounds);
		_animate.frame = animateFrame;
	}

	override function play(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		var anim = _animations.get(animName);
		if (anim != null)
		{
			@:privateAccess
			_animate.isAnimate = anim is FlxAnimateAnimation;
		}

		super.play(animName, force, reversed, frame);
	}

	var _animate(get, never):FlxAnimate;

	inline function get__animate():FlxAnimate
		return cast _sprite;

	var isAnimate(get, never):Bool;

	inline function get_isAnimate()
		return _animate.isAnimate;

	public inline function getDefaultFramerate():Float
		return _animate.library.frameRate;

	public inline function getDefaultTimeline():Timeline
		return _animate.library.timeline;

	public inline function getCollectionTimelines():Array<Timeline> {
		var timelines:Array<Timeline> = [];

		@:privateAccess
		for (collection in _animate.library.addedCollections)
		{
			timelines.push(collection.timeline);
		}

		return timelines;
	}

	override function destroy()
	{
		super.destroy();
		animateFrame = FlxDestroyUtil.destroy(animateFrame);
		FlxDestroyUtil.destroy(onFrameLabel);
	}
}

class FlxAnimateAnimation extends FlxAnimation
{
	public var timeline:Timeline;

	override function getCurrentFrameDuration():Float
	{
		return frameDuration;
	}

	override function destroy()
	{
		super.destroy();
		timeline = null;
	}
}
