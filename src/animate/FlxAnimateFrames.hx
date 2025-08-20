package animate;

import animate.FlxAnimateJson;
import animate.internal.SymbolItem;
import animate.internal.Timeline;
import animate.internal.elements.SymbolInstance;
import flixel.FlxG;
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

using StringTools;

/**
 * Settings used when first loading a texture atlas.
 *
 * @param swfMode 			Used if the movieclips of the symbol should render similarly to SWF files. Disabled by default.
 * 							See ``animate.internal.elements.MovieClipInstance`` for more.
 *
 * @param cacheOnLoad		If to cache all necessary filters and masks when the texture atlas is first loaded. Disabled by default.
 *							This setting may be useful for reducing lag on filter heavy atlases. But take into account that
 *							it can also heavily increase loading times.
 *
 * @param filterQuality		Level of compression used to render filters. Set to ``MEDIUM`` by default.
 *							``HIGH`` 	-> Will render filters at their full quality, with no resolution loss.
 *							``MEDIUM`` 	-> Will apply some lossless compression to the filter, most recommended option.
 *							``LOW`` 	-> Will use heavy and easily noticeable compression, use with precausion.
 *							``RUDY``	-> Having your eyes closed probably has better graphics than this.
 */
typedef FlxAnimateSettings =
{
	?swfMode:Bool,
	?cacheOnLoad:Bool,
	?filterQuality:FilterQuality
}

/**
 * Class used to store all the data needed for texture atlases, such as spritemaps, symbols...
 *
 * Note that this engine does **NOT** convert texture atlases into spritesheets, therefore trying to get
 * frames from here will result in getting the limbs from the spritemap.
 *
 * If you need the a frame of the texture atlas animation I recommend using ``framePixels`` on
 * a ``FlxAnimate`` sprite as it is supported.
 */
class FlxAnimateFrames extends FlxAtlasFrames
{
	// TODO:
	// public var instance:SymbolInstance;
	// public var stageInstance:SymbolInstanceJson;

	/**
	 * The main ``Timeline`` that the Texture Atlas was exported from.
	 */
	public var timeline:Timeline;

	/**
	 * Rectangle with the resolution of the Animate stage background.
	 * Defaults to 1280x720 if the Texture Atlas wasnt exported using BetterTA.
	 */
	public var stageRect:FlxRect;

	/**
	 * Color of the Animate stage background.
	 * Defaults to WHITE if the Texture Atlas wasnt exported using BetterTA.
	 */
	public var stageColor:FlxColor;

	/**
	 * Matrix of the Texture Atlas on the Animate stage.
	 * Defaults to an empty matrix if not exported from an instanced symbol.
	 */
	public var matrix:FlxMatrix; // TODO: to be replaced with library.instance

	/**
	 * Default frame rate that the Texture Atlas was exported from.
	 */
	public var frameRate:Float;

	public function new(graphic:FlxGraphic)
	{
		super(graphic);
		this.dictionary = [];
		this.addedCollections = [];
	}

	/**
	 * Returns a ``SymbolItem`` object contained inside the texture atlas dictionary/library.
	 *
	 * @param name Name of the symbol item to return.
	 * @return ``SymbolItem`` found with the given name, null if not found.
	 */
	public function getSymbol(name:String):Null<SymbolItem>
	{
		if (existsSymbol(name))
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

		for (collection in addedCollections)
		{
			if (collection.dictionary.exists(name))
				return collection.dictionary.get(name);
		}

		FlxG.log.warn('SymbolItem with name "$name" doesnt exist.');
		return null;
	}

	/**
	 * Returns if a ``SymbolItem`` object is contained inside the texture atlas dictionary/library.
	 *
	 * @param name Name of the symbol item to check for.
	 * @return Whether the symbol exists in the dictionary or not.
	 */
	public function existsSymbol(name:String):Bool
	{
		return (dictionary.exists(name));
	}

	/**
	 * Adds a ``SymbolItem`` object to the texture atlas dictionary/library.
	 *
	 * @param name Name of the symbol item to add.
	 */
	public function setSymbol(name:String, symbolItem:SymbolItem):Void
	{
		dictionary.set(name, symbolItem);
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
	public static function fromAnimate(animate:String, ?spritemaps:Array<SpritemapInput>, ?metadata:String, ?key:String, ?unique:Bool = false,
			?settings:FlxAnimateSettings):FlxAnimateFrames
	{
		var key:String = key ?? animate;

		if (!unique && _cachedAtlases.exists(key))
			return _cachedAtlases.get(key);

		if (FlxAnimateAssets.exists(animate + "/Animation.json", TEXT))
			return _fromAnimatePath(animate, key, settings);

		return _fromAnimateInput(animate, spritemaps, metadata, key, settings);
	}

	static function getTextFromPath(path:String):String
	{
		return FlxAnimateAssets.getText(path).replace(String.fromCharCode(0xFEFF), "");
	}

	static function listWithFilter(path:String, filter:String->Bool, includeSubDirectories:Bool = false)
	{
		var list = FlxAnimateAssets.list(path, null, path.substring(0, path.indexOf(':')), includeSubDirectories);
		return list.filter(filter);
	}

	static function getGraphic(path:String):FlxGraphic
	{
		if (FlxG.bitmap.checkCache(path))
			return FlxG.bitmap.get(path);

		return FlxG.bitmap.add(FlxAnimateAssets.getBitmapData(path), false, path);
	}

	var _loadedData:AnimationJson;
	var _isInlined:Bool;
	var _libraryList:Array<String>;
	var _settings:Null<FlxAnimateSettings>;

	// since FlxAnimateFrames can have more than one graphic im gonna need use do this
	// TODO: use another method that works closer to flixel's frame collection crap
	static var _cachedAtlases:Map<String, FlxAnimateFrames> = [];

	static function _fromAnimatePath(path:String, ?key:String, ?settings:FlxAnimateSettings)
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
			var list = listWithFilter(path + "/LIBRARY", (str) -> str.endsWith(".json"), true);
			libraryList = list.map((str) ->
			{
				str = str.split("/LIBRARY/").pop();
				return Path.withoutExtension(str);
			});
		}

