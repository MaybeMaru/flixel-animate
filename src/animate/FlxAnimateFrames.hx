package animate;

import animate.FlxAnimateJson;
import animate.internal.*;
import animate.internal.elements.*;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
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

	public function new(graphic:FlxGraphic)
	{
		super(graphic);
		dictionary = [];
	}

	extern static inline function getTextFromPath(path:String)
	{
		var content = #if (flixel >= "5.9.0") FlxG.assets.getText(path); #else #if sys sys.io.File.getContent(path); #else Assets.getText(path); #end #end
		return content.replace(String.fromCharCode(0xFEFF), "");
	}

	extern static inline function listWithFilter(path:String, filter:String->Bool)
	{
		#if sys
		var list:Array<String> = sys.FileSystem.readDirectory(path);
		return list.filter(filter);
		#else
		var openflList = Assets.list(TEXT).filter((str) -> return str.startsWith(path));
		var list:Array<String> = [];
		for (i in openflList)
		{
			if (filter(i))
				list.push(i.split("/").pop());
		}
		return list;
		#end
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
	static var _cachedAtlases:Map<String, FlxAnimateFrames>;

	public static function fromAnimate(path:String):FlxAnimateFrames
	{
		if (_cachedAtlases == null)
		{
			_cachedAtlases = [];
		}
		else if (_cachedAtlases.exists(path))
		{
			return _cachedAtlases.get(path);
		}

		final getGraphic = (path:String) ->
		{
			return #if (flixel < "5.9.0" && sys) FlxGraphic.fromBitmapData(openfl.display.BitmapData.fromFile(path), false,
				path); #else FlxG.bitmap.add(path); #end
		}

		final existsFile = (path:String, type:AssetType) ->
		{
			return #if (flixel < "5.9.0")
				#if sys
				sys.FileSystem.exists(path);
				#else
				Assets.exists(path, type);
				#end
			#else
				FlxG.assets.exists(path, switch (type)
				{
					case BINARY: BINARY;
					case IMAGE: IMAGE;
					default: TEXT;
				});
			#end
		}

		var animation:AnimationJson = Json.parse(getTextFromPath(path + "/Animation.json"));

		var frames = new FlxAnimateFrames(null);
		frames.path = path;
		frames._loadedData = animation;

		var isInlined = !existsFile(path + "/metadata.json", TEXT);
		frames._isInlined = isInlined;

		if (!isInlined)
		{
			var list = listWithFilter(frames.path + "/LIBRARY", (str) -> str.endsWith(".json"));
			frames._libraryList = list.map((str) -> Path.withoutExtension(Path.withoutDirectory(str)));
		}

		// Load all spritemaps
		for (sm in listSpritemaps(path))
		{
			var id = sm.split("spritemap")[1].split(".")[0];

			var graphic = getGraphic(path + '/spritemap$id.png');
			var atlas = new FlxAtlasFrames(graphic);

			var smContent = getTextFromPath(path + '/spritemap$id.json');
			var spritemap:SpritemapJson = Json.parse(smContent);

			for (sprite in spritemap.ATLAS.SPRITES)
			{
				var sprite = sprite.SPRITE;
				var rect = FlxRect.get(sprite.x, sprite.y, sprite.w, sprite.h);
				var size = FlxPoint.get(sprite.w, sprite.h);
				atlas.addAtlasFrame(rect, size, FlxPoint.get(), sprite.name, sprite.rotated ? ANGLE_NEG_90 : ANGLE_0);
			}

			frames.addAtlas(atlas);
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

		var metadata:MetadataJson = isInlined ? animation.MD : Json.parse(getTextFromPath(path + "/metadata.json"));

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

		for (symbol in dictionary.iterator())
			symbol.destroy();

		stageRect = FlxDestroyUtil.put(stageRect);
		dictionary = null;
		matrix = null;
		timeline = null;
	}
}
