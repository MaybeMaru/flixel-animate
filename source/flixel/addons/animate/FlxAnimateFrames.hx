package flixel.addons.animate;

import flixel.FlxG;
import flixel.addons.animate.FlxAnimateJson;
import flixel.addons.animate.internal.SymbolItem;
import flixel.addons.animate.internal.Timeline;
import flixel.addons.animate.internal.elements.SymbolInstance;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import haxe.Json;
import haxe.io.Path;
import openfl.utils.AssetType;
import openfl.utils.Assets;

using StringTools;

class FlxAnimateFrames extends FlxAtlasFrames
{
	public var timeline:Timeline;
	public var instance:SymbolInstance;
	public var dictionary:Map<String, SymbolItem>;
	public var path:String;

	public function new(graphic:FlxGraphic)
	{
		super(graphic);
		dictionary = [];
	}

	public function getSymbol(name:String)
	{
		if (dictionary.exists(name))
			return dictionary.get(name);

		if (_isInlined)
		{
			// Didnt load at first for some reason?
			if (_loadedData != null)
			{
				for (data in _loadedData.SD)
				{
					if (data.SN == name)
					{
						var timeline = new Timeline(data.TL, this, name);
						var symbol = new SymbolItem(timeline);
						dictionary.set(timeline.name, symbol);
						return symbol;
					}
				}
			}
		}
		else
		{
			if (_libraryList.contains(name))
			{
				var data:TimelineJson = Json.parse(getTextFromPath(path + "/LIBRARY/" + name + ".json"));
				var timeline = new Timeline(data, this, name);
				var symbol = new SymbolItem(timeline);
				dictionary.set(timeline.name, symbol);
				return symbol;
			}
		}

		FlxG.log.warn('SymbolItem with name "$name" doesnt exist.');
		return null;
	}

	/**
	 * Parsing method for Adobe Animate texture atlases
	 *
	 * @param   animate  	The texture atlas folder path or Animation.json contents string.
	 * @param   spritemaps	Optional, array of the spritemaps to load for the texture atlas
	 * @param   metadata	Optional, string of the metadata.json contents string.
	 * @param   key			Optional, force the cache to use a specific Key to index the texture atlas.
	 * @param   unique  	Optional, ensures that the texture atlas uses a new slot in the cache.
	 * @return  Newly created `FlxAnimateFrames` collection.
	 */
	public static function fromAnimate(animate:String, ?spritemaps:Array<SpritemapInput>, ?metadata:String, ?key:String, ?unique:Bool = false):FlxAnimateFrames
	{
		var key:String = key ?? animate;

		if (!unique && _cachedAtlases.exists(key))
			return _cachedAtlases.get(key);

		if (FlxAnimateAssets.exists(animate + "/Animation.json", TEXT))
			return _fromAnimatePath(animate, key);

		return _fromAnimateInput(animate, spritemaps, metadata, key);
	}

	static function getTextFromPath(path:String):String
	{
		return FlxAnimateAssets.getText(path).replace(String.fromCharCode(0xFEFF), "");
	}

	static function listWithFilter(path:String, filter:String->Bool)
	{
		var list:Array<String> = [];

		for (i in FlxAnimateAssets.list(TEXT, path.substring(0, path.indexOf(':')))
			.filter((str) -> return str.startsWith(path.substring(path.indexOf(':') + 1, path.length))))
		{
			if (filter(i))
				list.push(i.split("/").pop());
		}

		return list;
	}

	static function getGraphic(path:String):FlxGraphic
	{
		if (FlxG.bitmap.checkCache(path))
			return FlxG.bitmap.get(path);

		return FlxG.bitmap.add(FlxAnimateAssets.getBitmapData(path));
	}

	static function listSpritemaps(path:String):Array<String>
	{
		final filter = (str:String) -> return str.contains("spritemap") && str.endsWith(".json");
		return listWithFilter(path, filter);
	}

	var _loadedData:AnimationJson;
	var _isInlined:Bool;
	var _libraryList:Array<String>;

	// since FlxAnimateFrames can have more than one graphic im gonna need use do this
	// TODO: use another method that works closer to flixel's frame collection crap
	static var _cachedAtlases:Map<String, FlxAnimateFrames> = [];

	static function _fromAnimatePath(path:String, ?key:String)
	{
		var hasAnimation:Bool = FlxAnimateAssets.exists(path + "/Animation.json", TEXT);
		if (!hasAnimation)
		{
			FlxG.log.warn('No Animation.json file was found for path "$path".');
			return null;
		}

		var animation = getTextFromPath(path + "/Animation.json");
		var isInlined = !FlxAnimateAssets.exists(path + "/metadata.json", TEXT);
		var libraryList:Null<Array<String>> = null;
		var spritemaps:Array<SpritemapInput> = [];
		var metadata:Null<String> = isInlined ? null : getTextFromPath(path + "/metadata.json");

		if (!isInlined)
		{
			var list = listWithFilter(path + "/LIBRARY", (str) -> str.endsWith(".json"));
			libraryList = list.map((str) -> Path.withoutExtension(Path.withoutDirectory(str)));
		}

		// Load all spritemaps
		for (sm in listSpritemaps(path))
		{
			var id = sm.split("spritemap")[1].split(".")[0];
			spritemaps.push({
				source: getGraphic(path + '/spritemap$id.png'),
				json: getTextFromPath(path + '/spritemap$id.json')
			});
		}

		return _fromAnimateInput(animation, spritemaps, metadata, key ?? path, isInlined, libraryList);
	}

