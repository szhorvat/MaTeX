(* Paclet Info File *)

Paclet[
  Name -> "MaTeX",
  Version -> "1.7.8",
  MathematicaVersion -> "10.0+",
  Description -> "Create LaTeX-typeset labels within Mathematica.",
  "Keywords" -> {"LaTeX", "Typesetting", "Graphics"},
  Creator -> "Szabolcs Horv\[AAcute]t <szhorvat@gmail.com>",
  URL -> "http://szhorvat.net/mathematica/MaTeX",
  Thumbnail -> "Logo.png",
  "Icon" -> "Logo.png", (* M12.1+ uses Icon instead of Thumbnail. *)
  Extensions ->
      {
        {"Documentation", Language -> All, MainPage -> "Guides/MaTeX"},
        {"Kernel", Root -> ".", Context -> "MaTeX`"}
      }
]
