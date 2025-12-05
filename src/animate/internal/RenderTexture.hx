package animate.internal;

import openfl.geom.ColorTransform;
import openfl.geom.Matrix;
import flixel.math.FlxMatrix;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxDestroyUtil.IFlxDestroyable;
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import openfl.display3D.textures.RectangleTexture;
import flixel.FlxCamera;
import flixel.FlxG;
import openfl.display3D.Context3D;
import openfl.geom.Rectangle;
import openfl.display.OpenGLRenderer;
import openfl.Lib;

@:access(openfl.display.OpenGLRenderer)
class RenderTexture implements IFlxDestroyable
{
   	public var graphic(default, null):FlxGraphic;
	public var antialiasing:Bool = false;

	var _context:Context3D;
	var _renderer:OpenGLRenderer;
	var _texture:RectangleTexture;
	var _bitmap:BitmapData;
	var _camera:FlxCamera;
	var _matrix:FlxMatrix;

	public function new(width:Int, height:Int)
	{
		this._context = FlxG.stage.context3D;
		
		_camera = new FlxCamera();

		_texture = _context.createRectangleTexture(width, height, BGRA, true);
		_bitmap = BitmapData.fromTexture(_texture);
		graphic = FlxGraphic.fromBitmapData(_bitmap, true, null, false);

		_matrix = new FlxMatrix();

		_renderer = new OpenGLRenderer(_context);
		_renderer.__worldTransform = new Matrix();

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

	@:access(flixel.FlxCamera)
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

	@:access(openfl.display.DisplayObjectContainer)
	@:access(flixel.FlxCamera)
	@:access(openfl.display3D.Context3D)
	@:access(openfl.geom.Matrix)
	public function render():Void
	{
		_camera.render();

		_camera.canvas.__update(false, true);

        _renderer.__cleanup();
		_renderer.setShader(_renderer.__defaultShader);
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

	@:access(openfl.display3D.textures.TextureBase)
	@:access(openfl.display.BitmapData)
	@:access(flixel.graphics.FlxGraphic)
	function _resizeTexture(width:Int, height:Int)
	{
		if (_texture.__width == width && _texture.__height == height)
			return;

		_texture.dispose();
		_texture = _context.createRectangleTexture(width, height, BGRA, true);

		_bitmap.__texture = _texture;
		_bitmap.__textureContext = _texture.__textureContext;
		_bitmap.__resize(width, height);
		
		graphic.bitmap = _bitmap;
		// because flixel doesn't update this automatically?
		graphic.imageFrame.frame.frame.set(0, 0, width, height);
	}
}
