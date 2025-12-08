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

	var _texture:RectangleTexture;
	var _bitmap:BitmapData;
	var _camera:FlxCamera;
	var _matrix:FlxMatrix;
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

		_camera = new FlxCamera();
		_matrix = new FlxMatrix();

		resize(width, height);
	}

	public function destroy():Void
	{
		if (_texture != null)
		{
			_texture.dispose();
			_texture = null;
		}

		_bitmap = FlxDestroyUtil.dispose(_bitmap);
		graphic = FlxDestroyUtil.destroy(graphic);
		_camera = FlxDestroyUtil.destroy(_camera);
		_matrix = null;
	}

	public function clear():Void
	{
		_camera.clearDrawStack();
		_camera.canvas.graphics.clear();
		#if FLX_DEBUG
		_camera.debugLayer.graphics.clear();
		#end

		_bitmap.fillRect(_bitmap.rect, 0);
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

		_context.setRenderToTexture(_texture, true);

		_renderer.__render(_camera.canvas);

		if (cacheRTT != null)
			_context.setRenderToTexture(cacheRTT, cacheRTTDepthStencil, cacheRTTAntiAlias, cacheRTTSurfaceSelector);
		else
			_context.setRenderToBackBuffer();
	}

	public function resize(width:Int, height:Int):Void
	{
		_camera.width = width;
		_camera.height = height;

		_resizeTexture(width, height);
	}

	function _resizeTexture(width:Int, height:Int):Void
	{
		if (_texture != null)
		{
			if (_texture.__width == width && _texture.__height == height)
				return;
			else
			{
				_texture.dispose();
				_bitmap.dispose();
			}
		}

		_texture = _context.createRectangleTexture(width, height, BGRA, true);

		if (_bitmap == null)
		{
			_bitmap = BitmapData.fromTexture(_texture);
		}
		else
		{
			_bitmap.__texture = _texture;
			_bitmap.__textureContext = _texture.__textureContext;
			_bitmap.__resize(width, height);
		}

		// I have no idea why this is a thing
		_scaleFactor = 1.0 / Math.min(FlxG.scaleMode.scale.x, FlxG.scaleMode.scale.y);

		if (graphic == null)
			graphic = FlxGraphic.fromBitmapData(_bitmap, true, null, false);

		graphic.bitmap = _bitmap;
		// because flixel doesn't update this automatically?
		graphic.imageFrame.frame.frame.set(0, 0, width, height);
	}
}
