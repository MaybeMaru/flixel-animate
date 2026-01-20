package animate.internal;

import animate.FlxAnimateJson;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import openfl.geom.ColorTransform;

using flixel.util.FlxColorTransformUtil;

@:access(animate.internal.Frame)
class Tween implements IFlxDestroyable
{
	// If to apply the tween per animation frame or game frame
	public var applyInterpolation:Bool = false;

	var keyframe:Frame;

	var tweenType:TweenType;

	var curve:Array<FlxPoint>;

	var rotate:TweenRotate;
	var rotateTimes:Int;

	var scale:Bool;
	var snap:Bool;
	var sync:Bool;

	public function new(keyframe:Frame, ?tween:TweenJson)
	{
		this.keyframe = keyframe;

		@:privateAccess {
			var parent = keyframe.layer.timeline.parent;
			if (parent != null && parent._settings != null)
			{
				applyInterpolation = parent._settings.applyInterpolation ?? false;
			}
		}

		_matrix = new FlxMatrix();
		_helperMatrix = new FlxMatrix();
		_transform = new ColorTransform();

		if (tween == null)
			return;

		this.tweenType = switch (tween.TP)
		{
			case "MT" | "motion": MOTION;
			case "MTO" | "motion_OBJECT": MOTION_OBJECT;
			default: NONE;
		}

		var cubicCurve = tween.CV;
		if (cubicCurve != null)
		{
			curve = new Array<FlxPoint>();
			for (point in cubicCurve)
				curve.push(FlxPoint.get(point.x, point.y));
		}

		rotate = tween.RT ?? AUTO;
		rotateTimes = tween.RTT ?? 0;
		scale = tween.SC ?? true;
		snap = tween.SP ?? true;
		sync = tween.SC ?? true;
	}

	var _helperMatrix:FlxMatrix;
	var _matrix:FlxMatrix;
	var _transform:ColorTransform;

	public function drawTransform(camera:FlxCamera, currentFrame:Int, parentoMatrixatrix:FlxMatrix, ?command:AnimateDrawCommand):Void {}

	public function destroy():Void
	{
		keyframe = null;
		curve = FlxDestroyUtil.putArray(curve);
	}
}

enum abstract TweenRotate(String) from String
{
	var NONE = "none";
	var AUTO = "auto";
	var CLOCKWISE = "clockwise";
	var COUNTER_CLOCKWISE = "counter-clockwise";
}

enum abstract TweenType(String)
{
	var NONE = "N";
	var MOTION = "MT";
	var MOTION_OBJECT = "MTO";
	// var IK_POSE = "IKP";
	// var SHAPE = "SHP";
}
