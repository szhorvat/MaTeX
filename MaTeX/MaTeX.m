(* Mathematica Package  *)
(* Created by IntelliJ IDEA http://wlplugin.halirutan.de/ *)

(* :Title: MaTeX *)
(* :Author: Szabolcs Horvát <szhorvat@gmail.com> *)
(* :Context: MaTeX` *)
(* :Version: %%version%% *)
(* :Date: 2015-03-04 *)

(* :Mathematica Version: %%mathversion%% *)
(* :Copyright: (c) 2016 Szabolcs Horvát *)

(* Abort for old, unsupported versions of Mathematica *)
If[$VersionNumber < 10,
  Print["MaTeX requires Mathematica 10.0 or later."];
  Abort[]
]

If[$OperatingSystem === "Windows" && $VersionNumber == 10.0 && $SystemWordLength == 32,
  Print[
    "WARNING: MaTeX may not work with 32-bit versions of Mathematica 10.0 on Windows. " <>
    "If you encounter problems, consider using a 64-bit version or upgrading to a later Mathematica version."
  ]
]

BeginPackage["MaTeX`"];

Unprotect /@ Names["MaTeX`*"];

MaTeX::usage = "\
MaTeX[\"texcode\"] compiles texcode using LaTeX and returns the result as Mathematica graphics.  texcode must be valid inline math-mode LaTeX code.
MaTeX[expression] converts expression to LaTeX using TeXForm, then compiles it and returns the result.
MaTeX[{expr1, expr2, \[Ellipsis]}] processes all expressions while running LaTeX only once.  A list of results is returned.";

BlackFrame::usage = "BlackFrame is a setting for FrameStyle or AxesStyle that produces the default look in black instead of gray.";

ConfigureMaTeX::usage = "\
ConfigureMaTeX[\"key1\" \[Rule] \"value1\", \"key2\" \[Rule] \"value2\", \[Ellipsis]] sets configuration options for MaTeX and stores them permanently.
ConfigureMaTeX[] returns the current configuration.";

ClearMaTeXCache::usage = "ClearMaTeXCache[] clears MaTeX's cache.";

`Developer`$Version = "%%version%% (%%date%%)";

Begin["`Private`"]; (* Begin Private Context *)


(* workaround for Mathematica bug on Windows where RunProcess fails when run in directories with special chars in name *)
If[$OperatingSystem === "Windows",
  runProcess[args___] :=
      Module[{res},
        SetDirectory["\\"];
        res = RunProcess[args];
        ResetDirectory[];
        res
      ]
  ,
  runProcess = RunProcess
];


(* Load and check persistent configuration *)

$applicationDataDirectory = FileNameJoin[{$UserBaseDirectory, "ApplicationData", "MaTeX"}];
If[Not@DirectoryQ[$applicationDataDirectory], CreateDirectory[$applicationDataDirectory]]

$configFile = FileNameJoin[{$applicationDataDirectory, "config.m"}];

(* The following are best guess configurations for first-time setup *)

$defaultConfigBase = <| "pdfLaTeX" -> None, "Ghostscript" -> None, "CacheSize" -> 100 |>;

$defaultConfigOSX := <|
    "Ghostscript" -> Quiet@Check[If[FileExistsQ["/usr/local/bin/gs"], "/usr/local/bin/gs", None], None],
    "pdfLaTeX" -> Quiet@Check[If[FileExistsQ["/Library/TeX/texbin/pdflatex"], "/Library/TeX/texbin/pdflatex", None], None]
|>;

$defaultConfigLinux := <|
    "Ghostscript" -> Quiet@Check[First@ReadList["!which gs", String, 1], None],
    "pdfLaTeX" -> Quiet@Check[First@ReadList["!which pdflatex", String, 1], None]
|>;

winFindGS[] :=
    Quiet@Check[Module[{base, keys, vals, key, dll, exe},
      base = "HKEY_LOCAL_MACHINE\\SOFTWARE\\GPL Ghostscript";
      keys = Developer`EnumerateRegistrySubkeys[base];
      If[keys === $Failed,
        Return[None]
      ];
      key = Last@Sort[keys];
      vals = Developer`ReadRegistryKeyValues[base <> "\\" <> key];
      dll = Lookup[vals, "GS_DLL", $Failed];
      If[dll === $Failed,
        Return[None]
      ];
      If[Not@FileExistsQ[dll],
        Return[None]
      ];
      Switch[FileNameTake[dll],
        "gsdll64.dll", exe = "gswin64c.exe",
        "gsdll32.dll", exe = "gswin32c.exe",
        _, Return[None]
      ];
      AbsoluteFileName@FileNameJoin[{DirectoryName[dll], exe}]
    ], None]

winFindPL[] := Quiet@Check[AbsoluteFileName@First@ReadList["!where pdflatex.exe", String, 1], None]

$defaultConfigWindows := <|
    "Ghostscript" -> winFindGS[],
    "pdfLaTeX" -> winFindPL[]
|>

$defaultConfig :=
    Switch[$OperatingSystem,
      "MacOSX", Join[$defaultConfigBase, $defaultConfigOSX],
      "Unix", Join[$defaultConfigBase, $defaultConfigLinux],
      "Windows", Join[$defaultConfigBase, $defaultConfigWindows],
      _, $defaultConfigBase
    ]

(* Load configuration, if it exists *)
If[FileExistsQ[$configFile], $config = Import[$configFile, "Package"], $config = <||>];
If[Not@AssociationQ[$config],
  Print["The MaTeX configuration was corrupted so it had to be re-set. If you can reproduce this problem, please go to https://github.com/szhorvat/MaTeX and create a bug report."];
  $config = <||>
];

If[Not@SubsetQ[Keys[$config], Keys[$defaultConfigBase]],
  $config = Join[$defaultConfig, $config]
];
Export[$configFile, $config, "Package"];

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

    If[!pdflatexOK, Print["Please configure pdfLaTeX using ConfigureMaTeX[\"pdfLaTeX\" -> \"path to pdflatex executable\[Ellipsis]\"]"]];

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
      gsver = StringTrim@runProcess[{gs, "--version"}, "StandardOutput"];
      If[Not@OrderedQ[{{9,15}, FromDigits /@ StringSplit[gsver, "."]}],
        Print["Ghostscript version " <> gsver <> " found.  MaTeX requires Ghostscript 9.15 or later."];
        gsOK = False;
      ]
    ];

    If[!gsOK, Print["Please configure Ghostscript using ConfigureMaTeX[\"Ghostscript\" -> \"path to gs executable\[Ellipsis]\"]"]];

    If[Not@TrueQ[$config["CacheSize"] === Infinity || (IntegerQ[$config["CacheSize"]] && NonNegative[$config["CacheSize"]])],
      Print["CacheSize must be a nonnegative integer or \[Infinity].  Please update the configuration using ConfigureMaTeX[\"CacheSize\" -> \[Ellipsis]]."];
      cacheSizeOK = False,
      cacheSizeOK = True
    ];

    $configOK = pdflatexOK && gsOK && cacheSizeOK;
    If[Not[$configOK] && $Notebooks, 
      Print@StringForm["`` for documentation on configuring MaTeX.", Hyperlink["Click here", "paclet:MaTeX/tutorial/ConfiguringMaTeX"]]
	];
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
        {AbsoluteFileName::nffil, AbsoluteFileName::fdnfnd, General::fstr}
      ];
      If[Not@MemberQ[pathList, texpath],
        SetEnvironment["PATH" -> Environment["PATH"] <> pathSeparator <> texpath]
      ];
      Environment["PATH"]
    ]


