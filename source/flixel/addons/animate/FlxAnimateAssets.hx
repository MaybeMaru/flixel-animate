package flixel.addons.animate;

import flixel.FlxG;
import haxe.io.Bytes;
import openfl.display.BitmapData;

using StringTools;

/**
 * Wrapper for assets to allow HaxeFlixel 5.9.0+ and HaxeFlixel 5.8.0- compatibility
 */
class FlxAnimateAssets
{
	public static dynamic function exists(path:String, type:AssetType):Bool
	{
		#if (flixel >= "5.9.0")
		return FlxG.assets.exists(path, type);
		#else
		return openfl.utils.Assets.exists(path, type);
		#end
	}

	public static dynamic function getText(path:String):String
	{
		#if (flixel >= "5.9.0")
		return FlxG.assets.getText(path);
		#else
		return openfl.utils.Assets.getText(path);
		#end
	}

	public static dynamic function getBytes(path:String):Bytes
	{
		#if (flixel >= "5.9.0")
		return FlxG.assets.getBytes(path);
		#else
		return openfl.utils.Assets.getBytes(path);
		#end
	}

	public static dynamic function getBitmapData(path:String):BitmapData
	{
		#if (flixel >= "5.9.0")
		return FlxG.assets.getBitmapData(path);
		#else
		return openfl.utils.Assets.getBitmapData(path);
		#end
	}

	public static dynamic function list(?type:AssetType, ?library:String):Array<String>
	{
		#if (flixel >= "5.9.0")
		if (library != null && library.length != 0)
		{
			var lib = openfl.utils.Assets.getLibrary(library);

			if (lib != null)
				return lib.list(cast type.toOpenFlType());
		}

		return FlxG.assets.list(type);
		#else
		if (library != null && library.length != 0)
		{
			var lib = openfl.utils.Assets.getLibrary(library);

			if (lib != null)
				return lib.list(cast type);
		}

		return openfl.utils.Assets.list(type);
		#end
	}
}

typedef AssetType = #if (flixel >= "5.9.0") flixel.system.frontEnds.AssetFrontEnd.FlxAssetType #else openfl.utils.AssetType #end;
