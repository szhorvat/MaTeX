[![Join the chat at https://gitter.im/MaTeX-help/Lobby](https://badges.gitter.im/MaTeX-help/Lobby.svg)](https://gitter.im/MaTeX-help/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![GitHub (pre-)release](https://img.shields.io/github/release/szhorvat/MaTeX/all.svg)](https://github.com/szhorvat/MaTeX/releases)
[![Github All Releases](https://img.shields.io/github/downloads/szhorvat/MaTeX/total.svg)](https://github.com/szhorvat/MaTeX/releases)
[![Contributions welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](https://github.com/szhorvat/MaTeX/issues)
[![DOI](https://zenodo.org/badge/31675019.svg)](https://zenodo.org/badge/latestdoi/31675019)

# MaTeX

Create LaTeX labels in *Mathematica*.

在 Mathematica 里使用 LaTeX 的输出效果

See [the blog post](http://szhorvat.net/pelican/latex-typesetting-in-mathematica.html) for a detailed introduction to MaTeX and up to date troubleshooting information.

请参阅[博客文章](http://szhorvat.net/pelican/latex-typesetting-in-mathematica.html)，以获取有关 MaTeX 的详细介绍和最新的故障排除信息。

## Installation 安装



**In Mathematica 11.3 or later, simply evaluate `ResourceFunction["MaTeXInstall"][]` to install or upgrade MaTeX.**

**在 Mathematica 11.3 或更高版本中，只需运行 `ResourceFunction["MaTeXInstall"][]` 即可安装或升级 MaTeX。**

In older versions that do not support resource functions, follow the manual installation instructions:

在不支持资源功能的旧版本中，请遵循手动安装说明：

 - [Download the latest release](https://github.com/szhorvat/MaTeX/releases), distributed as a `.paclet` file, and install it using the `PacletInstall` function in Mathematica.  For example, assuming that the file `MaTeX-1.7.5.paclet` was downloaded into the directory `~/Downloads`, evaluate

- [下载最新版本](https://github.com/szhorvat/MaTeX/releases)，以 `.paclet` 文件形式分发，并使用 Mathematica 中的 `PacletInstall` 函数进行安装。例如，假设文件 "MaTeX-1.7.5.paclet" 已下载到目录 `~/Downloads` 中，请执行

    ```mathematica
    Needs["PacletManager`"]
    PacletInstall["~/Downloads/MaTeX-1.7.5.paclet"]
    ```

    The most convenient way to obtain the path to a file is Mathematica's Insert → File Path... menu command.

    获取文件路径的最便捷方法是 Mathematica 的 插入→文件路径... 菜单命令。


 - Make sure that [a TeX system](https://tug.org/begin.html) and Ghostscript 9.15 or later are installed.  

 - 确保已安装 [TeX 系统](https://tug.org/begin.html) 和 Ghostscript 9.15 或更高版本。

     For Windows and Linux, the latest Ghostscript is available from [its official download page](http://ghostscript.com/download/gsdnld.html).  

     对于 Windows 和 Linux，可从 [其官方下载页面](http://ghostscript.com/download/gsdnld.html) 获得最新的 Ghostscript。

     On OS X, MacTeX 2015 and later already include a compatible version of Ghostscript. If you use an older TeX distribution that doesn't, please obtain a recent Ghostscript from [Richard Koch's page](http://pages.uoregon.edu/koch/).

     在 OS X 上，MacTeX 2015 和更高版本已包含兼容版本的 Ghostscript。如果您使用的不是较旧的 TeX 发行版，请从 [Richard Koch 的页面](http://pages.uoregon.edu/koch/) 获取最新的 Ghostscript。

 - Evaluate ``<<MaTeX` ``.  MaTeX will attempt to auto-configure itself when it is loaded for the first time.  If auto-configuration fails, it will display instructions on how to configure the path to the `pdflatex` and Ghostscript executables manually.  *Note:* On Windows systems use the command line Ghostscript executable, i.e. the one with the name ending in c: `gswin32c.exe` or `gswin64c.exe`.

 - 运行 ``<<MaTeX` ``。首次加载时，MaTeX 会尝试自动进行自我配置。如果自动配置失败，它将显示有关如何手动配置 pdflatex 和 Ghostscript 可执行文件的路径的说明。 *注意：* 在 Windows 系统上，请使用命令行 Ghostscript 可执行文件，即名称以 c 结尾的文件：gswin32c.exe 或 gswin64c.exe。

 - Test MaTeX using `MaTeX["x^2"]`.

 - 用 `MaTeX ["x ^ 2"]` 测试 MaTeX。

    Open the documentation center and search for "MaTeX" to get started.

    打开文档中心，搜索 "MaTeX" 以开始使用。

## Upgrading or uninstalling 升级或卸载

A newer version can be safely installed when an older version is already present.  ``<<MaTeX` `` will always load the latest installed MaTeX that is compatible with your version of Mathematica.

当已经存在旧版本时，可以安全地安装新版本。 ``<<MaTeX` `` 将始终加载与您的 Mathematica 版本兼容的最新安装的 MaTeX。

A list of all installed versions can be retrieved using

可以使用以下命令检索所有已安装版本的列表

```mathematica
    PacletFind["MaTeX"]
```

Any of the items in the list can be uninstalled by applying `PacletUninstall` to it.  To uninstall all versions at once, use

可以通过运行 `PacletUninstall` 来卸载列表中的任何项目。要一次卸载所有版本，请使用

```mathematica
    PacletUninstall["MaTeX"]
```

To see more information about the version that gets loaded by `Needs`, use

要查看有关 `Needs` 加载的版本的更多信息，请使用

```mathematica
    PacletInformaton["MaTeX"]
```

**Note:** If you installed MaTeX before it started using the paclet distribution format (i.e. version 1.6.2), uninstall it by removing the `MaTeX` directory from the following location:

**注意：** 如果您是在开始使用 paclet 分发格式（即 1.6.2 版）之前安装 MaTeX 的，请通过从以下位置删除 `MaTeX` 目录来卸载它。

```mathematica
    SystemOpen@FileNameJoin[{$UserBaseDirectory, "Applications"}]
```

----

The following function will automatically download the latest release of MaTeX and install it:

以下函数将自动下载并安装最新版本的 MaTeX：

```mathematica
    updateMaTeX[] :=
      Module[{json, download, target},
        Check[
          json = Import["https://api.github.com/repos/szhorvat/MaTeX/releases/latest", "JSON"];
          download = Lookup[First@Lookup[json, "assets"], "browser_download_url"];
          target = FileNameJoin[{CreateDirectory[], "MaTeX.paclet"}];
          If[$Notebooks,
            PrintTemporary@Labeled[ProgressIndicator[Appearance -> "Necklace"], "Downloading...", Right],
            Print["Downloading..."]
          ];
          URLSave[download, target]
          ,
          Return[$Failed]
        ];
        If[FileExistsQ[target], PacletManager`PacletInstall[target], $Failed]
      ]
```

After evaluating the function definition above, just run `updateMaTeX[]`, then ``<<MaTeX` `` to load the updated version.

在运行了上面的函数定义之后，只需运行 `updateMaTeX[]`，然后运行 ``<<MaTeX` ``，以加载更新的版本。

## Usage 用法

Use `MaTeX[texcode]` or `MaTeX[expression]` to typeset using LaTeX.  The latter will automatically apply `TeXForm` to `expression`.

使用 `MaTeX [texcode]` 或 `MaTeX [expression]` 使用 LaTeX 进行排版。后者将自动将 `TeXForm` 应用于 `expression`。

The LaTeX code is interpreted in math mode.  Remember to escape backlashes (i.e. type *two* `\` characters when you mean one) when writing LaTeX code in Mathematica strings, e.g.

LaTeX 代码以数学模式解释。在 Mathematica 字符串中编写 LaTeX 代码时，请记住要避免反斜杠（即当你想表示一个 `\` 时请输入 *两个* `\` 字符），例如

```Mathematica
    MaTeX["\\sum_{k=1}^{\\infty} \\frac{1}{k}"]
```

Multiple expressions can also be processed in one go:

也可以一次性处理多个表达式：

```Mathematica
    MaTeX[{
      "\\frac{x^2}{\\sqrt{3}}",
      HoldForm[Integrate[Sin[x], {x, 0, 2 Pi}]],
      Expand[(1 + x)^5]
    }]
```

Processing a list of expressions together involves a single run of LaTeX, thus is much faster than processing each separately.

一起处理表达式列表仅需要运行一次 LaTeX ，因此比分别处理每个表达式要快得多。

For more usage instructions, search for "MaTeX" in the documentation center.

有关更多用法说明，请在文档中心中搜索 "MaTeX"。

## Notes on performance 性能说明

The limiting factor in the speed of `MaTeX` calls is running the `pdflatex` process, which might take as long as a second and cannot be sped up further.  However, MaTeX caches results, making subsequent calls with the same TeX code near-instantaneous.  MaTeX can also process a list of expressions using a single run of LaTeX, which is much faster than processing each separately.

`MaTeX` 调用速度的瓶颈是运行 `pdflatex` 进程，该过程可能需要一秒钟的时间，无法进一步加快。但是，MaTeX 会缓存结果，从而使得使用相同 TeX 代码的后续调用几乎是瞬时的。 MaTeX 还可以使用 LaTeX 一次性运行处理表达式列表，这比分别处理每个表达式要快得多。

## Revision history 修订记录

#### Version 1.7.5 版本 1.7.5

 - Documentation improvements
 - Improved error reporting

#### Version 1.7.4 版本 1.7.4

 - Documentation improvements

#### Version 1.7.3 版本 1.7.3

 - Added `"WorkingDirectory"` configuration option. This allows users to work around a `RunProcess` bug in some Mathematica versions on Windows where `RunProcess` would fail in a directory with non-ASCII characters in its name.
 - Exposed ``MaTeX`Developer`Texify``, to allow users to customize the expression to TeX code conversion. See Neat Examples in the MaTeX symbol documentation page.
 - Documentation improvements

#### Version 1.7.2 版本 1.7.2

 - Better compatibility with the new documentation search in Mathematica 11.2
 - Better error reporting in case of Ghostscript failure
 - Documentation improvements

#### Version 1.7.1 版本 1.7.1

 - Work around a rare `RunProcess` bug that affects some Mathematica 10.0 installations on Linux
 - Documentation improvements, along with a new tutorial on figure preparation

#### Version 1.7.0 版本 1.7.0

 - Internal refactoring, minor bug fixes and polish
 - New functions in ``MaTeX`Developer` `` to aid troubleshooting
 - Bug fix: running Ghostscript or pdflatex would fail on certain Linux distributions due to Mathematica changing `LD_LIBRARY_PATH`

#### Version 1.6.3 版本 1.6.3

 - More robust error checking and reporting
 - Documentation improvements

#### Version 1.6.2 版本 1.6.2

 - The documentation is now integrated into the Documentation Center.
 - Bug fix: full compatibility with Mathematica 10.0 restored.

#### Version 1.6.1 版本 1.6.1

 - Bug fix: better error checking for the CacheSize configuration option.

#### Version 1.6.0 版本 1.6.0

 - `MaTeX` now threads over lists. A list is batch-processed using a single run of LaTeX, which is much faster than element-wise processing. Implemented by [Andreas Ahlrichs](https://github.com/aquadr).

    Note that this changes behaviour slightly.  Previous versions of MaTeX compiled `MaTeX[{1, x^2, x/2}]` as a single expression.  Now each element of the list is converted to a separate result.  To restore the old behaviour, apply `TeXForm` explicitly: `MaTeX[TeXForm[{1, x^2, x/2}]`.

 - Expressions with head `TeXForm` are now automatically handled.

 - Bug fixes: Better handling of CR/LF line endings and character encodings.

#### Version 1.5.0 版本 1.5.0

 - Much improved LaTeX error reporting. Please report any problems you notice with the new error reporting.
 - MaTeX now checks for common user errors and issues warnings.  Turn them off using `Off[MaTeX::warn]`.

#### Version 1.4.0 版本 1.4.0

 - Separated `"Preamble"` and `"BasePreamble"` options.  The default preamble is now in `"BasePreamble"`.  The `"Preamble"` option can be set without needing to worry about the default.
 - Package symbols are protected
 - MaTeX now follows the standard Mathematica package structure.  This means that it now consists of multiple files.  Move the entire MaTeX directory (and not just `MaTeX.m`) into `$UserBaseDirectory/Applications` to install.

#### Version 1.3.0 版本 1.3.0

 - Added the `"TeXFileFunction"` and `"LogFileFunction"` options for easier debugging.  Set them to `Print` to see the generated LaTeX code or the LaTeX log file.

#### Version 1.2.0 版本 1.2.0

 - Added `ContentPadding` option: `ContentPadding -> True` ensures that the the output height is at least one line height
 - Added `LineSpacing` option
 - The size of vertical borders is slightly different now: use `LineSpacing -> {0, 14.4}` to reproduce the older behaviour
 - Bug fixes

#### Version 1.1.1 版本 1.1.1

 - Reliability fixes for Windows
 - Windows: Work around Mathematica bug causing MaTeX to fail when the current directory has special characters in its name
 - Windows: Ensure that auto-detected paths do not use `/` as path separator

#### Version 1.1.0 版本 1.1.0

 - MaTeX now attempts to automatically detect the location of Ghostscript and pdflatex on first run
 - Syntax highlighting for MaTeX functions (added SyntaxInformation)
 - Minor bug fixes and reliability fixes

#### Version 1.0.0 版本 1.0.0

 - Minor bug fixes and compatibility fixes

#### Version 0.3 版本 0.3

 - Bug fixes and other compatibility fixes: works with XeTeX and behaves better on Windows.  

#### Version 0.2 版本 0.2

 - Automatic baseline alignment.  MaTeX output is now perfectly aligned with Mathematica text.
 - Improved positioning accuracy
 - Added `FontSize` option (now requires the `lmodern` package)
 - Support for some accented characters
 - More robust `Magnification` handling

#### Version 0.1 版本 0.1

 - Initial release

## Feedback 反馈

MaTeX was primarily created for my own needs.  However, if you find it useful, feel free to drop me an email.

MaTeX 主要是为满足我自己的需求而创建的。但是，如果您觉得有用，请随时给我发送电子邮件。

Send feedback or bug reports to `szhorvat` at `gmail.com` or [open an issue in the tracker](https://github.com/szhorvat/MaTeX/issues).

将反馈或错误报告发送至 gmail.com 上的 szhorvat 或 [在跟踪器中打开问题](https://github.com/szhorvat/MaTeX/issues)。