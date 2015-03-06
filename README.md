# MaTeX

Create LaTeX labels in *Mathematica*.

##Installation

 - Place [`MaTeX.m`](https://github.com/szhorvat/MaTeX/raw/master/MaTeX.m) in the directory opened by `SystemOpen@FileNameJoin[{$UserBaseDirectory, "Applications"}]`.
 - Make sure that a TeX system and Ghostscript 9.15 or later are installed.  For OS X, get Ghostscript from [here](http://pages.uoregon.edu/koch/).
 - Evalate ``Needs["MaTeX`"]`` and follow the instructions on how to configure the path to the `pdflatex` and Ghostscript executables.  *Note:* On Windows systems use the command line Ghostscript executable, i.e. the one with the name ending in `c`: `gswin32c.exe` or `gswin64c.exe`.
 
**Update:** Nasser Abbasi has provided [detailed installation instructions for Windows systems](https://dl.dropboxusercontent.com/u/38623/using_matex_updated.pdf).  Thank you!


##Usage

Use `MaTeX[texcode]` or `MaTeX[expression]` to typeset using LaTeX.  The latter will automatically apply `TeXForm` to `expression`.

The LaTeX code is interpreted in math mode.  Remember to escape backlashes when writing LaTeX code in Mathematica strings, e.g. 

    MaTeX["\\sum_{k=1}^{\\infty} \\frac{1}{k}"]

For now, `MaTeX` always uses 12 pt fonts.  Use the `Magnification` option to get larger output.  For example, `MaTeX["\\sin x", Magnification -> 16/12]` will give 16 pt size.

##Notes on performance

The limiting factor in the speed of `MaTeX`-calls is running the `pdflatex` process, which might take as long as a second and cannot be sped up further.  However, MaTeX caches results, making subsequent calls with the same TeX code near-instantaneous.

##Feedback

MaTeX is still work in progress, and was primarily created for my own needs.  However, if you find it useful, feel free to drop me an email.

Send feedback or bug reports to `szhorvat` at `gmail.com` or open an issue in the tracker.
