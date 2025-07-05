package flixel.addons.animate.internal;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.util.FlxColor;

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

		this.color = parent.library.stageColor;
		colorTransform.concat(parent.colorTransform);

		if (colorTransform.alphaMultiplier <= 0)
			return;

		var mat = _matrix;
		mat.identity();
		mat.scale(parent.library.stageRect.width, parent.library.stageRect.height);
		mat.translate(-0.5 * (mat.a - 1), -0.5 * (mat.d - 1));
		mat.concat(parent._matrix);

		camera.drawPixels(this._frame, this.framePixels, mat, this.colorTransform, parent.blend, false, parent.shader);
	}
}