		// Load all spritemaps
		var spritemapList = listWithFilter(path, (file) -> file.startsWith("spritemap"), false);
		var jsonList = spritemapList.filter((file) -> file.endsWith(".json"));

		for (sm in jsonList)
		{
			var id = sm.split("spritemap")[1].split(".")[0];
			var imageFile = spritemapList.filter((file) -> file.startsWith('spritemap$id') && !file.endsWith(".json"))[0];

			spritemaps.push({
				source: getGraphic('$path/$imageFile'),
				json: getTextFromPath('$path/$sm')
			});
		}

		if (spritemaps.length <= 0)
		{
			FlxG.log.warn('No spritemaps were found for key "$path". Is the texture atlas incomplete?');
			return null;
		}

		return _fromAnimateInput(animation, spritemaps, metadata, key ?? path, isInlined, libraryList, settings);
	}

	static function _fromAnimateInput(animation:String, spritemaps:Array<SpritemapInput>, ?metadata:String, ?path:String, ?isInlined:Bool = true,
			?libraryList:Array<String>, settings:FlxAnimateSettings):FlxAnimateFrames
	{
		var animData:AnimationJson = null;
		try
		{
			animData = Json.parse(animation);
		}
		catch (e)
		{
			FlxG.log.warn('Couldnt load Animation.json with input "$animation". Is the texture atlas missing?');
			return null;
		}

		if (spritemaps == null || spritemaps.length <= 0)
		{
			FlxG.log.warn('No spritemaps were added for key "$path".');
			return null;
		}

		var frames = new FlxAnimateFrames(null);
		frames.path = path;
		frames._loadedData = animData;
		frames._isInlined = isInlined;
		frames._libraryList = libraryList;
		frames._settings = settings;

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

		var symbols = animData.SD;
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

		var metadata:MetadataJson = (metadata == null) ? animData.MD : Json.parse(metadata);

		frames.frameRate = metadata.FRT;
		frames.timeline = new Timeline(animData.AN.TL, frames, animData.AN.SN);
		frames.dictionary.set(frames.timeline.name, new SymbolItem(frames.timeline)); // Add main symbol to the library too

		// stage background color
		var w = metadata.W;
		var h = metadata.H;
		frames.stageRect = (w > 0 && h > 0) ? FlxRect.get(0, 0, w, h) : FlxRect.get(0, 0, 1280, 720);
		frames.stageColor = FlxColor.fromString(metadata.BGC);

		// stage instance of the main symbol
		var stageInstance:Null<SymbolInstanceJson> = animData.AN.STI;
		frames.matrix = (stageInstance != null) ? stageInstance.MX.toMatrix() : new FlxMatrix();

		// clear the temp data crap
		frames._loadedData = null;
		frames._libraryList = null;
		frames._settings = null;

		_cachedAtlases.set(path, frames);

		return frames;
	}

	var dictionary:Map<String, SymbolItem>;
	var path:String;
	var addedCollections:Array<FlxAnimateFrames>;

	override function addAtlas(collection:FlxAtlasFrames, overwriteHash:Bool = false):FlxAtlasFrames
	{
		if (collection is FlxAnimateFrames)
		{
			addedCollections.push(cast collection);
			return this;
		}

		return super.addAtlas(collection, overwriteHash);
	}

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

enum abstract FilterQuality(Int) to Int
{
	var HIGH = 0;
	var MEDIUM = 1;
	var LOW = 2;
	var RUDY = 3;

	public inline function getQualityFactor():Float
	{
		return switch (this)
		{
			case FilterQuality.MEDIUM: 1.75;
			case FilterQuality.LOW: 2.0;
			case FilterQuality.RUDY: 2.25;
			default: 1.0;
		}
	}

	public inline function getPixelFactor():Float
	{
		return switch (this)
		{
			case FilterQuality.MEDIUM: 16.0;
			case FilterQuality.LOW: 12.0;
			case FilterQuality.RUDY: 8.0;
			default: 1.0;
		}
	}
}
