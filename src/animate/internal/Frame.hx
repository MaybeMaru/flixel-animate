package animate.internal;

import animate.FlxAnimateFrames.FilterQuality;
import animate.FlxAnimateJson.FrameJson;
import animate.internal.elements.AtlasInstance;
import animate.internal.elements.ButtonInstance;
import animate.internal.elements.Element;
import animate.internal.elements.MovieClipInstance;
import animate.internal.elements.SymbolInstance;
import animate.internal.elements.TextFieldInstance;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMatrix;
import flixel.math.FlxRect;
import flixel.sound.FlxSound;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.media.Sound;

using StringTools;

@:access(animate.FlxAnimateFrames)
@:allow(animate.internal.Layer)
class Frame implements IFlxDestroyable
{
	public var layer(default, null):Null<Layer>;
	public var elements(default, null):Array<Element>;
	public var index:Int;
	public var duration:Int;
	public var name:String;
	public var sound:Null<FlxSound>;
	public var blend:BlendMode;

	// public var tween:Tween;

	public function new(?layer:Layer)
	{
		this.elements = [];
		this.name = "";
		this.layer = layer;
		this.duration = 1;
		this.index = 0;
	}

	/**
	 * Adds an ``Element`` object to the elements list of the frame.
	 * If the frame is masked it will require a redraw.
	 *
	 * @param element Element object to add to the frame. It won't be added if its already part of the list.
	 */
	public function add(element:Element):Void
	{
		if (elements.indexOf(element) != -1)
			return;

		element.parentFrame = this;
		elements.push(element);
		setDirty();
	}

	/**
	 * Insert an ``Element`` object to an index of the elements list of the frame.
	 * If the frame is masked it will require a redraw.
	 *
	 * @param index		Index where to add the element to.
	 * @param element 	Element object to add to the frame. It won't be added if its already part of the list.
	 */
	public function insert(index:Int, element:Element)
	{
		if (elements.indexOf(element) != -1)
			return;

		element.parentFrame = this;
		elements.insert(index, element);
		setDirty();
	}

	/**
	 * Changes the filters of the movieclip.
	 * Requires the movieclip to be rebaked when called.
	 *
	 * @param filters An array with ``BitmapFilter`` objects to apply to the movieclip.
	 */
	public function setFilters(?filters:Array<BitmapFilter>):Void
	{
		this._filters = filters;
		this._requireBake = (filters != null && filters.length > 0);
		setDirty();
	}

	/**
	 * Clears up the memory from the previously baked frames and
	 * sets the frame ready for a new rebake of masks/filters.
	 */
	public function setDirty()
	{
		if (_requireBake)
		{
			_dirty = true;
		}

		if (_bakedFrames != null)
		{
			_bakedFrames.dispose();
			_bakedFrames = null;
			_bakedIndices = null;
		}

		if (layer != null && layer.timeline != null)
			layer.timeline.parent.setSymbolDirty(layer.timeline.name);
	}

	/**
	 *	Packs and replaces the selected elements from the frame into a new symbol item and instance.
	 *	NOTE: Doesn't include the new symbol item into the texture atlas library/dictionary.
	 *
	 * @param fromIndex Index where to start converting elements from.
	 * @param toIndex 	Index where to stop converting elements from.
	 * @param type 		Optional, type of symbol instance to create (``GRAPHIC``, ``MOVIECLIP``, ``BUTTON``).
	 * @return 			An new symbol instance containing the selected elements.
	 */
	@:access(animate.internal.Layer)
	public function convertToSymbol(fromIndex:Int, toIndex:Int, ?type:ElementType = GRAPHIC):SymbolInstance
	{
		var elements = this.elements.splice(fromIndex, toIndex - fromIndex);

		var frame = new Frame();
		for (element in elements)
			frame.add(element);

		var timeline = new animate.internal.Timeline(null, layer.timeline.parent, "tempSymbol");
		var layer = new Layer(timeline);

		layer.frames.push(frame);
		layer.frameIndices.push(0);

		timeline.layers.push(layer);
		timeline.frameCount = layer.frameCount;

		var item = new SymbolItem(timeline);
		var instance = item.createInstance(type);
		insert(fromIndex, instance);

		return instance;
	}

	/**
	 * Applies a function to all the elements of the frame.
	 *
	 * @param callback The ``Element->Void`` function to call for all the existing elements.
	 */
	public function forEachElement(callback:Element->Void):Void
	{
		for (element in this.elements)
			callback(element);
	}

