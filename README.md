# MaTeX

Create LaTeX labels in Mathematica.

##Usage

Use `MaTeX[texcode]` or `MaTeX[expression]` to typeset using LaTeX.  The latter will automatically apply `TeXForm` to `expression`.

The LaTeX code is interpreted in math mode.  Remember to escape backlashes when writing LaTeX code in Mathematica strings, e.g. 

    MaTeX["\\sum_{k=1}^{\\infty} \frac{1}{k}"]

For now, `MaTeX` always uses 12 pt fonts.  Use the `Magnification` option to get larger output.  For example, `MaTeX["\\sin x", Magnification -> 16/12]` will give 16 pt size.

##Notes on performance

The limiting factor in the speed of `MaTeX`-calls is running the `pdflatex` process.  This cannot be sped up further.  However, MaTeX caches results, making subsequent calls with the same TeX code near-instantaneous.

##Feedback

MaTeX is still work in progress, and was primarily created for my own needs.  However, if you find it useful, feel free to drop me an email.

Send feedback or bug reports to `szhorvat` at `gmail.com` or open an issue in the tracker.
