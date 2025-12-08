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
import openfl.geom.Matrix;

@:access(openfl.display3D.Context3D)
@:access(openfl.display3D.textures.TextureBase)
@:access(openfl.display.OpenGLRenderer)
@:access(openfl.display.BitmapData)
@:access(openfl.display.DisplayObjectContainer)
@:access(flixel.FlxCamera)
@:access(flixel.graphics.FlxGraphic)
class RenderTexture implements IFlxDestroyable
{
	public var graphic(default, null):FlxGraphic;
	public var antialiasing:Bool = false;

	static var _context:Context3D;
	static var _renderer:OpenGLRenderer;

	var _textures:Map<String, BitmapData>;
	var _camera:FlxCamera;
	var _matrix:FlxMatrix;

	var _bitmap:BitmapData;
	var _scaleFactor:Float = 1.0;

	public function new(width:Int, height:Int)
	{
		if (_context == null)
			_context = FlxG.stage.context3D;

		if (_renderer == null)
		{
			_renderer = new OpenGLRenderer(_context);
			_renderer.__worldTransform = new Matrix();
		}

		_textures = [];
		_camera = new FlxCamera();
		_matrix = new FlxMatrix();

		// prepare the initial texture
		_scaleFactor = 1.0 / Math.min(FlxG.scaleMode.scale.x, FlxG.scaleMode.scale.y);
		_resizeTexture(width, height);
	}

	public function destroy():Void
	{
		for (texture in _textures.iterator())
			texture.dispose();

		_textures = null;
		_bitmap = null;

		graphic = FlxDestroyUtil.destroy(graphic);
		_camera = FlxDestroyUtil.destroy(_camera);
		_matrix = null;
	}

	public function drawToCamera(draw:FlxCamera->FlxMatrix->Void):Void
	{
		_matrix.identity();
		draw(_camera, _matrix);
	}

	public function render():Void
	{
		_camera.render();
		_camera.canvas.__update(false, true);

		_renderer.__cleanup();
		_renderer.setShader(_renderer.__defaultShader);
		_renderer.__worldTransform.identity();
		_renderer.__worldTransform.scale(_scaleFactor, _scaleFactor);
		_renderer.__setRenderTarget(_bitmap);

		_renderer.__allowSmoothing = antialiasing;
		_renderer.__pixelRatio = #if openfl_disable_hdpi 1 #else Lib.current.stage.window.scale #end;

		var cacheRTT = _context.__state.renderToTexture;
		var cacheRTTDepthStencil = _context.__state.renderToTextureDepthStencil;
		var cacheRTTAntiAlias = _context.__state.renderToTextureAntiAlias;
		var cacheRTTSurfaceSelector = _context.__state.renderToTextureSurfaceSelector;

		_context.setRenderToTexture(_bitmap.__texture, true);

		_renderer.__render(_camera.canvas);

		if (cacheRTT != null)
			_context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		else
			_context.setRenderToBackBuffer();
	}

	public function init(width:Int, height:Int,):Void
	{
		_camera.clearDrawStack();
		_camera.canvas.graphics.clear();
		#if FLX_DEBUG
		_camera.debugLayer.graphics.clear();
		#end

		_camera.width = width;
		_camera.height = height;

		_resizeTexture(width, height);
		graphic.bitmap = _bitmap;
		graphic.imageFrame.frame.frame.set(0, 0, width, height);

		_bitmap.fillRect(_bitmap.rect, 0);
	}

	function _resizeTexture(width:Int, height:Int):Void
	{
		if (_bitmap != null && _bitmap.width == width && _bitmap.height == height)
			return;

		var id:String = Std.string(width) + 'x' + Std.string(height);
		if (_textures.exists(id))
		{
			_bitmap = _textures.get(id);
			return;
		}

		_bitmap = BitmapData.fromTexture(_context.createRectangleTexture(width, height, BGRA, true));
		_textures.set(id, _bitmap);

		if (graphic == null)
			graphic = FlxGraphic.fromBitmapData(_bitmap, true, null, false);
	}
}
