package animate;

import animate.internal.filters.AdjustColorFilter;
import flixel.math.FlxMatrix;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.filters.BitmapFilterType;
import openfl.filters.BlurFilter;
import openfl.filters.DropShadowFilter;
import openfl.filters.GlowFilter;

using StringTools;

typedef SpritemapJson =
{
	ATLAS:
	{
		SPRITES:Array<SpriteJson>
	}
}

typedef SpriteJson =
{
	SPRITE:
	{
		name:String, x:Int, y:Int, w:Int, h:Int, rotated:Bool
	}
}

abstract AnimationJson(Dynamic)
{
	public var AN(get, never):AnimationDataJson;
	public var SD(get, never):Null<Array<SymbolJson>>;
	public var MD(get, never):MetadataJson;

	inline function get_AN()
		return this.AN ?? this.ANIMATION;

	inline function get_SD()
		return this.SD?.S ?? this.SYMBOL_DICTIONARY?.Symbols;

	inline function get_MD()
		return this.MD ?? this.metadata;
}

abstract AnimationDataJson(Dynamic)
{
	public var N(get, never):String;
	public var SN(get, never):String;
	public var TL(get, never):TimelineJson;
	public var STI(get, never):Null<SymbolInstanceJson>;

	inline function get_N()
		return this.N ?? this.name;

	inline function get_SN()
		return this.SN ?? this.SYMBOL_name;

	inline function get_TL()
		return this.TL ?? this.TIMELINE;

	inline function get_STI()
		return this.STI?.SI ?? this.StageInstance?.SYMBOL_Instance ?? null;
}

abstract TimelineJson(Dynamic)
{
	public var L(get, never):Array<LayerJson>;

	inline function get_L()
		return this.L ?? this.LAYERS;
}

abstract LayerJson(Dynamic)
{
	public var LN(get, never):String;

	public var LT(get, never):Null<String>;
	public var Clpb(get, never):Null<String>;

	public var FR(get, never):Array<FrameJson>;

	inline function get_LN()
		return this.LN ?? this.Layer_name;

	inline function get_LT()
		return this.LT ?? this.Layer_type;

	inline function get_Clpb()
		return this.Clpb ?? this.Clipped_by;

	inline function get_FR()
		return this.FR ?? this.Frames;
}

abstract FrameJson(Dynamic)
{
	public var I(get, never):Int;
	public var DU(get, never):Int;
	public var E(get, never):Array<ElementJson>;

	public var N(get, never):Null<String>;

	public var SND(get, never):SoundJson;

	inline function get_I()
		return this.I ?? this.index;

	inline function get_DU()
		return this.DU ?? this.duration;

	inline function get_E()
		return this.E ?? this.elements;

	inline function get_N()
		return this.N ?? this.name;

	inline function get_SND()
		return this.SND;
}

typedef SoundJson =
{
	N:String,
	SNC:String,
	LP:String,
	RP:Int
}

abstract ElementJson(Dynamic)
{
	public var SI(get, never):Null<SymbolInstanceJson>;
	public var ASI(get, never):Null<AtlasInstanceJson>;

	inline function get_SI()
		return this.SI ?? this.SYMBOL_Instance;

	inline function get_ASI()
		return this.ASI ?? this.ATLAS_SPRITE_instance;
}

abstract SymbolInstanceJson(Dynamic)
{
	public var SN(get, never):String;
	public var FF(get, never):Int;
	public var ST(get, never):String;
	public var TRP(get, never):TransformationPointJson;
	public var LP(get, never):String;
	public var MX(get, never):MatrixJson;

	public var B(get, never):Null< #if flash Int #else BlendMode #end>;
	public var C(get, never):Null<ColorJson>;
	public var F(get, never):Null<Array<FilterJson>>;

	inline function get_SN()
		return this.SN ?? this.SYMBOL_name;

	inline function get_FF()
		return this.FF ?? this.firstFrame ?? 0;

	inline function get_ST()
		return this.ST ?? this.symbolType;

	inline function get_TRP()
		return this.TRP ?? this.transformationPoint;

	inline function get_LP()
		return this.LP ?? this.loop;

	inline function get_MX()
		return MatrixJson.resolve(this);

	function get_B()
	{
		var blend:Dynamic = this.B ?? this.blend;
		if (blend != null) // blends from BTA
			return blend;

		var blend:Null<String> = this.IN;
		if (blend != null && blend.length > 0)
		{
			if (blend.contains("_bl")) // legacy blends method
			{
				var index:Int = Std.parseInt(blend.split("_bl")[1].split("_")[0]);
				return this.B = index;
			}
		}

		return null;
	}

	inline function get_C()
		return this.C ?? this.color;

	inline function get_F()
	{
		var filters:Dynamic = this.F ?? this.filters;
		if (filters == null || filters is Array)
			return filters;
		return this.F = FilterJson.resolve(filters);
	}
}

