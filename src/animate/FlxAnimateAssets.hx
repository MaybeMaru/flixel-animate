package animate;

import flixel.FlxG;
import haxe.io.Bytes;
import openfl.display.BitmapData;

using StringTools;

/**
 * Wrapper for assets to allow HaxeFlixel 5.9.0+ and HaxeFlixel 5.8.0- compatibility.
 * Class to be used for replacing the method used for loading assets, if using ``FlxAnimateFrames.fromAnimate`` through a folder path.
 * For more control over loading texture atlases I recommend using the rest of the params in the ``fromAnimate`` frame loader.
 */
class FlxAnimateAssets
{
	public static dynamic function exists(path:String, type:AssetType):Bool
	{
		// Check if the file exists inside of the filesystem
		#if (sys && desktop)
		if (sys.FileSystem.exists(path))
			return true;
		#end

		// Fallback to openfl/flixel assets
		#if (flixel >= "5.9.0")
		return FlxG.assets.exists(path, type);
		#else
		return openfl.utils.Assets.exists(path, type);
		#end
	}

	public static dynamic function getText(path:String):String
	{
		// Check if the text is obtainable through filesystem
		#if (sys && desktop)
		if (sys.FileSystem.exists(path))
			return sys.io.File.getContent(path);
		#end

		// Fallback to openfl/flixel assets
		#if (flixel >= "5.9.0")
		return FlxG.assets.getText(path);
		#else
		return openfl.utils.Assets.getText(path);
		#end
	}

	public static dynamic function getBytes(path:String):Bytes
	{
		// Check if the bytes are obtainable through filesystem
		#if (sys && desktop)
		if (sys.FileSystem.exists(path))
			return sys.io.File.getBytes(path);
		#end

		// Fallback to openfl/flixel assets
		#if (flixel >= "5.9.0")
		return FlxG.assets.getBytes(path);
		#else
		return openfl.utils.Assets.getBytes(path);
		#end
	}

	public static dynamic function getBitmapData(path:String):BitmapData
	{
		if (FlxG.bitmap.checkCache(path))
			return FlxG.bitmap.get(path).bitmap;

		// Check if the image is obtainable through filesystem
		#if (sys && desktop)
		if (sys.FileSystem.exists(path))
			return BitmapData.fromFile(path);
		#end

		// Fallback to openfl/flixel assets
		#if (flixel >= "5.9.0")
		return FlxG.assets.getBitmapData(path);
		#else
		return openfl.utils.Assets.getBitmapData(path);
		#end
	}

	public static dynamic function list(path:String, ?type:AssetType, ?library:String):Array<String>
	{
		// Check if the list is obtainable through filesystem
		#if (sys && desktop)
		if (library == null || library.length == 0)
			return sys.FileSystem.readDirectory(path);
		#end

		// Fallback to openfl/flixel assets list for library assets
		var result:Array<String> = null;

		#if (flixel >= "5.9.0")
		if (library != null && library.length > 0)
		{
			var lib = openfl.utils.Assets.getLibrary(library);

			if (lib != null)
				result = lib.list(cast type.toOpenFlType());
		}
		else
			result = FlxG.assets.list(type);
		#else
		if (library != null && library.length > 0)
		{
			var lib = openfl.utils.Assets.getLibrary(library);

			if (lib != null)
				result = lib.list(cast type);
		}

		result = openfl.utils.Assets.list(type);
		#end

		return result.filter((str) -> return str.startsWith(path.substring(path.indexOf(':') + 1, path.length)));
	}
}

typedef AssetType = #if (flixel >= "5.9.0") flixel.system.frontEnds.AssetFrontEnd.FlxAssetType #else openfl.utils.AssetType #end;
