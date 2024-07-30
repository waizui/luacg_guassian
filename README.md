# luacg Gaussian-Splatting


## Abstruct

This repositoty is a pure lua implementation of the rendering part of Gaussian-Splatting. No dependencies is needed, 
it's based on [luacg](https://github.com/waizui/luacg) project.
The main part of rendering a Gaussian(run.lua) has fewer than 200 lines of code, which is very easy to understand and make changes.

I also wrote the [explaination of 3D Gaussian-Splatting](https://waizui.github.io/posts/gaussian_splatting/gaussian_splatting.html).

## Usage

Clone this repo, download a lua interpreter if you haven't. cd to this repo and execute following command.

```bash
path_to_lua_interpreter ./run.lua
```

A picture named splatting.png will be generated, same as the following picture.

![pic](./splatting.png)