abstract FilterJson(Dynamic)
{
	public var N(get, never):String;
	public var BLX(get, never):Null<Float>;
	public var BLY(get, never):Null<Float>;
	public var Q(get, never):Null<Int>;
	public var BRT(get, never):Null<Int>;
	public var H(get, never):Null<Int>;
	public var CT(get, never):Null<Int>;
	public var SAT(get, never):Null<Int>;
	public var D(get, never):Null<Float>;
	public var KK(get, never):Null<Bool>;
	public var T(get, never):String;
	public var STR(get, never):Null<Float>;
	public var A(get, never):Null<Float>;
	public var SC(get, never):String;
	public var HC(get, never):String;
	public var IN(get, never):Null<Bool>;
	public var HO(get, never):Null<Bool>;
	public var C(get, never):String;
	public var CA(get, never):Array<Dynamic>;
	public var GE(get, never):Array<GradientEntry>;

	inline function get_N()
		return this.N ?? this.name;

	inline function get_BLX()
		return this.BLX ?? this.blurX;

	inline function get_BLY()
		return this.BLY ?? this.blurY;

	inline function get_Q()
		return this.Q ?? this.quality;

	inline function get_BRT()
		return this.BRT ?? this.brightness;

	inline function get_H()
		return this.H ?? this.hue;

	inline function get_CT()
		return this.CT ?? this.contrast;

	inline function get_SAT()
		return this.SAT ?? this.saturation;

	inline function get_D()
		return this.D ?? this.distance;

	inline function get_KK()
		return this.KK ?? this.knockout;

	inline function get_T()
		return this.T ?? this.type;

	inline function get_STR()
		return this.STR ?? this.strength;

	inline function get_A()
		return this.A ?? this.angle;

	inline function get_SC()
		return this.SC ?? this.shadowColor;

	inline function get_HC()
		return this.HC ?? this.highlightColor;

	inline function get_IN()
		return this.IN ?? this.inner;

	inline function get_HO()
		return this.HO ?? this.hideObject;

	inline function get_C()
		return this.C ?? this.color;

	inline function get_CA()
		return this.CA ?? this.colorArray;

	inline function get_GE()
		return this.GE ?? this.GradientEntries;

	function getGradientArray():{colors:Array<Int>, alphas:Array<Float>, ratios:Array<Float>}
	{
		var colors:Array<Int> = [];
		var alphas:Array<Float> = [];
		var ratios:Array<Float> = [];

		for (entry in GE)
		{
			colors.push(FlxColor.fromString(entry.C));
			alphas.push(entry.A);
			ratios.push(entry.R);
		}

		return {
			colors: colors,
			alphas: alphas,
			ratios: ratios
		}
	}

	function getBitmapFilterType():BitmapFilterType
	{
		var type:Null<String> = T;
		return (type == null) ? BitmapFilterType.INNER : switch (type)
		{
			case "full":
				BitmapFilterType.FULL;
			case "outer":
				BitmapFilterType.OUTER;
			default:
				BitmapFilterType.INNER;
		}
	}

	public function toBitmapFilter():BitmapFilter
	{
		switch (this.N)
		{
			case "blurFilter" | "BLF":
				var blf = new BlurFilter(BLX, BLY, Q);
				return blf;

			case "adjustColorFilter" | "ACF":
				var acf = new AdjustColorFilter();
				acf.set(BRT, H, CT, SAT);
				return acf.filter;

			case "dropShadowFilter" | "DSF":
				var dsf = new DropShadowFilter(D, A, FlxColor.fromString(C), 1.0, BLX, BLY, STR, Q, IN, KK, HO);
				return dsf;

			case "glowFilter" | "GF":
				var gf = new GlowFilter(FlxColor.fromString(C), 1.0, BLX, BLY, STR, Q, IN, KK);
				return gf;

				// TODO: add bevel support for other targets
				// case "bevelFilter" | "BF":
				// case "gradientBevelFilter" | "GBF":
				// case "gradientGlowFilter" | "GGF":
			#if flash
			case "bevelFilter" | "BF":
				var highlightColor = FlxColor.fromString(HC);
				var shadowColor = FlxColor.fromString(SC);
				var type:BitmapFilterType = getBitmapFilterType();
				var bf = new flash.filters.BevelFilter(D, A, highlightColor, 1, shadowColor, 1, BLX, BLY, STR, Q, type, KK);
				return bf;

			case "gradientBevelFilter" | "GBF":
				var type:BitmapFilterType = getBitmapFilterType();
				var ga = getGradientArray();
				var gbf = new flash.filters.GradientBevelFilter(D, A, ga.colors, ga.alphas, ga.ratios, BLX, BLY, STR, Q, type, KK);
				return gbf;

			case "gradientGlowFilter" | "GGF":
				var type:BitmapFilterType = getBitmapFilterType();
				var ga = getGradientArray();
				var ggf = new flash.filters.GradientGlowFilter(D, A, ga.colors, ga.alphas, ga.ratios, BLX, BLY, STR, Q, type, KK);
				return ggf;
			#end

			default:
				return null;
		}
	}

	public static function resolve(input:Dynamic):Array<FilterJson>
	{
		if (input == null || input is Array)
			return input;

		var filters:Array<FilterJson> = [];
		for (filter in Reflect.fields(input))
		{
			var filterJson:Dynamic = Reflect.field(input, filter);
			filterJson.N = switch (filter)
			{
				case "DropShadowFilter": "DSF";
				case "GlowFilter": "GF";
				case "BevelFilter": "BF";
				case "BlurFilter": "BLF";
				case "AdjustColorFilter": "ACF";
				case "GradientGlowFilter": "GGF";
				case "GradientBevelFilter": "GBF";
				default: filter;
			}
			filters.push(filterJson);
		}

		return filters;
	}
}

