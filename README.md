# MaTeX

Create LaTeX labels in Mathematica

##Usage

Use `MaTeX[texcode]` or `MaTeX[expression]`.  The latter will automatically apply `TeXForm` to expression.

##Notes on performance

The limiting factor in the speed of `MaTeX`-calls is running the `pdflatex` process.  This cannot be sped up further.  However, MaTeX caches results, making subsequent calls with the same TeX code near-instantaneous.

##Feedback

Send feedback or bug reports to `szhorvat` at `gmail.com` or open an issue in the tracker.