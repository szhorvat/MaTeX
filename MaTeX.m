(* Mathematica Package  *)
(* Created by IntelliJ IDEA http://wlplugin.halirutan.de/ *)

(* :Title: MaTeX *)
(* :Author: Szabolcs Horvát <szhorvat@gmail.com> *)
(* :Context: MaTeX` *)
(* :Version: 0.3 *)
(* :Date: 2015-03-04 *)

(* :Mathematica Version: 10 *)
(* :Copyright: (c) 2015 Szabolcs Horvát *)

(* Abort for old, unsupported versions of Mathematica *)
If[$VersionNumber < 10,
  Print["MaTeX requires Mathematica 10 or later."];
  Abort[]
]

BeginPackage["MaTeX`"]

MaTeX::usage = "\
MaTeX[\"texcode\"] will compile texcode using LaTeX and import the result into Mathematica as graphics.  texcode must be a string containing valid math-mode LaTeX code.
MaTeX[expression] will convert expression to LaTeX using TeXForm, then compile it and import it back to Mathematica."

BlackFrame::usage = "BlackFrame is a setting for FrameStyle or AxesStyle that produces the default look in black instead of gray."

ConfigureMaTeX::usage = "\
ConfigureMaTeX[\"key1\" \[Rule] \"value1\", \"key2\" \[Rule] \"value2\", ...] will set configuration options for MaTeX and store them permanently.
ConfigureMaTeX[] returns the current configuration."

ClearMaTeXCache::usage = "ClearMaTeXCache[] will clear MaTeX's cache."

Begin["`Private`"] (* Begin Private Context *)

(* Load and check persistent configuration *)

$applicationDataDirectory = FileNameJoin[{$UserBaseDirectory, "ApplicationData", "MaTeX"}]
If[Not@DirectoryQ[$applicationDataDirectory], CreateDirectory[$applicationDataDirectory]]

$configFile = FileNameJoin[{$applicationDataDirectory, "config.m"}]

If[FileExistsQ[$configFile], $config = Import[$configFile, "Package"], $config = <||>]

$config = Join[<| "pdfLaTeX" -> None, "Ghostscript" -> None, "CacheSize" -> 100 |>, $config]
Export[$configFile, $config, "Package"]

(* True if file exists and is not a directory *)
fileQ[file_] := FileExistsQ[file] && Not@DirectoryQ[file]

checkConfig[] :=
  Module[{pdflatex, gs, pdflatexOK, gsOK, cacheSizeOK, gsver},
    pdflatex = $config["pdfLaTeX"];
    If[StringQ[pdflatex],
      If[fileQ[pdflatex],
        pdflatexOK = True,
        Print["pdfLaTeX is not found at " <> pdflatex];
        pdflatexOK = False
      ],
      Print["The path to pdfLaTeX is not configured."];
      pdflatexOK = False
    ];

    If[!pdflatexOK, Print["Please configure pdfLaTeX using ConfigureMaTeX[\"pdfLaTeX\" -> \"path to pdflatex executable...\"]"]];

    gs = $config["Ghostscript"];
    If[StringQ[gs],
      If[fileQ[gs],
        gsOK = True,
        Print["Ghostscript is not found at " <> gs];
        gsOK = False
      ],
      Print["The path to Ghostscipt is not configured."];
      gsOK= False
    ];

    If[gsOK,
      gsver = StringTrim@RunProcess[{gs, "--version"}, "StandardOutput"];
      If[Not@OrderedQ[{{9,15}, FromDigits /@ StringSplit[gsver, "."]}],
        Print["Ghostscript version " <> gsver <> " found.  MaTeX requires Ghostscript 9.15 or later."];
        gsOK = False;
      ]
    ];

    If[!gsOK, Print["Please configure Ghostscript using ConfigureMaTeX[\"Ghostscript\" -> \"path to gs executable...\"]"]];

    If[Not@TrueQ@NonNegative[$config["CacheSize"]],
      Print["CacheSize must be a nonnegative number.  Please update the configuration using ConfigureMaTeX[\"CacheSize\" -> ...]."];
      cacheSizeOK = False,
      cacheSizeOK = True
    ];

    $configOK = pdflatexOK && gsOK && cacheSizeOK;
  ]


(* XeTeX won't work on OS X and possibly other systems unless texbin is in the system path.
   This function appends that directory to the PATH environment variable if not already present. *)
fixSystemPath[] :=
    Module[{texpath, pathList, pathSeparator},
      If[Not[$configOK], Return[$Failed]];
      texpath = AbsoluteFileName@DirectoryName@ExpandFileName[$config["pdfLaTeX"]];
      pathSeparator = If[$OperatingSystem === "Windows", ";", ":"];
      pathList = Quiet[
        AbsoluteFileName /@ StringSplit[Environment["PATH"], pathSeparator],
        {AbsoluteFileName::nffil, AbsoluteFileName::fdnfnd}
      ];
      If[Not@MemberQ[pathList, texpath],
        SetEnvironment["PATH" -> Environment["PATH"] <> pathSeparator <> texpath]
      ];
      Environment["PATH"]
    ]


checkConfig[] (* check configuration and set $configOK *)
debugPrint["System path: ", fixSystemPath[]]


debugPrint["Configuration: ", $config]
debugPrint["Confguration is valid: ", $configOK]


ConfigureMaTeX::badkey = "Unknown configuration key: ``"

ConfigureMaTeX[rules___Rule] :=
    (Scan[
      If[KeyExistsQ[$config, First[#]], AppendTo[$config, #], Message[ConfigureMaTeX::badkey, First[#]]]&,
      {rules}
    ];
    checkConfig[];
    fixSystemPath[];
    Export[$configFile, $config, "Package"];
    Normal[$config]
    )


ranid[] := StringJoin@RandomChoice[CharacterRange["a", "z"], 16]


(* Create temporary directory *)
dirpath = FileNameJoin[{$TemporaryDirectory, StringJoin["MaTeX_", ranid[]]}]
debugPrint["Creating temporary directory: ", dirpath]
CreateDirectory[dirpath]


template = StringTemplate["\
\\documentclass[12pt,border=1pt]{standalone}
\\usepackage[utf8]{inputenc}
\\usepackage{lmodern}
`preamble`
\\begin{document}
\\fontsize{`fontsize`pt}{1.2em}\\selectfont
\\newbox\\MaTeXbox
\\setbox\\MaTeXbox\\hbox{\\strut$`display` `tex`$}%
\\typeout{MATEXDEPTH:\\the\\dp\\MaTeXbox}%
\\typeout{MATEXHEIGHT:\\the\\ht\\MaTeXbox}%
\\typeout{MATEXWIDTH:\\the\\wd\\MaTeXbox}%
\\unhbox\\MaTeXbox
\\end{document}
"]

parseTeXError[err_String] :=
    StringJoin@Riffle[
      StringDrop[#, 2] & /@ Select[
        StringSplit[err, "\n"],
        StringMatchQ[#, "! *"] &
      ],
      "\n"
    ]

(* This function is used to try to detect errors based on the log file.
   It is necessary because on Windows RunProcess doesn't capture the correct exit code. *)
texErrorQ[log_String] := Count[StringSplit[log, "\n"], line_ /; StringMatchQ[line, "! *"]] > 0

getDimensions[log_String] := Interpreter["Number"]@First@StringCases[log, RegularExpression["MATEX"<>#<>":(.+?)pt"] -> "$1"]& /@ {"WIDTH", "HEIGHT", "DEPTH"}

extractOption[g_, opt_] := opt /. Options[g, opt]


cache = <||>

SetAttributes[store, HoldFirst]
store[memoStore_, key_, value_] :=
    (AppendTo[memoStore, key -> value];
    If[Length[memoStore] > $config["CacheSize"], memoStore = Rest[memoStore]];
    value
    )

ClearMaTeXCache[] := (cache = <||>;)

Options[MaTeX] = {
  "Preamble" -> {"\\usepackage{amsmath,amssymb}"},
  "DisplayStyle" -> True,
  FontSize -> 12,
  Magnification -> 1
}

MaTeX::gserr = "Error while running Ghostscript."
MaTeX::texerr = "Error while running LaTeX:\n``"
MaTeX::importerr = "Failed to import PDF.  This is unexpected.  Please go to https://github.com/szhorvat/MaTeX for instructions on how to report this problem."
MaTeX::invopt = "Invalid option value: ``"

iMaTeX[tex_String, preamble_, display_, fontsize_] :=
    Module[{key, cleanup, name, content,
            texfile, pdffile, pdfgsfile, logfile, auxfile,
            return, result,
            width, height, depth},

      key = {tex, Sort[preamble], display, fontsize};
      If[KeyExistsQ[cache, key],
        Return[cache[key]]
      ];

      cleanup[] := If[fileQ[#], DeleteFile[#]]& /@ {texfile, pdffile, pdfgsfile, logfile, auxfile};
      name = ranid[];

      content = <|
          "preamble" -> StringJoin@Riffle[preamble, "\n"],
          "tex" -> tex,
          "display" -> If[display, "\\displaystyle", ""],
          "fontsize" -> fontsize
          |>;
      texfile = Export[FileNameJoin[{dirpath, name <> ".tex"}], template[content], "Text", CharacterEncoding -> "UTF-8"];
      pdffile = FileNameJoin[{dirpath, name <> ".pdf"}];
      pdfgsfile = FileNameJoin[{dirpath, name <> "-gs.pdf"}];
      logfile = FileNameJoin[{dirpath, name <> ".log"}];
      auxfile = FileNameJoin[{dirpath, name <> ".aux"}];

      return = RunProcess[{$config["pdfLaTeX"], "-halt-on-error", "-interaction=nonstopmode", texfile}, ProcessDirectory -> dirpath];

      If[return["ExitCode"] != 0 || texErrorQ[return["StandardOutput"]] (* workaround for Windows version *),
        Message[MaTeX::texerr, parseTeXError[return["StandardOutput"]]];
        cleanup[];
        Return[$Failed]
      ];

      {width, height, depth} = getDimensions[return["StandardOutput"]];
      width  += 2;
      height += depth+2;
      {width, height, depth} *= 72/72.27; (* correct for PostScript point *)

      return = RunProcess[{$config["Ghostscript"], "-o", pdfgsfile, "-dNoOutputFonts", "-sDEVICE=pdfwrite", pdffile}, ProcessDirectory -> dirpath];
      If[return["ExitCode"] != 0,
        Message[MaTeX::gserr];
        cleanup[];
        Return[$Failed]
      ];

      result = Import[pdfgsfile, "PDF"];
      cleanup[];
      If[result === $Failed,
        Message[MaTeX::importerr];
        Return[$Failed]
      ];

      result = First[result];
      result = Show[result, ImageSize -> {width, height}, BaselinePosition -> Scaled[depth/height]];

      store[cache, key, result]
    ]

MaTeX[tex_String, opt:OptionsPattern[]] :=
    Module[{preamble, mag, result},
      If[! $configOK, checkConfig[]; Return[$Failed]];
      preamble = OptionValue["Preamble"];
      If[Not@VectorQ[preamble, StringQ],
        Message[MaTeX::invopt, "Preamble" -> preamble];
        Return[$Failed]
      ];
      If[Not@BooleanQ@OptionValue["DisplayStyle"],
        Message[MaTeX::invopt, "DisplayStyle" -> OptionValue["DisplayStyle"]];
        Return[$Failed]
      ];
      If[Not[NumberQ@OptionValue[FontSize] && TrueQ@Positive@OptionValue[FontSize]],
        Message[MaTeX::invopt, FontSize -> OptionValue[FontSize]];
        Return[$Failed]
      ];
      mag = OptionValue[Magnification];
      If[Not[NumericQ[mag] && TrueQ@Positive[mag]],
        Message[MaTeX::invopt, Magnification -> mag];
        Return[$Failed]
      ];
      result = iMaTeX[tex, preamble, OptionValue["DisplayStyle"], OptionValue[FontSize]];
      If[result === $Failed || TrueQ[mag == 1], result, Show[result, ImageSize -> N[mag] extractOption[result, ImageSize]]]
    ]

MaTeX[tex_StringForm, opt:OptionsPattern[]] := MaTeX[ToString[tex], opt]

MaTeX[tex_, opt:OptionsPattern[]] := MaTeX[ToString@TeXForm[tex], opt]


BlackFrame = Directive[AbsoluteThickness[0.5], Black]

End[] (* End Private Context *)

EndPackage[]
