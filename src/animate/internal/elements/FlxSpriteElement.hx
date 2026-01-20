package animate.internal.elements;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

class FlxSpriteElement extends FlxTypedElement<FlxSprite>
{
	var _colorTransform:ColorTransform = null;
	var _antialiasing:Bool = false;
	var _blend:BlendMode = null;
	var _point:FlxPoint = null;
	var _screenPoint:FlxPoint = null;
	var _angle:Float = 0.0;

	public function new(?sprite:FlxSprite)
	{
		super(sprite);

		this._colorTransform = new ColorTransform();
		this._point = FlxPoint.get();
		this._screenPoint = FlxPoint.get();
	}

	override function destroy():Void
	{
		super.destroy();
		_colorTransform = null;
		_point = FlxDestroyUtil.put(_point);
		_point = FlxDestroyUtil.put(_screenPoint);
	}

	override function applyObjectTransform(camera:FlxCamera, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand)
	{
		var hasTransform = transform != null;
		if (hasTransform)
		{
			if (transform.alphaMultiplier <= 0.0)
				return;

			var color = basic.colorTransform;
			if (color == null)
			{
				_transform.setMultipliers(1, 1, 1, 1);
				_transform.setOffsets(0, 0, 0, 0);
			}
			else
			{
				_transform.redMultiplier = color.redMultiplier;
				_transform.greenMultiplier = color.greenMultiplier;
				_transform.blueMultiplier = color.blueMultiplier;
				_transform.alphaMultiplier = color.alphaMultiplier;

				_transform.redOffset = color.redOffset;
				_transform.greenOffset = color.greenOffset;
				_transform.blueOffset = color.blueOffset;
				_transform.alphaOffset = color.alphaOffset;
			}
		}

		_blend = basic.blend;
		_point.set(basic.x, basic.y);
		_angle = basic.angle;
		_blend = basic.blend;
		_antialiasing = basic.antialiasing;

		var color = basic.colorTransform;
		_colorTransform.redMultiplier = color.redMultiplier;
		_colorTransform.greenMultiplier = color.greenMultiplier;
		_colorTransform.blueMultiplier = color.blueMultiplier;
		_colorTransform.alphaMultiplier = color.alphaMultiplier;

		_colorTransform.redOffset = color.redOffset;
		_colorTransform.greenOffset = color.greenOffset;
		_colorTransform.blueOffset = color.blueOffset;
		_colorTransform.alphaOffset = color.alphaOffset;

		// apply transformations
		super.applyObjectTransform(camera, parentMatrix, command);

		drawCommand.prepareCommand(command, this);

		var x = parentMatrix.transformX(basic.x, basic.y);
		var y = parentMatrix.transformY(basic.x, basic.y);

		basic.setPosition(0, 0);
		var screenPoint = basic.getScreenPosition(_screenPoint, camera);
		basic.setPosition(x - screenPoint.x, y - screenPoint.y);

		basic.angle += Math.atan2(parentMatrix.b, parentMatrix.a) * 180 / Math.PI;

		if (isColored)
			basic.colorTransform.concat(_transform);

		basic.blend = command.blend;
		basic.antialiasing = basic.antialiasing || command.antialiasing;
		basic.camera = camera;
	}

	override function resetObjectTransform()
	{
		super.resetObjectTransform();

		basic.setPosition(_point.x, _point.y);
		basic.angle = _angle;
		basic.blend = _blend;
		basic.camera = _camera;
		basic.antialiasing = _antialiasing;

		var transform = basic.colorTransform;
		transform.redMultiplier = _colorTransform.redMultiplier;
		transform.greenMultiplier = _colorTransform.greenMultiplier;
		transform.blueMultiplier = _colorTransform.blueMultiplier;
		transform.alphaMultiplier = _colorTransform.alphaMultiplier;

		transform.redOffset = _colorTransform.redOffset;
		transform.greenOffset = _colorTransform.greenOffset;
		transform.blueOffset = _colorTransform.blueOffset;
		transform.alphaOffset = _colorTransform.alphaOffset;
	}

	override function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand)
	{
		if (basic == null || basic.alpha <= 0)
			return;

		super.draw(camera, index, frameIndex, parentMatrix, command);
	}

	override function getObjectBounds(?result:FlxRect):FlxRect
	{
		#if (flixel >= "5.0.0")
		return basic.getScreenBounds(result);
		#else
		return (result != null) ? result.set() : FlxRect.get();
		#end
	}
}

typedef FlxBasicElement = FlxTypedElement<FlxBasic>;

class FlxTypedElement<T:FlxBasic> extends Element
{
	public var basic:T;
	public var active:Bool;

	var _camera:FlxCamera;

	public function new(?basic:T)
	{
		super(null, null, null);
		this.basic = basic;
		this.active = true;
	}

	override function destroy():Void
	{
		super.destroy();
		basic = null;
		_camera = null;
	}

	function applyObjectTransform(camera:FlxCamera, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand)
	{
		basic.camera = camera;
	}

	function resetObjectTransform()
	{
		basic.camera = _camera;
	}

	override function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand)
	{
		if (basic == null || !basic.visible)
			return;

		_camera = basic.camera;

		if (active)
			basic.update(FlxG.elapsed);

		applyObjectTransform(camera, parentMatrix, command);

		basic.draw();

		resetObjectTransform();
	}

	function getObjectBounds(?result:FlxRect):FlxRect
	{
		return result;
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, includeFilters:Bool = true, useCachedBounds:Bool = false):FlxRect
	{
		var bounds = super.getBounds(frameIndex, rect, matrix, includeFilters);

		if (basic != null)
			bounds = getObjectBounds(bounds);

		Timeline.applyMatrixToRect(bounds, matrix);

		return bounds;
	}
}
