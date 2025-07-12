<p align="center">
   <img src="https://github.com/user-attachments/assets/5d7f7ca3-dc29-46d8-8d3d-fa354b669091" alt="flixel-animate-logo-vector" width="530" height="260">
</p>

Flixel-animate is a [HaxeFlixel](https://haxeflixel.com/) library meant to load texture atlases generated both from Adobe Animate and the [BetterTextureAtlas plugin](https://github.com/Dot-Stuff/BetterTextureAtlas).
The library is heavily inspired by [FlxAnimate](https://github.com/Dot-Stuff/flxanimate), though with some differences to work similarly to the Flash/Animate JSFL implementation.

> [!WARNING]
> ``flixel-animate`` uses a bounds method that acts similarly to how a normal Sparrow flixel sprite would load. <br/>
> This "flixel accurate" bounds come with support for functions that require accurate ``width`` and ``height`` values like ``updateHitbox`` and ``centerOrigin``, which give closer parity with FlxSprite.
> If you are migrating from ``FlxAnimate`` these bounds may be different to FlxAnimate's ones. <br/>
> This offset value can be accessible through the function ``getBoundsOrigin`` inside each ``Timeline`` object. <br/>

## Usage

### General Information

To create a sprite with a loaded texture atlas, create an ``FlxAnimate`` sprite object.
The class ``FlxAnimate`` is meant as a replacement to ``FlxSprite``, its capable of loading both
normal atlases (such as Sparrow) and Adobe Animate texture atlases.

Here's a small sample:

```haxe
import animate.FlxAnimate;
import animate.FlxAnimateFrames;

var sprite:FlxAnimate = new FlxAnimate();
sprite.frames = FlxAnimateFrames.fromAnimate('path/to/atlas');
add(sprite);

sprite.anim.addByTimeline("main animation", sprite.library.timeline);
sprite.anim.play("main animation");
```

Note that ``sprite.anim`` is the same object as ``sprite.animation``!
You can use any of them, at your own choice, they both will play both texture atlas and normal flixel animations.
``sprite.anim`` only exists for type safety so you can access extra functions like ``addByTimeline`` and such.

### Adding Animations

Here's a list of all the ways to add animations when using an Adobe Animate texture atlas.

```haxe
sprite.anim.addBySymbol("symbolAnim", "symbolName");
sprite.anim.addBySymbolIndices("symbolAnim", "symbolName", [0, 1, 2, 3]);

sprite.anim.addByTimeline("tlAnim", someTimelineObject);
sprite.anim.addByTimelineIndices("tlIndicesAnim", someTimelineObject, [0, 1, 2, 3]);

sprite.anim.addByFrameLabel("labelAnim", "frameLabelName");
sprite.anim.addByFrameLabelIndices("labelIndicesAnim", "frameLabelName", [0, 1, 2, 3])
```

## Installation

To install ``flixel-animate``, there are two ways to obtain it:

1. ``Haxelib Installation``: This provides the latest stable version of ``flixel-animate``.

   ```bash
   haxelib install flixel-animate
   ```

3. ``Haxelib Git Installation``: This provides the latest version of ``flixel-animate`` from the Repository.

   ```bash
   haxelib git flixel-animate https://github.com/MaybeMaru/flixel-animate.git
   ```

Once you have ``flixel-animate`` installed, you'll need to add it to your project to use. <br/>
You will need to add the following code to your ``project.xml`` file:

   ```xml
   <haxelib name="flixel-animate" />
   ```
