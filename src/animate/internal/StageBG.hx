package animate.internal;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.util.FlxColor;

@:access(animate.FlxAnimate)
@:nullSafety(Strict)
class StageBG extends FlxSprite
{
	public function new()
	{
		super();

		this.makeGraphic(1, 1, FlxColor.WHITE, false, "flx_animate_stagebg_graphic_");
	}

	public function render(parent:FlxAnimate, camera:FlxCamera):Void
	{
		if (!visible || alpha <= 0)
			return;

		color = parent.library.stageColor;
		updateColorTransform();
		colorTransform.concat(parent.colorTransform);

		if (colorTransform.alphaMultiplier <= 0)
			return;

		var mat = _matrix;
		mat.identity();

		final stageRect = parent.library.stageRect;
		final stageMatrix = parent.library.matrix;

		mat.scale(stageRect.width, stageRect.height);
		mat.translate(-stageMatrix.tx, -stageMatrix.ty);

		if (parent.checkRenderTexture())
		{
			@:privateAccess
			var bounds = parent.timeline._bounds;
			mat.translate(-bounds.x, -bounds.y);
		}

		mat.concat(parent._matrix);

		camera.drawPixels(this._frame, this.framePixels, mat, this.colorTransform, parent.blend, false, parent.shader);
	}
}
