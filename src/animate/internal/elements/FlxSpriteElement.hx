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
		// prepare original values
		_point.set(basic.x, basic.y);
		_angle = basic.angle;
		_blend = basic.blend;
		_antialiasing = basic.antialiasing;

		var color = basic.colorTransform;
		_colorTransform.setMultipliers(color.redMultiplier, color.greenMultiplier, color.blueMultiplier, color.alphaMultiplier);
		_colorTransform.setOffsets(color.redOffset, color.greenOffset, color.blueOffset, color.alphaOffset);

		// apply transformations
		super.applyObjectTransform(camera, parentMatrix, command);

		drawCommand.prepareCommand(command, _transform, transform, basic.blend);

		var x = parentMatrix.transformX(basic.x, basic.y);
		var y = parentMatrix.transformY(basic.x, basic.y);

		basic.setPosition(0, 0);
		var screenPoint = basic.getScreenPosition(_screenPoint, camera);
		basic.setPosition(x - screenPoint.x, y - screenPoint.y);

		basic.angle += Math.atan2(parentMatrix.b, parentMatrix.a) * 180 / Math.PI;
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
		basic.setColorTransform(_colorTransform.redMultiplier, _colorTransform.greenMultiplier, _colorTransform.blueMultiplier,
			_colorTransform.alphaMultiplier, _colorTransform.redOffset, _colorTransform.greenOffset, _colorTransform.blueOffset, _colorTransform.alphaOffset);
	}

	override function draw(camera:FlxCamera, index:Int, frameIndex:Int, parentMatrix:FlxMatrix, ?command:AnimateDrawCommand)
	{
		if (basic == null || basic.alpha <= 0)
			return;

		super.draw(camera, index, frameIndex, parentMatrix, command);
	}

	override function getObjectBounds(?result:FlxRect):FlxRect
	{
		return basic.getScreenBounds(result);
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
