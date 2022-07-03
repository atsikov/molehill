# Molehill

> This is a legacy project intended for historical and educational purposes only

Molehill was a codename for the new Stage3D (3D hardware accelerated render) in FlashPlayer, presented back in 2011.

This library is a 2D sprite render and input handling engine, developed mostly by me with some help of Kirill Kovanov at later stages to build Facebook games while working at [Game Insight](https://www.game-insight.com/).

The engine provided smooth content-rich render (though depends on hardware) and made it easier to port assets from Unity-based mobile games.

`/tools` folder contains texture atlas packer and visual prefabs editor.

## Highlights

Features include but not limited to

* API similar to FlashPlayer's display list (a tree of sprites with a possibility to group them into containers)
* Separate UI layer
* Virtual tree and reconcilation mechanism
* Texture batching to minimise draw calls
* Sprite sheets support
* Particles system
* Masking

## Examples

Two games were released using the engine:
* Sky Adventures
* Transport Empire

Due to FlashPlayer discontinuation back in 2020, the examples are only available as youtube videos recoded by players themselves.

All videos are a property of their authors.

https://www.youtube.com/watch?v=Ep8YE_Tcfzk
