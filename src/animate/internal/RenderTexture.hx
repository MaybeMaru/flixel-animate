package animate.internal;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxMatrix;
import flixel.util.FlxDestroyUtil;
import openfl.Lib;
import openfl.display.BitmapData;
import openfl.display.OpenGLRenderer;
import openfl.display3D.Context3D;
import openfl.display3D.textures.RectangleTexture;
import openfl.geom.ColorTransform;
import openfl.geom.Matrix;

@:access(flixel.FlxCamera)
@:access(flixel.graphics.FlxGraphic)
@:access(openfl.display.BitmapData)
@:access(openfl.display.DisplayObjectContainer)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.geom.ColorTransform)
class RenderTexture implements IFlxDestroyable
{
	public var antialiasing:Bool = false;
	public var graphic(default, null):FlxGraphic;

	var _renderer:OpenGLRenderer;
	var _bitmaps:Map<String, BitmapData>;
	var _currentBitmap:BitmapData;
	var _camera:FlxCamera;
	var _matrix:FlxMatrix;

	public function new(width:Int, height:Int):Void
	{
		_renderer = new OpenGLRenderer(FlxG.stage.context3D);
		_renderer.__worldTransform = new Matrix();
		_renderer.__worldColorTransform = new ColorTransform();

		_bitmaps = [];
		_camera = new FlxCamera();
		_matrix = new FlxMatrix();

		_resetCamera(width, height);
		_ensureTexture(width, height);
	}

	public function destroy():Void
	{
		graphic = FlxDestroyUtil.destroy(graphic);

		_renderer.__cleanup();
		_renderer = null;

		for (bitmap in _bitmaps.iterator())
		{
			bitmap.__texture?.dispose();
			bitmap.dispose();
		}

		_bitmaps = null;

		_currentBitmap.__texture?.dispose();
		_currentBitmap.dispose();
		_currentBitmap = null;

		_camera = FlxDestroyUtil.destroy(_camera);
		_matrix = null;
	}

	public function drawToCamera(draw:FlxCamera->FlxMatrix->Void):Void
	{
		_matrix.identity();
		draw(_camera, _matrix);
	}

	// Custom draw because `BitmapData.draw` creates an `OpenGLRenderer` everytime it calls the function.
	public function render():Void
	{
		_camera.render();

		_camera.canvas.__update(false, true);

		_currentBitmap.__fillRect(_currentBitmap.rect, 0, true);

		_renderer.__cleanup();

		_renderer.setShader(_renderer.__defaultShader);

		_renderer.__allowSmoothing = antialiasing;
		_renderer.__pixelRatio = #if openfl_disable_hdpi 1 #else Lib.current.stage.window.scale #end;
		_renderer.__worldAlpha = 1 / _camera.canvas.__worldAlpha;
		_renderer.__worldTransform.copyFrom(_camera.canvas.__renderTransform);
		_renderer.__worldTransform.invert();
		_renderer.__worldColorTransform.__copyFrom(_camera.canvas.__worldColorTransform);
		_renderer.__worldColorTransform.__invert();
		_renderer.__setRenderTarget(_currentBitmap);

		_currentBitmap.__drawGL(_camera.canvas, _renderer);
	}

	public function resize(width:Int, height:Int):Void
	{
		_resetCamera(width, height);
		_ensureTexture(width, height);
	}

	/**
	 * @see https://github.com/HaxeFlixel/flixel/blob/873758673392d6424f3430e6f1bf68656efe1cf7/flixel/system/frontEnds/CameraFrontEnd.hx#L277-L282
	 */
	function _resetCamera(width:Int, height:Int):Void
	{
		_camera.clearDrawStack();
		_camera.canvas.graphics.clear();
		#if FLX_DEBUG
		_camera.debugLayer.graphics.clear();
		#end
		_camera.width = width;
		_camera.height = height;
	}

	function _ensureTexture(width:Int, height:Int):Void
	{
		if (_currentBitmap == null || (_currentBitmap.width != width || _currentBitmap.height != height))
		{
			final id:String = Std.string(width) + 'x' + Std.string(height);

			if (!_bitmaps.exists(id))
			{
				_bitmaps.set(id, BitmapData.fromTexture(FlxG.stage.context3D.createRectangleTexture(width, height, BGRA, true)));
			}

			_currentBitmap = _bitmaps.get(id);

			if (graphic == null)
				graphic = FlxGraphic.fromBitmapData(_currentBitmap, false, null, false);
		}

		if (graphic.bitmap != _currentBitmap)
			graphic.bitmap = _currentBitmap;

		if (graphic.imageFrame.frame.frame.width != width || graphic.imageFrame.frame.frame.height != height)
			graphic.imageFrame.frame.frame.set(0, 0, width, height);
	}
}