abstract GradientEntry(Dynamic)
{
	public var R(get, never):Float;
	public var C(get, never):String;
	public var A(get, never):Float;

	inline function get_R()
		return this.R ?? this.ratio;

	inline function get_C()
		return this.C ?? this.color;

	inline function get_A()
		return this.A ?? this.alpha;
}

abstract AtlasInstanceJson(Dynamic)
{
	public var N(get, never):String;
	public var MX(get, never):MatrixJson;

	inline function get_N()
		return this.N ?? this.name;

	inline function get_MX()
		return MatrixJson.resolve(this);
}

abstract SymbolJson(Dynamic)
{
	public var SN(get, never):String;
	public var TL(get, never):TimelineJson;

	inline function get_SN()
		return this.SN ?? this.SYMBOL_name;

	inline function get_TL()
		return this.TL ?? this.TIMELINE;
}

abstract MetadataJson(Dynamic)
{
	public var V(get, never):String;
	public var FRT(get, never):Float;

	public var W(get, never):Int;
	public var H(get, never):Int;
	public var BGC(get, never):String;

	inline function get_V()
		return this.V ?? this.version;

	inline function get_FRT()
		return this.FRT ?? this.framerate;

	inline function get_W()
		return this.W ?? this.width ?? 0;

	inline function get_H()
		return this.H ?? this.height ?? 0;

	inline function get_BGC()
		return this.BGC ?? this.backgroundColor ?? "#FFFFFF";
}

abstract ColorJson(Dynamic)
{
	public var M(get, never):String;
	public var RM(get, never):Null<Float>;
	public var GM(get, never):Null<Float>;
	public var BM(get, never):Null<Float>;
	public var AM(get, never):Null<Float>;
	public var RO(get, never):Null<Float>;
	public var GO(get, never):Null<Float>;
	public var BO(get, never):Null<Float>;
	public var AO(get, never):Null<Float>;
	public var TC(get, never):Null<String>;
	public var TM(get, never):Null<Float>;
	public var BRT(get, never):Null<Float>;

	inline function get_M()
		return this.M ?? this.mode;

	inline function get_RM()
		return this.RM ?? this.RedMultiplier;

	inline function get_GM()
		return this.GM ?? this.greenMultiplier;

	inline function get_BM()
		return this.BM ?? this.blueMultiplier;

	inline function get_AM()
		return this.AM ?? this.alphaMultiplier;

	inline function get_RO()
		return this.RO ?? this.redOffset;

	inline function get_GO()
		return this.GO ?? this.greenOffset;

	inline function get_BO()
		return this.BO ?? this.blueOffset;

	inline function get_AO()
		return this.AO ?? this.AlphaOffset;

	inline function get_TC()
		return this.TC ?? this.tintColor;

	inline function get_TM()
		return this.TM ?? this.tintMultiplier;

	inline function get_BRT()
		return this.BRT ?? this.brightness;
}

typedef TransformationPointJson =
{
	x:Float,
	y:Float
}

abstract MatrixJson(Array<Float>) from Array<Float>
{
	public var a(get, never):Float;
	public var b(get, never):Float;
	public var c(get, never):Float;
	public var d(get, never):Float;
	public var tx(get, never):Float;
	public var ty(get, never):Float;

	public static function resolve(input:Dynamic):MatrixJson
	{
		var mat2D:Null<MatrixJson> = input.MX ?? input.Matrix;
		if (mat2D != null)
			return mat2D;

		var m:Dynamic = input.M3D ?? input.Matrix3D;
		var mat3D:Array<Float>;

		if (m is Array)
		{
			mat3D = m;
		}
		else
		{
			mat3D = [
				m.m00, m.m01, m.m02, m.m03, m.m10, m.m11, m.m12, m.m13, m.m20, m.m21, m.m22, m.m23, m.m30, m.m31, m.m32, m.m33
			];
		}

		return [mat3D[0], mat3D[1], mat3D[4], mat3D[5], mat3D[12], mat3D[13]];
	}

	public inline function toMatrix():FlxMatrix
	{
		return new FlxMatrix(a, b, c, d, tx, ty);
	}

	inline function get_a()
		return this[0];

	inline function get_b()
		return this[1];

	inline function get_c()
		return this[2];

	inline function get_d()
		return this[3];

	inline function get_tx()
		return this[4];

	inline function get_ty()
		return this[5];
}
