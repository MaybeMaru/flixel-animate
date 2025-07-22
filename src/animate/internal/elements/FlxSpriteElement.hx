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

	public function new(?sprite:FlxSprite)
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
		if (sprite == null || !sprite.visible || sprite.alpha <= 0.0)
			return;

		var hasTransform = transform != null;
		if (hasTransform)
		{
			if (transform.alphaMultiplier <= 0.0)
				return;

			_transform.setMultipliers(1, 1, 1, 1);
			_transform.setOffsets(0, 0, 0, 0);
			_transform.concat(transform);
		}

		// if (sprite.animation.curAnim != null)
		//	sprite.animation.curAnim.curFrame = index;
		sprite.update(FlxG.elapsed);

		// Prepare all necessary render values
		var _blend = sprite.blend;
		var _camera = sprite.camera;
		_point.set(sprite.x, sprite.y);
		_angle = sprite.angle;

		var x = parentMatrix.transformX(sprite.x, sprite.y);
		var y = parentMatrix.transformY(sprite.x, sprite.y);
		var b = Blend.resolve(sprite.blend, blend);

		sprite.setPosition(0, 0);
		var screenPoint = sprite.getScreenPosition(_screenPoint, camera);
		sprite.setPosition(x - screenPoint.x, y - screenPoint.y);

		// Apply sprite render values
		sprite.angle += Math.atan2(parentMatrix.b, parentMatrix.a) * 180 / Math.PI;
		if (hasTransform)
			sprite.colorTransform.concat(transform);
		sprite.blend = b;
		sprite.antialiasing = antialiasing;
		sprite.camera = camera;

		// Finally render the sprite
		sprite.draw();

		// Apply back the og sprite's values
		sprite.setPosition(_point.x, _point.y);
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

		if (sprite != null)
			bounds = sprite.getScreenBounds(bounds);

		Timeline.applyMatrixToRect(bounds, matrix);

		return bounds;
	}
}