	/**
	 * Returns the bounds of the keyframe at a specific index.
	 *
	 * @param frameIndex			The frame index where to calculate the bounds from.
	 * @param rect					Optional, the rectangle used to input the final calculated values.
	 * @param matrix				Optional, the matrix to apply to the bounds calculation.
	 * @param includeFilters		Optional, if to include filtered bounds in the calculation or use the unfilitered ones (true to Flash's bounds).
	 * @return						A ``FlxRect`` with the complete frames's bounds at an index, empty if no elements were found.
	 */
	public function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true, ?useCachedBounds:Bool = false):FlxRect
	{
		rect ??= FlxRect.get();
		rect.set();

		// Returns empty bounds if theres no elements in the frame
		if (elements.length <= 0)
		{
			(matrix != null) ? rect.set(matrix.tx, matrix.ty, 0, 0) : rect.set(0, 0, 0, 0);
			return rect;
		}

		// Get the filtered/masked bounds, if they exist
		/*if (_bakedFrames != null)
			{
				var bakedFrame = _bakedFrames[frameIndex];
				if (bakedFrame != null)
				{
					bakedFrame.getBounds(frameIndex, rect, matrix, includeFilters);
					return rect;
				}
		}*/

		var tmpRect = FlxRect.get();

		// Loop through the bounds of each element
		rect = elements[0].getBounds(frameIndex, rect, matrix, includeFilters, useCachedBounds);
		for (i in 1...elements.length)
		{
			tmpRect = elements[i].getBounds(frameIndex, tmpRect, matrix, includeFilters, useCachedBounds);
			rect = Timeline.expandBounds(rect, tmpRect);
		}

		// If the frame is not yet masked, calculate the masked bounds manually
		if (_dirty && this.layer.parentLayer != null)
		{
			tmpRect.set();
			var maskerBounds = this.layer.parentLayer.getBounds(frameIndex + this.index, tmpRect, matrix, includeFilters, useCachedBounds);
			Timeline.maskBounds(rect, maskerBounds);
		}

		tmpRect.put();
		return rect;
	}

	public inline function iterator()
	{
		return elements.iterator();
	}

	public inline function keyValueIterator()
	{
		return elements.keyValueIterator();
	}

	@:allow(animate.internal.Layer)
	function _loadJson(frame:FrameJson, parent:FlxAnimateFrames):Void
	{
		this.index = frame.I;
		this.duration = frame.DU;
		this.name = frame.N ?? "";
		this.blend = #if flash animate.internal.filters.Blend.fromInt(frame.B); #else frame.B; #end

		var e = frame.E;
		if (e != null)
		{
			for (element in e)
			{
				var si = element.SI;
				if (si != null)
				{
					this.elements.push(switch (si.ST)
					{
						case "B" | "button":
							new ButtonInstance(si, parent, this);
						case "MC" | "movieclip":
							new MovieClipInstance(si, parent, this);
						default:
							new SymbolInstance(si, parent, this);
					});
				}
				else
				{
					var asi = element.ASI;
					if (asi != null)
					{
						this.elements.push(new AtlasInstance(asi, parent, this));
					}
					else
					{
						var tfi = element.TFI;
						if (tfi != null)
						{
							this.elements.push(new TextFieldInstance(tfi, parent, this));
						}
					}
				}
			}
		}

		// Resolve and precache bitmap filters
		var jsonFilters = frame.F;
		if (jsonFilters != null && jsonFilters.length > 0)
		{
			var filters:Array<BitmapFilter> = [];
			for (filter in jsonFilters)
			{
				var bmpFilter:Null<BitmapFilter> = filter.toBitmapFilter();
				if (bmpFilter != null)
					filters.push(bmpFilter);
			}

			this._filters = filters;
			this._dirty = true;
		}

		var jsonSound = frame.SND;
		if (jsonSound != null)
		{
			final soundPath:String = parent.path + '/LIBRARY/' + jsonSound.N;

			#if (cpp || hl) // Default sound loading has issues with WAV files on native for some reason
			if (soundPath.endsWith(".wav"))
			{
				var bytes = FlxAnimateAssets.getBytes(soundPath);
				var buffer = lime.media.AudioBuffer.fromBytes(bytes);
				var openflSound = Sound.fromAudioBuffer(buffer);
				sound = FlxG.sound.load(openflSound);
			}
			else
			#end
			{
				sound = FlxG.sound.load(soundPath);
			}
		}

		// var jsonTween = frame.TWN;
		// if (jsonTween != null)
		// {
		//	tween = new Tween(this, jsonTween);
		// }
	}

	var _dirty:Bool = false;
	var _requireBake:Bool = false;
	var _filters:Array<BitmapFilter> = null;
	var _filterQuality:FilterQuality = FilterQuality.MEDIUM;

	var _bakedFrames:BakedFramesVector;
	var _bakedIndices:Array<Int>;

	function _bakeFrame(frameIndex:Int):Void
	{
		if (layer.parentLayer == null && (_filters == null || _filters.length == 0))
		{
			_dirty = false;
			return;
		}

		// Prepare vector to store baked frames
		if (_bakedFrames == null)
			_bakedFrames = new BakedFramesVector(duration);

		// Prepare indices vector
		// This is used as a way to save on the necessary bitmaps to render a mask
		if (_bakedIndices == null)
		{
			var isSimpleRender:Bool = true;
			for (element in elements)
			{
				if (element is AtlasInstance)
					continue;

				if (!element.toSymbolInstance().isSimpleSymbol())
				{
					isSimpleRender = false;
					break;
				}
			}

			if (isSimpleRender)
			{
				_bakedIndices = [];
				for (i in 0...duration)
				{
					// only render the neccesary frame indices
					var parentFrame = (layer.parentLayer == null) ? this : layer.parentLayer.getFrameAtIndex(index + i);
					_bakedIndices.push(parentFrame == null ? -1 : parentFrame.index);
				}
			}
			else
			{
				_bakedIndices = [for (i in 0...duration) i];
			}
		}

		frameIndex = _bakedIndices[frameIndex];
		if (frameIndex == -1 || _bakedFrames[frameIndex] != null)
			return;

		var bakedFrame:Null<AtlasInstance> = FilterRenderer.bakeFrame(this, frameIndex + this.index, layer);
		if (bakedFrame == null)
			return;

		bakedFrame.parentFrame = this;
		_bakedFrames[frameIndex] = bakedFrame;

		if (bakedFrame.frame == null || bakedFrame.frame.frame.isEmpty)
			bakedFrame.visible = false;

		// All frames have been baked
		if (_dirty && _bakedFrames.isFull())
			_dirty = false;
	}

	@:allow(animate.internal.elements.SymbolInstance)
	@:allow(animate.internal.FilterRenderer)
	@:allow(animate.internal.Timeline)
	@:allow(animate.internal.filters.Blend)
	@:allow(animate.internal.elements.AtlasInstance)
	@:allow(animate.internal.AnimateDrawCommand)
	private static var __isDirtyCall:Bool = false;

	public function draw(camera:FlxCamera, currentFrame:Int, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand)
	{
		if (command != null)
			command.prepareFrameCommand(this);

		if (_dirty)
		{
			if (layer != null)
				_bakeFrame(currentFrame - this.index);
		}

		if (_bakedFrames != null)
		{
			var bakedIndex = _bakedIndices[currentFrame - this.index];
			if (bakedIndex == -1)
				return;

			var bakedFrame = _bakedFrames[bakedIndex];
			if (bakedFrame != null)
			{
				if (bakedFrame.visible)
					bakedFrame.draw(camera, currentFrame, this.index, parentMatrix, command);
				return;
			}
		}

		// if (tween != null)
		//	tween.drawTransform(camera, currentFrame, parentMatrix, command);
		// else
		_drawElements(camera, currentFrame, parentMatrix, command);
	}

	@:allow(animate.internal.FilterRenderer)
	inline function _drawElements(camera:FlxCamera, currentFrame:Int, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand)
	{
		for (element in elements)
		{
			if (element.visible)
				element.draw(camera, currentFrame, this.index, parentMatrix, command);
		}
	}

	public function destroy():Void
	{
		elements = FlxDestroyUtil.destroyArray(elements);
		sound = FlxDestroyUtil.destroy(sound);
		layer = null;

		if (_bakedFrames != null)
		{
			_bakedFrames.dispose();
			_bakedFrames = null;
		}
	}

	public function toString():String
	{
		return '{name: "$name", index: $index, duration: $duration}';
	}
}
