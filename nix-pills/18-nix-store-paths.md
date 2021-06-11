# Nix Store Paths

Welcome to the 18th Nix pill. In the previous
[17th](#nixpkgs-overriding-packages) pill we have scratched the surface
of the `nixpkgs` repository structure. It is a set of packages, and it's
possible to override such packages so that all other packages will use
the overrides.

Before reading existing derivations, I'd like to talk about store paths
and how they are computed. In particular we are interested in fixed
store paths that depend on an integrity hash (e.g. a sha256), which is
usually applied to source tarballs.

The way store paths are computed is a little contrived, mostly due to
historical reasons. Our reference will be the [Nix source
code](https://github.com/NixOS/nix/blob/07f992a74b64f4376d5b415d0042babc924772f3/src/libstore/store-api.cc#L197).

## Source paths

Let's start simple. You know nix allows relative paths to be used, such
that the file or directory is stored in the nix store, that is
`./myfile` gets stored into `/nix/store/.......` We want to understand
how is the store path generated for such a file:

    $ echo mycontent > myfile

I remind you, the simplest derivation you can write has a `name`, a
`builder` and the `system`:

Now inspect the .drv to see where is `./myfile` being stored:

Great, how did nix decide to use `xv2iccirbrvklck36f1g7vldn5v58vck` ?
Keep looking at the nix comments.

**Note:** doing `nix-store --add myfile` will store the file in the same
store path.

### Step 1, compute the hash of the file

The comments tell us to first compute the sha256 of the NAR
serialization of the file. Can be done in two ways:

Or:

In general, Nix understands two contents: flat for regular files, or
recursive for NAR serializations which can be anything.

### Step 2, build the string description

Then nix uses a special string which includes the hash, the path type
and the file name. We store this in another file:

    $ echo -n "source:sha256:2bfef67de873c54551d884fdab3055d84d573e654efa79db3c0d7b98883f9ee3:/nix/store:myfile" > myfile.str

### Step 3, compute the final hash

Finally the comments tell us to compute the base-32 representation of
the first 160 bits (truncation) of a sha256 of the above string:

## Output paths

Output paths are usually generated for derivations. We use the above
example because it's simple. Even if we didn't build the derivation, nix
knows the out path `hs0yi5n5nw6micqhy8l1igkbhqdkzqa1`. This is because
the out path only depends on inputs.

It's computed in a similar way to source paths, except that the .drv is
hashed and the type of derivation is `output:out`. In case of multiple
outputs, we may have different `output:<id>`.

At the time nix computes the out path, the .drv contains an empty string
for each out path. So what we do is getting our .drv and replacing the
out path with an empty string:

The `myout.drv` is the .drv state in which nix is when computing the out
path for our derivation:

Then nix puts that out path in the .drv, and that's it.

In case the .drv has input derivations, that is it references other
.drv, then such .drv paths are replaced by this same algorithm which
returns a hash.

In other words, you get a final .drv where every other .drv path is
replaced by its hash.

## Fixed-output paths

Finally, the other most used kind of path is when we know beforehand an
integrity hash of a file. This is usual for tarballs.

A derivation can take three special attributes: `outputHashMode`,
`outputHash` and `outputHashAlgo` which are well documented in the [nix
manual](https://nixos.org/nix/manual/#sec-advanced-attributes).

The builder must create the out path and make sure its hash is the same
as the one declared with `outputHash`.

Let's say our builder should create a file whose contents is
`mycontent`:

Inspect the .drv and see that it also stored the fact that it's a
fixed-output derivation with sha256 algorithm, compared to the previous
examples:

It doesn't matter which input derivations are being used, the final out
path must only depend on the declared hash.

What nix does is to create an intermediate string representation of the
fixed-output content:

Then proceed as it was a normal derivation output path:

Hence, the store path only depends on the declared fixed-output hash.

## Conclusion

There are other types of store paths, but you get the idea. Nix first
hashes the contents, then creates a string description, and the final
store path is the hash of this string.

Also we've introduced some fundamentals, in particular the fact that Nix
knows beforehand the out path of a derivation since it only depends on
the inputs. We've also introduced fixed-output derivations which are
especially used by the nixpkgs repository for downloading and verifying
source tarballs.

## Next pill

...we will introduce `stdenv`. In the previous pills we rolled our own
`mkDerivation` convenience function for wrapping the builtin derivation,
but the `nixpkgs` repository also has its own convenience functions for
dealing with autotools projects and other build systems.