checkConfig[]; (* check configuration and set $configOK *)
fixSystemPath[]; (* fix path for XeTeX *)


ConfigureMaTeX::badkey = "Unknown configuration key: ``. Valid keys are: " <> ToString[Keys[$defaultConfig], InputForm] <> ".";
SyntaxInformation[ConfigureMaTeX] = {"ArgumentsPattern" -> {OptionsPattern[]}, "OptionNames" -> Keys[$defaultConfig]};

ConfigureMaTeX[rules___Rule] :=
    (Scan[
      If[KeyExistsQ[$defaultConfig, First[#]], AppendTo[$config, #], Message[ConfigureMaTeX::badkey, First[#]]]&,
      {rules}
    ];
    checkConfig[];
    fixSystemPath[];
    Export[$configFile, $config, "Package"];
    Normal[$config]
    )


ranid[] := StringJoin@RandomChoice[CharacterRange["a", "z"], 16]


(* Create temporary directory *)
dirpath = FileNameJoin[{$TemporaryDirectory, StringJoin["MaTeX_", ranid[]]}];
CreateDirectory[dirpath];


(* Thank you to David Carlisle and Tom Hejda for help with the LaTeX code in template.tex. *)
(* Warning: Do not use FileTemplate because it mishandles CR/LF. *)
template = StringTemplate@Import[FileNameJoin[{DirectoryName[$InputFileName], "template.tex"}], "Text", CharacterEncoding -> "UTF-8"];

(* Fix for StringDelete not being available in M10.0 *)
If[$VersionNumber >= 10.1,
  stringDelete = StringDelete,
  stringDelete[s_String, patt_] := StringReplace[s, patt -> ""]
]

(* Interprets a UTF-8 encoded string stored as a byte sequence *)
fromUTF8[s_String] := FromCharacterCode[ToCharacterCode[s], "UTF-8"]

errorLinePattern = ("! "~~___) | ("!"~~___~~"error"~~___) | (___~~"Fatal error occurred"~~___);

parseTeXError[err_String] :=
    Module[{lines, line, i=0, eof, errLinesLimit = 3, errLineCounter, result},
      lines = StringSplit[stringDelete[err, "\r"] (* fix for CR/LF on Windows *), "\n"];
      eof = Length[lines];
      line := lines[[i]];
      result = Last@Reap@While[True,
        If[i == eof, Break[]];
        i += 1;
        If[StringMatchQ[line, errorLinePattern],
          Sow[line]
        ];
        If[StringMatchQ[line, "! Undefined control sequence." | ("! LaTeX Error:"~~___)],
          While[True,
            If[i == eof, Break[]];
            i += 1;
            errLineCounter = 0;
            Which[
              StringMatchQ[line, "! *"],
              i -= 1; (* another error line found, handle it in the main loop *)
              Break[]
              ,
              StringMatchQ[line, "l."~~(DigitCharacter..)~~___],
              Sow@stringDelete[line, StartOfString~~"l."~~(DigitCharacter..)~~Whitespace];
              Break[];
              ,
              StringMatchQ[line,
                ("See the LaTeX manual or LaTeX Companion for explanation."~~___) |
                ("Type  H <return>  for immediate help."~~___) |
                (" ..."~~___) |
                ("Enter file name: ") |
                Whitespace | ""],
              Null (* do nothing *)
              ,
              True,
              Sow[line];
              errLineCounter += 1;
            ];
            If[errLineCounter == errLinesLimit, Break[]]
          ];
        ];
      ];
      (* this conditional is necessary in case no error line was Sown and result === {} *)
      If[result =!= {},
        result = First[result];
      ];
      Style[StringJoin@Riffle[result, "\n"], "OutputForm"]
    ]

(* This function is used to try to detect errors based on the log file.
   It is necessary because on Windows RunProcess doesn't capture the correct exit code. *)
texErrorQ[log_String] := Count[StringSplit[stringDelete[log, "\r"], "\n"], line_ /; StringMatchQ[line, errorLinePattern]] > 0

getDimensions[log_String] := Interpreter["Number"]@StringCases[log, RegularExpression["MATEX"<>#<>":(.+?)pt"] -> "$1"]& /@ {"WIDTH", "HEIGHT", "DEPTH"}

extractOption[g_, opt_] := opt /. Options[g, opt]


cache = <||>;

SetAttributes[store, HoldFirst]
store[memoStore_, keys_, values_] :=
    (AssociateTo[memoStore, Thread[keys -> values]]; (* do not use AssocationThread; associations are not supported as 2nd arg of AssociateTo in v10.0 *)
    If[Length[memoStore] > $config["CacheSize"],
      memoStore = Take[memoStore, -$config["CacheSize"]]
    ];
    values
    )


SyntaxInformation[ClearMaTeXCache] = {"ArgumentsPattern" -> {}};
ClearMaTeXCache[] := (cache = <||>;)


Options[MaTeX] = {
  "BasePreamble" -> {"\\usepackage{lmodern,exscale}", "\\usepackage{amsmath,amssymb}"},
  "Preamble" -> {},
  "DisplayStyle" -> True,
  ContentPadding -> True,
  LineSpacing -> {1.2, 0},
  FontSize -> 12,
  Magnification -> 1,
  "LogFileFunction" -> None,
  "TeXFileFunction" -> None
};
SyntaxInformation[MaTeX] = {"ArgumentsPattern" -> {_, OptionsPattern[]}};

MaTeX::gserr     = "Error while running Ghostscript.";
MaTeX::texerr    = "Error while running LaTeX.\n``";
MaTeX::stderr    = "Additional error information received:\n``";
MaTeX::nopdf     = "LaTeX failed to produce a PDF file.";
MaTeX::importerr = "Failed to import PDF. This is unexpected. Please go to https://github.com/szhorvat/MaTeX and create a bug report.";
MaTeX::invopt    = "Invalid option value: ``.";

$psfactor = 72/72.27; (* conversion factor from TeX points to PostScript points *)

iMaTeX[tex:{__String}, preamble_, display_, fontsize_, strut_, ls : {lsmult_, lsadd_}, logFileFun_, texFileFun_] :=
    Module[{keys, cleanup, name, content,
            texfile, pdffile, pdfgsfile, logfile, auxfile,
            return, results, stderr,
            width, height, depth},

      (* If all entries are already cached, use cache; otherwise recompile using LaTeX *)
      keys = {#, Union[preamble], display, fontsize, strut, ls}& /@ tex;
      If[SubsetQ[Keys[cache], keys],
        Return[Lookup[cache, keys]]
      ];

      cleanup[] := If[fileQ[#], DeleteFile[#]]& /@ {texfile, pdffile, pdfgsfile, logfile, auxfile};   
      name = ranid[];

      (* Note: StringTemplate automatically numericizes expressions like Sqrt[2]. *)
      content = <|
          "preamble" -> StringJoin@Riffle[preamble, "\n"],
          "tex" -> StringJoin@Riffle[StringTemplate["\\MaTeX{``}"] /@ tex, "\n"],
          "display" -> If[display, "\\displaystyle", ""],
          "strut" -> If[strut, "\\strut", ""],
          "fontsize" -> fontsize,
          "skipsize" -> lsmult fontsize + lsadd
          |>;
      texfile = Export[FileNameJoin[{dirpath, name <> ".tex"}], template[content], "Text", CharacterEncoding -> "UTF-8"];
      If[texFileFun =!= None, With[{str = Import[texfile, "Text", CharacterEncoding -> "UTF-8"]}, texFileFun[str]]];

      pdffile = FileNameJoin[{dirpath, name <> ".pdf"}];
      pdfgsfile = FileNameJoin[{dirpath, name <> "-gs.pdf"}];
      logfile = FileNameJoin[{dirpath, name <> ".log"}];
      auxfile = FileNameJoin[{dirpath, name <> ".aux"}];

      return = runProcess[{$config["pdfLaTeX"], "-halt-on-error", "-interaction=nonstopmode", texfile}, ProcessDirectory -> dirpath];
      If[logFileFun =!= None, With[{str = Import[logfile, "Text", CharacterEncoding -> "UTF-8"]}, logFileFun[str]]];

      If[
        return["ExitCode"] != 0 ||
        texErrorQ[return["StandardOutput"]] (* workaround for Windows, where the exit code may be misreported *)
        ,
        Message[MaTeX::texerr, parseTeXError[fromUTF8@return["StandardOutput"]]];
        (* MiKTeX will output useful messages to stderr when there was a serious system error. *)
        If[KeyExistsQ[return, "StandardError"],
          stderr = StringTrim@stringDelete[return["StandardError"], "\r"];
          If[stderr =!= "",
            Block[{$MessagePrePrint = Identity}, (* do not truncate the error message *)
              Message[MaTeX::stderr, Style[stderr, "OutputForm"]]
            ]
          ]
        ];
        cleanup[];
        Return[$Failed]
      ];

      If[Not@FileExistsQ[pdffile],
        Message[MaTeX::nopdf];
        cleanup[];
        Return[$Failed]
      ];

      {width, height, depth} = getDimensions[return["StandardOutput"]];
      (* +2 is for the 1 pt border on each side *)
      width  += 2;
      height += depth+2;
      {width, height, depth} *= $psfactor; (* correct for PostScript point *)

      return = runProcess[{$config["Ghostscript"], "-o", pdfgsfile, "-dNoOutputFonts", "-sDEVICE=pdfwrite", pdffile}, ProcessDirectory -> dirpath];
      If[return["ExitCode"] != 0,
        Message[MaTeX::gserr];
        cleanup[];
        Return[$Failed]
      ];

      results = Import[pdfgsfile, "PDF"];
      cleanup[];
      If[results === $Failed,
        Message[MaTeX::importerr];
        Return[$Failed]
      ];
      
      results = MapThread[Show[#1, ImageSize -> {#2, #3}, BaselinePosition -> Scaled[(#4+$psfactor)/#3]]&,{results,width,height,depth}]; (* +$psfactor is for 1 pt border *)
      
      store[cache, keys, results]
    ]

MaTeX::warn = "Warning: ``";

(* check for common errors and warn user without aborting *)
checkForCommonErrors[str_String] :=
    Which[
      StringMatchQ[str, ("$$"~~___)|(___~~"$$")],
      Message[MaTeX::warn, "$$ delimiter used. MaTeX expects math-mode input by default. Use the \"DisplayStyle\" option to choose inline or display styles."]
      ,
      StringMatchQ[str, "\\begin{equation}"~~___],
      Message[MaTeX::warn, "\\begin{equation} used. MaTeX expects math-mode input by default. Use the \"DisplayStyle\" option to choose inline or display styles."]
      ,
      StringMatchQ[str, ("$"~~___)|(___~~"$")],
      Message[MaTeX::warn, "$ delimiter used. MaTeX expects math-mode input by default."]
      ,
      StringMatchQ[str, ___~~"\\"] && Not@StringMatchQ[str, ___~~"\\\\"],
      Message[MaTeX::warn, "Input ends in \\. \[VeryThinSpace]Did you forget to use \\\\ to denote a single backslash?"]
      ,
      StringMatchQ[str, "\\begin{eqnarray}"~~___],
      Message[MaTeX::warn, "\\begin{eqnarray} cannot be used in math-mode. MaTeX expects math-mode input by default. Use \\begin{aligned} to typeset systems of equations."]
      ,
      StringMatchQ[str, "\\begin{eqnarray\\*}"~~___],
      Message[MaTeX::warn, "\\begin{eqnarray*} cannot be used in math-mode. MaTeX expects math-mode input by default. Use \\begin{aligned} to typeset systems of equations."]
    ]


(* Convert supported expression types to a string contaninig TeX code *)
texify[expr_String] := expr
texify[expr_StringForm] := ToString[expr] (* per user request, StringForm is treated like the string it represents; may be removed in the future; use StringTemplate instead. *)
texify[expr_TeXForm] := ToString[expr]
texify[expr_] := ToString@TeXForm[expr]


MaTeX[tex:{__String}, opt:OptionsPattern[]] :=
    Module[{basepreamble, preamble, mag, results, trimmedTeX},
      (* check that MaTeX is configured *)
      If[! $configOK, checkConfig[]; Return[$Failed]];

      (* verify option values for correctness *)
      preamble = OptionValue["Preamble"];
      If[preamble === None, preamble = {}];
      If[Not@VectorQ[preamble, StringQ],
        Message[MaTeX::invopt, "Preamble" -> preamble];
        Return[$Failed]
      ];
      basepreamble = OptionValue["BasePreamble"];
      If[basepreamble === None, basepreamble = {}];
      If[Not@VectorQ[basepreamble, StringQ],
        Message[MaTeX::invopt, "BasePreamble" -> basepreamble];
        Return[$Failed]
      ];
      preamble = Join[basepreamble, preamble];
      If[Not@BooleanQ@OptionValue["DisplayStyle"],
        Message[MaTeX::invopt, "DisplayStyle" -> OptionValue["DisplayStyle"]];
        Return[$Failed]
      ];
      If[Not@BooleanQ@OptionValue[ContentPadding],
        Message[MaTeX::invopt, ContentPadding -> OptionValue[ContentPadding]];
        Return[$Failed]
      ];
      If[Not[NumericQ@OptionValue[FontSize] && TrueQ@Positive@OptionValue[FontSize]],
        Message[MaTeX::invopt, FontSize -> OptionValue[FontSize]];
        Return[$Failed]
      ];
      If[Not[MatchQ[OptionValue[LineSpacing], {mult_, add_} /; NumericQ[mult] && TrueQ@NonNegative[mult] && NumericQ[add]]],
        Message[MaTeX::invopt, LineSpacing -> OptionValue[LineSpacing]];
        Return[$Failed]
      ];
      mag = OptionValue[Magnification];
      If[Not[NumericQ[mag] && TrueQ@Positive[mag]],
        Message[MaTeX::invopt, Magnification -> mag];
        Return[$Failed]
      ];

      (* trim extra newlines from input and check for common errors *)
      trimmedTeX = StringTrim[tex, "\n"..];
      checkForCommonErrors /@ trimmedTeX;

      (* do the main work *)
      results =
          iMaTeX[trimmedTeX, preamble,
            OptionValue["DisplayStyle"], OptionValue[FontSize], OptionValue[ContentPadding], OptionValue[LineSpacing],
            OptionValue["LogFileFunction"], OptionValue["TeXFileFunction"]
          ];

      (* pass through $Failed; apply magnification *)
      If[results === $Failed || TrueQ[mag == 1],
        results,
        Show[#, ImageSize -> N[mag] extractOption[#, ImageSize]]& /@ results
      ]
    ]

MaTeX[{}, opt:OptionsPattern[]] := {} (* prevent infinite recursion *)

MaTeX[tex_List, opt:OptionsPattern[]] := MaTeX[texify /@ tex, opt]

MaTeX[tex_, opt:OptionsPattern[]] := With[{result = MaTeX[{tex}, opt]}, If[result === $Failed, $Failed, First[result]]]


BlackFrame = Directive[AbsoluteThickness[0.5], Black];


(* Protect all package symbols *)
With[{syms = Names["MaTeX`*"]}, SetAttributes[syms, {Protected, ReadProtected}] ];

End[]; (* End Private Context *)

EndPackage[];