	static function _fromAnimateInput(animation:String, spritemaps:Array<SpritemapInput>, ?metadata:String, ?path:String, ?isInlined:Bool = true,
			?libraryList:Array<String>):FlxAnimateFrames
	{
		var animation:AnimationJson = Json.parse(animation);
		var frames = new FlxAnimateFrames(null);
		frames.path = path;
		frames._loadedData = animation;
		frames._isInlined = isInlined;
		frames._libraryList = libraryList;

		var spritemapCollection = new FlxAnimateSpritemapCollection(frames);
		frames.parent = spritemapCollection;

		// Load all spritemaps
		for (spritemap in spritemaps)
		{
			var graphic = FlxG.bitmap.add(spritemap.source);
			if (graphic == null)
				continue;

			var atlas = new FlxAtlasFrames(graphic);
			var spritemap:SpritemapJson = Json.parse(spritemap.json);

			for (sprite in spritemap.ATLAS.SPRITES)
			{
				var sprite = sprite.SPRITE;
				var rect = FlxRect.get(sprite.x, sprite.y, sprite.w, sprite.h);
				var size = FlxPoint.get(sprite.w, sprite.h);
				atlas.addAtlasFrame(rect, size, FlxPoint.get(), sprite.name, sprite.rotated ? ANGLE_NEG_90 : ANGLE_0);
			}

			frames.addAtlas(atlas);
			spritemapCollection.addSpritemap(graphic);
		}

		var symbols = animation.SD;
		if (symbols != null && symbols.length > 0)
		{
			var i = symbols.length - 1;
			while (i > -1)
			{
				var data = symbols[i--];
				var timeline = new Timeline(data.TL, frames, data.SN);
				frames.dictionary.set(timeline.name, new SymbolItem(timeline));
			}
		}

		var metadata:MetadataJson = (metadata == null) ? animation.MD : Json.parse(metadata);

		frames.frameRate = metadata.FRT;
		frames.timeline = new Timeline(animation.AN.TL, frames, animation.AN.SN);
		frames.dictionary.set(frames.timeline.name, new SymbolItem(frames.timeline)); // Add main symbol to the library too

		// stage background color
		var w = metadata.W;
		var h = metadata.H;
		frames.stageRect = (w > 0 && h > 0) ? FlxRect.get(0, 0, w, h) : FlxRect.get();
		frames.stageColor = FlxColor.fromString(metadata.BGC);

		// stage instance of the main symbol
		var stageInstance:Null<SymbolInstanceJson> = animation.AN.STI;
		frames.matrix = (stageInstance != null) ? stageInstance.MX.toMatrix() : new FlxMatrix();

		// clear the temp data crap
		frames._loadedData = null;
		frames._libraryList = null;

		_cachedAtlases.set(path, frames);

		return frames;
	}

	// public var stageInstance:SymbolInstanceJson;
	public var stageRect:FlxRect;
	public var stageColor:FlxColor;
	public var matrix:FlxMatrix;
	public var frameRate:Float;

	override function destroy():Void
	{
		if (_cachedAtlases.exists(path))
			_cachedAtlases.remove(path);

		super.destroy();

		if (dictionary != null)
		{
			for (symbol in dictionary.iterator())
				symbol.destroy();
		}

		stageRect = FlxDestroyUtil.put(stageRect);
		timeline = FlxDestroyUtil.destroy(timeline);
		dictionary = null;
		matrix = null;
	}
}

/**
 * This class is used as a temporal graphic for texture atlas frame caching.
 * Mainly used to work with flixel's method of destroying FlxFramesCollection
 * while keeping the ability to reused cached atlases where possible.
 */
class FlxAnimateSpritemapCollection extends FlxGraphic
{
	public function new(parentFrames:FlxAnimateFrames)
	{
		super("", null);
		this.spritemaps = [];
		this.parentFrames = parentFrames;
	}

	var spritemaps:Array<FlxGraphic>;
	var parentFrames:FlxAnimateFrames;

	public function addSpritemap(graphic:FlxGraphic):Void
	{
		if (this.bitmap == null)
			this.bitmap = graphic.bitmap;

		if (spritemaps.indexOf(graphic) == -1)
			spritemaps.push(graphic);
	}

	override function checkUseCount():Void
	{
		if (useCount <= 0 && destroyOnNoUse && !persist)
		{
			for (spritemap in spritemaps)
				spritemap.decrementUseCount();

			spritemaps.resize(0);
			parentFrames = FlxDestroyUtil.destroy(parentFrames);
		}
	}

	override function destroy():Void
	{
		bitmap = null; // Turning null early to let the og spritemap graphic remove the bitmap
		super.destroy();
		parentFrames = null;
		spritemaps = null;
	}
}

typedef SpritemapInput =
{
	source:FlxGraphicAsset,
	json:String
}
