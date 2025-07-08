package animate.internal.elements;

import animate.internal.filters.Blend;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxDestroyUtil;
import openfl.display.BlendMode;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

@:access(flixel.FlxSprite)
class FlxSpriteElement extends Element
{
	public var sprite:FlxSprite;

	var _transform:ColorTransform;
	var _point:FlxPoint;
	var _screenPoint:FlxPoint;
	var _angle:Float;

	public function new(sprite:FlxSprite)
	{
		super(null, null, null);
		this.sprite = sprite;

		this._transform = new ColorTransform();
		this._point = FlxPoint.get();
		this._screenPoint = FlxPoint.get();
		this._angle = 0.0;
	}

	override function destroy():Void
	{
		super.destroy();
		sprite = null;
		_transform = null;
		_point = FlxDestroyUtil.put(_point);
		_point = FlxDestroyUtil.put(_screenPoint);
	}

	override function draw(camera:FlxCamera, index:Int, tlFrame:Frame, parentMatrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode,
			?antialiasing:Bool, ?shader:FlxShader)
	{
		// if (sprite.animation.curAnim != null)
		//	sprite.animation.curAnim.curFrame = index;
		sprite.update(FlxG.elapsed);

		var _blend = sprite.blend;
		var _camera = sprite.camera;
		_point.set(sprite.x, sprite.y);
		_angle = sprite.angle;

		var hasTransform = transform != null;
		if (hasTransform)
		{
			_transform.setMultipliers(1, 1, 1, 1);
			_transform.setOffsets(0, 0, 0, 0);
			_transform.concat(transform);
		}

		var x = parentMatrix.transformX(sprite.x, sprite.y);
		var y = parentMatrix.transformY(sprite.x, sprite.y);
		var b = Blend.resolve(sprite.blend, blend);

		sprite.setPosition(0, 0);
		var screenPoint = sprite.getScreenPosition(_screenPoint, camera);

		sprite.setPosition(x - screenPoint.x, y - screenPoint.y);
		sprite.angle += Math.atan2(parentMatrix.b, parentMatrix.a) * 180 / Math.PI;
		if (hasTransform)
			sprite.colorTransform.concat(transform);
		sprite.blend = b;
		sprite.antialiasing = antialiasing;

		sprite.camera = camera;

		if (sprite.visible)
			sprite.draw();

		sprite.x = _point.x;
		sprite.y = _point.y;
		sprite.angle = _angle;
		sprite.blend = _blend;
		sprite.camera = _camera;

		if (hasTransform)
		{
			sprite.colorTransform.setMultipliers(1, 1, 1, 1);
			sprite.colorTransform.setOffsets(0, 0, 0, 0);
			sprite.colorTransform.concat(_transform);
		}
	}

	override function getBounds(frameIndex:Int, ?rect:FlxRect, ?matrix:FlxMatrix, ?includeFilters:Bool = true):FlxRect
	{
		var bounds = super.getBounds(frameIndex, rect, matrix, includeFilters);
		bounds = sprite.getScreenBounds(bounds);

		if (matrix != null)
			bounds = Timeline.applyMatrixToRect(bounds, matrix);

		return bounds;
	}
}
