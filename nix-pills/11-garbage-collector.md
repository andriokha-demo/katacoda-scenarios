# Garbage Collector

Welcome to the 11th Nix pill. In the previous [10th
pill](#developing-with-nix-shell) we managed to obtain a self-contained
development environment for a project. The concept is that `nix-build`
is able to build a derivation in isolation, while `nix-shell` is able to
drop us in a shell with (almost) the same environment used by
`nix-build`. This allows us to debug, modify and manually build
software.

Today we stop packaging and look at a mandatory nix component, the
garbage collector. When using nix tools, often derivations are built.
This include both .drv files and out paths. These artifacts go in the
nix store, but we've never cared about deleting them until now.

## How does it work

Other package managers, like `dpkg`, have ways of removing unused
software. Nix is much more precise in its garbage collection compared to
these other systems.

I bet with `dpkg`, `rpm` or similar traditional packaging systems, you
end up having some unnecessary packages installed or dangling files.
With nix this does not happen.

How do we determine whether a store path is still needed? The same way
programming languages with a garbage collector decide whether an object
is still alive.

Programming languages with a garbage collector have an important concept
in order to keep track of live objects: GC roots. A GC root is an object
that is always alive (unless explicitly removed as GC root). All objects
recursively referred to by a GC root are live.

Therefore, the garbage collection process starts from GC roots, and
recursively mark referenced objects as live. All other objects can be
collected and deleted.

In Nix there's this same concept. Instead of being objects, of course,
[GC roots are store paths](http://nixos.org/nix/manual/#ssec-gc-roots).
The implementation is very simple and transparent to the user. GC roots
are stored under `/nix/var/nix/gcroots`. If there's a symlink to a store
path, then that store path is a GC root.

Nix allows this directory to have subdirectories: it will simply recurse
directories in search of symlinks to store paths.

So we have a list of GC roots. At this point, deleting dead store paths
is as easy as you can imagine. We have the list of all live store paths,
hence the rest of the store paths are dead.

In particular, Nix first moves dead store paths to `/nix/store/trash`
which is an atomic operation. Afterwards, the trash is emptied.

## Playing with the GC

Before playing with the GC, first run the [nix garbage
collector](http://nixos.org/nix/manual/#sec-nix-collect-garbage) once,
so that we have a clean playground for our experiments:

Perfect, if you run it again it won't find anything new to delete, as
expected.

What's left in the nix store is everything being referenced from the GC
roots.

Let's install for a moment bsd-games:

The nix-store command can be used to query the GC roots that refer to a
given derivation. In this case, our current user environment does refer
to bsd-games.

Now remove it, collect garbage and note that bsd-games is still in the
nix store:

This is because the old generation is still in the nix store because
it's a GC root. As we'll see below, all profiles and their generations
are GC roots.

Removing a GC root is simple. Let's try deleting the generation that
refers to bsd-games, collect garbage, and note that now bsd-games is no
longer in the nix store:

*Note*: `nix-env --list-generations` does not rely on any particular
metadata. It is able to list generations based solely on the file names
under the profiles directory.

However we removed the link from `/nix/var/nix/profiles`, not from
`/nix/var/nix/gcroots`. Turns out, that `/nix/var/nix/gcroots/profiles`
is a symlink to `/nix/var/nix/profiles`. That is very handy. It means
any profile and its generations are GC roots.

It's as simple as that, anything under `/nix/var/nix/gcroots` is a GC
root. And anything not being garbage collected is because it's referred
from one of the GC roots.

## Indirect roots

Remember that building the GNU hello world package with `nix-build`
produces a `result` symlink in the current directory. Despite the
collected garbage done above, the `hello` program is still working:
therefore it has not been garbage collected. Clearly, since there's no
other derivation that depends upon the GNU hello world package, it must
be a GC root.

In fact, `nix-build` automatically adds the result symlink as a GC root.
Yes, not the built derivation, but the symlink. These GC roots are added
under `/nix/var/nix/gcroots/auto`.

Don't care about the name of the symlink. What's important is that a
symlink exists that point to `/home/nix/result`. This is called an
**indirect GC root**. That is, the GC root is effectively specified
outside of `/nix/var/nix/gcroots`. Whatever `result` points to, it will
not be garbage collected.

How do we remove the derivation then? There are two possibilities:

-   Remove the indirect GC root from `/nix/var/nix/gcroots/auto`.

-   Remove the `result` symlink.

In the first case, the derivation will be deleted from the nix store,
and `result` becomes a dangling symlink. In the second case, the
derivation is removed as well as the indirect root in
`/nix/var/nix/gcroots/auto`.

Running `nix-collect-garbage` after deleting the GC root or the indirect
GC root, will remove the derivation from the store.

## Cleanup everything

What's the main source of software duplication in the nix store?
Clearly, GC roots due to `nix-build` and profile generations. Doing a
`nix-build` results in a GC root for a build that somehow will refer to
a specific version of glibc, and other libraries. After an upgrade, if
that build is not deleted by the user, it will not be garbage collected.
Thus the old dependencies referred to by the build will not be deleted
either.

Same goes for profiles. Manipulating the `nix-env` profile will create
further generations. Old generations refer to old software, thus
increasing duplication in the nix store after an upgrade.

What are the basic steps for upgrading and removing everything old,
including old generations? In other words, do an upgrade similar to
other systems, where they forget everything about the older state:

First, we download a new version of the nixpkgs channel, which holds the
description of all the software. Then we upgrade our installed packages
with `nix-env -u`. That will bring us into a fresh new generation with
all updated software.

Then we remove all the indirect roots generated by `nix-build`: beware,
this will result in dangling symlinks. You may be smarter and also
remove the target of those symlinks.

Finally, the `-d` option of `nix-collect-garbage` is used to delete old
generations of all profiles, then collect garbage. After this, you lose
the ability to rollback to any previous generation. So make sure the new
generation is working well before running the command.

## Conclusion

Garbage collection in Nix is a powerful mechanism to cleanup your
system. The nix-store commands allow us to know why a certain derivation
is in the nix store.

Cleaning up everything down to the oldest bit of software after an
upgrade seems a bit contrived, but that's the price of having multiple
generations, multiple profiles, multiple versions of software, thus
rollbacks etc.. The price of having many possibilities.

## Next pill

...we will package another project and introduce what I call the
"inputs" design pattern. We've only played with a single derivation
until now, however we'd like to start organizing a small repository of
software. The "inputs" pattern is widely used in nixpkgs; it allows us
to decouple derivations from the repository itself and increase
customization opportunities.
