package animate.internal.filters;

import animate.internal.filters.Blend;
import openfl.display.BitmapData;
import openfl.display.GraphicsShader;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class MaskShader extends GraphicsShader
{
	@:glFragmentSource('
        #pragma header
        
        uniform sampler2D maskBitmap;
        uniform vec2 maskUVOffset;
        uniform vec2 maskUVScale;
        
        void main()
        {
            vec4 color = texture2D(bitmap, openfl_TextureCoordv);
            
			vec2 maskCoord = (openfl_TextureCoordv * maskUVScale) + maskUVOffset;			
			vec4 maskerColor = texture2D(maskBitmap, maskCoord);
        
            color *= maskerColor.a;
            gl_FragColor = color;
        }
    ')
	public function new()
	{
		super();
	}

	public function setup(masked:BitmapData, masker:BitmapData, x:Float, y:Float)
	{
		this.maskBitmap.input = masker;
		this.maskUVOffset.value = [x / masker.width, y / masker.height];
		this.maskUVScale.value = [masked.width / masker.width, masked.height / masker.height];
		return this;
	}

	static var shader(get, null):MaskShader;

	inline static function get_shader()
	{
		return shader ?? (shader = new MaskShader());
	}

	public static function maskAlpha(masked:BitmapData, masker:BitmapData, rect:Rectangle) @:privateAccess
	{
		if (masked == null || masker == null || masked.width <= 0 || masked.height <= 0 || masker.width <= 0 || masker.height <= 0)
			return;

		var shader = shader.setup(masked, masker, rect.x, rect.y);
		FilterRenderer.renderWithShader(masked, masked.clone(), shader);
	}
}
